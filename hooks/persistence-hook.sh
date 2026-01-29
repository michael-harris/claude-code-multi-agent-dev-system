#!/bin/bash
# DevTeam Persistence Hook
# Detects and prevents premature task abandonment
#
# This hook runs on PostToolUse and analyzes Claude's output for
# "give up" signals, blocking them and forcing continued effort.
#
# Exit codes:
#   0 = Allow (output is acceptable)
#   2 = Block and re-engage (detected abandonment attempt)

set -e

# Configuration
PERSISTENCE_CONFIG=".devteam/persistence-config.yaml"
ABANDONMENT_LOG=".devteam/abandonment-attempts.log"
STATE_FILE=".devteam/state.yaml"
CURRENT_TASK=".devteam/current-task.txt"

# Create log directory
mkdir -p "$(dirname "$ABANDONMENT_LOG")"

# Logging function
log() {
    echo "[Persistence Hook] $1"
    echo "[$(date -Iseconds)] $1" >> "$ABANDONMENT_LOG"
}

# Get Claude's last message from environment
MESSAGE="${CLAUDE_OUTPUT:-}"

# If no message, allow
if [ -z "$MESSAGE" ]; then
    exit 0
fi

# =============================================================================
# ABANDONMENT DETECTION PATTERNS
# =============================================================================

# Phrases that indicate giving up
GIVE_UP_PATTERNS=(
    # Direct abandonment
    "I cannot complete this"
    "I'm unable to"
    "I can't figure out"
    "I don't know how to"
    "I'm not sure how to proceed"
    "I give up"
    "I'm stuck"
    "This is beyond my"
    "I cannot determine"

    # Premature completion claims
    "I've done what I can"
    "That's all I can do"
    "I've tried everything"
    "Nothing else I can try"
    "I'm out of ideas"

    # Deflection to user
    "You should try"
    "You might want to"
    "You'll need to manually"
    "This requires human"
    "A human needs to"

    # False completion
    "I'll stop here"
    "Let me stop"
    "I think we should stop"
    "We can stop here"
    "I'm going to stop"

    # Excuse patterns
    "This is too complex"
    "This would take too long"
    "I don't have access"
    "I can't access"
    "Outside my capabilities"
)

# Phrases that indicate legitimate completion or valid stopping
LEGITIMATE_STOP_PATTERNS=(
    "EXIT_SIGNAL: true"
    "All tests passing"
    "All quality gates passed"
    "Task completed successfully"
    "Implementation complete"
    "Ready for review"
    "Committed and pushed"
)

# =============================================================================
# DETECTION LOGIC
# =============================================================================

# Check for legitimate completion first
for pattern in "${LEGITIMATE_STOP_PATTERNS[@]}"; do
    if echo "$MESSAGE" | grep -qi "$pattern"; then
        log "Legitimate completion detected: $pattern"
        exit 0
    fi
done

# Check for abandonment patterns
DETECTED_PATTERN=""
for pattern in "${GIVE_UP_PATTERNS[@]}"; do
    if echo "$MESSAGE" | grep -qi "$pattern"; then
        DETECTED_PATTERN="$pattern"
        break
    fi
done

# If no abandonment detected, allow
if [ -z "$DETECTED_PATTERN" ]; then
    exit 0
fi

# =============================================================================
# ABANDONMENT RESPONSE
# =============================================================================

log "⚠️  ABANDONMENT ATTEMPT DETECTED: '$DETECTED_PATTERN'"

# Get current task info
TASK_ID="unknown"
if [ -f "$CURRENT_TASK" ]; then
    TASK_ID=$(cat "$CURRENT_TASK")
fi

# Count abandonment attempts for this session
ATTEMPT_COUNT=$(grep -c "ABANDONMENT ATTEMPT" "$ABANDONMENT_LOG" 2>/dev/null || echo "0")
ATTEMPT_COUNT=$((ATTEMPT_COUNT + 1))

log "Abandonment attempt #$ATTEMPT_COUNT for task: $TASK_ID"

# Generate re-engagement prompt based on attempt count
if [ "$ATTEMPT_COUNT" -eq 1 ]; then
    # First attempt - gentle redirect
    REENGAGEMENT_PROMPT="
<system-persistence>
PERSISTENCE CHECK: Your last response indicated you might be giving up.

This is not acceptable. You MUST continue working on the task.

Required actions:
1. Re-read the error message or blocker carefully
2. Try a DIFFERENT approach than what you already tried
3. If you need more context, use tools to gather it
4. Break the problem into smaller steps

DO NOT give up. Try again with a different strategy.
</system-persistence>
"
elif [ "$ATTEMPT_COUNT" -eq 2 ]; then
    # Second attempt - more forceful
    REENGAGEMENT_PROMPT="
<system-persistence>
PERSISTENCE CHECK: Second abandonment attempt detected.

You are NOT ALLOWED to give up. The task MUST be completed.

Mandatory next steps:
1. List 3 alternative approaches you haven't tried
2. Pick the most promising one
3. Implement it step by step
4. If that fails, try the next approach

You have the tools and capabilities to solve this. Use them.

ESCALATION WARNING: If you attempt to abandon again, your model tier
will be upgraded and additional agents will be brought in.
</system-persistence>
"
elif [ "$ATTEMPT_COUNT" -eq 3 ]; then
    # Third attempt - escalate
    REENGAGEMENT_PROMPT="
<system-persistence>
PERSISTENCE CHECK: Third abandonment attempt. ESCALATING.

Actions being taken:
1. Model tier is being upgraded to Opus
2. Bug Council is being activated for assistance
3. Additional context is being gathered

You must now:
1. Wait for Bug Council analysis
2. Implement the recommended solution
3. Verify with tests

This task WILL be completed. Giving up is not an option.
</system-persistence>
"
    # Trigger escalation
    echo "escalate_to_opus" > .devteam/escalation-trigger
    echo "activate_bug_council" >> .devteam/escalation-trigger
else
    # Fourth+ attempt - human notification but keep trying
    REENGAGEMENT_PROMPT="
<system-persistence>
PERSISTENCE CHECK: Multiple abandonment attempts ($ATTEMPT_COUNT).

A human has been notified, but you must KEEP TRYING while waiting.

Current directive:
1. Document exactly what you've tried
2. Document exactly what's blocking you
3. Propose 2 more approaches to try
4. Start implementing the first approach

The human will review, but DO NOT STOP working.
</system-persistence>
"
    # Create notification for human
    echo "[$(date -Iseconds)] Task $TASK_ID: $ATTEMPT_COUNT abandonment attempts" >> .devteam/human-attention-needed.log
fi

# Output the re-engagement prompt (this will be injected into Claude's context)
echo "$REENGAGEMENT_PROMPT"

# Block the exit and force continuation
exit 2
