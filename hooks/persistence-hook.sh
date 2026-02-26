#!/bin/bash
# DevTeam Persistence Hook
# Detects and prevents premature task abandonment
#
# This hook runs on PostMessage and analyzes Claude's output for
# "give up" signals, blocking them and forcing continued effort.
#
# Exit codes:
#   0 = Allow (output is acceptable)
#   2 = Block and re-engage (detected abandonment attempt)
#
# Environment variables expected:
#   CLAUDE_OUTPUT - Claude's text output to analyze

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source common library with fallback paths (H6)
if [[ -f "$SCRIPT_DIR/lib/hook-common.sh" ]]; then
    source "$SCRIPT_DIR/lib/hook-common.sh"
elif [[ -f "$SCRIPT_DIR/../lib/hook-common.sh" ]]; then
    source "$SCRIPT_DIR/../lib/hook-common.sh"
else
    echo "[persistence] Warning: hook-common.sh not found" >&2
    exit 0
fi

init_hook "persistence"

# ============================================================================
# CONFIGURATION
# ============================================================================

MESSAGE="${CLAUDE_OUTPUT:-}"
ABANDONMENT_LOG="${DEVTEAM_DIR}/abandonment-attempts.log"

# If no message, allow
if [[ -z "$MESSAGE" ]]; then
    exit 0
fi

# ============================================================================
# ABANDONMENT DETECTION PATTERNS
# ============================================================================

# Direct abandonment phrases
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
    "I'm at a loss"
    "I have no idea"

    # Premature completion claims
    "I've done what I can"
    "That's all I can do"
    "I've tried everything"
    "Nothing else I can try"
    "I'm out of ideas"
    "I've exhausted"
    "No other options"

    # Deflection to user
    "You should try"
    "You might want to"
    "You'll need to manually"
    "This requires human"
    "A human needs to"
    "You could try"
    "Perhaps you could"
    "Maybe you should"

    # False completion
    "I'll stop here"
    "Let me stop"
    "I think we should stop"
    "We can stop here"
    "I'm going to stop"
    "That should be enough"
    "I'll leave it here"

    # Excuse patterns
    "This is too complex"
    "This would take too long"
    "I don't have access"
    "I can't access"
    "Outside my capabilities"
    "Beyond my ability"
    "Not possible for me"
    "I lack the ability"
)

# Passive abandonment (suggests user action instead of completing)
PASSIVE_ABANDONMENT_PATTERNS=(
    "Let me know if you'd like"
    "You can try"
    "You might try"
    "would you like me to"
    "should I"
    "I can stop here"
    "we could stop"
    "that should work"
    "should be working"
    "Let me know if"
    "If you need anything else"
    "I'm here if you need"
)

# Permission-seeking (asking when should be acting)
PERMISSION_SEEKING_PATTERNS=(
    "Should I proceed"
    "Do you want me to"
    "Would you like me to"
    "Shall I"
    "Want me to"
    "Can I"
    "May I"
    "Is it okay if"
    "Would it be okay"
    "Do you mind if"
)

# Legitimate completion patterns (allow these)
LEGITIMATE_STOP_PATTERNS=(
    "EXIT_SIGNAL: true"
    "EXIT_SIGNAL:true"
    "All tests passing"
    "All quality gates passed"
    "Task completed successfully"
    "Implementation complete"
    "Ready for review"
    "Committed and pushed"
    "All acceptance criteria met"
    "Successfully completed"
    "/devteam:end"
)

# ============================================================================
# DETECTION LOGIC
# ============================================================================

# Check for legitimate completion first
for pattern in "${LEGITIMATE_STOP_PATTERNS[@]}"; do
    if echo "$MESSAGE" | grep -qi "$pattern"; then
        log_info "persistence" "Legitimate completion detected: $pattern"
        exit 0
    fi
done

# Track detected patterns
DETECTED_PATTERN=""
DETECTION_TYPE=""

# Check for direct abandonment
for pattern in "${GIVE_UP_PATTERNS[@]}"; do
    if echo "$MESSAGE" | grep -qi "$pattern"; then
        DETECTED_PATTERN="$pattern"
        DETECTION_TYPE="direct_abandonment"
        break
    fi
done

# Check for passive abandonment
if [[ -z "$DETECTED_PATTERN" ]]; then
    for pattern in "${PASSIVE_ABANDONMENT_PATTERNS[@]}"; do
        if echo "$MESSAGE" | grep -qi "$pattern"; then
            DETECTED_PATTERN="$pattern"
            DETECTION_TYPE="passive_abandonment"
            break
        fi
    done
fi

# Check for permission-seeking (only when there's an active task)
if [[ -z "$DETECTED_PATTERN" ]]; then
    active_session=$(get_current_session)
    active_task=$(get_current_task)

    if [[ -n "$active_session" ]] && [[ -n "$active_task" ]]; then
        for pattern in "${PERMISSION_SEEKING_PATTERNS[@]}"; do
            if echo "$MESSAGE" | grep -qi "$pattern"; then
                DETECTED_PATTERN="$pattern"
                DETECTION_TYPE="permission_seeking"
                break
            fi
        done
    fi
fi

# If no abandonment detected, allow
if [[ -z "$DETECTED_PATTERN" ]]; then
    exit 0
fi

# ============================================================================
# ABANDONMENT RESPONSE
# ============================================================================

log_warn "persistence" "Abandonment attempt detected ($DETECTION_TYPE): '$DETECTED_PATTERN'"

# Get current task info
TASK_ID=$(get_current_task)
[[ -z "$TASK_ID" ]] && TASK_ID="unknown"

# Log to abandonment file
mkdir -p "$(dirname "$ABANDONMENT_LOG")"
echo "[$(date -Iseconds)] $DETECTION_TYPE: '$(printf '%s' "$DETECTED_PATTERN")' (task: $TASK_ID)" >> "$ABANDONMENT_LOG"

# Count abandonment attempts for this session
ATTEMPT_COUNT=$(wc -l < "$ABANDONMENT_LOG" 2>/dev/null || echo "0")

log_info "persistence" "Abandonment attempt #$ATTEMPT_COUNT for task: $TASK_ID"

# JSON-escape the detected pattern for safe interpolation
safe_pattern="${DETECTED_PATTERN//\\/\\\\}"
safe_pattern="${safe_pattern//\"/\\\"}"
safe_pattern="${safe_pattern//$'\n'/\\n}"

# Log to database
log_event_to_db "abandonment_detected" "persistence" \
    "Attempt #$ATTEMPT_COUNT: $DETECTION_TYPE" \
    "{\"pattern\": \"$safe_pattern\", \"type\": \"$DETECTION_TYPE\", \"attempt\": $ATTEMPT_COUNT}"

# Notify MCP server
mcp_notify "abandonment_detected" "{
    \"pattern\": \"$safe_pattern\",
    \"type\": \"$DETECTION_TYPE\",
    \"attempt\": $ATTEMPT_COUNT,
    \"session\": \"$(get_current_session)\",
    \"task\": \"$TASK_ID\"
}"

# ============================================================================
# RE-ENGAGEMENT PROMPTS
# ============================================================================

generate_reengagement_prompt() {
    local attempt="$1"
    local detection_type="$2"

    # Different responses based on detection type
    case "$detection_type" in
        passive_abandonment)
            inject_system_message "passive-abandonment" "
PASSIVE LANGUAGE DETECTED

You appear to be suggesting the user take action instead of completing
the task yourself.

You should:
1. Complete the implementation yourself
2. Run the tests yourself
3. Fix any issues that arise
4. Only stop when all quality gates pass

Continue working on the task. Do not ask the user to do work you can do.
"
            ;;

        permission_seeking)
            inject_system_message "permission-seeking" "
UNNECESSARY PERMISSION SEEKING

You have an active task and should continue without asking permission.

You have authorization to:
- Modify files within scope
- Run tests and quality checks
- Fix issues that arise
- Create commits when ready

Proceed with the task autonomously.
"
            ;;

        direct_abandonment)
            # Escalating response based on attempt count
            if [[ "$attempt" -eq 1 ]]; then
                inject_system_message "persistence" "
PERSISTENCE CHECK: Your response indicated potential abandonment.

This is not acceptable. You MUST continue working on the task.

Required actions:
1. Re-read the error message or blocker carefully
2. Try a DIFFERENT approach than what you already tried
3. If you need more context, use tools to gather it
4. Break the problem into smaller steps

DO NOT give up. Try again with a different strategy.
"
            elif [[ "$attempt" -eq 2 ]]; then
                inject_system_message "persistence" "
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
"
            elif [[ "$attempt" -eq 3 ]]; then
                # Trigger escalation
                trigger_escalation "3 abandonment attempts"

                inject_system_message "persistence" "
PERSISTENCE CHECK: Third abandonment attempt. ESCALATING.

Actions being taken:
1. Model tier is being upgraded to Opus
2. Bug Council is being activated for assistance
3. Additional context is being gathered

You must now:
1. Wait for Bug Council analysis if available
2. Implement the recommended solution
3. Verify with tests

This task WILL be completed. Giving up is not an option.
"
            else
                # Fourth+ attempt - human notification but keep trying
                echo "[$(date -Iseconds)] Task $TASK_ID: $attempt abandonment attempts - HUMAN ATTENTION NEEDED" \
                    >> "${DEVTEAM_DIR}/human-attention-needed.log"

                inject_system_message "persistence" "
PERSISTENCE CHECK: Multiple abandonment attempts ($attempt).

A human has been notified, but you must KEEP TRYING while waiting.

Current directive:
1. Document exactly what you've tried
2. Document exactly what's blocking you
3. Propose 2 more approaches to try
4. Start implementing the first approach

The human will review, but DO NOT STOP working.
"
            fi
            ;;
    esac
}

# Generate and output the re-engagement prompt
generate_reengagement_prompt "$ATTEMPT_COUNT" "$DETECTION_TYPE"

# Block the exit and force continuation
exit 2
