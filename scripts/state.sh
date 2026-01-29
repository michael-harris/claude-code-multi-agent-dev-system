#!/bin/bash
# DevTeam State Management Functions
# Source this file to use state functions in hooks and commands

# Configuration
DEVTEAM_DIR="${DEVTEAM_DIR:-.devteam}"
DB_FILE="${DEVTEAM_DIR}/devteam.db"

# Ensure database exists
_ensure_db() {
    if [ ! -f "$DB_FILE" ]; then
        local script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
        bash "${script_dir}/db-init.sh"
    fi
}

# ============================================================================
# SESSION MANAGEMENT
# ============================================================================

# Generate a unique session ID
generate_session_id() {
    echo "session-$(date +%Y%m%d-%H%M%S)-$(head -c 4 /dev/urandom | xxd -p)"
}

# Start a new session
start_session() {
    local command="$1"
    local command_type="$2"
    local execution_mode="${3:-normal}"

    _ensure_db

    local session_id
    session_id=$(generate_session_id)

    sqlite3 "$DB_FILE" "
        INSERT INTO sessions (id, command, command_type, execution_mode, status, current_phase)
        VALUES ('$session_id', '$command', '$command_type', '$execution_mode', 'running', 'initializing');
    "

    echo "$session_id"
}

# End the current session
end_session() {
    local status="${1:-completed}"
    local exit_reason="${2:-Success}"

    sqlite3 "$DB_FILE" "
        UPDATE sessions
        SET status = '$status',
            exit_reason = '$exit_reason',
            ended_at = CURRENT_TIMESTAMP
        WHERE status = 'running';
    "
}

# Get current session ID
get_current_session_id() {
    _ensure_db
    sqlite3 "$DB_FILE" "SELECT id FROM sessions WHERE status = 'running' ORDER BY started_at DESC LIMIT 1;"
}

# Check if a session is running
is_session_running() {
    local count
    count=$(sqlite3 "$DB_FILE" "SELECT COUNT(*) FROM sessions WHERE status = 'running';")
    [ "$count" -gt 0 ]
}

# Get session as JSON
get_session_json() {
    local session_id="${1:-$(get_current_session_id)}"
    sqlite3 -json "$DB_FILE" "SELECT * FROM sessions WHERE id = '$session_id';"
}

# ============================================================================
# STATE GETTERS
# ============================================================================

# Get a specific session field
get_state() {
    local field="$1"
    local session_id="${2:-$(get_current_session_id)}"
    sqlite3 "$DB_FILE" "SELECT $field FROM sessions WHERE id = '$session_id';"
}

# Get current phase
get_current_phase() {
    get_state "current_phase"
}

# Get current agent
get_current_agent() {
    get_state "current_agent"
}

# Get current model
get_current_model() {
    get_state "current_model"
}

# Get current iteration
get_current_iteration() {
    get_state "current_iteration"
}

# Get consecutive failures
get_consecutive_failures() {
    get_state "consecutive_failures"
}

# Get execution mode
get_execution_mode() {
    get_state "execution_mode"
}

# Check if eco mode
is_eco_mode() {
    local mode
    mode=$(get_execution_mode)
    [ "$mode" = "eco" ]
}

# Check if bug council activated
is_bug_council_active() {
    local activated
    activated=$(get_state "bug_council_activated")
    [ "$activated" = "1" ]
}

# ============================================================================
# STATE SETTERS
# ============================================================================

# Set a specific session field
set_state() {
    local field="$1"
    local value="$2"
    local session_id="${3:-$(get_current_session_id)}"

    sqlite3 "$DB_FILE" "
        UPDATE sessions
        SET $field = '$value'
        WHERE id = '$session_id';
    "
}

# Set current phase
set_phase() {
    set_state "current_phase" "$1"
}

# Set current agent
set_current_agent() {
    set_state "current_agent" "$1"
}

# Set current model
set_current_model() {
    set_state "current_model" "$1"
}

# Increment iteration
increment_iteration() {
    local session_id="${1:-$(get_current_session_id)}"
    sqlite3 "$DB_FILE" "
        UPDATE sessions
        SET current_iteration = current_iteration + 1
        WHERE id = '$session_id';
    "
}

# Increment consecutive failures
increment_failures() {
    local session_id="${1:-$(get_current_session_id)}"
    sqlite3 "$DB_FILE" "
        UPDATE sessions
        SET consecutive_failures = consecutive_failures + 1
        WHERE id = '$session_id';
    "
}

# Reset consecutive failures
reset_failures() {
    local session_id="${1:-$(get_current_session_id)}"
    sqlite3 "$DB_FILE" "
        UPDATE sessions
        SET consecutive_failures = 0
        WHERE id = '$session_id';
    "
}

# Activate bug council
activate_bug_council() {
    local reason="$1"
    local session_id="${2:-$(get_current_session_id)}"
    sqlite3 "$DB_FILE" "
        UPDATE sessions
        SET bug_council_activated = TRUE,
            bug_council_reason = '$reason'
        WHERE id = '$session_id';
    "
}

# ============================================================================
# KEY-VALUE STATE (for complex data)
# ============================================================================

# Set a key-value pair
set_kv_state() {
    local key="$1"
    local value="$2"
    local session_id="${3:-$(get_current_session_id)}"

    sqlite3 "$DB_FILE" "
        INSERT OR REPLACE INTO session_state (session_id, key, value, updated_at)
        VALUES ('$session_id', '$key', '$value', CURRENT_TIMESTAMP);
    "
}

# Get a key-value pair
get_kv_state() {
    local key="$1"
    local session_id="${2:-$(get_current_session_id)}"
    sqlite3 "$DB_FILE" "SELECT value FROM session_state WHERE session_id = '$session_id' AND key = '$key';"
}

# Delete a key-value pair
delete_kv_state() {
    local key="$1"
    local session_id="${2:-$(get_current_session_id)}"
    sqlite3 "$DB_FILE" "DELETE FROM session_state WHERE session_id = '$session_id' AND key = '$key';"
}

# ============================================================================
# COST TRACKING
# ============================================================================

# Add tokens to session total
add_tokens() {
    local tokens_input="$1"
    local tokens_output="$2"
    local cost_cents="$3"
    local session_id="${4:-$(get_current_session_id)}"

    sqlite3 "$DB_FILE" "
        UPDATE sessions
        SET total_tokens_input = total_tokens_input + $tokens_input,
            total_tokens_output = total_tokens_output + $tokens_output,
            total_cost_cents = total_cost_cents + $cost_cents
        WHERE id = '$session_id';
    "
}

# Get total cost in dollars
get_total_cost_dollars() {
    local session_id="${1:-$(get_current_session_id)}"
    sqlite3 "$DB_FILE" "SELECT ROUND(total_cost_cents / 100.0, 4) FROM sessions WHERE id = '$session_id';"
}

# ============================================================================
# CIRCUIT BREAKER
# ============================================================================

# Check if circuit breaker should trip
should_trip_circuit_breaker() {
    local failures
    local max_failures

    failures=$(get_consecutive_failures)
    max_failures=$(get_state "max_consecutive_failures")

    [ "$failures" -ge "$max_failures" ]
}

# Trip the circuit breaker
trip_circuit_breaker() {
    set_state "circuit_breaker_state" "open"
}

# Reset the circuit breaker
reset_circuit_breaker() {
    set_state "circuit_breaker_state" "closed"
    reset_failures
}

# ============================================================================
# MODEL ESCALATION
# ============================================================================

# Get next model tier
get_next_model() {
    local current="$1"
    case "$current" in
        haiku)  echo "sonnet" ;;
        sonnet) echo "opus" ;;
        opus)   echo "bug_council" ;;
        *)      echo "sonnet" ;;
    esac
}

# Record escalation
record_escalation() {
    local from_model="$1"
    local to_model="$2"
    local reason="$3"
    local agent="${4:-}"
    local session_id="${5:-$(get_current_session_id)}"

    local iteration
    iteration=$(get_current_iteration)

    sqlite3 "$DB_FILE" "
        INSERT INTO escalations (session_id, from_model, to_model, reason, agent, iteration)
        VALUES ('$session_id', '$from_model', '$to_model', '$reason', '$agent', $iteration);
    "

    # Update current model
    set_current_model "$to_model"
}

# ============================================================================
# PLAN MANAGEMENT
# ============================================================================

# Set active plan
set_active_plan() {
    local plan_id="$1"
    local session_id="${2:-$(get_current_session_id)}"
    set_state "plan_id" "$plan_id" "$session_id"
}

# Set active sprint
set_active_sprint() {
    local sprint_id="$1"
    local session_id="${2:-$(get_current_session_id)}"
    set_state "sprint_id" "$sprint_id" "$session_id"
}

# ============================================================================
# UTILITY FUNCTIONS
# ============================================================================

# Get session summary (for status display)
get_session_summary() {
    local session_id="${1:-$(get_current_session_id)}"
    sqlite3 -json "$DB_FILE" "SELECT * FROM v_session_summary WHERE id = '$session_id';"
}

# Get model usage for session
get_model_usage() {
    local session_id="${1:-$(get_current_session_id)}"
    sqlite3 -column -header "$DB_FILE" "SELECT * FROM v_model_usage WHERE session_id = '$session_id';"
}

# Abort current session
abort_session() {
    local reason="${1:-User aborted}"
    end_session "aborted" "$reason"
}

# Check max iterations
is_max_iterations_reached() {
    local current
    local max
    current=$(get_current_iteration)
    max=$(get_state "max_iterations")
    [ "$current" -ge "$max" ]
}
