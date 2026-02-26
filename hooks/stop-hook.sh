#!/bin/bash
# DevTeam Stop Hook
# Implements session persistence for autonomous mode
# Prevents Claude from exiting without proper completion signal
#
# Exit codes:
#   0 = Allow exit (work complete or not in autonomous mode)
#   2 = Block exit and re-inject prompt (work not complete)
#
# Environment variables expected:
#   STOP_HOOK_MESSAGE or CLAUDE_OUTPUT - Claude's last message

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source common library with fallback paths (H6)
if [[ -f "$SCRIPT_DIR/lib/hook-common.sh" ]]; then
    source "$SCRIPT_DIR/lib/hook-common.sh"
elif [[ -f "$SCRIPT_DIR/../lib/hook-common.sh" ]]; then
    source "$SCRIPT_DIR/../lib/hook-common.sh"
else
    echo "[stop] Warning: hook-common.sh not found" >&2
    exit 0
fi

init_hook "stop"

# ============================================================================
# CONFIGURATION
# ============================================================================

MESSAGE="${STOP_HOOK_MESSAGE:-${CLAUDE_OUTPUT:-}}"

# ============================================================================
# VALID EXIT SIGNALS
# ============================================================================

VALID_EXIT_SIGNALS=(
    "EXIT_SIGNAL: true"
    "EXIT_SIGNAL:true"
    "All quality gates passed"
    "Task completed successfully"
    "Implementation complete"
    "Session ended"
    "All tasks completed"
    "Sprint completed"
    "/devteam:end"
)

# ============================================================================
# EXIT SIGNAL DETECTION
# ============================================================================

has_valid_exit_signal() {
    local message="$1"

    for signal in "${VALID_EXIT_SIGNALS[@]}"; do
        if echo "$message" | grep -qi "$signal"; then
            return 0
        fi
    done

    return 1
}

# ============================================================================
# SESSION STATE CHECK
# ============================================================================

has_incomplete_work() {
    local session_id
    session_id=$(get_current_session)

    if [[ -z "$session_id" ]]; then
        return 1  # No session = no incomplete work
    fi

    # Escape session_id for SQL
    local safe_session_id="${session_id//\'/\'\'}"

    # Check for in-progress tasks in database
    if db_exists; then
        local in_progress
        in_progress=$(db_query "SELECT COUNT(*) FROM tasks WHERE session_id = '$safe_session_id' AND status = 'in_progress';")
        in_progress="${in_progress:-0}"
        if ! [[ "$in_progress" =~ ^[0-9]+$ ]]; then in_progress=0; fi

        if [[ "$in_progress" -gt 0 ]]; then
            log_info "stop" "Found $in_progress in-progress tasks"
            return 0
        fi
    fi

    # Check session status
    local session_status
    session_status=$(db_query "SELECT status FROM sessions WHERE id = '$safe_session_id';")

    if [[ "$session_status" == "running" ]]; then
        # Check for recent failures
        local recent_failures
        recent_failures=$(db_query "SELECT COUNT(*) FROM events
            WHERE session_id = '$safe_session_id'
            AND event_type IN ('gate_failed', 'agent_failed', 'task_failed')
            AND timestamp > datetime('now', '-5 minutes');")
        recent_failures="${recent_failures:-0}"
        if ! [[ "$recent_failures" =~ ^[0-9]+$ ]]; then recent_failures=0; fi

        if [[ "$recent_failures" -gt 0 ]]; then
            log_info "stop" "Found $recent_failures recent failures"
            return 0
        fi
    fi

    # Check database for pending work (fallback)
    if db_exists; then
        local pending
        pending=$(db_query "SELECT COUNT(*) FROM tasks WHERE status = 'pending';" 2>/dev/null || echo "0")
        pending="${pending:-0}"
        if ! [[ "$pending" =~ ^[0-9]+$ ]]; then pending=0; fi
        local in_prog
        in_prog=$(db_query "SELECT COUNT(*) FROM tasks WHERE status = 'in_progress';" 2>/dev/null || echo "0")
        in_prog="${in_prog:-0}"
        if ! [[ "$in_prog" =~ ^[0-9]+$ ]]; then in_prog=0; fi

        if [[ "$pending" -gt 0 ]] || [[ "$in_prog" -gt 0 ]]; then
            log_info "stop" "Database shows pending: $pending, in_progress: $in_prog"
            return 0
        fi
    fi

    return 1
}

# ============================================================================
# CHECKPOINT SAVE ON EXIT
# ============================================================================

save_exit_checkpoint() {
    local session_id
    session_id=$(get_current_session)

    if [[ -n "$session_id" ]]; then
        log_info "stop" "Saving checkpoint before exit"
        save_checkpoint "Auto-checkpoint before exit"

        # Log event
        log_event_to_db "checkpoint_created" "session" "Auto-checkpoint before exit"
    fi
}

# ============================================================================
# SESSION CLEANUP
# ============================================================================

cleanup_session() {
    local exit_reason="${1:-completed}"

    # Remove autonomous mode marker
    rm -f "$AUTONOMOUS_MARKER"

    # Update session status
    local session_id
    session_id=$(get_current_session)
    if [[ -n "$session_id" ]]; then
        local safe_session_id="${session_id//\'/\'\'}"
        db_query "UPDATE sessions SET status = 'completed', exit_reason = '$exit_reason', ended_at = datetime('now') WHERE id = '$safe_session_id';"
    fi

    # Notify MCP (JSON-escape the exit_reason)
    local safe_reason="${exit_reason//\\/\\\\}"
    safe_reason="${safe_reason//\"/\\\"}"
    safe_reason="${safe_reason//$'\n'/\\n}"
    mcp_notify "session_exit" "{\"authorized\": true, \"reason\": \"$safe_reason\"}"
}

# ============================================================================
# MAIN EXECUTION
# ============================================================================

main() {
    # Check if autonomous mode is active
    if ! is_autonomous_mode; then
        log_debug "stop" "Not in autonomous mode, allowing exit"
        exit 0
    fi

    # Check for valid exit signal in message
    if [[ -n "$MESSAGE" ]] && has_valid_exit_signal "$MESSAGE"; then
        log_info "stop" "Valid exit signal detected"

        # Save final checkpoint
        save_exit_checkpoint

        # Clean up session
        cleanup_session "completed"

        exit 0
    fi

    # Check circuit breaker
    if is_circuit_breaker_open; then
        log_warn "stop" "Circuit breaker OPEN - allowing exit for human intervention"

        save_exit_checkpoint
        cleanup_session "circuit_breaker"

        inject_system_message "circuit-breaker" "
CIRCUIT BREAKER TRIPPED

Maximum consecutive failures ($MAX_FAILURES) reached.
Human intervention is required.

Session has been paused. Check .devteam/devteam.db and .devteam/last-errors.txt for details.
"
        exit 0
    fi

    # Check max iterations
    if is_max_iterations_reached; then
        log_warn "stop" "Maximum iterations ($MAX_ITERATIONS) reached"

        save_exit_checkpoint
        cleanup_session "max_iterations"

        inject_system_message "max-iterations" "
MAXIMUM ITERATIONS REACHED

The session has reached $MAX_ITERATIONS iterations.
Review progress in .devteam/ and decide next steps.
"
        exit 0
    fi

    # In autonomous mode without a valid exit signal, always block
    # This is the core enforcement - autonomous mode requires explicit exit signal
    log_warn "stop" "Exit blocked - no valid exit signal in autonomous mode"
    log_event_to_db "exit_blocked" "persistence" "Exit blocked - no valid exit signal"

    # Get current state for message
    local session_id
    session_id=$(get_current_session)
    local task_id
    task_id=$(get_current_task)
    local iteration
    iteration=$(get_current_iteration)
    if ! [[ "$iteration" =~ ^[0-9]+$ ]]; then iteration=0; fi

    inject_system_message "exit-blocked" "
EXIT BLOCKED

Autonomous mode requires a valid exit signal.

Current state:
- Session: ${session_id:-none}
- Task: ${task_id:-none}
- Iteration: ${iteration:-0}/$MAX_ITERATIONS

You must either:
1. Complete the task (all quality gates pass)
2. Use devteam_save_checkpoint to save progress
3. Use devteam_end_session with appropriate status

Include EXIT_SIGNAL: true when properly complete.
"
    # Increment iteration counter
    local current_iter
    current_iter=$(get_current_iteration)
    current_iter=${current_iter:-0}
    if [[ ! "$current_iter" =~ ^[0-9]+$ ]]; then current_iter=0; fi
    if [[ -n "$session_id" ]]; then
        local safe_session_id="${session_id//\'/\'\'}"
        db_query "UPDATE sessions SET current_iteration = $((current_iter + 1)) WHERE id = '$safe_session_id';"
    fi

    # Also update circuit breaker file
    if [[ -f "$CIRCUIT_BREAKER_FILE" ]] && command -v jq &>/dev/null; then
        local new_iter=$((current_iter + 1))
        jq ".total_iterations = $new_iter" "$CIRCUIT_BREAKER_FILE" > "${CIRCUIT_BREAKER_FILE}.tmp" && \
            mv "${CIRCUIT_BREAKER_FILE}.tmp" "$CIRCUIT_BREAKER_FILE" \
            || rm -f "${CIRCUIT_BREAKER_FILE}.tmp"
    fi

    # Notify MCP
    mcp_notify "exit_blocked" "$(get_claude_context)"

    exit 2
}

main "$@"
