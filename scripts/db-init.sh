#!/bin/bash
# DevTeam Database Initialization
# Creates and initializes the SQLite database if it doesn't exist

set -euo pipefail

# Configuration
DEVTEAM_DIR="${DEVTEAM_DIR:-.devteam}"
DB_FILE="${DEVTEAM_DIR}/devteam.db"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCHEMA_FILE="${SCRIPT_DIR}/schema.sql"
SCHEMA_V2_FILE="${SCRIPT_DIR}/schema-v2.sql"

# Current schema version - increment when schema changes
SCHEMA_VERSION="2"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${GREEN}[devteam]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[devteam]${NC} $1"
}

log_error() {
    echo -e "${RED}[devteam]${NC} $1" >&2
}

# Check for sqlite3
check_sqlite() {
    if ! command -v sqlite3 &> /dev/null; then
        log_error "sqlite3 is not installed. Please install it:"
        log_error "  macOS: brew install sqlite3"
        log_error "  Ubuntu/Debian: sudo apt-get install sqlite3"
        log_error "  Windows: Download from https://sqlite.org/download.html"
        exit 1
    fi
}

# Create .devteam directory if needed
ensure_devteam_dir() {
    if [ ! -d "$DEVTEAM_DIR" ]; then
        mkdir -p "$DEVTEAM_DIR"
        log_info "Created $DEVTEAM_DIR directory"
    fi
}

# Execute SQL with foreign keys enabled
sql_exec() {
    sqlite3 "$DB_FILE" "PRAGMA foreign_keys = ON; $1"
}

# Get current schema version from database
get_db_schema_version() {
    if [ ! -f "$DB_FILE" ]; then
        echo "0"
        return
    fi

    # Check if schema_version table exists
    local table_exists
    table_exists=$(sqlite3 "$DB_FILE" "SELECT COUNT(*) FROM sqlite_master WHERE type='table' AND name='schema_version';" 2>/dev/null || echo "0")

    if [ "$table_exists" = "0" ]; then
        echo "0"
        return
    fi

    # Get the version
    local version
    version=$(sqlite3 "$DB_FILE" "SELECT version FROM schema_version ORDER BY applied_at DESC LIMIT 1;" 2>/dev/null || echo "0")
    echo "${version:-0}"
}

# Initialize database
init_database() {
    local current_version
    current_version=$(get_db_schema_version)

    if [ ! -f "$DB_FILE" ]; then
        log_info "Initializing DevTeam database..."

        if [ ! -f "$SCHEMA_FILE" ]; then
            log_error "Schema file not found: $SCHEMA_FILE"
            exit 1
        fi

        # Create database with schema
        if ! sqlite3 "$DB_FILE" < "$SCHEMA_FILE"; then
            log_error "Failed to create database schema"
            exit 1
        fi

        # Apply schema v2 (acceptance criteria, features, context management)
        if [ -f "$SCHEMA_V2_FILE" ]; then
            if ! sqlite3 "$DB_FILE" < "$SCHEMA_V2_FILE"; then
                log_error "Failed to apply schema v2"
                exit 1
            fi
            log_info "Applied schema v2 (acceptance criteria, features, context management)"
        fi

        # Enable foreign keys and set schema version
        sql_exec "CREATE TABLE IF NOT EXISTS schema_version (version INTEGER PRIMARY KEY, applied_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP);"
        sql_exec "INSERT INTO schema_version (version) VALUES ($SCHEMA_VERSION);"

        log_info "Database created: $DB_FILE (schema v$SCHEMA_VERSION)"
    elif [ "$current_version" = "0" ]; then
        log_info "Database exists but no schema version, updating..."

        # Create schema version table
        sql_exec "CREATE TABLE IF NOT EXISTS schema_version (version INTEGER PRIMARY KEY, applied_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP);"

        # Re-run schema to add any missing tables (IF NOT EXISTS handles this safely)
        if ! sqlite3 "$DB_FILE" < "$SCHEMA_FILE"; then
            log_error "Failed to update database schema"
            exit 1
        fi

        sql_exec "INSERT OR REPLACE INTO schema_version (version) VALUES ($SCHEMA_VERSION);"
        log_info "Schema updated to v$SCHEMA_VERSION"
    elif [ "$current_version" -lt "$SCHEMA_VERSION" ]; then
        log_info "Database schema upgrade needed: v$current_version → v$SCHEMA_VERSION"
        run_migrations "$current_version"
    else
        log_info "Database schema is current (v$current_version)"
    fi
}

# Run migrations from current version to target version
run_migrations() {
    local from_version="$1"

    # Migration v1 → v2: Add acceptance criteria, features, context management
    if [ "$from_version" -lt 2 ]; then
        log_info "Running migration v1 → v2..."
        if [ -f "$SCHEMA_V2_FILE" ]; then
            if ! sqlite3 "$DB_FILE" < "$SCHEMA_V2_FILE"; then
                log_error "Failed to apply schema v2 migration"
                exit 1
            fi
            log_info "Applied schema v2: acceptance_criteria, features, context_snapshots, context_budgets, progress_summaries, session_phases"
        fi
    fi

    # Update schema version
    sql_exec "INSERT OR REPLACE INTO schema_version (version) VALUES ($SCHEMA_VERSION);"
    log_info "Migrations complete, now at v$SCHEMA_VERSION"
}

# Verify database integrity
verify_database() {
    local integrity
    integrity=$(sqlite3 "$DB_FILE" "PRAGMA integrity_check;" 2>/dev/null)

    if [ "$integrity" != "ok" ]; then
        log_error "Database integrity check failed!"
        log_error "Consider backing up and reinitializing: mv $DB_FILE ${DB_FILE}.bak"
        exit 1
    fi
}

# Clean up old state files (migration from YAML)
cleanup_old_state() {
    local old_files=(
        "${DEVTEAM_DIR}/state.yaml"
        "${DEVTEAM_DIR}/circuit-breaker.json"
        "${DEVTEAM_DIR}/rate-limit-state.json"
        "${DEVTEAM_DIR}/abandonment-attempts.log"
    )

    for file in "${old_files[@]}"; do
        if [ -f "$file" ]; then
            log_warn "Found old state file: $file"
            log_warn "Consider removing after verifying migration: rm $file"
        fi
    done
}

# Main
main() {
    check_sqlite
    ensure_devteam_dir
    init_database
    verify_database
    cleanup_old_state

    log_info "Database ready: $DB_FILE"
}

# Run if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
