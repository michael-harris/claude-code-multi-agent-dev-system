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
    # Must have at least one digit before optional decimal point
    # Accepts: 0, 123, 0.5, 123.456 - Rejects: ., .5, empty
    if [[ ! "$value" =~ ^[0-9]+(\.[0-9]+)?$ ]]; then
        log_error "Invalid decimal $name: $value" "validation"
        return 1
    fi
    return 0
}

# ============================================================================
# SQL SECURITY
# ============================================================================

# Valid table names (whitelist to prevent SQL injection)
readonly VALID_TABLES=(
    "sessions"
    "events"
    "schema_version"
)

# Valid column names per table (whitelist to prevent SQL injection)
declare -A VALID_COLUMNS
VALID_COLUMNS[sessions]="id,started_at,ended_at,status,current_phase,current_agent,current_model,current_iteration,consecutive_failures,execution_mode,bug_council_activated,bug_council_reason,circuit_breaker_state,max_consecutive_failures,max_iterations,plan_id,sprint_id,exit_reason,total_tokens_input,total_tokens_output,total_cost_cents"
VALID_COLUMNS[events]="id,session_id,timestamp,event_type,phase,agent,model,iteration,status,message,metadata,tokens_input,tokens_output,cost_cents"
VALID_COLUMNS[schema_version]="version,applied_at"

# Validate table name against whitelist
validate_table_name() {
    local table="$1"
    if ! _in_array "$table" "${VALID_TABLES[@]}"; then
        log_error "Invalid table name: $table" "validation"
        return 1
    fi
    return 0
}

# Validate column name against whitelist for specific table
validate_column_name() {
    local table="$1"
    local column="$2"

    # Get valid columns for this table
    local valid_cols="${VALID_COLUMNS[$table]:-}"
    if [ -z "$valid_cols" ]; then
        log_error "Unknown table for column validation: $table" "validation"
        return 1
    fi

    # Check if column is in the comma-separated list
    if [[ ! ",$valid_cols," == *",$column,"* ]]; then
        log_error "Invalid column name '$column' for table '$table'" "validation"
        return 1
    fi
    return 0
}

# Validate multiple column names
validate_columns() {
    local table="$1"
    local columns="$2"

    # Split by comma and validate each
    IFS=',' read -ra col_array <<< "$columns"
    for col in "${col_array[@]}"; do
        # Trim whitespace
        col="${col## }"
        col="${col%% }"
        if ! validate_column_name "$table" "$col"; then
            return 1
        fi
    done
    return 0
}

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

# Escape string for safe JSON value
# Handles special characters that need escaping in JSON strings
json_escape() {
    local value="$1"
    # Escape backslashes first (must be first)
    value="${value//\\/\\\\}"
    # Escape double quotes
    value="${value//\"/\\\"}"
    # Escape newlines
    value="${value//$'\n'/\\n}"
    # Escape carriage returns
    value="${value//$'\r'/\\r}"
    # Escape tabs
    value="${value//$'\t'/\\t}"
    echo "$value"
}

# Build a JSON object from key-value pairs
# Usage: json_object "key1" "value1" "key2" "value2" ...
json_object() {
    local result="{"
    local first=true

    while [ $# -ge 2 ]; do
        local key="$1"
        local value="$2"
        shift 2

        if [ "$first" = true ]; then
            first=false
        else
            result+=", "
        fi

        local escaped_value
        escaped_value=$(json_escape "$value")
        result+="\"$key\": \"$escaped_value\""
    done

    result+="}"
    echo "$result"
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

    # Validate table name
    if ! validate_table_name "$table"; then
        return 1
    fi

    # Validate column names
    if ! validate_columns "$table" "$columns"; then
        return 1
    fi

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

# Build safe UPDATE query with validated table/column names
# Usage: sql_update "table" "col1" "val1" "where_col" "where_val"
sql_update() {
    local table="$1"
    local set_column="$2"
    local set_value="$3"
    local where_column="$4"
    local where_value="$5"

    # Validate table name
    if ! validate_table_name "$table"; then
        return 1
    fi

    # Validate column names
    if ! validate_column_name "$table" "$set_column"; then
        return 1
    fi
    if ! validate_column_name "$table" "$where_column"; then
        return 1
    fi

    local escaped_set_value
    escaped_set_value=$(sql_escape "$set_value")
    local escaped_where_value
    escaped_where_value=$(sql_escape "$where_value")

    local query="UPDATE $table SET $set_column = '$escaped_set_value' WHERE $where_column = '$escaped_where_value';"
    sql_exec "$query"
}

# Build safe UPDATE query with multiple SET clauses
# Usage: sql_update_multi "table" "where_col" "where_val" "col1" "val1" "col2" "val2" ...
sql_update_multi() {
    local table="$1"
    local where_column="$2"
    local where_value="$3"
    shift 3

    # Validate table name
    if ! validate_table_name "$table"; then
        return 1
    fi

    # Validate where column
    if ! validate_column_name "$table" "$where_column"; then
        return 1
    fi

    # Build SET clause from pairs
    local set_clause=""
    local first=true
    while [ $# -ge 2 ]; do
        local col="$1"
        local val="$2"
        shift 2

        # Validate column name
        if ! validate_column_name "$table" "$col"; then
            return 1
        fi

        if [ "$first" = true ]; then
            first=false
        else
            set_clause+=", "
        fi

        local escaped_val
        escaped_val=$(sql_escape "$val")
        set_clause+="$col = '$escaped_val'"
    done

    local escaped_where_value
    escaped_where_value=$(sql_escape "$where_value")

    local query="UPDATE $table SET $set_clause WHERE $where_column = '$escaped_where_value';"
    sql_exec "$query"
}

# Build safe SELECT query
# Usage: sql_select "field1,field2" "table" "where_col" "where_val"
sql_select() {
    local fields="$1"
    local table="$2"
    local where_column="$3"
    local where_value="$4"

    # Validate table name
    if ! validate_table_name "$table"; then
        return 1
    fi

    # Validate select fields (can be "*" for all)
    if [ "$fields" != "*" ]; then
        if ! validate_columns "$table" "$fields"; then
            return 1
        fi
    fi

    # Validate where column
    if ! validate_column_name "$table" "$where_column"; then
        return 1
    fi

    local escaped_value
    escaped_value=$(sql_escape "$where_value")

    local query="SELECT $fields FROM $table WHERE $where_column = '$escaped_value';"
    sql_exec "$query"
}

# ============================================================================
# TRANSACTION SUPPORT
# ============================================================================

# Begin a transaction (for atomic multi-step operations)
sql_begin_transaction() {
    sql_exec "BEGIN IMMEDIATE TRANSACTION;"
}

# Commit a transaction
sql_commit() {
    sql_exec "COMMIT;"
}

# Rollback a transaction
sql_rollback() {
    sql_exec "ROLLBACK;"
}

# Execute multiple statements atomically
# Usage: sql_transaction "stmt1;" "stmt2;" "stmt3;"
sql_transaction() {
    if [ ! -f "$DB_FILE" ]; then
        log_error "Database file not found: $DB_FILE" "sql"
        return 1
    fi

    # Build full transaction
    local full_sql="BEGIN IMMEDIATE TRANSACTION;"
    for stmt in "$@"; do
        full_sql+=" $stmt"
    done
    full_sql+=" COMMIT;"

    local result
    if ! result=$(sqlite3 "$DB_FILE" "$full_sql" 2>&1); then
        log_error "Transaction failed: $result" "sql"
        # Attempt rollback in case partial execution
        sqlite3 "$DB_FILE" "ROLLBACK;" 2>/dev/null || true
        return 1
    fi

    echo "$result"
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
# Uses POSIX-compliant method for portability
generate_id() {
    local prefix="${1:-id}"
    local hex_suffix

    # Try xxd first (common on Linux), fall back to od (POSIX)
    if command -v xxd &> /dev/null; then
        hex_suffix=$(head -c 4 /dev/urandom | xxd -p)
    else
        # POSIX-compliant alternative using od
        hex_suffix=$(head -c 4 /dev/urandom | od -An -tx1 | tr -d ' \n')
    fi

    echo "${prefix}-$(date +%Y%m%d-%H%M%S)-${hex_suffix}"
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
