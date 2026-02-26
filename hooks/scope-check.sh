#!/bin/bash
# DevTeam Scope Check Hook
# Validates git commits against task scope
# Also used as git pre-commit hook
#
# Exit codes:
#   0 = Commit allowed (within scope)
#   1 = Commit blocked (scope violation)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source common library (handle both direct call and git hook call)
if [[ -f "$SCRIPT_DIR/lib/hook-common.sh" ]]; then
    source "$SCRIPT_DIR/lib/hook-common.sh"
elif [[ -f "$SCRIPT_DIR/../lib/hook-common.sh" ]]; then
    source "$SCRIPT_DIR/../lib/hook-common.sh"
else
    # Minimal fallback if library not found
    echo "[scope-check] Warning: hook-common.sh not found"
    DEVTEAM_DIR=".devteam"
fi

init_hook "scope-check" 2>/dev/null || true

# ============================================================================
# CONFIGURATION
# ============================================================================

CURRENT_TASK_FILE="${DEVTEAM_DIR}/current-task.txt"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# ============================================================================
# SENSITIVE FILE PATTERNS
# ============================================================================

SENSITIVE_PATTERNS=(
    ".env"
    ".env.*"
    "*.env"
    "*credentials*"
    "*secret*"
    "*password*"
    "*.pem"
    "*.key"
    "*.p12"
    "*.pfx"
    "*token*"
    ".aws/*"
    ".ssh/*"
    "*_rsa"
    "*_dsa"
    "*_ecdsa"
    "*_ed25519"
    "id_rsa*"
    "*.keystore"
    "*.jks"
)

# ============================================================================
# GET TASK SCOPE
# ============================================================================

get_task_scope() {
    local task_id="$1"

    # Try database first
    if db_exists 2>/dev/null; then
        local safe_task_id="${task_id//\'/\'\'}"
        local scope
        scope=$(db_query "SELECT scope_files FROM tasks WHERE id = '$safe_task_id';" 2>/dev/null || true)
        if [[ -n "$scope" ]]; then
            echo "$scope" | tr ',' '\n'
            return
        fi
    fi

    # Try task file (JSON format)
    local task_file=""
    for dir in "docs/planning/tasks" "docs/tasks" ".devteam/tasks"; do
        if [[ -f "${DEVTEAM_ROOT:-$(pwd)}/${dir}/${task_id}.json" ]]; then
            task_file="${DEVTEAM_ROOT:-$(pwd)}/${dir}/${task_id}.json"
            break
        fi
    done

    if [[ -z "$task_file" ]] || [[ ! -f "$task_file" ]]; then
        return
    fi

    # Parse JSON for scope using jq
    if command -v jq &>/dev/null && [ -f "$task_file" ]; then
        jq -r '.scope.allowed_files[]? // empty' "$task_file" | sed 's/^/+/'
        jq -r '.scope.allowed_patterns[]? // empty' "$task_file" | sed 's/^/+/'
        jq -r '.scope.forbidden_files[]? // empty' "$task_file" | sed 's/^/-/'
        jq -r '.scope.forbidden_directories[]? // empty' "$task_file" | sed 's/^/!/'
    fi
}

# ============================================================================
# SCOPE VALIDATION
# ============================================================================

validate_file_against_scope() {
    local file="$1"
    local scope="$2"

    local allowed_found=false
    local forbidden_match=""

    while IFS= read -r line; do
        [[ -z "$line" ]] && continue

        local prefix="${line:0:1}"
        local pattern="${line:1}"

        case "$prefix" in
            "+")
                # Allowed pattern
                if [[ "$file" == $pattern ]]; then
                    allowed_found=true
                fi
                ;;
            "-")
                # Forbidden file
                if [[ "$file" == "$pattern" ]]; then
                    forbidden_match="Explicitly forbidden file"
                fi
                ;;
            "!")
                # Forbidden directory
                pattern="${pattern%/}"
                if [[ "$file" == "$pattern"/* ]]; then
                    forbidden_match="In forbidden directory: ${pattern}/"
                fi
                ;;
        esac
    done <<< "$scope"

    # Forbidden takes precedence
    if [[ -n "$forbidden_match" ]]; then
        echo "$forbidden_match"
        return 1
    fi

    # Check if any allowed patterns exist
    if echo "$scope" | grep -q "^+"; then
        if [[ "$allowed_found" == true ]]; then
            return 0
        else
            echo "Not in allowed_files or allowed_patterns"
            return 1
        fi
    fi

    # No allowed patterns defined = everything allowed
    return 0
}

# ============================================================================
# SENSITIVE FILE CHECK
# ============================================================================

check_sensitive_files() {
    local staged_files="$1"
    local warnings=()

    while IFS= read -r file; do
        [[ -z "$file" ]] && continue

        for pattern in "${SENSITIVE_PATTERNS[@]}"; do
            if [[ "$file" == $pattern ]] || [[ "$(basename "$file")" == $pattern ]]; then
                warnings+=("$file")
                break
            fi
        done
    done <<< "$staged_files"

    if [[ ${#warnings[@]} -gt 0 ]]; then
        log_warn "scope-check" "Sensitive files in commit: ${warnings[*]}" 2>/dev/null || true

        echo ""
        echo -e "${YELLOW}WARNING: Potentially sensitive files detected:${NC}"
        echo ""
        for file in "${warnings[@]}"; do
            echo -e "  ${YELLOW}!${NC} $file"
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
    # Get current task ID
    local task_id=""
    if [[ -f "$CURRENT_TASK_FILE" ]]; then
        task_id=$(cat "$CURRENT_TASK_FILE" 2>/dev/null || true)
    fi

    # If no task context, allow with warning
    if [[ -z "$task_id" ]]; then
        echo -e "${YELLOW}! No task context found. Scope check skipped.${NC}"
        echo "  To enable scope checking, set current task in $CURRENT_TASK_FILE"
        exit 0
    fi

    log_debug "scope-check" "Checking scope for task: $task_id" 2>/dev/null || true

    # Get scope for task
    local scope
    scope=$(get_task_scope "$task_id")

    if [[ -z "$scope" ]]; then
        echo -e "${YELLOW}! No scope defined for task $task_id. Scope check skipped.${NC}"
        exit 0
    fi

    echo "Checking scope for task: $task_id"
    echo ""

    # Get staged files
    local staged_files
    staged_files=$(git diff --cached --name-only --diff-filter=ACMR 2>/dev/null || true)

    if [[ -z "$staged_files" ]]; then
        echo -e "${GREEN}No files staged for commit.${NC}"
        exit 0
    fi

    # Check for sensitive files (warning only)
    check_sensitive_files "$staged_files"

    # Track violations
    local violations=()
    local violation_count=0
    local file_count=0

    # Validate each file
    while IFS= read -r file; do
        [[ -z "$file" ]] && continue
        file=$(echo "$file" | tr '\\' '/')
        file_count=$((file_count + 1))

        local reason
        if reason=$(validate_file_against_scope "$file" "$scope"); then
            echo -e "  ${GREEN}ok${NC} $file"
        else
            violations+=("$file|$reason")
            violation_count=$((violation_count + 1))
            echo -e "  ${RED}X${NC} $file"
            echo -e "      Reason: $reason"
        fi
    done <<< "$staged_files"

    echo ""

    # Report results
    if [[ $violation_count -gt 0 ]]; then
        log_error "scope-check" "$violation_count scope violations" 2>/dev/null || true
        log_event_to_db "scope_violation" "error" "Commit blocked: $violation_count out-of-scope files" 2>/dev/null || true

        echo -e "${RED}========================================${NC}"
        echo -e "${RED}  SCOPE VIOLATION - COMMIT BLOCKED${NC}"
        echo -e "${RED}========================================${NC}"
        echo ""
        echo "Task: $task_id"
        echo "Violations: $violation_count"
        echo ""
        echo "Out-of-scope changes:"
        for v in "${violations[@]}"; do
            local vfile="${v%%|*}"
            local vreason="${v#*|}"
            echo -e "  ${RED}X${NC} $vfile"
            echo "      $vreason"
        done
        echo ""
        echo "To fix:"
        echo "  1. Revert out-of-scope files:"
        for v in "${violations[@]}"; do
            local vfile="${v%%|*}"
            echo "     git checkout -- $vfile"
        done
        echo ""
        echo "  2. Or update task scope if changes are truly required"
        echo "  3. Or create a separate task for out-of-scope work"
        echo ""

        # Notify MCP (JSON-escape the task_id)
        local safe_json_task="${task_id//\\/\\\\}"
        safe_json_task="${safe_json_task//\"/\\\"}"
        mcp_notify "scope_violation" "{\"task\": \"$safe_json_task\", \"violations\": $violation_count}" 2>/dev/null || true

        exit 1
    else
        log_info "scope-check" "Commit scope validated: $file_count files" 2>/dev/null || true

        echo -e "${GREEN}========================================${NC}"
        echo -e "${GREEN}  SCOPE CHECK PASSED${NC}"
        echo -e "${GREEN}========================================${NC}"
        echo ""
        echo "All $file_count files are within task scope."

        # Notify MCP (JSON-escape the task_id)
        local safe_json_task="${task_id//\\/\\\\}"
        safe_json_task="${safe_json_task//\"/\\\"}"
        mcp_notify "commit_validated" "{\"task\": \"$safe_json_task\", \"files\": $file_count}" 2>/dev/null || true

        exit 0
    fi
}

main "$@"
