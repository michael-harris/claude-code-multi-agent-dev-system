#!/bin/bash
# DevTeam Database Maintenance Script
# Performs routine maintenance on the SQLite database
#
# Usage:
#   ./db-maintenance.sh [command]
#
# Commands:
#   vacuum     - Reclaim unused space
#   analyze    - Update query statistics
#   cleanup    - Remove old sessions
#   backup     - Create database backup
#   check      - Verify database integrity
#   stats      - Show database statistics
#   all        - Run all maintenance tasks
#
# Example:
#   ./db-maintenance.sh all
#   ./db-maintenance.sh backup

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/common.sh"

# Configuration
BACKUP_DIR="${DEVTEAM_DIR}/backups"
MAX_BACKUPS=5
SESSION_RETENTION_DAYS=30

# ============================================================================
# MAINTENANCE COMMANDS
# ============================================================================

# Vacuum the database to reclaim space
cmd_vacuum() {
    log_info "Running VACUUM..." "maintenance"

    local before_size
    before_size=$(file_size_bytes "$DB_FILE")

    if ! sqlite3 "$DB_FILE" "VACUUM;"; then
        log_error "VACUUM failed" "maintenance"
        return 1
    fi

    local after_size
    after_size=$(file_size_bytes "$DB_FILE")

    local saved=$((before_size - after_size))
    log_info "VACUUM complete. Space reclaimed: $saved bytes" "maintenance"
}

# Update query statistics
cmd_analyze() {
    log_info "Running ANALYZE..." "maintenance"

    if ! sqlite3 "$DB_FILE" "ANALYZE;"; then
        log_error "ANALYZE failed" "maintenance"
        return 1
    fi

    log_info "ANALYZE complete" "maintenance"
}

# Clean up old sessions
cmd_cleanup() {
    log_info "Cleaning up sessions older than $SESSION_RETENTION_DAYS days..." "maintenance"

    local cutoff_date
    cutoff_date=$(date_days_ago "$SESSION_RETENTION_DAYS")

    # Validate cutoff_date is a safe date string (YYYY-MM-DD)
    if [[ ! "$cutoff_date" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]]; then
        log_error "Invalid cutoff date: $cutoff_date" "maintenance"
        return 1
    fi

    # Count sessions to delete
    local count
    count=$(sqlite3 "$DB_FILE" "SELECT COUNT(*) FROM sessions WHERE ended_at < '$cutoff_date' AND status != 'running';")

    if [ "$count" -eq 0 ]; then
        log_info "No old sessions to clean up" "maintenance"
        return 0
    fi

    log_info "Found $count sessions to clean up" "maintenance"

    # Delete sessions; ON DELETE CASCADE handles child tables (events, agent_runs, gate_results, escalations)
    sqlite3 "$DB_FILE" <<EOF
PRAGMA foreign_keys = ON;
BEGIN TRANSACTION;

-- Delete related session_state (may not have CASCADE)
DELETE FROM session_state WHERE session_id IN (
    SELECT id FROM sessions WHERE ended_at < '$cutoff_date' AND status != 'running'
);

-- Delete the sessions (CASCADE will clean up events, agent_runs, gate_results, escalations)
DELETE FROM sessions WHERE ended_at < '$cutoff_date' AND status != 'running';

COMMIT;
EOF

    log_info "Cleaned up $count old sessions" "maintenance"
}

# Create database backup
cmd_backup() {
    log_info "Creating database backup..." "maintenance"

    mkdir -p "$BACKUP_DIR"

    local timestamp
    timestamp=$(date '+%Y%m%d-%H%M%S')
    local backup_file="$BACKUP_DIR/devteam-$timestamp.db"

    # Use SQLite's backup command for consistency
    if ! sqlite3 "$DB_FILE" ".backup '$backup_file'"; then
        log_error "Backup failed" "maintenance"
        return 1
    fi

    log_info "Backup created: $backup_file" "maintenance"

    # Rotate old backups (POSIX-compliant approach)
    local backup_count
    backup_count=$(find "$BACKUP_DIR" -name "devteam-*.db" -type f | wc -l)
    backup_count=$((backup_count))  # Trim whitespace

    if [ "$backup_count" -gt "$MAX_BACKUPS" ]; then
        log_info "Rotating old backups (keeping $MAX_BACKUPS)..." "maintenance"
        local to_delete=$((backup_count - MAX_BACKUPS))
        # Sort by name (oldest first due to timestamp format) and delete oldest
        find "$BACKUP_DIR" -name "devteam-*.db" -type f | \
            sort | \
            head -n "$to_delete" | \
            xargs rm -f
    fi

    log_info "Backup complete" "maintenance"
}

# Check database integrity
cmd_check() {
    log_info "Checking database integrity..." "maintenance"

    local integrity
    integrity=$(sqlite3 "$DB_FILE" "PRAGMA integrity_check;")

    if [ "$integrity" = "ok" ]; then
        log_info "Database integrity check passed" "maintenance"
    else
        log_error "Database integrity check failed: $integrity" "maintenance"
        return 1
    fi

    # Check foreign keys
    local fk_check
    fk_check=$(sqlite3 "$DB_FILE" "PRAGMA foreign_key_check;")

    if [ -z "$fk_check" ]; then
        log_info "Foreign key check passed" "maintenance"
    else
        log_warn "Foreign key violations found: $fk_check" "maintenance"
    fi
}

# Show database statistics
cmd_stats() {
    log_info "Database Statistics" "maintenance"

    echo ""
    echo "=== Database Size ==="
    local size
    size=$(file_size_bytes "$DB_FILE")
    local size_mb
    size_mb=$(echo "scale=2; $size / 1024 / 1024" | bc 2>/dev/null || echo "?")
    echo "File size: $size bytes ($size_mb MB)"

    echo ""
    echo "=== Table Row Counts ==="
    sqlite3 "$DB_FILE" <<EOF
SELECT 'sessions' as table_name, COUNT(*) as count FROM sessions
UNION ALL
SELECT 'events', COUNT(*) FROM events
UNION ALL
SELECT 'agent_runs', COUNT(*) FROM agent_runs
UNION ALL
SELECT 'escalations', COUNT(*) FROM escalations
UNION ALL
SELECT 'gate_results', COUNT(*) FROM gate_results
UNION ALL
SELECT 'session_state', COUNT(*) FROM session_state;
EOF

    echo ""
    echo "=== Session Statistics ==="
    sqlite3 -column -header "$DB_FILE" <<EOF
SELECT
    status,
    COUNT(*) as count,
    ROUND(AVG(total_tokens_input + total_tokens_output), 0) as avg_tokens,
    ROUND(AVG(total_cost_cents), 2) as avg_cost_cents
FROM sessions
GROUP BY status;
EOF

    echo ""
    echo "=== Recent Sessions ==="
    sqlite3 -column -header "$DB_FILE" <<EOF
SELECT
    id,
    status,
    current_phase,
    datetime(started_at) as started
FROM sessions
ORDER BY started_at DESC
LIMIT 5;
EOF
}

# Run all maintenance tasks
cmd_all() {
    log_info "Running all maintenance tasks..." "maintenance"

    cmd_backup
    cmd_cleanup
    cmd_vacuum
    cmd_analyze
    cmd_check
    cmd_stats

    log_info "All maintenance tasks complete" "maintenance"
}

# ============================================================================
# MAIN
# ============================================================================

show_help() {
    echo "DevTeam Database Maintenance"
    echo ""
    echo "Usage: $0 [command]"
    echo ""
    echo "Commands:"
    echo "  vacuum     Reclaim unused space"
    echo "  analyze    Update query statistics"
    echo "  cleanup    Remove old sessions (>$SESSION_RETENTION_DAYS days)"
    echo "  backup     Create database backup"
    echo "  check      Verify database integrity"
    echo "  stats      Show database statistics"
    echo "  all        Run all maintenance tasks"
    echo ""
    echo "Environment:"
    echo "  DEVTEAM_DIR    Base directory (default: .devteam)"
    echo ""
}

main() {
    local command="${1:-help}"

    ensure_db || {
        log_error "Database not found. Run db-init.sh first." "maintenance"
        exit 1
    }

    case "$command" in
        vacuum)  cmd_vacuum ;;
        analyze) cmd_analyze ;;
        cleanup) cmd_cleanup ;;
        backup)  cmd_backup ;;
        check)   cmd_check ;;
        stats)   cmd_stats ;;
        all)     cmd_all ;;
        help|-h|--help)
            show_help
            exit 0
            ;;
        *)
            log_error "Unknown command: $command" "maintenance"
            show_help
            exit 1
            ;;
    esac
}

main "$@"
