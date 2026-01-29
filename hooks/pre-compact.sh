#!/bin/bash
# DevTeam Pre-Compact Hook
# Saves critical state before context compaction to preserve important information

set -e

# Configuration
MEMORY_DIR=".devteam/memory"
STATE_FILE=".devteam/state.yaml"
COMPACT_FILE="$MEMORY_DIR/pre-compact-$(date +%Y%m%d-%H%M%S).md"

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

    # Add current task context
    if [ -f "$STATE_FILE" ]; then
        echo "## Current Execution State" >> "$COMPACT_FILE"
        echo "" >> "$COMPACT_FILE"

        # Extract and save current context
        if command -v yq &> /dev/null; then
            echo "- Sprint: $(yq -r '.current_execution.current_sprint // "none"' "$STATE_FILE")" >> "$COMPACT_FILE"
            echo "- Task: $(yq -r '.current_execution.current_task // "none"' "$STATE_FILE")" >> "$COMPACT_FILE"
            echo "- Phase: $(yq -r '.current_execution.phase // "unknown"' "$STATE_FILE")" >> "$COMPACT_FILE"

            # Get current task details if in progress
            CURRENT_TASK=$(yq -r '.current_execution.current_task // ""' "$STATE_FILE")
            if [ -n "$CURRENT_TASK" ] && [ "$CURRENT_TASK" != "null" ]; then
                echo "" >> "$COMPACT_FILE"
                echo "### Current Task Details" >> "$COMPACT_FILE"
                echo "" >> "$COMPACT_FILE"

                TASK_STATUS=$(yq -r ".tasks[\"$CURRENT_TASK\"].status // \"unknown\"" "$STATE_FILE")
                TASK_ITERATION=$(yq -r ".tasks[\"$CURRENT_TASK\"].iterations // 0" "$STATE_FILE")
                TASK_TIER=$(yq -r ".tasks[\"$CURRENT_TASK\"].complexity.tier // \"unknown\"" "$STATE_FILE")

                echo "- Status: $TASK_STATUS" >> "$COMPACT_FILE"
                echo "- Iteration: $TASK_ITERATION" >> "$COMPACT_FILE"
                echo "- Complexity Tier: $TASK_TIER" >> "$COMPACT_FILE"
            fi
        else
            # Fallback without yq
            grep -A5 "current_execution:" "$STATE_FILE" >> "$COMPACT_FILE" 2>/dev/null || true
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

1. Full state is in `.devteam/state.yaml` - always read it to understand progress
2. Check task status before starting work
3. Update state file after completing tasks
4. Output `EXIT_SIGNAL: true` only when ALL work is genuinely complete

## Recovery Instructions

If resuming after compaction:
1. Read `.devteam/state.yaml` to understand current state
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
