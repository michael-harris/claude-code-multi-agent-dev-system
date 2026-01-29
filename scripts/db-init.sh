#!/bin/bash
# DevTeam Database Initialization
# Creates and initializes the SQLite database if it doesn't exist

set -e

# Configuration
DEVTEAM_DIR="${DEVTEAM_DIR:-.devteam}"
DB_FILE="${DEVTEAM_DIR}/devteam.db"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCHEMA_FILE="${SCRIPT_DIR}/schema.sql"

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

# Initialize database
init_database() {
    if [ ! -f "$DB_FILE" ]; then
        log_info "Initializing DevTeam database..."

        if [ ! -f "$SCHEMA_FILE" ]; then
            log_error "Schema file not found: $SCHEMA_FILE"
            exit 1
        fi

        sqlite3 "$DB_FILE" < "$SCHEMA_FILE"
        log_info "Database created: $DB_FILE"
    else
        # Check if we need to run migrations
        local current_version
        current_version=$(sqlite3 "$DB_FILE" "SELECT value FROM session_state WHERE key='schema_version' LIMIT 1" 2>/dev/null || echo "0")

        if [ "$current_version" = "0" ]; then
            log_info "Database exists, checking schema..."
            # Re-run schema to add any missing tables (IF NOT EXISTS handles this safely)
            sqlite3 "$DB_FILE" < "$SCHEMA_FILE" 2>/dev/null || true
        fi
    fi
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
