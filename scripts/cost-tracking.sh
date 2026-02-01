#!/bin/bash
# cost-tracking.sh - Monitor API costs and token usage per session/task
# Based on Anthropic's "Effective Harnesses for Long-Running Agents"

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="${PROJECT_ROOT:-$(pwd)}"
DEVTEAM_DIR="${PROJECT_ROOT}/.devteam"
DB_FILE="${DEVTEAM_DIR}/state.db"
COST_LOG="${DEVTEAM_DIR}/cost-log.json"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

log_info() { echo -e "${GREEN}[cost]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[cost]${NC} $1"; }
log_error() { echo -e "${RED}[cost]${NC} $1"; }

# Pricing (as of early 2025 - update as needed)
declare -A MODEL_PRICING
MODEL_PRICING["claude-3-opus"]="15.00:75.00"      # input:output per 1M tokens
MODEL_PRICING["claude-3-sonnet"]="3.00:15.00"
MODEL_PRICING["claude-3-haiku"]="0.25:1.25"
MODEL_PRICING["claude-3-5-sonnet"]="3.00:15.00"
MODEL_PRICING["claude-3-5-haiku"]="0.80:4.00"
MODEL_PRICING["gpt-4"]="30.00:60.00"
MODEL_PRICING["gpt-4-turbo"]="10.00:30.00"
MODEL_PRICING["gpt-4o"]="5.00:15.00"
MODEL_PRICING["gpt-4o-mini"]="0.15:0.60"

# Ensure directories
ensure_dirs() {
    mkdir -p "$DEVTEAM_DIR"
}

# Calculate cost for tokens
calculate_cost() {
    local model="$1"
    local input_tokens="$2"
    local output_tokens="$3"

    local pricing="${MODEL_PRICING[$model]:-3.00:15.00}"
    local input_price="${pricing%%:*}"
    local output_price="${pricing##*:}"

    # Cost = (tokens / 1,000,000) * price
    local input_cost
    input_cost=$(echo "scale=6; $input_tokens / 1000000 * $input_price" | bc)
    local output_cost
    output_cost=$(echo "scale=6; $output_tokens / 1000000 * $output_price" | bc)
    local total_cost
    total_cost=$(echo "scale=6; $input_cost + $output_cost" | bc)

    echo "$total_cost"
}

# Record API usage
record_usage() {
    local session_id="${1:-$(date +%Y%m%d)}"
    local task_id="${2:-none}"
    local model="${3:-claude-3-sonnet}"
    local input_tokens="${4:-0}"
    local output_tokens="${5:-0}"
    local operation="${6:-unknown}"

    ensure_dirs

    local cost
    cost=$(calculate_cost "$model" "$input_tokens" "$output_tokens")
    local timestamp
    timestamp=$(date -Iseconds)

    # Append to JSON log
    local entry
    entry=$(cat << EOF
{
    "timestamp": "${timestamp}",
    "session_id": "${session_id}",
    "task_id": "${task_id}",
    "model": "${model}",
    "input_tokens": ${input_tokens},
    "output_tokens": ${output_tokens},
    "total_tokens": $((input_tokens + output_tokens)),
    "cost_usd": ${cost},
    "operation": "${operation}"
}
EOF
)

    # Initialize or append to cost log
    if [[ ! -f "$COST_LOG" ]]; then
        echo "[$entry]" > "$COST_LOG"
    else
        # Remove trailing ] and add new entry
        sed -i '$ s/]$/,/' "$COST_LOG"
        echo "$entry]" >> "$COST_LOG"
    fi

    # Also record in database if available
    if [[ -f "$DB_FILE" ]]; then
        sqlite3 "$DB_FILE" << EOF
INSERT INTO token_usage (
    session_id,
    task_id,
    model,
    input_tokens,
    output_tokens,
    cost_usd,
    operation,
    recorded_at
) VALUES (
    '${session_id}',
    '${task_id}',
    '${model}',
    ${input_tokens},
    ${output_tokens},
    ${cost},
    '${operation}',
    datetime('now')
);
EOF
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
        local total_input
        total_input=$(sqlite3 "$DB_FILE" "SELECT COALESCE(SUM(input_tokens), 0) FROM token_usage WHERE session_id='${session_id}';" 2>/dev/null || echo 0)
        local total_output
        total_output=$(sqlite3 "$DB_FILE" "SELECT COALESCE(SUM(output_tokens), 0) FROM token_usage WHERE session_id='${session_id}';" 2>/dev/null || echo 0)
        local total_cost
        total_cost=$(sqlite3 "$DB_FILE" "SELECT COALESCE(SUM(cost_usd), 0) FROM token_usage WHERE session_id='${session_id}';" 2>/dev/null || echo 0)
        local request_count
        request_count=$(sqlite3 "$DB_FILE" "SELECT COUNT(*) FROM token_usage WHERE session_id='${session_id}';" 2>/dev/null || echo 0)

        printf "  %-25s %s\n" "Session ID:" "$session_id"
        printf "  %-25s %s\n" "API Requests:" "$request_count"
        printf "  %-25s %s\n" "Input Tokens:" "$(printf "%'d" "$total_input")"
        printf "  %-25s %s\n" "Output Tokens:" "$(printf "%'d" "$total_output")"
        printf "  %-25s %s\n" "Total Tokens:" "$(printf "%'d" "$((total_input + total_output))")"
        printf "  %-25s \$%.4f\n" "Total Cost:" "$total_cost"

        echo ""
        echo "By Model:"
        echo "─────────────────────────────────────────────────────────────"
        sqlite3 -column -header "$DB_FILE" << EOF
SELECT
    model,
    COUNT(*) as requests,
    SUM(input_tokens) as input_tokens,
    SUM(output_tokens) as output_tokens,
    printf('%.4f', SUM(cost_usd)) as cost_usd
FROM token_usage
WHERE session_id='${session_id}'
GROUP BY model
ORDER BY SUM(cost_usd) DESC;
EOF

        echo ""
        echo "By Operation:"
        echo "─────────────────────────────────────────────────────────────"
        sqlite3 -column -header "$DB_FILE" << EOF
SELECT
    operation,
    COUNT(*) as count,
    SUM(input_tokens + output_tokens) as tokens,
    printf('%.4f', SUM(cost_usd)) as cost_usd
FROM token_usage
WHERE session_id='${session_id}'
GROUP BY operation
ORDER BY SUM(cost_usd) DESC
LIMIT 10;
EOF
    else
        echo "No database found. Checking JSON log..."
        if [[ -f "$COST_LOG" ]]; then
            # Use jq if available, otherwise basic parsing
            if command -v jq &> /dev/null; then
                local total_cost
                total_cost=$(jq "[.[] | select(.session_id == \"${session_id}\") | .cost_usd] | add // 0" "$COST_LOG")
                local total_tokens
                total_tokens=$(jq "[.[] | select(.session_id == \"${session_id}\") | .total_tokens] | add // 0" "$COST_LOG")
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
        sqlite3 -column -header "$DB_FILE" << EOF
SELECT
    session_id,
    COUNT(*) as requests,
    SUM(input_tokens) as input_tokens,
    SUM(output_tokens) as output_tokens,
    printf('\$%.4f', SUM(cost_usd)) as total_cost
FROM token_usage
WHERE date(recorded_at) = '${date}'
GROUP BY session_id
ORDER BY SUM(cost_usd) DESC;
EOF

        echo ""
        echo "─────────────────────────────────────────────────────────────"
        local day_total
        day_total=$(sqlite3 "$DB_FILE" "SELECT printf('\$%.4f', COALESCE(SUM(cost_usd), 0)) FROM token_usage WHERE date(recorded_at)='${date}';")
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
        total_input=$(sqlite3 "$DB_FILE" "SELECT COALESCE(SUM(input_tokens), 0) FROM token_usage;" 2>/dev/null || echo 0)
        local total_output
        total_output=$(sqlite3 "$DB_FILE" "SELECT COALESCE(SUM(output_tokens), 0) FROM token_usage;" 2>/dev/null || echo 0)
        local total_cost
        total_cost=$(sqlite3 "$DB_FILE" "SELECT COALESCE(SUM(cost_usd), 0) FROM token_usage;" 2>/dev/null || echo 0)
        local request_count
        request_count=$(sqlite3 "$DB_FILE" "SELECT COUNT(*) FROM token_usage;" 2>/dev/null || echo 0)
        local session_count
        session_count=$(sqlite3 "$DB_FILE" "SELECT COUNT(DISTINCT session_id) FROM token_usage;" 2>/dev/null || echo 0)

        printf "  %-25s %s\n" "Total Sessions:" "$session_count"
        printf "  %-25s %s\n" "Total API Requests:" "$(printf "%'d" "$request_count")"
        printf "  %-25s %s\n" "Total Input Tokens:" "$(printf "%'d" "$total_input")"
        printf "  %-25s %s\n" "Total Output Tokens:" "$(printf "%'d" "$total_output")"
        printf "  %-25s %s\n" "Total Tokens:" "$(printf "%'d" "$((total_input + total_output))")"
        printf "  %-25s \$%.4f\n" "Total Cost:" "$total_cost"

        echo ""
        echo "By Day (Last 7 Days):"
        echo "─────────────────────────────────────────────────────────────"
        sqlite3 -column -header "$DB_FILE" << EOF
SELECT
    date(recorded_at) as date,
    COUNT(*) as requests,
    SUM(input_tokens + output_tokens) as tokens,
    printf('\$%.4f', SUM(cost_usd)) as cost
FROM token_usage
WHERE recorded_at >= date('now', '-7 days')
GROUP BY date(recorded_at)
ORDER BY date(recorded_at) DESC;
EOF

        echo ""
        echo "By Model (All Time):"
        echo "─────────────────────────────────────────────────────────────"
        sqlite3 -column -header "$DB_FILE" << EOF
SELECT
    model,
    COUNT(*) as requests,
    SUM(input_tokens + output_tokens) as tokens,
    printf('\$%.4f', SUM(cost_usd)) as cost
FROM token_usage
GROUP BY model
ORDER BY SUM(cost_usd) DESC;
EOF
    else
        echo "No database found."
    fi
    echo ""
}

# Set budget alert
set_budget() {
    local budget_type="$1"  # session, daily, monthly
    local amount="$2"

    ensure_dirs

    local budget_file="${DEVTEAM_DIR}/budgets.json"

    if [[ ! -f "$budget_file" ]]; then
        echo "{}" > "$budget_file"
    fi

    # Update budget
    local tmp_file
    tmp_file=$(mktemp)
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
        local session_cost
        session_cost=$(sqlite3 "$DB_FILE" "SELECT COALESCE(SUM(cost_usd), 0) FROM token_usage WHERE session_id='${session_id}';" 2>/dev/null || echo 0)
        local daily_cost
        daily_cost=$(sqlite3 "$DB_FILE" "SELECT COALESCE(SUM(cost_usd), 0) FROM token_usage WHERE date(recorded_at) = date('now');" 2>/dev/null || echo 0)

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
        sqlite3 -csv -header "$DB_FILE" "SELECT * FROM token_usage ORDER BY recorded_at DESC;" > "$output"
        log_info "Exported to ${output}"
    else
        log_error "No database found"
    fi
}

# Main
case "${1:-help}" in
    record)
        record_usage "${2:-}" "${3:-}" "${4:-claude-3-sonnet}" "${5:-0}" "${6:-0}" "${7:-unknown}"
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
        echo "  $0 record ses01 task01 claude-3-sonnet 5000 2000 code-gen"
        echo "  $0 session ses01"
        echo "  $0 budget set daily 25.00"
        echo "  $0 budget check"
        ;;
esac
