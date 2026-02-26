#!/bin/bash
# DevTeam Session End Hook
# Saves session context for future resumption

set -euo pipefail

# Configuration
MEMORY_DIR=".devteam/memory"
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
MEMORY_FILE="$MEMORY_DIR/session-$TIMESTAMP.md"

# Source common library for SQLite helpers
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [[ -f "$SCRIPT_DIR/lib/hook-common.sh" ]]; then
    source "$SCRIPT_DIR/lib/hook-common.sh"
elif [[ -f "$SCRIPT_DIR/../lib/hook-common.sh" ]]; then
    source "$SCRIPT_DIR/../lib/hook-common.sh"
else
    echo "[DevTeam Session End] Warning: hook-common.sh not found" >&2
    exit 0
fi

# Logging function
log() {
    echo "[DevTeam Session End] $1"
}

# ============================================
# EXTRACT STATE INFORMATION
# ============================================
extract_state() {
    if db_exists 2>/dev/null; then
        local safe_session_id
        safe_session_id=$(get_current_session 2>/dev/null || echo "")
        safe_session_id="${safe_session_id//\'/\'\'}"
        CURRENT_SPRINT=$(db_query "SELECT sprint_id FROM sessions WHERE id = '$safe_session_id';" 2>/dev/null || echo "unknown")
        CURRENT_TASK=$(db_query "SELECT current_task_id FROM sessions WHERE id = '$safe_session_id';" 2>/dev/null || echo "unknown")
        PHASE=$(db_query "SELECT current_phase FROM sessions WHERE id = '$safe_session_id';" 2>/dev/null || echo "unknown")
        COMPLETED_TASKS=$(db_query "SELECT COUNT(*) FROM tasks WHERE status='completed';" 2>/dev/null || echo "0")
        TOTAL_TASKS=$(db_query "SELECT COUNT(*) FROM tasks;" 2>/dev/null || echo "0")

        CURRENT_SPRINT="${CURRENT_SPRINT:-unknown}"
        CURRENT_TASK="${CURRENT_TASK:-unknown}"
        PHASE="${PHASE:-unknown}"
        COMPLETED_TASKS="${COMPLETED_TASKS:-0}"
        TOTAL_TASKS="${TOTAL_TASKS:-0}"
    else
        CURRENT_SPRINT="unknown"
        CURRENT_TASK="unknown"
        PHASE="unknown"
        COMPLETED_TASKS="0"
        TOTAL_TASKS="0"
    fi
}

# ============================================
# SAVE SESSION MEMORY
# ============================================
save_memory() {
    mkdir -p "$MEMORY_DIR"

    extract_state

    cat > "$MEMORY_FILE" << EOF
# Session Memory - $(date -Iseconds)

## Context at Session End

- **Sprint:** $CURRENT_SPRINT
- **Task:** $CURRENT_TASK
- **Phase:** $PHASE
- **Progress:** $COMPLETED_TASKS / $TOTAL_TASKS tasks completed

## State Database Location

The full project state is stored in: \`.devteam/devteam.db\` (SQLite)

## Resumption Instructions

To resume this work:
1. The database contains all progress information
2. Run \`/devteam:implement --resume\` to continue autonomous execution
3. Or run \`/devteam:implement --sprint <sprint-id>\` to continue a specific sprint

## Notes

This session ended at $(date).

If this was an unexpected interruption (context limit, timeout, etc.),
the work can be resumed from the last saved state.

EOF

    log "Session memory saved to $MEMORY_FILE"
}

# ============================================
# CLEANUP OLD MEMORY FILES
# ============================================
cleanup_old_memories() {
    # Keep only the last 10 memory files
    if [ -d "$MEMORY_DIR" ]; then
        FILE_COUNT=$(ls -1 "$MEMORY_DIR"/session-*.md 2>/dev/null | wc -l)
        if [ "$FILE_COUNT" -gt 10 ]; then
            log "Cleaning up old memory files (keeping last 10)"
            ls -t "$MEMORY_DIR"/session-*.md | tail -n +11 | xargs rm -f
        fi
    fi
}

# ============================================
# MAIN EXECUTION
# ============================================
main() {
    log "Saving session state..."

    # Save memory file
    save_memory

    # Cleanup old files
    cleanup_old_memories

    log "Session end complete"
}

# Run main function
main
