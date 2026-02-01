#!/bin/bash
# DevTeam Progress Summary Generator
# Creates and updates human-readable progress.txt file
#
# Usage: source this file in hooks and commands
#   source "$(dirname "$0")/../scripts/progress.sh"

set -euo pipefail

# Get script directory and source common library
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/common.sh"

# Progress file path
PROGRESS_FILE="${DEVTEAM_DIR:-".devteam"}/progress.txt"
FEATURES_FILE="${DEVTEAM_DIR:-".devteam"}/features.json"

# ============================================================================
# PROGRESS FILE GENERATION
# ============================================================================

# Generate progress summary
# Args: [session_id]
generate_progress_summary() {
    local session_id="${1:-}"

    if [ -z "$session_id" ]; then
        session_id=$(get_current_session_id 2>/dev/null || echo "")
    fi

    local timestamp
    timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

    local project_name
    project_name=$(basename "$(pwd)")

    # Get feature stats if features.json exists
    local total_features=0
    local passing_features=0
    local failing_features=0
    local pass_percentage=0

    if [ -f "$FEATURES_FILE" ]; then
        total_features=$(jq '.features | length' "$FEATURES_FILE" 2>/dev/null || echo "0")
        passing_features=$(jq '[.features[] | select(.passes == true)] | length' "$FEATURES_FILE" 2>/dev/null || echo "0")
        failing_features=$((total_features - passing_features))
        if [ "$total_features" -gt 0 ]; then
            pass_percentage=$((passing_features * 100 / total_features))
        fi
    fi

    # Get recent commits
    local recent_commits
    recent_commits=$(git log --oneline -5 2>/dev/null || echo "No commits yet")

    # Get current session info from database
    local current_phase=""
    local current_iteration=0
    local session_status=""

    if [ -n "$session_id" ]; then
        current_phase=$(sql_exec "SELECT current_phase FROM sessions WHERE id = '$session_id';" 2>/dev/null || echo "")
        current_iteration=$(sql_exec "SELECT current_iteration FROM sessions WHERE id = '$session_id';" 2>/dev/null || echo "0")
        session_status=$(sql_exec "SELECT status FROM sessions WHERE id = '$session_id';" 2>/dev/null || echo "")
    fi

    # Generate the progress file
    cat > "$PROGRESS_FILE" << EOF
═══════════════════════════════════════════════════════════════
DEVTEAM PROGRESS TRACKER
═══════════════════════════════════════════════════════════════

Project: ${project_name}
Last Updated: ${timestamp}
Session: ${session_id:-"None active"}
Status: ${session_status:-"N/A"}

───────────────────────────────────────────────────────────────
FEATURE STATUS
───────────────────────────────────────────────────────────────
Total Features: ${total_features}
Passing: ${passing_features} (${pass_percentage}%)
Failing: ${failing_features}

Progress Bar: $(generate_progress_bar "$passing_features" "$total_features")

───────────────────────────────────────────────────────────────
SESSION INFO
───────────────────────────────────────────────────────────────
Current Phase: ${current_phase:-"N/A"}
Iteration: ${current_iteration}

───────────────────────────────────────────────────────────────
RECENT COMMITS
───────────────────────────────────────────────────────────────
${recent_commits}

───────────────────────────────────────────────────────────────
NEXT STEPS
───────────────────────────────────────────────────────────────
$(get_next_feature)

═══════════════════════════════════════════════════════════════
EOF

    log_info "Progress summary updated: $PROGRESS_FILE" "progress"
}

# Generate ASCII progress bar
# Args: current, total
generate_progress_bar() {
    local current="${1:-0}"
    local total="${2:-0}"
    local width=40

    if [ "$total" -eq 0 ]; then
        echo "[$(printf '%*s' $width '' | tr ' ' '-')]  0%"
        return
    fi

    local filled=$((current * width / total))
    local empty=$((width - filled))
    local percent=$((current * 100 / total))

    local bar="["
    bar+=$(printf '%*s' $filled '' | tr ' ' '█')
    bar+=$(printf '%*s' $empty '' | tr ' ' '░')
    bar+="] ${percent}%"

    echo "$bar"
}

# Get next feature to work on
get_next_feature() {
    if [ ! -f "$FEATURES_FILE" ]; then
        echo "No features.json found. Run initializer phase first."
        return
    fi

    local next_feature
    next_feature=$(jq -r '
        .features
        | map(select(.passes == false))
        | sort_by(
            if .priority == "critical" then 0
            elif .priority == "high" then 1
            elif .priority == "medium" then 2
            else 3
            end
        )
        | .[0]
        | if . then "[\(.id)] \(.description)" else "All features complete!" end
    ' "$FEATURES_FILE" 2>/dev/null)

    echo "${next_feature:-"Unable to determine next feature"}"
}

# ============================================================================
# FEATURE TRACKING
# ============================================================================

# Mark a feature as passing
# Args: feature_id
mark_feature_passing() {
    local feature_id="$1"

    if [ ! -f "$FEATURES_FILE" ]; then
        log_error "features.json not found" "progress"
        return 1
    fi

    local timestamp
    timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

    # Update the feature
    local tmp_file
    tmp_file=$(mktemp)

    jq --arg id "$feature_id" --arg ts "$timestamp" '
        .features = [.features[] |
            if .id == $id then
                .passes = true |
                .verified_at = $ts |
                .steps = [.steps[] | .passes = true]
            else .
            end
        ] |
        .updated_at = $ts
    ' "$FEATURES_FILE" > "$tmp_file"

    mv "$tmp_file" "$FEATURES_FILE"

    log_info "Feature $feature_id marked as passing" "progress"

    # Update progress file
    generate_progress_summary
}

# Mark a feature as failing
# Args: feature_id, reason
mark_feature_failing() {
    local feature_id="$1"
    local reason="${2:-"Verification failed"}"

    if [ ! -f "$FEATURES_FILE" ]; then
        log_error "features.json not found" "progress"
        return 1
    fi

    local timestamp
    timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

    local tmp_file
    tmp_file=$(mktemp)

    jq --arg id "$feature_id" --arg ts "$timestamp" --arg reason "$reason" '
        .features = [.features[] |
            if .id == $id then
                .passes = false |
                .last_failure = $reason |
                .updated_at = $ts
            else .
            end
        ] |
        .updated_at = $ts
    ' "$FEATURES_FILE" > "$tmp_file"

    mv "$tmp_file" "$FEATURES_FILE"

    log_warn "Feature $feature_id marked as failing: $reason" "progress"

    # Update progress file
    generate_progress_summary
}

# Get feature status
# Args: feature_id
get_feature_status() {
    local feature_id="$1"

    if [ ! -f "$FEATURES_FILE" ]; then
        echo "unknown"
        return
    fi

    jq -r --arg id "$feature_id" '
        .features[] | select(.id == $id) | if .passes then "passing" else "failing" end
    ' "$FEATURES_FILE" 2>/dev/null || echo "unknown"
}

# ============================================================================
# PROGRESS DATABASE SYNC
# ============================================================================

# Sync progress to database
# Args: [session_id]
sync_progress_to_db() {
    local session_id="${1:-}"

    if [ -z "$session_id" ]; then
        session_id=$(get_current_session_id 2>/dev/null || echo "")
    fi

    if [ -z "$session_id" ]; then
        log_warn "No session ID for progress sync" "progress"
        return 1
    fi

    # Get stats
    local total_features=0
    local passing_features=0

    if [ -f "$FEATURES_FILE" ]; then
        total_features=$(jq '.features | length' "$FEATURES_FILE" 2>/dev/null || echo "0")
        passing_features=$(jq '[.features[] | select(.passes == true)] | length' "$FEATURES_FILE" 2>/dev/null || echo "0")
    fi

    local remaining=$((total_features - passing_features))

    # Get test status (from last gate result)
    local tests_passing=0
    local tests_failing=0

    tests_passing=$(sql_exec "
        SELECT COALESCE(
            json_extract(details, '$.tests_passed'),
            0
        )
        FROM gate_results
        WHERE session_id = '$session_id' AND gate = 'tests'
        ORDER BY timestamp DESC LIMIT 1;
    " 2>/dev/null || echo "0")

    tests_failing=$(sql_exec "
        SELECT COALESCE(
            json_extract(details, '$.tests_failed'),
            0
        )
        FROM gate_results
        WHERE session_id = '$session_id' AND gate = 'tests'
        ORDER BY timestamp DESC LIMIT 1;
    " 2>/dev/null || echo "0")

    # Get current iteration
    local current_iteration
    current_iteration=$(sql_exec "SELECT current_iteration FROM sessions WHERE id = '$session_id';" 2>/dev/null || echo "0")

    # Get last commit
    local last_commit
    last_commit=$(git rev-parse --short HEAD 2>/dev/null || echo "")

    # Read progress file content
    local summary_text=""
    if [ -f "$PROGRESS_FILE" ]; then
        summary_text=$(cat "$PROGRESS_FILE")
    fi

    # Escape for SQL
    summary_text=$(echo "$summary_text" | sed "s/'/''/g")

    # Insert progress summary
    sql_exec "
        INSERT INTO progress_summaries (
            session_id,
            summary_text,
            from_iteration,
            to_iteration,
            tasks_completed,
            tasks_remaining,
            tests_passing,
            tests_failing,
            features_passing,
            features_total,
            last_commit_sha
        ) VALUES (
            '$session_id',
            '$summary_text',
            ${current_iteration:-0},
            ${current_iteration:-0},
            $passing_features,
            $remaining,
            ${tests_passing:-0},
            ${tests_failing:-0},
            $passing_features,
            $total_features,
            '$last_commit'
        );
    " 2>/dev/null

    log_info "Progress synced to database" "progress"
}

# ============================================================================
# INITIALIZATION
# ============================================================================

# Create initial features.json from PRD or task list
# Args: plan_id
initialize_features_json() {
    local plan_id="${1:-}"

    local project_name
    project_name=$(basename "$(pwd)")

    local timestamp
    timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

    # Create initial structure
    cat > "$FEATURES_FILE" << EOF
{
  "project_name": "${project_name}",
  "plan_id": "${plan_id}",
  "created_at": "${timestamp}",
  "updated_at": "${timestamp}",
  "features": []
}
EOF

    log_info "Initialized features.json" "progress"
}

# Add a feature to features.json
# Args: id, category, description, priority, steps_json
add_feature() {
    local id="$1"
    local category="$2"
    local description="$3"
    local priority="${4:-medium}"
    local steps_json="${5:-"[]"}"

    if [ ! -f "$FEATURES_FILE" ]; then
        initialize_features_json
    fi

    local timestamp
    timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

    local tmp_file
    tmp_file=$(mktemp)

    jq --arg id "$id" \
       --arg cat "$category" \
       --arg desc "$description" \
       --arg pri "$priority" \
       --argjson steps "$steps_json" \
       --arg ts "$timestamp" '
        .features += [{
            "id": $id,
            "category": $cat,
            "description": $desc,
            "priority": $pri,
            "steps": $steps,
            "passes": false
        }] |
        .updated_at = $ts
    ' "$FEATURES_FILE" > "$tmp_file"

    mv "$tmp_file" "$FEATURES_FILE"

    log_info "Added feature $id" "progress"
}

# ============================================================================
# MAIN
# ============================================================================

# Run if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    case "${1:-}" in
        generate)
            generate_progress_summary "${2:-}"
            ;;
        mark-passing)
            mark_feature_passing "${2:-}"
            ;;
        mark-failing)
            mark_feature_failing "${2:-}" "${3:-}"
            ;;
        status)
            get_feature_status "${2:-}"
            ;;
        sync)
            sync_progress_to_db "${2:-}"
            ;;
        init)
            initialize_features_json "${2:-}"
            ;;
        add)
            add_feature "${2:-}" "${3:-}" "${4:-}" "${5:-}" "${6:-"[]"}"
            ;;
        *)
            echo "Usage: $0 {generate|mark-passing|mark-failing|status|sync|init|add} [args]"
            exit 1
            ;;
    esac
fi
