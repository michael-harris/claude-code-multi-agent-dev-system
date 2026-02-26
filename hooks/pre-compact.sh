#!/bin/bash
# DevTeam Pre-Compact Hook
# Saves critical state before context compaction to preserve important information

set -euo pipefail

# Configuration
MEMORY_DIR=".devteam/memory"
COMPACT_FILE="$MEMORY_DIR/pre-compact-$(date +%Y%m%d-%H%M%S).md"

# Source common library for SQLite helpers
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [[ -f "$SCRIPT_DIR/lib/hook-common.sh" ]]; then
    source "$SCRIPT_DIR/lib/hook-common.sh"
elif [[ -f "$SCRIPT_DIR/../lib/hook-common.sh" ]]; then
    source "$SCRIPT_DIR/../lib/hook-common.sh"
else
    echo "[DevTeam Pre-Compact] Warning: hook-common.sh not found" >&2
    exit 0
fi

# Logging function
log() {
    echo "[DevTeam Pre-Compact] $1"
}

# ============================================
# SAVE CRITICAL CONTEXT
# ============================================
save_critical_context() {
    mkdir -p "$MEMORY_DIR"

    cat > "$COMPACT_FILE" << 'HEADER'
# Pre-Compaction State Snapshot

This file was created automatically before context compaction.
It preserves critical information that should not be lost.

HEADER

    # Add current task context from SQLite database
    if db_exists 2>/dev/null; then
        echo "## Current Execution State" >> "$COMPACT_FILE"
        echo "" >> "$COMPACT_FILE"

        # Extract and save current context from database
        local db_sprint db_task db_phase safe_session_id
        safe_session_id=$(get_current_session 2>/dev/null || echo "")
        safe_session_id="${safe_session_id//\'/\'\'}"
        db_sprint=$(db_query "SELECT sprint_id FROM sessions WHERE id = '$safe_session_id';" 2>/dev/null || echo "none")
        db_task=$(db_query "SELECT current_task_id FROM sessions WHERE id = '$safe_session_id';" 2>/dev/null || echo "none")
        db_phase=$(db_query "SELECT current_phase FROM sessions WHERE id = '$safe_session_id';" 2>/dev/null || echo "unknown")

        echo "- Sprint: ${db_sprint:-none}" >> "$COMPACT_FILE"
        echo "- Task: ${db_task:-none}" >> "$COMPACT_FILE"
        echo "- Phase: ${db_phase:-unknown}" >> "$COMPACT_FILE"

        # Get current task details if in progress
        CURRENT_TASK="${db_task:-}"
        if [ -n "$CURRENT_TASK" ] && [ "$CURRENT_TASK" != "none" ]; then
            local safe_task="${CURRENT_TASK//\'/\'\'}"
            local task_status task_iteration task_tier
            task_status=$(db_query "SELECT status FROM tasks WHERE id='$safe_task';" 2>/dev/null || echo "unknown")
            task_iteration=$(db_query "SELECT actual_iterations FROM tasks WHERE id='$safe_task';" 2>/dev/null || echo "0")
            task_tier=$(db_query "SELECT estimated_effort FROM tasks WHERE id='$safe_task';" 2>/dev/null || echo "unknown")

            echo "" >> "$COMPACT_FILE"
            echo "### Current Task Details" >> "$COMPACT_FILE"
            echo "" >> "$COMPACT_FILE"
            echo "- Status: ${task_status:-unknown}" >> "$COMPACT_FILE"
            echo "- Iteration: ${task_iteration:-0}" >> "$COMPACT_FILE"
            echo "- Complexity Tier: ${task_tier:-unknown}" >> "$COMPACT_FILE"
        fi

        echo "" >> "$COMPACT_FILE"
    fi

    # Add autonomous mode status
    if [ -f ".devteam/autonomous-mode" ]; then
        echo "## Autonomous Mode" >> "$COMPACT_FILE"
        echo "" >> "$COMPACT_FILE"
        echo "Autonomous mode is ACTIVE. Continue working until EXIT_SIGNAL." >> "$COMPACT_FILE"
        echo "" >> "$COMPACT_FILE"

        if [ -f ".devteam/circuit-breaker.json" ]; then
            echo "### Circuit Breaker Status" >> "$COMPACT_FILE"
            echo '```json' >> "$COMPACT_FILE"
            cat ".devteam/circuit-breaker.json" >> "$COMPACT_FILE"
            echo '```' >> "$COMPACT_FILE"
            echo "" >> "$COMPACT_FILE"
        fi
    fi

    # Add reminder about state file
    cat >> "$COMPACT_FILE" << 'FOOTER'

## Important Reminders

1. Full state is in `.devteam/devteam.db` (SQLite) - query it to understand progress
2. Check task status before starting work
3. Update database state after completing tasks
4. Output `EXIT_SIGNAL: true` only when ALL work is genuinely complete

## Recovery Instructions

If resuming after compaction:
1. Query `.devteam/devteam.db` to understand current state
2. Continue from the current task/sprint
3. Do not restart completed work

FOOTER

    log "Critical context saved to $COMPACT_FILE"
}

# ============================================
# OUTPUT CONTEXT FOR CLAUDE
# ============================================
output_context() {
    # This output will be preserved in Claude's context after compaction
    echo ""
    echo "## Post-Compaction Context"
    echo ""

    if [ -f "$COMPACT_FILE" ]; then
        cat "$COMPACT_FILE"
    fi
}

# ============================================
# MAIN EXECUTION
# ============================================
main() {
    log "Preparing for context compaction..."

    # Save critical context
    save_critical_context

    # Output for Claude
    output_context

    log "Pre-compact preparation complete"
}

# Run main function
main
