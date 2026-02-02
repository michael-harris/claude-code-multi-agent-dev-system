# DevTeam Hooks Augmentation - Implementation Plan

## Overview

Augment the existing hook system to provide backup enforcement and logging when the MCP orchestrator is unavailable or as a secondary control layer. These hooks work alongside the MCP server to ensure robust operation.

**Target Location:** `hooks/` directory (existing)

---

## Current State Analysis

### Existing Hooks

| File | Purpose | Status |
|------|---------|--------|
| `persistence-hook.sh` | Detect abandonment patterns | Implemented, needs enhancement |
| `stop-hook.sh` | Block exit without EXIT_SIGNAL | Implemented, needs enhancement |
| `scope-check.sh` | Validate commits against scope | Implemented, needs MCP integration |
| `*.ps1` versions | PowerShell equivalents | Exist, need same enhancements |

### Issues to Address

1. Hooks don't communicate with MCP server
2. Environment variables not reliably set
3. No automatic installation mechanism
4. Missing pre-tool-use validation hook
5. No session state awareness
6. Incomplete error recovery integration

---

## Task 1: Create Hook Infrastructure

### Task 1.1: Create Shared Hook Library

**File: `hooks/lib/hook-common.sh`**

```bash
#!/bin/bash
# Shared library for all DevTeam hooks

set -euo pipefail

# ============================================================================
# CONFIGURATION
# ============================================================================

DEVTEAM_ROOT="${DEVTEAM_ROOT:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}"
DEVTEAM_DIR="${DEVTEAM_ROOT}/.devteam"
DEVTEAM_DB="${DEVTEAM_DIR}/state.db"
DEVTEAM_LOG="${DEVTEAM_DIR}/hooks.log"
MCP_SOCKET="${DEVTEAM_DIR}/mcp.sock"

# ============================================================================
# LOGGING
# ============================================================================

log_hook() {
    local level="$1"
    local hook="$2"
    local message="$3"
    local timestamp
    timestamp=$(date -Iseconds)

    mkdir -p "$(dirname "$DEVTEAM_LOG")"
    echo "[$timestamp] [$level] [$hook] $message" >> "$DEVTEAM_LOG"

    if [[ "$level" == "ERROR" ]] || [[ "${DEVTEAM_DEBUG:-}" == "true" ]]; then
        echo "[$hook] $message" >&2
    fi
}

log_debug() { log_hook "DEBUG" "$1" "$2"; }
log_info() { log_hook "INFO" "$1" "$2"; }
log_warn() { log_hook "WARN" "$1" "$2"; }
log_error() { log_hook "ERROR" "$1" "$2"; }

# ============================================================================
# DATABASE ACCESS (when MCP unavailable)
# ============================================================================

# Check if database exists
db_exists() {
    [[ -f "$DEVTEAM_DB" ]]
}

# Execute SQL query
db_query() {
    local query="$1"
    if db_exists; then
        sqlite3 -batch "$DEVTEAM_DB" "$query" 2>/dev/null || true
    fi
}

# Get current session ID
get_current_session() {
    db_query "SELECT id FROM sessions WHERE status = 'running' ORDER BY created_at DESC LIMIT 1;"
}

# Get current task ID
get_current_task() {
    local session_id
    session_id=$(get_current_session)
    if [[ -n "$session_id" ]]; then
        db_query "SELECT id FROM tasks WHERE session_id = '$session_id' AND status = 'in_progress' LIMIT 1;"
    fi
}

# Get current iteration
get_current_iteration() {
    local session_id
    session_id=$(get_current_session)
    if [[ -n "$session_id" ]]; then
        db_query "SELECT iteration FROM sessions WHERE id = '$session_id';"
    else
        echo "0"
    fi
}

# Get current model
get_current_model() {
    local session_id
    session_id=$(get_current_session)
    if [[ -n "$session_id" ]]; then
        db_query "SELECT current_model FROM sessions WHERE id = '$session_id';"
    else
        echo "sonnet"
    fi
}

# Get scope files for current task
get_scope_files() {
    local task_id
    task_id=$(get_current_task)
    if [[ -n "$task_id" ]]; then
        db_query "SELECT scope_files FROM tasks WHERE id = '$task_id';" | tr ',' '\n'
    fi
}

# Increment failure counter
increment_failures() {
    local session_id
    session_id=$(get_current_session)
    if [[ -n "$session_id" ]]; then
        db_query "UPDATE sessions SET consecutive_failures = consecutive_failures + 1 WHERE id = '$session_id';"
    fi
}

# Log event to database
log_event_to_db() {
    local event_type="$1"
    local category="$2"
    local message="$3"
    local data="${4:-{}}"

    local session_id
    session_id=$(get_current_session)

    if [[ -n "$session_id" ]]; then
        local escaped_message
        escaped_message=$(echo "$message" | sed "s/'/''/g")
        local escaped_data
        escaped_data=$(echo "$data" | sed "s/'/''/g")

        db_query "INSERT INTO events (session_id, event_type, event_category, message, data)
                  VALUES ('$session_id', '$event_type', '$category', '$escaped_message', '$escaped_data');"
    fi
}

# ============================================================================
# MCP COMMUNICATION
# ============================================================================

# Check if MCP server is available
mcp_available() {
    [[ -S "$MCP_SOCKET" ]] || [[ -n "${MCP_SERVER_PID:-}" ]]
}

# Send message to MCP server (if available)
mcp_notify() {
    local event_type="$1"
    local data="$2"

    if mcp_available; then
        # Try to notify MCP server
        echo "{\"type\": \"$event_type\", \"data\": $data}" | nc -U "$MCP_SOCKET" 2>/dev/null || true
    fi
}

# ============================================================================
# SCOPE VALIDATION
# ============================================================================

# Check if file is in scope
file_in_scope() {
    local file="$1"
    local scope_files
    scope_files=$(get_scope_files)

    # If no scope defined, everything is in scope
    if [[ -z "$scope_files" ]]; then
        return 0
    fi

    # Check each scope pattern
    while IFS= read -r pattern; do
        if [[ -z "$pattern" ]]; then
            continue
        fi

        # Exact match
        if [[ "$file" == "$pattern" ]]; then
            return 0
        fi

        # Glob match
        if [[ "$file" == $pattern ]]; then
            return 0
        fi

        # Directory match (pattern ends with /)
        if [[ "$pattern" == */ ]] && [[ "$file" == "$pattern"* ]]; then
            return 0
        fi
    done <<< "$scope_files"

    return 1
}

# Get files being modified (from git)
get_modified_files() {
    git diff --name-only HEAD 2>/dev/null || true
    git diff --name-only --staged 2>/dev/null || true
}

# ============================================================================
# CONTEXT EXTRACTION
# ============================================================================

# Extract context from Claude Code environment
get_claude_context() {
    cat << EOF
{
    "tool_name": "${CLAUDE_TOOL_NAME:-}",
    "tool_input": "${CLAUDE_TOOL_INPUT:-}",
    "output": "${CLAUDE_OUTPUT:-}",
    "session": "$(get_current_session)",
    "task": "$(get_current_task)",
    "iteration": $(get_current_iteration),
    "model": "$(get_current_model)"
}
EOF
}

# ============================================================================
# RESPONSE INJECTION
# ============================================================================

# Inject system message into Claude's context
inject_system_message() {
    local tag="$1"
    local message="$2"

    cat << EOF
<system-$tag>
$message
</system-$tag>
EOF
}

# ============================================================================
# INITIALIZATION
# ============================================================================

# Ensure devteam directory exists
ensure_devteam_dir() {
    mkdir -p "$DEVTEAM_DIR"
}

# Initialize hook (call at start of each hook)
init_hook() {
    local hook_name="$1"
    ensure_devteam_dir
    log_debug "$hook_name" "Hook initialized"
}
```

### Task 1.2: Create PowerShell Shared Library

**File: `hooks/lib/hook-common.ps1`**

Create PowerShell equivalent of the bash library with:
- Same function signatures
- SQLite access via System.Data.SQLite or sqlite3 CLI
- Same logging format
- MCP notification support

---

## Task 2: Enhance Pre-Tool-Use Hook

### Task 2.1: Create Pre-Tool-Use Hook

**File: `hooks/pre-tool-use-hook.sh`**

```bash
#!/bin/bash
# DevTeam Pre-Tool-Use Hook
# Runs BEFORE each tool call to validate and inject context
#
# Exit codes:
#   0 = Allow tool call
#   2 = Block tool call with message

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/hook-common.sh"

init_hook "pre-tool-use"

# ============================================================================
# CONFIGURATION
# ============================================================================

TOOL_NAME="${CLAUDE_TOOL_NAME:-}"
TOOL_INPUT="${CLAUDE_TOOL_INPUT:-}"

# ============================================================================
# SCOPE VALIDATION FOR FILE OPERATIONS
# ============================================================================

validate_file_operation() {
    local tool="$1"
    local input="$2"

    # Extract file path from tool input
    local file_path=""

    case "$tool" in
        Write|Edit|NotebookEdit)
            # Extract file_path from JSON input
            file_path=$(echo "$input" | grep -oP '"file_path"\s*:\s*"\K[^"]+' || true)
            ;;
        Bash)
            # Check for file-modifying commands
            if echo "$input" | grep -qE '(cat\s*>|echo\s*>|sed\s+-i|mv\s|cp\s|rm\s)'; then
                # Extract target file (simplified - may need enhancement)
                file_path=$(echo "$input" | grep -oP '>\s*\K[^\s]+' | head -1 || true)
            fi
            ;;
        *)
            return 0  # Non-file operations allowed
            ;;
    esac

    if [[ -n "$file_path" ]]; then
        if ! file_in_scope "$file_path"; then
            log_warn "pre-tool-use" "Scope violation attempted: $file_path"
            log_event_to_db "scope_violation" "warning" "Attempted to modify out-of-scope file: $file_path"

            inject_system_message "scope-warning" "
⚠️ SCOPE VIOLATION BLOCKED

You attempted to modify: $file_path

This file is outside your allowed scope for this task.

Allowed scope:
$(get_scope_files)

Please only modify files within the allowed scope.
"
            exit 2
        fi
    fi
}

# ============================================================================
# CONTEXT INJECTION
# ============================================================================

inject_iteration_context() {
    local iteration
    iteration=$(get_current_iteration)

    local max_iterations=10
    local remaining=$((max_iterations - iteration))

    if [[ "$remaining" -le 3 ]] && [[ "$remaining" -gt 0 ]]; then
        inject_system_message "iteration-warning" "
⚠️ ITERATION WARNING

You have $remaining iterations remaining before max iterations reached.
Current iteration: $iteration/$max_iterations

Focus on fixing the most critical issues first.
"
    fi
}

# ============================================================================
# DANGEROUS COMMAND DETECTION
# ============================================================================

check_dangerous_commands() {
    local tool="$1"
    local input="$2"

    if [[ "$tool" != "Bash" ]]; then
        return 0
    fi

    # List of dangerous patterns
    local dangerous_patterns=(
        "rm -rf /"
        "rm -rf /*"
        "rm -rf ~"
        "dd if=/dev"
        "mkfs"
        ":(){ :|:& };:"
        "> /dev/sd"
        "chmod -R 777 /"
        "git push.*--force.*main"
        "git push.*--force.*master"
        "DROP DATABASE"
        "DROP TABLE"
        "TRUNCATE"
    )

    for pattern in "${dangerous_patterns[@]}"; do
        if echo "$input" | grep -qiE "$pattern"; then
            log_error "pre-tool-use" "Dangerous command blocked: $pattern"
            log_event_to_db "dangerous_command" "error" "Blocked dangerous command: $pattern"

            inject_system_message "danger-blocked" "
🛑 DANGEROUS COMMAND BLOCKED

The command you attempted contains a potentially destructive pattern:
$pattern

This command has been blocked for safety.

If this is intentional and authorized, ask the user for explicit confirmation.
"
            exit 2
        fi
    done
}

# ============================================================================
# MAIN EXECUTION
# ============================================================================

main() {
    # Skip if no tool name
    if [[ -z "$TOOL_NAME" ]]; then
        exit 0
    fi

    log_debug "pre-tool-use" "Validating: $TOOL_NAME"

    # Check for dangerous commands first
    check_dangerous_commands "$TOOL_NAME" "$TOOL_INPUT"

    # Validate scope for file operations
    validate_file_operation "$TOOL_NAME" "$TOOL_INPUT"

    # Inject context if needed
    inject_iteration_context

    # Notify MCP server
    mcp_notify "pre_tool_use" "$(get_claude_context)"

    exit 0
}

main "$@"
```

### Task 2.2: Create PowerShell Version

**File: `hooks/pre-tool-use-hook.ps1`**

PowerShell equivalent with same functionality.

---

## Task 3: Enhance Post-Tool-Use Hook

### Task 3.1: Create Enhanced Post-Tool-Use Hook

**File: `hooks/post-tool-use-hook.sh`**

```bash
#!/bin/bash
# DevTeam Post-Tool-Use Hook
# Runs AFTER each tool call to log, detect patterns, and guide next steps
#
# Exit codes:
#   0 = Continue normally
#   (Post hooks typically don't block, just observe and inject)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/hook-common.sh"

init_hook "post-tool-use"

# ============================================================================
# CONFIGURATION
# ============================================================================

TOOL_NAME="${CLAUDE_TOOL_NAME:-}"
TOOL_RESULT="${CLAUDE_TOOL_RESULT:-}"
CONSECUTIVE_FAILURES_FILE="$DEVTEAM_DIR/consecutive-failures.txt"

# ============================================================================
# FAILURE DETECTION
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
    "exit code [1-9]"
    "exit status [1-9]"
    "Build failed"
    "Test failed"
    "Compilation failed"
)

# Patterns indicating success
SUCCESS_PATTERNS=(
    "PASS"
    "PASSED"
    "All tests pass"
    "Build succeeded"
    "Successfully"
    "0 errors"
    "exit code 0"
    "exit status 0"
)

detect_outcome() {
    local result="$1"

    # Check for success patterns first
    for pattern in "${SUCCESS_PATTERNS[@]}"; do
        if echo "$result" | grep -qi "$pattern"; then
            echo "success"
            return
        fi
    done

    # Check for failure patterns
    for pattern in "${FAILURE_PATTERNS[@]}"; do
        if echo "$result" | grep -qiE "$pattern"; then
            echo "failure"
            return
        fi
    done

    echo "unknown"
}

# ============================================================================
# FAILURE TRACKING
# ============================================================================

get_consecutive_failures() {
    if [[ -f "$CONSECUTIVE_FAILURES_FILE" ]]; then
        cat "$CONSECUTIVE_FAILURES_FILE"
    else
        echo "0"
    fi
}

increment_consecutive_failures() {
    local current
    current=$(get_consecutive_failures)
    echo $((current + 1)) > "$CONSECUTIVE_FAILURES_FILE"
    increment_failures  # Also update database
}

reset_consecutive_failures() {
    echo "0" > "$CONSECUTIVE_FAILURES_FILE"
}

# ============================================================================
# QUALITY GATE DETECTION
# ============================================================================

detect_quality_gate() {
    local tool="$1"
    local result="$2"

    if [[ "$tool" != "Bash" ]]; then
        return
    fi

    # Detect which gate was run
    local gate=""

    if echo "$result" | grep -qiE "(pytest|jest|go test|npm test|rspec|phpunit)"; then
        gate="tests"
    elif echo "$result" | grep -qiE "(tsc|mypy|pyright|type.check)"; then
        gate="typecheck"
    elif echo "$result" | grep -qiE "(eslint|ruff|golangci-lint|rubocop|phpcs)"; then
        gate="lint"
    elif echo "$result" | grep -qiE "(bandit|npm audit|gosec|brakeman|security)"; then
        gate="security"
    elif echo "$result" | grep -qiE "(coverage|--cov|coverprofile)"; then
        gate="coverage"
    fi

    if [[ -n "$gate" ]]; then
        local outcome
        outcome=$(detect_outcome "$result")
        local passed="false"
        [[ "$outcome" == "success" ]] && passed="true"

        log_event_to_db "gate_result" "gate" "Gate $gate: $outcome" \
            "{\"gate\": \"$gate\", \"passed\": $passed}"

        log_info "post-tool-use" "Quality gate detected: $gate ($outcome)"
    fi
}

# ============================================================================
# ESCALATION CHECK
# ============================================================================

check_escalation_needed() {
    local failures
    failures=$(get_consecutive_failures)
    local current_model
    current_model=$(get_current_model)

    # Escalation thresholds
    local threshold=2  # Normal mode
    if [[ "${DEVTEAM_ECO_MODE:-false}" == "true" ]]; then
        threshold=4
    fi

    if [[ "$failures" -ge "$threshold" ]]; then
        local next_model=""

        case "$current_model" in
            haiku)
                next_model="sonnet"
                ;;
            sonnet)
                next_model="opus"
                ;;
            opus)
                next_model="bug_council"
                ;;
        esac

        if [[ -n "$next_model" ]]; then
            log_warn "post-tool-use" "Escalation triggered: $current_model -> $next_model"
            log_event_to_db "escalation_triggered" "escalation" \
                "Escalating from $current_model to $next_model after $failures failures"

            # Update database
            local session_id
            session_id=$(get_current_session)
            if [[ -n "$session_id" ]]; then
                db_query "UPDATE sessions SET current_model = '$next_model', consecutive_failures = 0 WHERE id = '$session_id';"

                db_query "INSERT INTO escalations (session_id, from_model, to_model, reason)
                          VALUES ('$session_id', '$current_model', '$next_model', '$failures consecutive failures');"
            fi

            reset_consecutive_failures

            # Inject escalation message
            if [[ "$next_model" == "bug_council" ]]; then
                inject_system_message "escalation" "
🔴 BUG COUNCIL ACTIVATION REQUIRED

$failures consecutive failures with $current_model model.

The Bug Council must be activated to diagnose this issue.

Use devteam_bug_council_analyze if MCP is available, or manually invoke
the 5-member diagnostic team:
1. Root Cause Analyst
2. Code Archaeologist
3. Pattern Matcher
4. Systems Thinker
5. Adversarial Tester
"
            else
                inject_system_message "escalation" "
⚠️ MODEL ESCALATED

Previous model: $current_model
New model: $next_model
Reason: $failures consecutive failures

Continue with enhanced reasoning. The escalated model has more capabilities
to solve complex problems.

Review the previous errors and try a different approach.
"
            fi
        fi
    fi
}

# ============================================================================
# SUCCESS HANDLING
# ============================================================================

check_potential_completion() {
    local result="$1"

    # Check if this looks like all tests passing
    if echo "$result" | grep -qiE "(All tests pass|0 failed|100% passed)"; then
        log_info "post-tool-use" "Potential task completion detected"

        inject_system_message "completion-check" "
✅ Tests appear to be passing.

Before marking complete, ensure:
1. All acceptance criteria are met
2. All quality gates pass (tests, types, lint, security)
3. No scope violations occurred

If everything passes, report completion with devteam_report_completion
or output EXIT_SIGNAL: true
"
    fi
}

# ============================================================================
# ERROR EXTRACTION
# ============================================================================

extract_and_store_errors() {
    local result="$1"
    local errors_file="$DEVTEAM_DIR/last-errors.txt"

    # Extract error lines
    echo "$result" | grep -iE "(error|fail|exception|assert)" | head -20 > "$errors_file" 2>/dev/null || true
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
    log_event_to_db "tool_executed" "general" "Tool executed: $TOOL_NAME ($outcome)" \
        "{\"tool\": \"$TOOL_NAME\", \"outcome\": \"$outcome\"}"

    # Handle based on outcome
    case "$outcome" in
        failure)
            increment_consecutive_failures
            extract_and_store_errors "$TOOL_RESULT"
            check_escalation_needed
            ;;
        success)
            reset_consecutive_failures
            check_potential_completion "$TOOL_RESULT"
            ;;
    esac

    # Detect quality gate results
    detect_quality_gate "$TOOL_NAME" "$TOOL_RESULT"

    # Notify MCP server
    mcp_notify "post_tool_use" "$(get_claude_context)"

    exit 0
}

main "$@"
```

### Task 3.2: Create PowerShell Version

**File: `hooks/post-tool-use-hook.ps1`**

---

## Task 4: Enhance Persistence Hook

### Task 4.1: Update Persistence Hook

**File: `hooks/persistence-hook.sh`** (update existing)

Add the following enhancements to the existing persistence hook:

```bash
# Add to existing persistence-hook.sh

# ============================================================================
# ENHANCED ABANDONMENT DETECTION
# ============================================================================

# Additional patterns for more sophisticated detection
PASSIVE_ABANDONMENT_PATTERNS=(
    "Let me know if you need"
    "Let me know if you want"
    "Feel free to"
    "You can try"
    "would you like me to"
    "should I"
    "I can stop here"
    "we could stop"
    "that should work"
    "should be working"
)

# Patterns indicating the agent is asking for permission instead of acting
PERMISSION_SEEKING_PATTERNS=(
    "Should I proceed"
    "Do you want me to"
    "Would you like me to"
    "Shall I"
    "Want me to"
    "Can I"
)

detect_passive_abandonment() {
    local message="$1"

    # Check for passive abandonment
    for pattern in "${PASSIVE_ABANDONMENT_PATTERNS[@]}"; do
        if echo "$message" | grep -qi "$pattern"; then
            return 0
        fi
    done

    return 1
}

detect_permission_seeking() {
    local message="$1"

    # Check if asking permission when should be acting
    local active_session
    active_session=$(get_current_session)

    if [[ -n "$active_session" ]]; then
        for pattern in "${PERMISSION_SEEKING_PATTERNS[@]}"; do
            if echo "$message" | grep -qi "$pattern"; then
                return 0
            fi
        done
    fi

    return 1
}

# ============================================================================
# INTEGRATION WITH MCP
# ============================================================================

notify_mcp_abandonment() {
    local pattern="$1"
    local attempt="$2"

    mcp_notify "abandonment_detected" "{
        \"pattern\": \"$pattern\",
        \"attempt\": $attempt,
        \"session\": \"$(get_current_session)\",
        \"task\": \"$(get_current_task)\"
    }"
}

# ============================================================================
# UPDATED MAIN LOGIC
# ============================================================================

# Add to main detection logic:
if detect_passive_abandonment "$MESSAGE"; then
    log_warn "persistence" "Passive abandonment detected"

    inject_system_message "passive-abandonment" "
⚠️ PASSIVE LANGUAGE DETECTED

You appear to be suggesting the user take action instead of completing
the task yourself.

You should:
1. Complete the implementation
2. Run the tests yourself
3. Fix any issues that arise
4. Only stop when all quality gates pass

Continue working on the task.
"
    exit 2
fi

if detect_permission_seeking "$MESSAGE"; then
    log_warn "persistence" "Permission seeking detected"

    inject_system_message "permission-seeking" "
⚠️ UNNECESSARY PERMISSION SEEKING

You have an active task and should continue without asking permission.

You have authorization to:
- Modify files within scope
- Run tests and quality checks
- Fix issues that arise
- Create commits when ready

Proceed with the task.
"
    exit 2
fi
```

---

## Task 5: Enhance Stop Hook

### Task 5.1: Update Stop Hook

**File: `hooks/stop-hook.sh`** (update existing)

```bash
#!/bin/bash
# DevTeam Stop Hook
# Prevents Claude from exiting without proper completion signal
#
# Exit codes:
#   0 = Allow exit
#   2 = Block exit

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/hook-common.sh"

init_hook "stop"

# ============================================================================
# CONFIGURATION
# ============================================================================

MESSAGE="${CLAUDE_OUTPUT:-}"

# ============================================================================
# COMPLETION DETECTION
# ============================================================================

VALID_EXIT_SIGNALS=(
    "EXIT_SIGNAL: true"
    "EXIT_SIGNAL:true"
    "All quality gates passed"
    "Task completed successfully"
    "Implementation complete"
    "Session ended"
    "/devteam:end"
)

has_valid_exit_signal() {
    local message="$1"

    for signal in "${VALID_EXIT_SIGNALS[@]}"; do
        if echo "$message" | grep -qi "$signal"; then
            return 0
        fi
    done

    return 1
}

# ============================================================================
# SESSION STATE CHECK
# ============================================================================

has_incomplete_work() {
    local session_id
    session_id=$(get_current_session)

    if [[ -z "$session_id" ]]; then
        return 1  # No session = no incomplete work
    fi

    # Check for in-progress tasks
    local in_progress
    in_progress=$(db_query "SELECT COUNT(*) FROM tasks WHERE session_id = '$session_id' AND status = 'in_progress';")

    if [[ "$in_progress" -gt 0 ]]; then
        return 0
    fi

    # Check if session is still running
    local session_status
    session_status=$(db_query "SELECT status FROM sessions WHERE id = '$session_id';")

    if [[ "$session_status" == "running" ]]; then
        # Check if any gates failed recently
        local recent_failures
        recent_failures=$(db_query "SELECT COUNT(*) FROM events
            WHERE session_id = '$session_id'
            AND event_type IN ('gate_failed', 'agent_failed')
            AND timestamp > datetime('now', '-5 minutes');")

        if [[ "$recent_failures" -gt 0 ]]; then
            return 0
        fi
    fi

    return 1
}

# ============================================================================
# CHECKPOINT SAVE
# ============================================================================

save_exit_checkpoint() {
    local session_id
    session_id=$(get_current_session)

    if [[ -n "$session_id" ]]; then
        log_info "stop" "Saving checkpoint before exit"

        # Create checkpoint
        "$DEVTEAM_ROOT/scripts/checkpoint.sh" save "Auto-checkpoint before exit" || true

        # Log event
        log_event_to_db "checkpoint_created" "session" "Auto-checkpoint before exit"
    fi
}

# ============================================================================
# MAIN EXECUTION
# ============================================================================

main() {
    # Check for valid exit signal
    if has_valid_exit_signal "$MESSAGE"; then
        log_info "stop" "Valid exit signal detected"

        # Save final checkpoint
        save_exit_checkpoint

        # Notify MCP
        mcp_notify "session_exit" "{\"authorized\": true}"

        exit 0
    fi

    # Check for incomplete work
    if has_incomplete_work; then
        log_warn "stop" "Exit blocked - incomplete work detected"
        log_event_to_db "exit_blocked" "persistence" "Exit blocked - incomplete work"

        inject_system_message "exit-blocked" "
🛑 EXIT BLOCKED

You cannot exit with incomplete work.

Current state:
- Session: $(get_current_session)
- Task: $(get_current_task)
- Iteration: $(get_current_iteration)

You must either:
1. Complete the task (all quality gates pass)
2. Use devteam_save_checkpoint to save progress
3. Use devteam_end_session with appropriate status

Include EXIT_SIGNAL: true when properly complete.
"
        exit 2
    fi

    # No incomplete work, allow exit
    log_info "stop" "Exit allowed - no incomplete work"
    save_exit_checkpoint
    exit 0
}

main "$@"
```

---

## Task 6: Create Scope Check Hook

### Task 6.1: Enhance Scope Check Hook

**File: `hooks/scope-check-hook.sh`** (update existing or create)

```bash
#!/bin/bash
# DevTeam Scope Check Hook
# Validates git commits against task scope
#
# Runs as git pre-commit hook
#
# Exit codes:
#   0 = Commit allowed
#   1 = Commit blocked

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Find hook-common.sh relative to git hooks dir or devteam hooks dir
if [[ -f "$SCRIPT_DIR/../lib/hook-common.sh" ]]; then
    source "$SCRIPT_DIR/../lib/hook-common.sh"
elif [[ -f "$SCRIPT_DIR/lib/hook-common.sh" ]]; then
    source "$SCRIPT_DIR/lib/hook-common.sh"
else
    echo "Error: Cannot find hook-common.sh"
    exit 1
fi

init_hook "scope-check"

# ============================================================================
# GET STAGED FILES
# ============================================================================

get_staged_files() {
    git diff --cached --name-only --diff-filter=ACMR
}

# ============================================================================
# SCOPE VALIDATION
# ============================================================================

validate_commit_scope() {
    local violations=()
    local scope_files
    scope_files=$(get_scope_files)

    # If no scope defined, allow all
    if [[ -z "$scope_files" ]]; then
        log_debug "scope-check" "No scope restrictions"
        return 0
    fi

    while IFS= read -r file; do
        if [[ -z "$file" ]]; then
            continue
        fi

        if ! file_in_scope "$file"; then
            violations+=("$file")
        fi
    done < <(get_staged_files)

    if [[ ${#violations[@]} -gt 0 ]]; then
        log_error "scope-check" "Scope violations: ${violations[*]}"
        log_event_to_db "scope_violation" "error" "Commit blocked: ${#violations[@]} out-of-scope files"

        echo ""
        echo "═══════════════════════════════════════════════════════════════"
        echo " 🛑 COMMIT BLOCKED - SCOPE VIOLATION"
        echo "═══════════════════════════════════════════════════════════════"
        echo ""
        echo "The following files are outside your task scope:"
        echo ""
        for file in "${violations[@]}"; do
            echo "  ❌ $file"
        done
        echo ""
        echo "Allowed scope:"
        echo "$scope_files" | while read -r pattern; do
            [[ -n "$pattern" ]] && echo "  ✓ $pattern"
        done
        echo ""
        echo "Options:"
        echo "  1. Remove out-of-scope files from commit: git reset HEAD <file>"
        echo "  2. Request scope expansion through devteam_request_scope"
        echo "  3. If this is intentional, commit with --no-verify (not recommended)"
        echo ""
        echo "═══════════════════════════════════════════════════════════════"
        echo ""

        return 1
    fi

    return 0
}

# ============================================================================
# SENSITIVE FILE CHECK
# ============================================================================

SENSITIVE_PATTERNS=(
    ".env"
    ".env.*"
    "*credentials*"
    "*secret*"
    "*password*"
    "*.pem"
    "*.key"
    "*token*"
    ".aws/*"
    ".ssh/*"
)

check_sensitive_files() {
    local warnings=()

    while IFS= read -r file; do
        if [[ -z "$file" ]]; then
            continue
        fi

        for pattern in "${SENSITIVE_PATTERNS[@]}"; do
            if [[ "$file" == $pattern ]]; then
                warnings+=("$file")
                break
            fi
        done
    done < <(get_staged_files)

    if [[ ${#warnings[@]} -gt 0 ]]; then
        log_warn "scope-check" "Sensitive files in commit: ${warnings[*]}"

        echo ""
        echo "⚠️  WARNING: Potentially sensitive files detected:"
        echo ""
        for file in "${warnings[@]}"; do
            echo "  ⚠️  $file"
        done
        echo ""
        echo "Please verify these files don't contain secrets."
        echo ""
    fi
}

# ============================================================================
# MAIN EXECUTION
# ============================================================================

main() {
    log_debug "scope-check" "Validating commit scope"

    # Check for sensitive files (warning only)
    check_sensitive_files

    # Validate scope (blocking)
    if ! validate_commit_scope; then
        exit 1
    fi

    # Notify MCP
    mcp_notify "commit_validated" "{\"files\": $(get_staged_files | jq -R -s -c 'split("\n") | map(select(length > 0))')}"

    log_info "scope-check" "Commit scope validated"
    exit 0
}

main "$@"
```

---

## Task 7: Create Hook Installer

### Task 7.1: Create Installation Script

**File: `hooks/install.sh`**

```bash
#!/bin/bash
# DevTeam Hooks Installer
# Installs hooks into Claude Code configuration

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

echo "═══════════════════════════════════════════════════════════════"
echo " DevTeam Hooks Installer"
echo "═══════════════════════════════════════════════════════════════"
echo ""

# ============================================================================
# DETECT CLAUDE CODE CONFIG
# ============================================================================

CLAUDE_CONFIG_DIR=""
CLAUDE_CONFIG_FILE=""

if [[ -d "$HOME/.claude" ]]; then
    CLAUDE_CONFIG_DIR="$HOME/.claude"
    CLAUDE_CONFIG_FILE="$CLAUDE_CONFIG_DIR/settings.json"
elif [[ -d "$HOME/Library/Application Support/Claude" ]]; then
    CLAUDE_CONFIG_DIR="$HOME/Library/Application Support/Claude"
    CLAUDE_CONFIG_FILE="$CLAUDE_CONFIG_DIR/settings.json"
elif [[ -d "$APPDATA/Claude" ]]; then
    CLAUDE_CONFIG_DIR="$APPDATA/Claude"
    CLAUDE_CONFIG_FILE="$CLAUDE_CONFIG_DIR/settings.json"
fi

if [[ -z "$CLAUDE_CONFIG_DIR" ]]; then
    echo "❌ Could not find Claude Code configuration directory."
    echo ""
    echo "Please manually configure hooks in your Claude Code settings."
    exit 1
fi

echo "Found Claude Code config: $CLAUDE_CONFIG_FILE"
echo ""

# ============================================================================
# MAKE HOOKS EXECUTABLE
# ============================================================================

echo "Making hooks executable..."
chmod +x "$SCRIPT_DIR"/*.sh 2>/dev/null || true
chmod +x "$SCRIPT_DIR"/lib/*.sh 2>/dev/null || true
echo "✓ Hooks are executable"
echo ""

# ============================================================================
# INSTALL GIT HOOKS
# ============================================================================

if [[ -d "$PROJECT_ROOT/.git" ]]; then
    echo "Installing git hooks..."

    GIT_HOOKS_DIR="$PROJECT_ROOT/.git/hooks"
    mkdir -p "$GIT_HOOKS_DIR"

    # Pre-commit hook
    cat > "$GIT_HOOKS_DIR/pre-commit" << EOF
#!/bin/bash
exec "$SCRIPT_DIR/scope-check-hook.sh"
EOF
    chmod +x "$GIT_HOOKS_DIR/pre-commit"

    echo "✓ Git pre-commit hook installed"
else
    echo "⚠️  Not a git repository - skipping git hooks"
fi
echo ""

# ============================================================================
# GENERATE CLAUDE CODE CONFIG
# ============================================================================

echo "Generating Claude Code hook configuration..."
echo ""

HOOKS_CONFIG=$(cat << EOF
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": ".*",
        "hooks": ["$SCRIPT_DIR/pre-tool-use-hook.sh"]
      }
    ],
    "PostToolUse": [
      {
        "matcher": ".*",
        "hooks": ["$SCRIPT_DIR/post-tool-use-hook.sh"]
      }
    ],
    "Stop": [
      {
        "matcher": ".*",
        "hooks": ["$SCRIPT_DIR/stop-hook.sh"]
      }
    ],
    "PostMessage": [
      {
        "matcher": ".*",
        "hooks": ["$SCRIPT_DIR/persistence-hook.sh"]
      }
    ]
  }
}
EOF
)

echo "Add the following to your Claude Code settings ($CLAUDE_CONFIG_FILE):"
echo ""
echo "═══════════════════════════════════════════════════════════════"
echo "$HOOKS_CONFIG"
echo "═══════════════════════════════════════════════════════════════"
echo ""

# ============================================================================
# OFFER TO AUTO-INSTALL
# ============================================================================

read -p "Would you like to automatically add these hooks to your config? [y/N] " -n 1 -r
echo ""

if [[ $REPLY =~ ^[Yy]$ ]]; then
    if [[ -f "$CLAUDE_CONFIG_FILE" ]]; then
        # Backup existing config
        cp "$CLAUDE_CONFIG_FILE" "$CLAUDE_CONFIG_FILE.backup"
        echo "✓ Backed up existing config to $CLAUDE_CONFIG_FILE.backup"

        # Merge hooks into existing config
        if command -v jq &> /dev/null; then
            jq -s '.[0] * .[1]' "$CLAUDE_CONFIG_FILE" <(echo "$HOOKS_CONFIG") > "$CLAUDE_CONFIG_FILE.tmp"
            mv "$CLAUDE_CONFIG_FILE.tmp" "$CLAUDE_CONFIG_FILE"
            echo "✓ Hooks merged into config"
        else
            echo "❌ jq not installed. Please manually merge the configuration."
        fi
    else
        echo "$HOOKS_CONFIG" > "$CLAUDE_CONFIG_FILE"
        echo "✓ Config file created"
    fi
fi

echo ""
echo "═══════════════════════════════════════════════════════════════"
echo " Installation Complete"
echo "═══════════════════════════════════════════════════════════════"
echo ""
echo "Hooks installed:"
echo "  ✓ pre-tool-use-hook.sh  - Scope validation, dangerous command blocking"
echo "  ✓ post-tool-use-hook.sh - Failure tracking, escalation detection"
echo "  ✓ stop-hook.sh          - Exit control, checkpoint save"
echo "  ✓ persistence-hook.sh   - Abandonment prevention"
echo "  ✓ scope-check-hook.sh   - Git pre-commit scope validation"
echo ""
echo "Restart Claude Code for hooks to take effect."
echo ""
```

### Task 7.2: Create PowerShell Installer

**File: `hooks/install.ps1`**

PowerShell equivalent for Windows users.

---

## Task 8: Testing and Documentation

### Task 8.1: Create Hook Test Suite

**File: `hooks/tests/test-hooks.sh`**

```bash
#!/bin/bash
# Test suite for DevTeam hooks

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HOOKS_DIR="$(dirname "$SCRIPT_DIR")"
TESTS_PASSED=0
TESTS_FAILED=0

# Test helper
run_test() {
    local name="$1"
    local expected="$2"
    shift 2

    echo -n "Testing: $name... "

    local result
    result=$("$@" 2>&1) || true
    local exit_code=$?

    if [[ "$exit_code" -eq "$expected" ]]; then
        echo "✓ PASS"
        ((TESTS_PASSED++))
    else
        echo "✗ FAIL (expected $expected, got $exit_code)"
        echo "  Output: $result"
        ((TESTS_FAILED++))
    fi
}

# Test: Persistence hook detects "I give up"
export CLAUDE_OUTPUT="I give up on this task"
run_test "persistence detects give up" 2 "$HOOKS_DIR/persistence-hook.sh"

# Test: Persistence hook allows completion
export CLAUDE_OUTPUT="EXIT_SIGNAL: true"
run_test "persistence allows EXIT_SIGNAL" 0 "$HOOKS_DIR/persistence-hook.sh"

# Test: Stop hook blocks without signal
export CLAUDE_OUTPUT="Let me stop here"
run_test "stop blocks without signal" 2 "$HOOKS_DIR/stop-hook.sh"

# Summary
echo ""
echo "═══════════════════════════════════════════════════════════════"
echo " Test Results: $TESTS_PASSED passed, $TESTS_FAILED failed"
echo "═══════════════════════════════════════════════════════════════"

[[ $TESTS_FAILED -eq 0 ]]
```

### Task 8.2: Create Documentation

**File: `hooks/README.md`** (update)

Update the existing README with:
- Complete hook descriptions
- Installation instructions
- Configuration options
- Troubleshooting guide
- Integration with MCP server

---

## Summary: Task List

| Task | File(s) | Priority |
|------|---------|----------|
| 1.1 | `hooks/lib/hook-common.sh` | High |
| 1.2 | `hooks/lib/hook-common.ps1` | Medium |
| 2.1 | `hooks/pre-tool-use-hook.sh` | High |
| 2.2 | `hooks/pre-tool-use-hook.ps1` | Medium |
| 3.1 | `hooks/post-tool-use-hook.sh` | High |
| 3.2 | `hooks/post-tool-use-hook.ps1` | Medium |
| 4.1 | `hooks/persistence-hook.sh` (enhance) | High |
| 5.1 | `hooks/stop-hook.sh` (enhance) | High |
| 6.1 | `hooks/scope-check-hook.sh` | High |
| 7.1 | `hooks/install.sh` | High |
| 7.2 | `hooks/install.ps1` | Medium |
| 8.1 | `hooks/tests/test-hooks.sh` | Medium |
| 8.2 | `hooks/README.md` | Medium |

---

## Execution Order

1. **Task 1.1**: Create shared library (all hooks depend on this)
2. **Tasks 2.1, 3.1**: Create pre/post tool use hooks
3. **Tasks 4.1, 5.1, 6.1**: Enhance existing hooks
4. **Task 7.1**: Create installer
5. **Tasks 1.2, 2.2, 3.2, 7.2**: PowerShell versions
6. **Tasks 8.1, 8.2**: Testing and documentation

---

## Integration Notes

### Hooks + MCP Server

The hooks are designed to work alongside the MCP server:

1. **MCP Available**: Hooks notify MCP of events, MCP handles orchestration
2. **MCP Unavailable**: Hooks provide fallback enforcement using SQLite directly

### Environment Variables

Hooks expect these environment variables from Claude Code:
- `CLAUDE_TOOL_NAME`: Current tool being called
- `CLAUDE_TOOL_INPUT`: Tool input parameters
- `CLAUDE_TOOL_RESULT`: Tool execution result
- `CLAUDE_OUTPUT`: Claude's text output

### Exit Codes

- `0`: Allow (continue normally)
- `1`: Error (something went wrong)
- `2`: Block (prevent action, inject message)
