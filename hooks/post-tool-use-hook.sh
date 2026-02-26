#!/bin/bash
# DevTeam Post-Tool-Use Hook
# Runs AFTER each tool call to log, detect patterns, and guide next steps
#
# Exit codes:
#   0 = Continue normally
#   (Post hooks typically don't block, just observe and inject guidance)
#
# Environment variables expected:
#   CLAUDE_TOOL_NAME - Name of the tool that was called
#   CLAUDE_TOOL_RESULT - Result/output from the tool

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source common library with fallback paths (H6)
if [[ -f "$SCRIPT_DIR/lib/hook-common.sh" ]]; then
    source "$SCRIPT_DIR/lib/hook-common.sh"
elif [[ -f "$SCRIPT_DIR/../lib/hook-common.sh" ]]; then
    source "$SCRIPT_DIR/../lib/hook-common.sh"
else
    echo "[post-tool-use] Warning: hook-common.sh not found" >&2
    exit 0
fi

init_hook "post-tool-use"

# ============================================================================
# CONFIGURATION
# ============================================================================

TOOL_NAME="${CLAUDE_TOOL_NAME:-}"
TOOL_RESULT="${CLAUDE_TOOL_RESULT:-}"

# ============================================================================
# OUTCOME DETECTION PATTERNS
# ============================================================================

# Patterns indicating failure
FAILURE_PATTERNS=(
    "FAIL"
    "FAILED"
    "Error:"
    "error:"
    "ERROR"
    "Exception"
    "Traceback"
    "AssertionError"
    "TypeError"
    "SyntaxError"
    "ReferenceError"
    "ModuleNotFoundError"
    "ImportError"
    "AttributeError"
    "NameError"
    "KeyError"
    "IndexError"
    "ValueError"
    "RuntimeError"
    "exit code [1-9]"
    "exit status [1-9]"
    "exited with code [1-9]"
    "Build failed"
    "Test failed"
    "Compilation failed"
    "compile error"
    "Permission denied"
    "No such file"
    "command not found"
    "ENOENT"
    "EACCES"
    "EPERM"
)

# Patterns indicating success
SUCCESS_PATTERNS=(
    "PASS"
    "PASSED"
    "All tests pass"
    "tests passed"
    "Build succeeded"
    "Successfully"
    "Completed successfully"
    "0 errors"
    "0 failures"
    "exit code 0"
    "exit status 0"
    "OK"
    "Done"
    "created successfully"
    "updated successfully"
)

# ============================================================================
# OUTCOME DETECTION
# ============================================================================

detect_outcome() {
    local result="$1"

    # Check for failure patterns first (more specific, takes priority)
    for pattern in "${FAILURE_PATTERNS[@]}"; do
        if echo "$result" | grep -qiE "$pattern"; then
            echo "failure"
            return
        fi
    done

    # Check for success patterns
    for pattern in "${SUCCESS_PATTERNS[@]}"; do
        if echo "$result" | grep -qi "$pattern"; then
            echo "success"
            return
        fi
    done

    echo "unknown"
}

# ============================================================================
# QUALITY GATE DETECTION
# ============================================================================

detect_quality_gate() {
    local tool="$1"
    local result="$2"

    # Only analyze Bash command results
    if [[ "$tool" != "Bash" ]]; then
        return
    fi

    local gate=""
    local gate_type=""

    # Detect which quality gate was run
    if echo "$result" | grep -qiE "(pytest|jest|vitest|mocha|go test|npm test|yarn test|bun test|rspec|phpunit|cargo test)"; then
        gate="tests"
        gate_type="test"
    elif echo "$result" | grep -qiE "(tsc|mypy|pyright|type.check|typescript)"; then
        gate="typecheck"
        gate_type="type"
    elif echo "$result" | grep -qiE "(eslint|ruff|golangci-lint|rubocop|phpcs|flake8|pylint|biome|prettier)"; then
        gate="lint"
        gate_type="lint"
    elif echo "$result" | grep -qiE "(bandit|npm audit|yarn audit|gosec|brakeman|safety|snyk|trivy)"; then
        gate="security"
        gate_type="security"
    elif echo "$result" | grep -qiE "(coverage|--cov|coverprofile|lcov|nyc|c8)"; then
        gate="coverage"
        gate_type="coverage"
    elif echo "$result" | grep -qiE "(build|compile|webpack|vite|esbuild|rollup|tsc --build)"; then
        gate="build"
        gate_type="build"
    fi

    if [[ -n "$gate" ]]; then
        local outcome
        outcome=$(detect_outcome "$result")
        local passed="false"
        [[ "$outcome" == "success" ]] && passed="true"

        log_info "post-tool-use" "Quality gate detected: $gate ($outcome)"
        log_event_to_db "gate_result" "gate" "Gate $gate: $outcome" \
            "{\"gate\": \"$gate\", \"type\": \"$gate_type\", \"passed\": $passed}"

        # If gate failed, provide guidance
        if [[ "$passed" == "false" ]]; then
            local error_count
            error_count=$(echo "$result" | grep -ciE "(error|fail)" || echo "0")

            inject_system_message "gate-failed" "
QUALITY GATE FAILED: $gate

Detected approximately $error_count error(s).

Next steps:
1. Analyze the specific errors above
2. Fix the issues one at a time
3. Re-run the $gate gate to verify fixes
4. Continue until gate passes

Do not proceed to the next task until this gate passes.
"
        fi
    fi
}

# ============================================================================
# FAILURE TRACKING & ESCALATION
# ============================================================================

handle_failure() {
    local result="$1"

    # Increment failure counter
    increment_failures

    local failures
    failures=$(get_consecutive_failures)
    local current_model
    current_model=$(get_current_model)

    log_warn "post-tool-use" "Failure detected (consecutive: $failures)"

    # Extract and store error summary
    local errors_file="$DEVTEAM_DIR/last-errors.txt"
    echo "$result" | grep -iE "(error|fail|exception|assert)" | head -20 > "$errors_file" 2>/dev/null || true

    # Determine escalation threshold
    local threshold=2
    if [[ "$ECO_MODE" == "true" ]]; then
        threshold=4
    fi

    # Check if escalation needed
    if [[ "$failures" -ge "$threshold" ]]; then
        trigger_escalation "$failures consecutive failures"

        local next_model
        case "$current_model" in
            haiku) next_model="sonnet" ;;
            sonnet) next_model="opus" ;;
            opus) next_model="bug_council" ;;
            *) next_model="" ;;
        esac

        if [[ "$next_model" == "bug_council" ]]; then
            inject_system_message "bug-council" "
BUG COUNCIL ACTIVATION REQUIRED

$failures consecutive failures with $current_model model.

The Bug Council must be activated to diagnose this issue.

The 5-member diagnostic team:
1. Root Cause Analyst - Identifies fundamental causes
2. Code Archaeologist - Examines code history and context
3. Pattern Matcher - Finds similar issues and solutions
4. Systems Thinker - Analyzes component interactions
5. Adversarial Tester - Challenges assumptions

Use devteam_bug_council_analyze if MCP is available.
"
        elif [[ -n "$next_model" ]]; then
            inject_system_message "escalation" "
MODEL ESCALATED

Previous model: $current_model
New model: $next_model
Reason: $failures consecutive failures

The escalated model has enhanced reasoning capabilities.

Please:
1. Review the previous errors carefully
2. Consider alternative approaches
3. Try a different strategy than before
"
        fi
    fi
}

# ============================================================================
# SUCCESS HANDLING
# ============================================================================

handle_success() {
    local result="$1"

    # Reset failure counter on success
    reset_failures

    log_info "post-tool-use" "Success detected"

    # Check if this looks like complete task success
    if echo "$result" | grep -qiE "(All tests pass|0 failed|100% passed|all.*gates.*pass)"; then
        log_info "post-tool-use" "Potential task completion detected"

        inject_system_message "completion-check" "
Tests appear to be passing.

Before marking complete, verify:
1. All acceptance criteria are met
2. All quality gates pass (tests, types, lint, security)
3. No scope violations occurred
4. Code is properly committed

If everything passes, report completion with EXIT_SIGNAL: true
"
    fi
}

# ============================================================================
# ERROR PATTERN ANALYSIS
# ============================================================================

analyze_error_patterns() {
    local result="$1"

    # Detect common error patterns and provide specific guidance

    # Missing dependency
    if echo "$result" | grep -qiE "(ModuleNotFoundError|Cannot find module|package.*not found)"; then
        inject_system_message "missing-dep" "
MISSING DEPENDENCY DETECTED

A required package or module is not installed.

Actions:
1. Identify the missing package from the error
2. Install it using the appropriate package manager
3. Re-run the failed command
"
    fi

    # Type errors
    if echo "$result" | grep -qiE "(TypeError|type.*mismatch|expected.*got)"; then
        inject_system_message "type-error" "
TYPE ERROR DETECTED

There's a type mismatch in the code.

Actions:
1. Check the expected vs actual types
2. Verify function signatures and return types
3. Add type annotations if helpful
"
    fi

    # Permission errors
    if echo "$result" | grep -qiE "(Permission denied|EACCES|EPERM)"; then
        inject_system_message "permission-error" "
PERMISSION ERROR DETECTED

The operation was blocked due to insufficient permissions.

Actions:
1. Check file/directory permissions
2. Verify you have access to the resource
3. Do NOT use sudo/admin unless absolutely necessary and user-approved
"
    fi
}

# ============================================================================
# MAIN EXECUTION
# ============================================================================

main() {
    # Skip if no tool result
    if [[ -z "$TOOL_RESULT" ]]; then
        exit 0
    fi

    log_debug "post-tool-use" "Processing result from: $TOOL_NAME"

    # Detect outcome
    local outcome
    outcome=$(detect_outcome "$TOOL_RESULT")

    # Log tool execution
    log_event_to_db "tool_executed" "general" "Tool: $TOOL_NAME, Outcome: $outcome" \
        "{\"tool\": \"$TOOL_NAME\", \"outcome\": \"$outcome\"}"

    # Handle based on outcome
    case "$outcome" in
        failure)
            handle_failure "$TOOL_RESULT"
            analyze_error_patterns "$TOOL_RESULT"
            ;;
        success)
            handle_success "$TOOL_RESULT"
            ;;
        unknown)
            log_debug "post-tool-use" "Outcome unknown, no action taken"
            ;;
    esac

    # Detect and log quality gate results
    detect_quality_gate "$TOOL_NAME" "$TOOL_RESULT"

    # Notify MCP server
    mcp_notify "post_tool_use" "$(get_claude_context)"

    exit 0
}

main "$@"
