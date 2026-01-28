#!/bin/bash
# DevTeam Session End Hook
# Saves session context for future resumption

set -e

# Configuration
MEMORY_DIR=".devteam/memory"
STATE_FILE=".devteam/state.yaml"
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
MEMORY_FILE="$MEMORY_DIR/session-$TIMESTAMP.md"

# Logging function
log() {
    echo "[DevTeam Session End] $1"
}

# ============================================
# EXTRACT STATE INFORMATION
# ============================================
extract_state() {
    if [ -f "$STATE_FILE" ]; then
        if command -v yq &> /dev/null; then
            CURRENT_SPRINT=$(yq -r '.current_execution.current_sprint // "unknown"' "$STATE_FILE" 2>/dev/null)
            CURRENT_TASK=$(yq -r '.current_execution.current_task // "unknown"' "$STATE_FILE" 2>/dev/null)
            PHASE=$(yq -r '.current_execution.phase // "unknown"' "$STATE_FILE" 2>/dev/null)
            COMPLETED_TASKS=$(yq -r '.statistics.completed_tasks // 0' "$STATE_FILE" 2>/dev/null)
            TOTAL_TASKS=$(yq -r '.statistics.total_tasks // 0' "$STATE_FILE" 2>/dev/null)
        else
            CURRENT_SPRINT=$(grep "current_sprint:" "$STATE_FILE" 2>/dev/null | head -1 | awk '{print $2}' || echo "unknown")
            CURRENT_TASK=$(grep "current_task:" "$STATE_FILE" 2>/dev/null | head -1 | awk '{print $2}' || echo "unknown")
            PHASE=$(grep "phase:" "$STATE_FILE" 2>/dev/null | head -1 | awk '{print $2}' || echo "unknown")
            COMPLETED_TASKS=$(grep -c "status: completed" "$STATE_FILE" 2>/dev/null || echo "0")
            TOTAL_TASKS=$(grep -c "TASK-" "$STATE_FILE" 2>/dev/null || echo "0")
        fi
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

## State File Location

The full project state is stored in: \`$STATE_FILE\`

## Resumption Instructions

To resume this work:
1. The state file contains all progress information
2. Run \`/devteam:auto --resume\` to continue autonomous execution
3. Or run \`/devteam:sprint <sprint-id>\` to continue a specific sprint

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
