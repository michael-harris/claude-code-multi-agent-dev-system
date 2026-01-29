#!/bin/bash
# DevTeam Common Library
# Shared utilities for security, logging, and validation
# Source this file in other scripts

set -euo pipefail

# ============================================================================
# CONFIGURATION
# ============================================================================

DEVTEAM_DIR="${DEVTEAM_DIR:-.devteam}"
DB_FILE="${DEVTEAM_DIR}/devteam.db"
LOG_LEVEL="${DEVTEAM_LOG_LEVEL:-info}"  # debug, info, warn, error

# Valid log levels (numeric for comparison)
declare -A LOG_LEVELS=(
    [debug]=0
    [info]=1
    [warn]=2
    [error]=3
)

# Colors for output
readonly COLOR_RED='\033[0;31m'
readonly COLOR_GREEN='\033[0;32m'
readonly COLOR_YELLOW='\033[1;33m'
readonly COLOR_BLUE='\033[0;34m'
readonly COLOR_NC='\033[0m'

# ============================================================================
# STRUCTURED LOGGING
# ============================================================================

# Internal: Check if log level should be output
_should_log() {
    local level="$1"
    local current_level="${LOG_LEVELS[$LOG_LEVEL]:-1}"
    local msg_level="${LOG_LEVELS[$level]:-1}"
    [ "$msg_level" -ge "$current_level" ]
}

# Log with timestamp and level
log() {
    local level="$1"
    local message="$2"
    local context="${3:-}"

    if ! _should_log "$level"; then
        return 0
    fi

    local timestamp
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')

    local color=""
    case "$level" in
        debug) color="$COLOR_BLUE" ;;
        info)  color="$COLOR_GREEN" ;;
        warn)  color="$COLOR_YELLOW" ;;
        error) color="$COLOR_RED" ;;
    esac

    local ctx_str=""
    if [ -n "$context" ]; then
        ctx_str=" [$context]"
    fi

    echo -e "${color}[$timestamp] [devteam] [$level]${ctx_str}${COLOR_NC} $message" >&2
}

log_debug() { log "debug" "$1" "${2:-}"; }
log_info()  { log "info" "$1" "${2:-}"; }
log_warn()  { log "warn" "$1" "${2:-}"; }
log_error() { log "error" "$1" "${2:-}"; }

# ============================================================================
# INPUT VALIDATION
# ============================================================================

# Valid session field names (whitelist)
readonly VALID_SESSION_FIELDS=(
    "status"
    "current_phase"
    "current_agent"
    "current_model"
    "current_iteration"
    "consecutive_failures"
    "execution_mode"
    "bug_council_activated"
    "bug_council_reason"
    "circuit_breaker_state"
    "max_consecutive_failures"
    "max_iterations"
    "plan_id"
    "sprint_id"
    "exit_reason"
    "ended_at"
    "total_tokens_input"
    "total_tokens_output"
    "total_cost_cents"
)

# Valid phase values
readonly VALID_PHASES=(
    "initializing"
    "interview"
    "research"
    "planning"
    "executing"
    "quality_check"
    "bug_council"
    "completed"
    "aborted"
    "failed"
)

# Valid model values
readonly VALID_MODELS=(
    "haiku"
    "sonnet"
    "opus"
    "bug_council"
)

# Valid status values
readonly VALID_STATUSES=(
    "running"
    "completed"
    "aborted"
    "failed"
)

# Check if value is in array
_in_array() {
    local needle="$1"
    shift
    local item
    for item in "$@"; do
        if [ "$item" = "$needle" ]; then
            return 0
        fi
    done
    return 1
}

# Validate session field name
validate_field_name() {
    local field="$1"
    if ! _in_array "$field" "${VALID_SESSION_FIELDS[@]}"; then
        log_error "Invalid field name: $field" "validation"
        return 1
    fi
    return 0
}

# Validate phase value
validate_phase() {
    local phase="$1"
    if ! _in_array "$phase" "${VALID_PHASES[@]}"; then
        log_error "Invalid phase: $phase" "validation"
        return 1
    fi
    return 0
}

# Validate model value
validate_model() {
    local model="$1"
    if ! _in_array "$model" "${VALID_MODELS[@]}"; then
        log_error "Invalid model: $model" "validation"
        return 1
    fi
    return 0
}

# Validate status value
validate_status() {
    local status="$1"
    if ! _in_array "$status" "${VALID_STATUSES[@]}"; then
        log_error "Invalid status: $status" "validation"
        return 1
    fi
    return 0
}

# Validate session ID format (prevents injection)
validate_session_id() {
    local session_id="$1"
    # Session IDs should match: session-YYYYMMDD-HHMMSS-hexchars
    if [[ ! "$session_id" =~ ^session-[0-9]{8}-[0-9]{6}-[a-f0-9]+$ ]]; then
        log_error "Invalid session ID format: $session_id" "validation"
        return 1
    fi
    return 0
}

# Validate numeric value
validate_numeric() {
    local value="$1"
    local name="${2:-value}"
    if [[ ! "$value" =~ ^[0-9]+$ ]]; then
        log_error "Invalid numeric $name: $value" "validation"
        return 1
    fi
    return 0
}

# Validate numeric (allows decimals)
validate_decimal() {
    local value="$1"
    local name="${2:-value}"
    if [[ ! "$value" =~ ^[0-9]+\.?[0-9]*$ ]]; then
        log_error "Invalid decimal $name: $value" "validation"
        return 1
    fi
    return 0
}

# ============================================================================
# SQL SECURITY
# ============================================================================

# Escape string for safe SQL insertion
# Uses proper escaping: doubles single quotes and handles special chars
sql_escape() {
    local value="$1"
    # Escape single quotes by doubling them (SQL standard)
    value="${value//\'/\'\'}"
    # Escape backslashes
    value="${value//\\/\\\\}"
    echo "$value"
}

# Safe SQL query execution with error handling
# Usage: sql_exec "SELECT * FROM table WHERE id = ?" "value"
# Note: SQLite CLI doesn't support true prepared statements,
# so we use careful escaping and validation
sql_exec() {
    local query="$1"
    shift

    if [ ! -f "$DB_FILE" ]; then
        log_error "Database file not found: $DB_FILE" "sql"
        return 1
    fi

    local result
    if ! result=$(sqlite3 "$DB_FILE" "$query" 2>&1); then
        log_error "SQL execution failed: $result" "sql"
        log_debug "Query was: $query" "sql"
        return 1
    fi

    echo "$result"
}

# Safe SQL query execution with JSON output
sql_exec_json() {
    local query="$1"

    if [ ! -f "$DB_FILE" ]; then
        log_error "Database file not found: $DB_FILE" "sql"
        return 1
    fi

    local result
    if ! result=$(sqlite3 -json "$DB_FILE" "$query" 2>&1); then
        log_error "SQL execution failed: $result" "sql"
        return 1
    fi

    echo "$result"
}

# Safe SQL query execution with column headers
sql_exec_table() {
    local query="$1"

    if [ ! -f "$DB_FILE" ]; then
        log_error "Database file not found: $DB_FILE" "sql"
        return 1
    fi

    local result
    if ! result=$(sqlite3 -column -header "$DB_FILE" "$query" 2>&1); then
        log_error "SQL execution failed: $result" "sql"
        return 1
    fi

    echo "$result"
}

# Build safe INSERT query
# Usage: sql_insert "table" "col1,col2" "val1" "val2"
sql_insert() {
    local table="$1"
    local columns="$2"
    shift 2

    local values=""
    local first=true
    for val in "$@"; do
        if [ "$first" = true ]; then
            first=false
        else
            values+=","
        fi
        local escaped
        escaped=$(sql_escape "$val")
        values+="'$escaped'"
    done

    local query="INSERT INTO $table ($columns) VALUES ($values);"
    sql_exec "$query"
}

# Build safe UPDATE query
# Usage: sql_update "table" "field=value,field2=value2" "id = ?" "id_value"
sql_update() {
    local table="$1"
    local set_clause="$2"
    local where_field="$3"
    local where_value="$4"

    local escaped_value
    escaped_value=$(sql_escape "$where_value")

    local query="UPDATE $table SET $set_clause WHERE $where_field = '$escaped_value';"
    sql_exec "$query"
}

# Build safe SELECT query
# Usage: sql_select "field" "table" "id = ?" "id_value"
sql_select() {
    local fields="$1"
    local table="$2"
    local where_field="$3"
    local where_value="$4"

    local escaped_value
    escaped_value=$(sql_escape "$where_value")

    local query="SELECT $fields FROM $table WHERE $where_field = '$escaped_value';"
    sql_exec "$query"
}

# ============================================================================
# DATABASE UTILITIES
# ============================================================================

# Ensure database exists and is valid
ensure_db() {
    if [ ! -f "$DB_FILE" ]; then
        local script_dir
        script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
        log_info "Database not found, initializing..." "db"
        if ! bash "${script_dir}/db-init.sh"; then
            log_error "Failed to initialize database" "db"
            return 1
        fi
    fi
    return 0
}

# Check database integrity
check_db_integrity() {
    local integrity
    integrity=$(sqlite3 "$DB_FILE" "PRAGMA integrity_check;" 2>/dev/null || echo "error")
    if [ "$integrity" != "ok" ]; then
        log_error "Database integrity check failed: $integrity" "db"
        return 1
    fi
    return 0
}

# ============================================================================
# ERROR HANDLING
# ============================================================================

# Trap handler for errors
on_error() {
    local line_no="$1"
    local error_code="$2"
    log_error "Error on line $line_no (exit code: $error_code)" "trap"
}

# Set up error trap (call at start of main script)
setup_error_trap() {
    trap 'on_error ${LINENO} $?' ERR
}

# ============================================================================
# UTILITY FUNCTIONS
# ============================================================================

# Generate unique ID with prefix
generate_id() {
    local prefix="${1:-id}"
    echo "${prefix}-$(date +%Y%m%d-%H%M%S)-$(head -c 4 /dev/urandom | xxd -p)"
}

# Check if command exists
require_command() {
    local cmd="$1"
    if ! command -v "$cmd" &> /dev/null; then
        log_error "Required command not found: $cmd" "setup"
        return 1
    fi
    return 0
}
