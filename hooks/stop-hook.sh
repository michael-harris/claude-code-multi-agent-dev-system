#!/bin/bash
# DevTeam Stop Hook
# Implements Ralph-style session persistence for autonomous mode
#
# Exit codes:
#   0 = Allow exit (work complete or not in autonomous mode)
#   2 = Block exit and re-inject prompt (work not complete)

set -e

# Configuration
STATE_FILE=".devteam/state.yaml"
CIRCUIT_BREAKER_FILE=".devteam/circuit-breaker.json"
AUTONOMOUS_MARKER=".devteam/autonomous-mode"
MAX_FAILURES=5
MAX_ITERATIONS=100

# Logging function
log() {
    echo "[DevTeam Stop Hook] $1"
}

# Check if autonomous mode is active
if [ ! -f "$AUTONOMOUS_MARKER" ]; then
    # Not in autonomous mode, allow normal exit
    exit 0
fi

# Check for explicit EXIT_SIGNAL in Claude's output
# The STOP_HOOK_MESSAGE environment variable contains the last message
if [ -n "$STOP_HOOK_MESSAGE" ]; then
    if echo "$STOP_HOOK_MESSAGE" | grep -q "EXIT_SIGNAL: true"; then
        log "EXIT_SIGNAL received. Project complete."
        rm -f "$AUTONOMOUS_MARKER"
        exit 0
    fi
fi

# Initialize circuit breaker if it doesn't exist
if [ ! -f "$CIRCUIT_BREAKER_FILE" ]; then
    mkdir -p "$(dirname "$CIRCUIT_BREAKER_FILE")"
    echo '{"consecutive_failures": 0, "total_iterations": 0, "last_failure": null}' > "$CIRCUIT_BREAKER_FILE"
fi

# Read circuit breaker state
if command -v jq &> /dev/null; then
    FAILURES=$(jq -r '.consecutive_failures // 0' "$CIRCUIT_BREAKER_FILE" 2>/dev/null || echo "0")
    ITERATIONS=$(jq -r '.total_iterations // 0' "$CIRCUIT_BREAKER_FILE" 2>/dev/null || echo "0")
else
    # Fallback if jq not available
    FAILURES=$(grep -o '"consecutive_failures": [0-9]*' "$CIRCUIT_BREAKER_FILE" 2>/dev/null | grep -o '[0-9]*' || echo "0")
    ITERATIONS=$(grep -o '"total_iterations": [0-9]*' "$CIRCUIT_BREAKER_FILE" 2>/dev/null | grep -o '[0-9]*' || echo "0")
fi

# Check circuit breaker threshold
if [ "$FAILURES" -ge "$MAX_FAILURES" ]; then
    log "Circuit breaker OPEN: $FAILURES consecutive failures."
    log "Human intervention required. Check .devteam/state.yaml for details."
    rm -f "$AUTONOMOUS_MARKER"
    exit 0
fi

# Check maximum iterations
if [ "$ITERATIONS" -ge "$MAX_ITERATIONS" ]; then
    log "Maximum iterations ($MAX_ITERATIONS) reached."
    log "Review progress in .devteam/state.yaml"
    rm -f "$AUTONOMOUS_MARKER"
    exit 0
fi

# Check state file for completion status
if [ -f "$STATE_FILE" ]; then
    # Count task statuses
    PENDING=$(grep -c "status: pending" "$STATE_FILE" 2>/dev/null || echo "0")
    IN_PROGRESS=$(grep -c "status: in_progress" "$STATE_FILE" 2>/dev/null || echo "0")

    # If no pending or in-progress tasks, work is complete
    if [ "$PENDING" -eq 0 ] && [ "$IN_PROGRESS" -eq 0 ]; then
        # Double-check sprints
        SPRINT_PENDING=$(grep -c "status: pending" "$STATE_FILE" 2>/dev/null | head -1 || echo "0")

        if [ "$SPRINT_PENDING" -eq 0 ]; then
            log "All work complete. Allowing exit."
            rm -f "$AUTONOMOUS_MARKER"
            exit 0
        fi
    fi
fi

# Work not complete - increment iteration and continue
ITERATIONS=$((ITERATIONS + 1))

# Update circuit breaker file
if command -v jq &> /dev/null; then
    jq ".total_iterations = $ITERATIONS" "$CIRCUIT_BREAKER_FILE" > "${CIRCUIT_BREAKER_FILE}.tmp" && \
        mv "${CIRCUIT_BREAKER_FILE}.tmp" "$CIRCUIT_BREAKER_FILE"
else
    # Fallback without jq - use portable sed syntax for macOS/Linux compatibility
    if [[ "$OSTYPE" == "darwin"* ]]; then
        sed -i '' "s/\"total_iterations\": [0-9]*/\"total_iterations\": $ITERATIONS/" "$CIRCUIT_BREAKER_FILE"
    else
        sed -i "s/\"total_iterations\": [0-9]*/\"total_iterations\": $ITERATIONS/" "$CIRCUIT_BREAKER_FILE"
    fi
fi

log "Work in progress (iteration $ITERATIONS/$MAX_ITERATIONS). Continuing..."
log "Pending: $PENDING, In Progress: $IN_PROGRESS"

# Exit code 2 tells Claude Code to block exit and re-inject the prompt
exit 2
