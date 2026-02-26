#!/bin/bash
# DevTeam Pre-Tool-Use Hook
# Runs BEFORE each tool call to validate and inject context
#
# Exit codes:
#   0 = Allow tool call
#   2 = Block tool call with message
#
# Environment variables expected:
#   CLAUDE_TOOL_NAME - Name of the tool being called
#   CLAUDE_TOOL_INPUT - JSON input for the tool

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source common library with fallback paths (H6)
if [[ -f "$SCRIPT_DIR/lib/hook-common.sh" ]]; then
    source "$SCRIPT_DIR/lib/hook-common.sh"
elif [[ -f "$SCRIPT_DIR/../lib/hook-common.sh" ]]; then
    source "$SCRIPT_DIR/../lib/hook-common.sh"
else
    echo "[pre-tool-use] Warning: hook-common.sh not found" >&2
    exit 0
fi

init_hook "pre-tool-use"

# ============================================================================
# CONFIGURATION
# ============================================================================

TOOL_NAME="${CLAUDE_TOOL_NAME:-}"
TOOL_INPUT="${CLAUDE_TOOL_INPUT:-}"

if [[ -z "$TOOL_NAME" ]] && [[ -z "$TOOL_INPUT" ]]; then
    log_warn "pre-tool-use" "No CLAUDE_TOOL_NAME or CLAUDE_TOOL_INPUT set"
    exit 0  # Nothing to validate (H7)
fi

# ============================================================================
# DANGEROUS COMMAND PATTERNS
# ============================================================================

# Commands that should ALWAYS be blocked
DANGEROUS_PATTERNS=(
    # Destructive file operations
    "rm -rf /"
    "rm -rf /*"
    "rm -rf ~"
    "rm -rf \$HOME"
    "rm -rf \\\$HOME"

    # Disk/system destruction
    "dd if=/dev/zero"
    "dd if=/dev/random"
    "mkfs\."
    "fdisk"
    "parted"
    "> /dev/sd"
    "> /dev/nvme"

    # Fork bombs and system abuse
    ":\(\)\{ :\|:& \};"
    ":(){ :|:& };"

    # Dangerous permissions
    "chmod -R 777 /"
    "chmod -R 777 /\*"
    "chown -R.*/"

    # Git force push to main/master
    "git push.*--force.*main"
    "git push.*--force.*master"
    "git push.*-f.*main"
    "git push.*-f.*master"

    # Database destruction
    "DROP DATABASE"
    "DROP TABLE"
    "TRUNCATE TABLE"
    "DELETE FROM.*WHERE 1"

    # Credential/key exposure
    "cat.*\.ssh/id_"
    "cat.*/etc/shadow"
    "cat.*/etc/passwd"

    # Crypto mining/malware indicators
    "curl.*\|.*bash"
    "wget.*\|.*bash"
    "curl.*\|.*sh"
    "wget.*\|.*sh"

    # Arbitrary code execution
    "eval\s+"

    # Privilege escalation
    "sudo\s+"

    # Overly permissive permissions
    "chmod\s+777"

    # Variant of rm -rf /
    "rm\s+-rf\s+/\*"
)

# ============================================================================
# SCOPE VALIDATION FOR FILE OPERATIONS
# ============================================================================

validate_file_operation() {
    local tool="$1"
    local input="$2"

    # Extract file path from tool input based on tool type
    local file_path=""

    case "$tool" in
        Write|Edit|NotebookEdit)
            # Extract file_path from JSON input
            file_path=$(echo "$input" | sed -n 's/.*"file_path"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' 2>/dev/null || true)
            ;;
        Bash)
            # Check for file-modifying commands and extract target
            if echo "$input" | grep -qE '(cat\s*>|echo\s*>|printf\s*>|tee\s)'; then
                # Redirect operations
                file_path=$(echo "$input" | sed -n 's/.*>[[:space:]]*\([^[:space:];&|]*\).*/\1/p' 2>/dev/null | head -1 || true)
            elif echo "$input" | grep -qE '(sed\s+-i|mv\s|cp\s)'; then
                # In-place edit or move/copy
                file_path=$(echo "$input" | awk '{print $NF}' 2>/dev/null || true)
            fi
            ;;
        *)
            # Non-file operations are allowed
            return 0
            ;;
    esac

    # If we extracted a file path, validate it
    if [[ -n "$file_path" ]]; then
        # Remove quotes if present
        file_path="${file_path%\"}"
        file_path="${file_path#\"}"

        if ! file_in_scope "$file_path"; then
            log_warn "pre-tool-use" "Scope violation attempted: $file_path"
            log_event_to_db "scope_violation" "warning" "Attempted to modify out-of-scope file: $file_path"

            local scope_list
            scope_list=$(get_scope_files | head -10)

            inject_system_message "scope-warning" "
SCOPE VIOLATION BLOCKED

You attempted to modify: $file_path

This file is outside your allowed scope for this task.

Allowed scope:
$scope_list

Please only modify files within the allowed scope. If you need to modify
files outside the scope, request scope expansion through devteam_request_scope
or create a separate task for the out-of-scope work.
"
            exit 2
        fi
    fi

    return 0
}

# ============================================================================
# DANGEROUS COMMAND DETECTION
# ============================================================================

check_dangerous_commands() {
    local tool="$1"
    local input="$2"

    # Only check Bash commands
    if [[ "$tool" != "Bash" ]]; then
        return 0
    fi

    # Extract command from JSON input
    local command=""
    if command -v jq &>/dev/null; then
        command=$(echo "$input" | jq -r '.command // empty' 2>/dev/null)
    fi
    if [[ -z "$command" ]]; then
        command=$(echo "$input" | grep -o '"command"[[:space:]]*:[[:space:]]*"[^"]*"' | head -1 | sed 's/.*"command"[[:space:]]*:[[:space:]]*"//;s/"$//')
    fi

    for pattern in "${DANGEROUS_PATTERNS[@]}"; do
        if echo "$command" | grep -qiE "$pattern"; then
            log_error "pre-tool-use" "Dangerous command blocked: $pattern"
            log_event_to_db "dangerous_command" "error" "Blocked dangerous command matching: $pattern"

            inject_system_message "danger-blocked" "
DANGEROUS COMMAND BLOCKED

The command you attempted contains a potentially destructive pattern:
  Pattern: $pattern

This command has been blocked for safety.

If this is intentional and authorized:
1. Ask the user for explicit confirmation
2. Explain why this destructive operation is necessary
3. The user can override with explicit approval

Safety first - destructive operations require human confirmation.
"
            exit 2
        fi
    done

    return 0
}

# ============================================================================
# ITERATION WARNING INJECTION
# ============================================================================

inject_iteration_context() {
    local iteration
    iteration=$(get_current_iteration)
    if ! [[ "$iteration" =~ ^[0-9]+$ ]]; then
        iteration=0
    fi

    local max_iterations="$MAX_ITERATIONS"
    if ! [[ "$max_iterations" =~ ^[0-9]+$ ]]; then
        max_iterations=100
    fi
    local remaining=$((max_iterations - iteration))

    # Warn when getting close to max iterations
    if [[ "$remaining" -le 5 ]] && [[ "$remaining" -gt 0 ]]; then
        inject_system_message "iteration-warning" "
ITERATION WARNING

You have $remaining iterations remaining before max iterations reached.
Current iteration: $iteration/$max_iterations

Focus on:
1. Fixing the most critical issues first
2. Running quality gates to verify progress
3. Saving checkpoints if needed

If you cannot complete within remaining iterations, prioritize a stable state.
"
    elif [[ "$remaining" -le 0 ]]; then
        inject_system_message "iteration-limit" "
ITERATION LIMIT REACHED

You have reached the maximum iteration count ($max_iterations).
The session will end after this iteration.

Ensure you:
1. Save any important progress
2. Document current state
3. Report what was completed vs remaining

Use EXIT_SIGNAL: true to cleanly end the session.
"
    fi
}

# ============================================================================
# CIRCUIT BREAKER CHECK
# ============================================================================

check_circuit_breaker() {
    local failures
    failures=$(get_consecutive_failures)
    if ! [[ "$failures" =~ ^[0-9]+$ ]]; then
        failures=0
    fi

    local max_fail="$MAX_FAILURES"
    if ! [[ "$max_fail" =~ ^[0-9]+$ ]]; then
        max_fail=5
    fi
    local warning_threshold=$((max_fail - 2))

    if [[ "$failures" -ge "$warning_threshold" ]] && [[ "$failures" -lt "$max_fail" ]]; then
        inject_system_message "failure-warning" "
FAILURE WARNING

Consecutive failures: $failures / $max_fail

The circuit breaker will trip after $max_fail consecutive failures,
requiring human intervention.

Consider:
1. Trying a different approach
2. Breaking the problem into smaller steps
3. Escalating to a more capable model
4. Asking for help with specific blockers
"
    fi
}

# ============================================================================
# TOOL-SPECIFIC VALIDATION
# ============================================================================

validate_tool_specific() {
    local tool="$1"
    local input="$2"

    case "$tool" in
        Task)
            # Validate Task tool usage
            local prompt
            prompt=$(echo "$input" | sed -n 's/.*"prompt"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' 2>/dev/null || true)
            if [[ -z "$prompt" ]] || [[ ${#prompt} -lt 10 ]]; then
                log_warn "pre-tool-use" "Task tool called with insufficient prompt"
            fi
            ;;
        WebFetch|WebSearch)
            # Log external network access
            log_info "pre-tool-use" "External network access: $tool"
            ;;
    esac

    return 0
}

# ============================================================================
# MAIN EXECUTION
# ============================================================================

main() {
    # Skip if no tool name provided
    if [[ -z "$TOOL_NAME" ]]; then
        exit 0
    fi

    log_debug "pre-tool-use" "Validating tool: $TOOL_NAME"

    # Check for dangerous commands first (highest priority)
    check_dangerous_commands "$TOOL_NAME" "$TOOL_INPUT"

    # Validate scope for file operations
    validate_file_operation "$TOOL_NAME" "$TOOL_INPUT"

    # Tool-specific validation
    validate_tool_specific "$TOOL_NAME" "$TOOL_INPUT"

    # Check circuit breaker status
    check_circuit_breaker

    # Inject iteration context if needed
    inject_iteration_context

    # Notify MCP server (non-blocking)
    mcp_notify "pre_tool_use" "$(get_claude_context)"

    # All checks passed
    exit 0
}

main "$@"
