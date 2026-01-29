#!/bin/bash
# DevTeam Event Logging Functions
# Source this file to log events from hooks and commands

# Get script directory and source state functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/state.sh"

# ============================================================================
# CORE EVENT LOGGING
# ============================================================================

# Log an event
log_event() {
    local event_type="$1"
    local category="${2:-general}"
    local message="${3:-}"
    local data="${4:-null}"
    local agent="${5:-}"
    local model="${6:-}"
    local tokens_input="${7:-0}"
    local tokens_output="${8:-0}"
    local cost_cents="${9:-0}"

    local session_id
    session_id=$(get_current_session_id)

    if [ -z "$session_id" ]; then
        return 0  # No active session, skip logging
    fi

    local iteration
    local phase
    iteration=$(get_current_iteration)
    phase=$(get_current_phase)

    # Escape single quotes in message and data
    message="${message//\'/\'\'}"
    data="${data//\'/\'\'}"

    sqlite3 "$DB_FILE" "
        INSERT INTO events (
            session_id, event_type, event_category, message, data,
            agent, model, iteration, phase,
            tokens_input, tokens_output, cost_cents
        ) VALUES (
            '$session_id', '$event_type', '$category', '$message', '$data',
            '$agent', '$model', $iteration, '$phase',
            $tokens_input, $tokens_output, $cost_cents
        );
    "
}

# ============================================================================
# SESSION EVENTS
# ============================================================================

log_session_started() {
    local command="$1"
    local command_type="$2"
    log_event "session_started" "session" "Session started: $command" "{\"command_type\": \"$command_type\"}"
}

log_session_ended() {
    local status="$1"
    local reason="$2"
    log_event "session_ended" "session" "Session ended: $status" "{\"status\": \"$status\", \"reason\": \"$reason\"}"
}

# ============================================================================
# PHASE EVENTS
# ============================================================================

log_phase_changed() {
    local new_phase="$1"
    local previous_phase="${2:-}"
    log_event "phase_changed" "phase" "Phase: $new_phase" "{\"previous\": \"$previous_phase\", \"current\": \"$new_phase\"}"
}

# ============================================================================
# AGENT EVENTS
# ============================================================================

log_agent_started() {
    local agent="$1"
    local model="$2"
    local task_id="${3:-}"

    log_event "agent_started" "agent" "Agent started: $agent ($model)" \
        "{\"task_id\": \"$task_id\"}" "$agent" "$model"

    # Also insert into agent_runs
    local session_id
    session_id=$(get_current_session_id)
    local iteration
    iteration=$(get_current_iteration)

    sqlite3 "$DB_FILE" "
        INSERT INTO agent_runs (session_id, agent, model, task_id, iteration, status)
        VALUES ('$session_id', '$agent', '$model', '$task_id', $iteration, 'running');
    "
}

log_agent_completed() {
    local agent="$1"
    local model="$2"
    local files_changed="${3:-[]}"
    local tokens_input="${4:-0}"
    local tokens_output="${5:-0}"
    local cost_cents="${6:-0}"

    log_event "agent_completed" "agent" "Agent completed: $agent" \
        "{\"files_changed\": $files_changed}" "$agent" "$model" \
        "$tokens_input" "$tokens_output" "$cost_cents"

    # Update agent_runs
    local session_id
    session_id=$(get_current_session_id)

    sqlite3 "$DB_FILE" "
        UPDATE agent_runs
        SET status = 'success',
            ended_at = CURRENT_TIMESTAMP,
            duration_seconds = CAST((julianday(CURRENT_TIMESTAMP) - julianday(started_at)) * 86400 AS INTEGER),
            files_changed = '$files_changed',
            tokens_input = $tokens_input,
            tokens_output = $tokens_output,
            cost_cents = $cost_cents
        WHERE session_id = '$session_id'
        AND agent = '$agent'
        AND status = 'running'
        ORDER BY started_at DESC
        LIMIT 1;
    "

    # Update session totals
    add_tokens "$tokens_input" "$tokens_output" "$cost_cents"
}

log_agent_failed() {
    local agent="$1"
    local model="$2"
    local error_message="$3"
    local error_type="${4:-unknown}"

    log_event "agent_failed" "agent" "Agent failed: $agent - $error_message" \
        "{\"error_type\": \"$error_type\"}" "$agent" "$model"

    # Update agent_runs
    local session_id
    session_id=$(get_current_session_id)

    sqlite3 "$DB_FILE" "
        UPDATE agent_runs
        SET status = 'failed',
            ended_at = CURRENT_TIMESTAMP,
            duration_seconds = CAST((julianday(CURRENT_TIMESTAMP) - julianday(started_at)) * 86400 AS INTEGER),
            error_message = '${error_message//\'/\'\'}',
            error_type = '$error_type'
        WHERE session_id = '$session_id'
        AND agent = '$agent'
        AND status = 'running'
        ORDER BY started_at DESC
        LIMIT 1;
    "

    # Increment failure counter
    increment_failures
}

# ============================================================================
# ESCALATION EVENTS
# ============================================================================

log_model_escalated() {
    local from_model="$1"
    local to_model="$2"
    local reason="$3"
    local agent="${4:-}"

    log_event "model_escalated" "escalation" "Model escalated: $from_model -> $to_model ($reason)" \
        "{\"from\": \"$from_model\", \"to\": \"$to_model\", \"reason\": \"$reason\"}" "$agent" "$to_model"

    # Record in escalations table
    record_escalation "$from_model" "$to_model" "$reason" "$agent"
}

log_model_deescalated() {
    local from_model="$1"
    local to_model="$2"
    local reason="$3"

    log_event "model_deescalated" "escalation" "Model de-escalated: $from_model -> $to_model ($reason)" \
        "{\"from\": \"$from_model\", \"to\": \"$to_model\", \"reason\": \"$reason\"}"
}

# ============================================================================
# QUALITY GATE EVENTS
# ============================================================================

log_gate_passed() {
    local gate="$1"
    local details="${2:-{}}"

    log_event "gate_passed" "gate" "Gate passed: $gate" "$details"

    # Insert into gate_results
    local session_id
    session_id=$(get_current_session_id)
    local iteration
    iteration=$(get_current_iteration)

    sqlite3 "$DB_FILE" "
        INSERT INTO gate_results (session_id, gate, iteration, passed, details)
        VALUES ('$session_id', '$gate', $iteration, TRUE, '$details');
    "
}

log_gate_failed() {
    local gate="$1"
    local error_count="${2:-0}"
    local details="${3:-{}}"

    log_event "gate_failed" "gate" "Gate failed: $gate ($error_count errors)" "$details"

    # Insert into gate_results
    local session_id
    session_id=$(get_current_session_id)
    local iteration
    iteration=$(get_current_iteration)

    sqlite3 "$DB_FILE" "
        INSERT INTO gate_results (session_id, gate, iteration, passed, error_count, details)
        VALUES ('$session_id', '$gate', $iteration, FALSE, $error_count, '$details');
    "
}

# ============================================================================
# BUG COUNCIL EVENTS
# ============================================================================

log_bug_council_activated() {
    local reason="$1"

    log_event "bug_council_activated" "bug_council" "Bug Council activated: $reason" \
        "{\"reason\": \"$reason\"}"

    activate_bug_council "$reason"
}

log_bug_council_completed() {
    local winning_proposal="$1"
    local votes="${2:-{}}"

    log_event "bug_council_completed" "bug_council" "Bug Council decision: $winning_proposal" "$votes"
}

# ============================================================================
# INTERVIEW EVENTS
# ============================================================================

log_interview_started() {
    local interview_type="$1"

    log_event "interview_started" "interview" "Interview started: $interview_type" \
        "{\"type\": \"$interview_type\"}"

    # Create interview record
    local session_id
    session_id=$(get_current_session_id)

    sqlite3 "$DB_FILE" "
        INSERT INTO interviews (session_id, interview_type, status)
        VALUES ('$session_id', '$interview_type', 'in_progress');
    "
}

log_interview_question() {
    local question_key="$1"
    local question_text="$2"
    local response="${3:-}"

    log_event "interview_question" "interview" "Q: $question_text" \
        "{\"key\": \"$question_key\", \"response\": \"$response\"}"
}

log_interview_completed() {
    local questions_count="$1"

    log_event "interview_completed" "interview" "Interview completed ($questions_count questions)" \
        "{\"questions_count\": $questions_count}"

    # Update interview record
    local session_id
    session_id=$(get_current_session_id)

    sqlite3 "$DB_FILE" "
        UPDATE interviews
        SET status = 'completed',
            completed_at = CURRENT_TIMESTAMP,
            questions_answered = $questions_count
        WHERE session_id = '$session_id'
        AND status = 'in_progress'
        ORDER BY started_at DESC
        LIMIT 1;
    "
}

# ============================================================================
# RESEARCH EVENTS
# ============================================================================

log_research_started() {
    log_event "research_started" "research" "Research phase started"

    # Create research session
    local session_id
    session_id=$(get_current_session_id)

    sqlite3 "$DB_FILE" "
        INSERT INTO research_sessions (session_id, status)
        VALUES ('$session_id', 'in_progress');
    "
}

log_research_finding() {
    local finding_type="$1"
    local title="$2"
    local description="${3:-}"
    local priority="${4:-medium}"

    log_event "research_finding" "research" "Finding: $title" \
        "{\"type\": \"$finding_type\", \"priority\": \"$priority\"}"

    # Insert finding
    local session_id
    session_id=$(get_current_session_id)

    sqlite3 "$DB_FILE" "
        INSERT INTO research_findings (
            research_session_id,
            finding_type,
            title,
            description,
            priority
        )
        SELECT id, '$finding_type', '${title//\'/\'\'}', '${description//\'/\'\'}', '$priority'
        FROM research_sessions
        WHERE session_id = '$session_id'
        ORDER BY started_at DESC
        LIMIT 1;
    "
}

log_research_completed() {
    local findings_count="$1"
    local blockers_count="${2:-0}"

    log_event "research_completed" "research" "Research completed ($findings_count findings, $blockers_count blockers)" \
        "{\"findings\": $findings_count, \"blockers\": $blockers_count}"

    # Update research session
    local session_id
    session_id=$(get_current_session_id)

    sqlite3 "$DB_FILE" "
        UPDATE research_sessions
        SET status = 'completed',
            completed_at = CURRENT_TIMESTAMP,
            findings_count = $findings_count,
            blockers_found = $blockers_count
        WHERE session_id = '$session_id'
        AND status = 'in_progress'
        ORDER BY started_at DESC
        LIMIT 1;
    "
}

# ============================================================================
# TASK EVENTS
# ============================================================================

log_task_started() {
    local task_id="$1"
    local task_description="$2"

    log_event "task_started" "task" "Task started: $task_id - $task_description" \
        "{\"task_id\": \"$task_id\"}"
}

log_task_completed() {
    local task_id="$1"

    log_event "task_completed" "task" "Task completed: $task_id" \
        "{\"task_id\": \"$task_id\"}"
}

log_task_failed() {
    local task_id="$1"
    local reason="$2"

    log_event "task_failed" "task" "Task failed: $task_id - $reason" \
        "{\"task_id\": \"$task_id\", \"reason\": \"$reason\"}"
}

# ============================================================================
# ERROR AND WARNING EVENTS
# ============================================================================

log_error() {
    local message="$1"
    local details="${2:-{}}"

    log_event "error_occurred" "error" "$message" "$details"
}

log_warning() {
    local message="$1"
    local details="${2:-{}}"

    log_event "warning_issued" "warning" "$message" "$details"
}

# ============================================================================
# ABANDONMENT EVENTS
# ============================================================================

log_abandonment_detected() {
    local pattern="$1"
    local attempt_number="$2"

    log_event "abandonment_detected" "persistence" "Abandonment pattern detected: $pattern (attempt $attempt_number)" \
        "{\"pattern\": \"$pattern\", \"attempt\": $attempt_number}"
}

log_abandonment_prevented() {
    local action="$1"

    log_event "abandonment_prevented" "persistence" "Abandonment prevented: $action" \
        "{\"action\": \"$action\"}"
}

# ============================================================================
# QUERY FUNCTIONS
# ============================================================================

# Get recent events for current session
get_recent_events() {
    local limit="${1:-20}"
    local session_id="${2:-$(get_current_session_id)}"

    sqlite3 -column -header "$DB_FILE" "
        SELECT timestamp, event_type, message
        FROM events
        WHERE session_id = '$session_id'
        ORDER BY timestamp DESC
        LIMIT $limit;
    "
}

# Get events by type
get_events_by_type() {
    local event_type="$1"
    local session_id="${2:-$(get_current_session_id)}"

    sqlite3 -json "$DB_FILE" "
        SELECT * FROM events
        WHERE session_id = '$session_id'
        AND event_type = '$event_type'
        ORDER BY timestamp;
    "
}

# Get escalation history
get_escalation_history() {
    local session_id="${1:-$(get_current_session_id)}"

    sqlite3 -column -header "$DB_FILE" "
        SELECT timestamp, from_model, to_model, reason, agent
        FROM escalations
        WHERE session_id = '$session_id'
        ORDER BY timestamp;
    "
}

# Get gate results for current session
get_gate_results() {
    local session_id="${1:-$(get_current_session_id)}"

    sqlite3 -column -header "$DB_FILE" "
        SELECT iteration, gate, passed, error_count, timestamp
        FROM gate_results
        WHERE session_id = '$session_id'
        ORDER BY timestamp;
    "
}
