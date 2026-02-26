#!/bin/bash
# cost-tracking.sh - Monitor API costs and token usage per session/task
# Based on Anthropic's "Effective Harnesses for Long-Running Agents"

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/common.sh"

PROJECT_ROOT="${PROJECT_ROOT:-$(pwd)}"
DEVTEAM_DIR="${PROJECT_ROOT}/.devteam"
DB_FILE="${DEVTEAM_DIR}/devteam.db"
COST_LOG="${DEVTEAM_DIR}/cost-log.json"

# Register temp file cleanup
setup_temp_cleanup

# Pricing (updated for Claude 4.5/4.6 models -- February 2026)
declare -A MODEL_PRICING
# Current Claude models
MODEL_PRICING["claude-opus-4-6"]="15.00:75.00"             # Opus 4.6 (input:output per 1M tokens)
MODEL_PRICING["claude-sonnet-4-5-20250929"]="3.00:15.00"    # Sonnet 4.5
MODEL_PRICING["claude-haiku-4-5-20251001"]="0.80:4.00"      # Haiku 4.5
# Aliases for short model names used by plugin.json
MODEL_PRICING["opus"]="15.00:75.00"
MODEL_PRICING["sonnet"]="3.00:15.00"
MODEL_PRICING["haiku"]="0.80:4.00"
# Legacy Claude models (for historical data)
MODEL_PRICING["claude-opus-4-5-20251101"]="15.00:75.00"
MODEL_PRICING["claude-sonnet-4-20250514"]="3.00:15.00"
MODEL_PRICING["claude-haiku-4-20250414"]="0.80:4.00"
MODEL_PRICING["claude-3-5-sonnet-20241022"]="3.00:15.00"
MODEL_PRICING["claude-3-5-haiku-20241022"]="0.80:4.00"

# Check for bc dependency -- required for cost calculations
_BC_AVAILABLE=true
if ! command -v bc &>/dev/null; then
    log_error "bc is not installed; cost tracking requires bc for calculations" "cost"
    log_error "  Install: apt-get install bc (Debian/Ubuntu), brew install bc (macOS)" "cost"
    _BC_AVAILABLE=false
fi

# Ensure directories
ensure_dirs() {
    mkdir -p "$DEVTEAM_DIR"
}

# Calculate cost for tokens
# NOTE: Returns cost in USD (dollars), NOT cents.
# - This script stores USD in token_usage.cost_usd
# - state.sh/events.sh use CENTS in sessions.total_cost_cents and agent_runs.cost_cents
# - Callers bridging between the two systems must convert (* 100 for dollars→cents)
calculate_cost() {
    local model="$1"
    local input_tokens="$2"
    local output_tokens="$3"

    # Validate inputs are numeric
    if ! [[ "$input_tokens" =~ ^[0-9]+$ ]] || ! [[ "$output_tokens" =~ ^[0-9]+$ ]]; then
        log_error "Non-numeric token values: input=$input_tokens output=$output_tokens" "cost"
        echo "0"
        return 1
    fi

    if [ "$_BC_AVAILABLE" != "true" ]; then
        log_error "bc not available for cost calculation" "cost"
        echo "0"
        return 1
    fi

    local pricing="${MODEL_PRICING[$model]:-3.00:15.00}"
    local input_price="${pricing%%:*}"
    local output_price="${pricing##*:}"

    # Cost = (tokens / 1,000,000) * price
    local input_cost
    input_cost=$(echo "scale=6; $input_tokens / 1000000 * $input_price" | bc | sed 's/^\./0./')
    local output_cost
    output_cost=$(echo "scale=6; $output_tokens / 1000000 * $output_price" | bc | sed 's/^\./0./')
    local total_cost
    total_cost=$(echo "scale=6; $input_cost + $output_cost" | bc | sed 's/^\./0./')

    echo "$total_cost"
}

# Record API usage
record_usage() {
    local session_id="${1:-$(date +%Y%m%d)}"
    local task_id="${2:-none}"
    local model="${3:-claude-3-5-sonnet}"
    local input_tokens="${4:-0}"
    local output_tokens="${5:-0}"
    local operation="${6:-unknown}"

    ensure_dirs

    local cost
    cost=$(calculate_cost "$model" "$input_tokens" "$output_tokens")
    local timestamp
    timestamp=$(date -Iseconds)

    # Append to JSON log
    local esc_ts esc_sid esc_tid esc_model esc_op
    esc_ts=$(json_escape "$timestamp")
    esc_sid=$(json_escape "$session_id")
    esc_tid=$(json_escape "$task_id")
    esc_model=$(json_escape "$model")
    esc_op=$(json_escape "$operation")

    local entry
    entry=$(cat << JSONEOF
{
    "timestamp": "${esc_ts}",
    "session_id": "${esc_sid}",
    "task_id": "${esc_tid}",
    "model": "${esc_model}",
    "input_tokens": ${input_tokens},
    "output_tokens": ${output_tokens},
    "total_tokens": $((input_tokens + output_tokens)),
    "cost_usd": ${cost},
    "operation": "${esc_op}"
}
JSONEOF
)

    # Initialize or append to cost log
    if [[ ! -f "$COST_LOG" ]]; then
        echo "[$entry]" > "$COST_LOG"
    else
        # Portable sed: use temp file instead of sed -i
        local tmp
        tmp=$(safe_mktemp)
        sed '$ s/]$/,/' "$COST_LOG" > "$tmp" && mv "$tmp" "$COST_LOG"
        echo "$entry]" >> "$COST_LOG"
    fi

    # Also record in database if available
    if [[ -f "$DB_FILE" ]]; then
        # Validate numeric values before SQL interpolation
        if ! [[ "$input_tokens" =~ ^[0-9]+$ ]]; then
            log_error "Invalid input_tokens value: $input_tokens" "cost"
            return 1
        fi
        if ! [[ "$output_tokens" =~ ^[0-9]+$ ]]; then
            log_error "Invalid output_tokens value: $output_tokens" "cost"
            return 1
        fi
        if ! [[ "$cost" =~ ^[0-9]+(\.[0-9]+)?$ ]]; then
            log_error "Invalid cost value: $cost" "cost"
            return 1
        fi

        local sql_sid sql_tid sql_model sql_op
        sql_sid=$(sql_escape "$session_id")
        sql_tid=$(sql_escape "$task_id")
        sql_model=$(sql_escape "$model")
        sql_op=$(sql_escape "$operation")

        sql_exec "INSERT INTO token_usage (session_id, task_id, model, input_tokens, output_tokens, cost_usd, operation, recorded_at) VALUES ('${sql_sid}', '${sql_tid}', '${sql_model}', ${input_tokens}, ${output_tokens}, ${cost}, '${sql_op}', datetime('now'));" > /dev/null
    fi

    log_info "Recorded: ${input_tokens}+${output_tokens} tokens = \$${cost} (${model})"
}

# Get session summary
session_summary() {
    local session_id="${1:-$(date +%Y%m%d)}"

    ensure_dirs

    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo " Session Cost Summary: ${session_id}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""

    if [[ -f "$DB_FILE" ]]; then
        local sql_sid
        sql_sid=$(sql_escape "$session_id")

        local total_input
        total_input=$(sql_exec "SELECT COALESCE(SUM(input_tokens), 0) FROM token_usage WHERE session_id='${sql_sid}';" 2>/dev/null || echo 0)
        local total_output
        total_output=$(sql_exec "SELECT COALESCE(SUM(output_tokens), 0) FROM token_usage WHERE session_id='${sql_sid}';" 2>/dev/null || echo 0)
        local total_cost
        total_cost=$(sql_exec "SELECT COALESCE(SUM(cost_usd), 0) FROM token_usage WHERE session_id='${sql_sid}';" 2>/dev/null || echo 0)
        local request_count
        request_count=$(sql_exec "SELECT COUNT(*) FROM token_usage WHERE session_id='${sql_sid}';" 2>/dev/null || echo 0)

        printf "  %-25s %s\n" "Session ID:" "$session_id"
        printf "  %-25s %s\n" "API Requests:" "$request_count"
        printf "  %-25s %s\n" "Input Tokens:" "$(format_number "$total_input")"
        printf "  %-25s %s\n" "Output Tokens:" "$(format_number "$total_output")"
        printf "  %-25s %s\n" "Total Tokens:" "$(format_number "$((total_input + total_output))")"
        printf "  %-25s \$%.4f\n" "Total Cost:" "$total_cost"

        echo ""
        echo "By Model:"
        echo "─────────────────────────────────────────────────────────────"
        sql_exec_table "SELECT model, COUNT(*) as requests, SUM(input_tokens) as input_tokens, SUM(output_tokens) as output_tokens, printf('%.4f', SUM(cost_usd)) as cost_usd FROM token_usage WHERE session_id='${sql_sid}' GROUP BY model ORDER BY SUM(cost_usd) DESC;"

        echo ""
        echo "By Operation:"
        echo "─────────────────────────────────────────────────────────────"
        sql_exec_table "SELECT operation, COUNT(*) as count, SUM(input_tokens + output_tokens) as tokens, printf('%.4f', SUM(cost_usd)) as cost_usd FROM token_usage WHERE session_id='${sql_sid}' GROUP BY operation ORDER BY SUM(cost_usd) DESC LIMIT 10;"
    else
        echo "No database found. Checking JSON log..."
        if [[ -f "$COST_LOG" ]]; then
            # Use jq if available, otherwise basic parsing
            if command -v jq &> /dev/null; then
                local total_cost
                total_cost=$(jq --arg sid "$session_id" '[.[] | select(.session_id == $sid) | .cost_usd] | add // 0' "$COST_LOG")
                local total_tokens
                total_tokens=$(jq --arg sid "$session_id" '[.[] | select(.session_id == $sid) | .total_tokens] | add // 0' "$COST_LOG")
                echo "  Total Tokens: ${total_tokens}"
                echo "  Total Cost: \$${total_cost}"
            else
                echo "  (Install jq for detailed JSON analysis)"
                grep -c "\"session_id\": \"${session_id}\"" "$COST_LOG" 2>/dev/null || echo "  No data for session"
            fi
        else
            echo "No cost data found."
        fi
    fi
    echo ""
}

# Get daily summary
daily_summary() {
    local date="${1:-$(date +%Y-%m-%d)}"

    ensure_dirs

    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo " Daily Cost Summary: ${date}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""

    if [[ -f "$DB_FILE" ]]; then
        local sql_date
        sql_date=$(sql_escape "$date")

        sql_exec_table "SELECT session_id, COUNT(*) as requests, SUM(input_tokens) as input_tokens, SUM(output_tokens) as output_tokens, printf('\$%.4f', SUM(cost_usd)) as total_cost FROM token_usage WHERE date(recorded_at) = '${sql_date}' GROUP BY session_id ORDER BY SUM(cost_usd) DESC;"

        echo ""
        echo "─────────────────────────────────────────────────────────────"
        local day_total
        day_total=$(sql_exec "SELECT printf('\$%.4f', COALESCE(SUM(cost_usd), 0)) FROM token_usage WHERE date(recorded_at)='${sql_date}';")
        echo "Daily Total: ${day_total}"
    else
        echo "No database found."
    fi
    echo ""
}

# Get overall totals
total_summary() {
    ensure_dirs

    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo " All-Time Cost Summary"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""

    if [[ -f "$DB_FILE" ]]; then
        local total_input
        total_input=$(sql_exec "SELECT COALESCE(SUM(input_tokens), 0) FROM token_usage;" 2>/dev/null || echo 0)
        local total_output
        total_output=$(sql_exec "SELECT COALESCE(SUM(output_tokens), 0) FROM token_usage;" 2>/dev/null || echo 0)
        local total_cost
        total_cost=$(sql_exec "SELECT COALESCE(SUM(cost_usd), 0) FROM token_usage;" 2>/dev/null || echo 0)
        local request_count
        request_count=$(sql_exec "SELECT COUNT(*) FROM token_usage;" 2>/dev/null || echo 0)
        local session_count
        session_count=$(sql_exec "SELECT COUNT(DISTINCT session_id) FROM token_usage;" 2>/dev/null || echo 0)

        printf "  %-25s %s\n" "Total Sessions:" "$session_count"
        printf "  %-25s %s\n" "Total API Requests:" "$(format_number "$request_count")"
        printf "  %-25s %s\n" "Total Input Tokens:" "$(format_number "$total_input")"
        printf "  %-25s %s\n" "Total Output Tokens:" "$(format_number "$total_output")"
        printf "  %-25s %s\n" "Total Tokens:" "$(format_number "$((total_input + total_output))")"
        printf "  %-25s \$%.4f\n" "Total Cost:" "$total_cost"

        echo ""
        echo "By Day (Last 7 Days):"
        echo "─────────────────────────────────────────────────────────────"
        sql_exec_table "SELECT date(recorded_at) as date, COUNT(*) as requests, SUM(input_tokens + output_tokens) as tokens, printf('\$%.4f', SUM(cost_usd)) as cost FROM token_usage WHERE recorded_at >= date('now', '-7 days') GROUP BY date(recorded_at) ORDER BY date(recorded_at) DESC;"

        echo ""
        echo "By Model (All Time):"
        echo "─────────────────────────────────────────────────────────────"
        sql_exec_table "SELECT model, COUNT(*) as requests, SUM(input_tokens + output_tokens) as tokens, printf('\$%.4f', SUM(cost_usd)) as cost FROM token_usage GROUP BY model ORDER BY SUM(cost_usd) DESC;"
    else
        echo "No database found."
    fi
    echo ""
}

# Set budget alert
set_budget() {
    local budget_type="$1"  # session, daily, monthly
    local amount="$2"

    # Validate inputs
    budget_type=$(sanitize_input "$budget_type" 32)
    if ! [[ "$amount" =~ ^[0-9]+(\.[0-9]+)?$ ]]; then
        log_error "Invalid budget amount: $amount" "cost"
        return 1
    fi

    ensure_dirs

    local budget_file="${DEVTEAM_DIR}/budgets.json"

    if [[ ! -f "$budget_file" ]]; then
        echo "{}" > "$budget_file"
    fi

    # Update budget
    local tmp_file
    tmp_file=$(safe_mktemp)
    if command -v jq &> /dev/null; then
        jq ".${budget_type} = ${amount}" "$budget_file" > "$tmp_file" && mv "$tmp_file" "$budget_file"
    else
        echo "{\"${budget_type}\": ${amount}}" > "$budget_file"
    fi

    log_info "Set ${budget_type} budget to \$${amount}"
}

# Check budget
check_budget() {
    local session_id="${1:-$(date +%Y%m%d)}"

    ensure_dirs

    local budget_file="${DEVTEAM_DIR}/budgets.json"

    if [[ ! -f "$budget_file" ]]; then
        log_info "No budgets configured"
        return 0
    fi

    if [[ -f "$DB_FILE" ]]; then
        local sql_sid
        sql_sid=$(sql_escape "$session_id")

        local session_cost
        session_cost=$(sql_exec "SELECT COALESCE(SUM(cost_usd), 0) FROM token_usage WHERE session_id='${sql_sid}';" 2>/dev/null || echo 0)
        local daily_cost
        daily_cost=$(sql_exec "SELECT COALESCE(SUM(cost_usd), 0) FROM token_usage WHERE date(recorded_at) = date('now');" 2>/dev/null || echo 0)

        if command -v jq &> /dev/null; then
            local session_budget
            session_budget=$(jq -r ".session // 0" "$budget_file")
            local daily_budget
            daily_budget=$(jq -r ".daily // 0" "$budget_file")

            echo ""
            echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            echo " Budget Status"
            echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            echo ""

            if [[ "$session_budget" != "0" ]]; then
                local session_pct
                session_pct=$(echo "scale=1; $session_cost / $session_budget * 100" | bc)
                printf "  Session: \$%.4f / \$%.2f (%s%%)\n" "$session_cost" "$session_budget" "$session_pct"
                if (( $(echo "$session_cost > $session_budget" | bc -l) )); then
                    log_warn "⚠️  SESSION BUDGET EXCEEDED!"
                elif (( $(echo "$session_cost > $session_budget * 0.8" | bc -l) )); then
                    log_warn "Session at 80%+ of budget"
                fi
            fi

            if [[ "$daily_budget" != "0" ]]; then
                local daily_pct
                daily_pct=$(echo "scale=1; $daily_cost / $daily_budget * 100" | bc)
                printf "  Daily:   \$%.4f / \$%.2f (%s%%)\n" "$daily_cost" "$daily_budget" "$daily_pct"
                if (( $(echo "$daily_cost > $daily_budget" | bc -l) )); then
                    log_warn "⚠️  DAILY BUDGET EXCEEDED!"
                elif (( $(echo "$daily_cost > $daily_budget * 0.8" | bc -l) )); then
                    log_warn "Daily at 80%+ of budget"
                fi
            fi
            echo ""
        fi
    fi
}

# Export to CSV
export_csv() {
    local output="${1:-${DEVTEAM_DIR}/cost-export.csv}"

    ensure_dirs

    if [[ -f "$DB_FILE" ]]; then
        sqlite3 -csv -header "$DB_FILE" "PRAGMA foreign_keys = ON; SELECT * FROM token_usage ORDER BY recorded_at DESC;" > "$output"
        log_info "Exported to ${output}"
    else
        log_error "No database found"
    fi
}

# Main
case "${1:-help}" in
    record)
        record_usage "${2:-}" "${3:-}" "${4:-sonnet}" "${5:-0}" "${6:-0}" "${7:-unknown}"
        ;;
    session)
        session_summary "${2:-$(date +%Y%m%d)}"
        ;;
    daily)
        daily_summary "${2:-$(date +%Y-%m-%d)}"
        ;;
    total|all)
        total_summary
        ;;
    budget)
        case "${2:-check}" in
            set)
                set_budget "${3:-daily}" "${4:-10}"
                ;;
            check)
                check_budget "${3:-$(date +%Y%m%d)}"
                ;;
            *)
                echo "Usage: $0 budget [set|check] [type] [amount]"
                ;;
        esac
        ;;
    export)
        export_csv "${2:-}"
        ;;
    help|*)
        echo "Usage: $0 <command> [args]"
        echo ""
        echo "Commands:"
        echo "  record <session> <task> <model> <input> <output> <op>"
        echo "                             Record API usage"
        echo "  session [session_id]       Show session summary"
        echo "  daily [date]               Show daily summary"
        echo "  total                      Show all-time totals"
        echo "  budget set <type> <amt>    Set budget (session/daily)"
        echo "  budget check [session]     Check budget status"
        echo "  export [file]              Export to CSV"
        echo ""
        echo "Examples:"
        echo "  $0 record ses01 task01 sonnet 5000 2000 code-gen"
        echo "  $0 session ses01"
        echo "  $0 budget set daily 25.00"
        echo "  $0 budget check"
        ;;
esac
