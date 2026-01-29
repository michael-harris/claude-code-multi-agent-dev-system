#!/bin/bash
# Scope Enforcement Pre-Commit Hook
# Blocks commits that modify files outside the current task's scope

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Get current task ID
TASK_ID=""
if [ -f ".devteam/current-task.txt" ]; then
    TASK_ID=$(cat .devteam/current-task.txt)
fi

# If no task context, allow commit with warning
if [ -z "$TASK_ID" ]; then
    echo -e "${YELLOW}⚠ No task context found. Scope check skipped.${NC}"
    echo "  To enable scope checking, set current task in .devteam/current-task.txt"
    exit 0
fi

# Find task file
TASK_FILE=""
for dir in "docs/planning/tasks" "docs/tasks" ".devteam/tasks"; do
    if [ -f "${dir}/${TASK_ID}.yaml" ]; then
        TASK_FILE="${dir}/${TASK_ID}.yaml"
        break
    fi
done

if [ -z "$TASK_FILE" ] || [ ! -f "$TASK_FILE" ]; then
    echo -e "${YELLOW}⚠ Task file not found for ${TASK_ID}. Scope check skipped.${NC}"
    exit 0
fi

# Check if scope is defined in task
if ! grep -q "^scope:" "$TASK_FILE"; then
    echo -e "${YELLOW}⚠ No scope defined in task ${TASK_ID}. Scope check skipped.${NC}"
    echo "  Add 'scope:' section to task file to enable enforcement."
    exit 0
fi

echo "Checking scope for task: ${TASK_ID}"
echo "Task file: ${TASK_FILE}"
echo ""

# Get changed files (staged for commit)
CHANGED_FILES=$(git diff --cached --name-only)

if [ -z "$CHANGED_FILES" ]; then
    echo -e "${GREEN}✓ No files staged for commit.${NC}"
    exit 0
fi

# Parse scope from task file (simplified YAML parsing)
parse_yaml_list() {
    local key=$1
    local file=$2
    # Extract list items under the key
    awk -v key="$key:" '
        $0 ~ key { found=1; next }
        found && /^[^ ]/ { found=0 }
        found && /^    - / { gsub(/^    - "?|"?$/, ""); print }
    ' "$file"
}

# Get scope lists
ALLOWED_FILES=$(parse_yaml_list "allowed_files" "$TASK_FILE")
ALLOWED_PATTERNS=$(parse_yaml_list "allowed_patterns" "$TASK_FILE")
FORBIDDEN_FILES=$(parse_yaml_list "forbidden_files" "$TASK_FILE")
FORBIDDEN_DIRS=$(parse_yaml_list "forbidden_directories" "$TASK_FILE")

# Get max files limit
MAX_FILES=$(grep "max_files_changed:" "$TASK_FILE" | awk '{print $2}' | tr -d '"')
if [ -z "$MAX_FILES" ]; then
    MAX_FILES=999  # No limit if not specified
fi

# Track violations
VIOLATIONS=""
VIOLATION_COUNT=0
FILE_COUNT=0

# Check each changed file
for FILE in $CHANGED_FILES; do
    FILE_COUNT=$((FILE_COUNT + 1))
    ALLOWED=false
    VIOLATION_REASON=""

    # Check forbidden files first (highest priority)
    for FORBIDDEN in $FORBIDDEN_FILES; do
        if [ "$FILE" = "$FORBIDDEN" ]; then
            VIOLATION_REASON="Explicitly forbidden file"
            break
        fi
    done

    # Check forbidden directories
    if [ -z "$VIOLATION_REASON" ]; then
        for FORBIDDEN_DIR in $FORBIDDEN_DIRS; do
            # Remove trailing slash for consistent matching
            FORBIDDEN_DIR="${FORBIDDEN_DIR%/}"
            if [[ "$FILE" == "$FORBIDDEN_DIR"/* ]]; then
                VIOLATION_REASON="In forbidden directory: ${FORBIDDEN_DIR}/"
                break
            fi
        done
    fi

    # If not forbidden, check if allowed
    if [ -z "$VIOLATION_REASON" ]; then
        # Check exact file matches
        for ALLOWED_FILE in $ALLOWED_FILES; do
            if [ "$FILE" = "$ALLOWED_FILE" ]; then
                ALLOWED=true
                break
            fi
        done

        # Check pattern matches (simplified glob matching)
        if [ "$ALLOWED" = false ]; then
            for PATTERN in $ALLOWED_PATTERNS; do
                # Convert glob pattern to regex for matching
                REGEX=$(echo "$PATTERN" | sed 's/\*\*/.*/' | sed 's/\*/.*/g')
                if [[ "$FILE" =~ ^${REGEX}$ ]]; then
                    ALLOWED=true
                    break
                fi
            done
        fi

        if [ "$ALLOWED" = false ]; then
            VIOLATION_REASON="Not in allowed_files or allowed_patterns"
        fi
    fi

    # Record violation
    if [ -n "$VIOLATION_REASON" ]; then
        VIOLATIONS="${VIOLATIONS}  ${RED}✗${NC} ${FILE}\n    Reason: ${VIOLATION_REASON}\n"
        VIOLATION_COUNT=$((VIOLATION_COUNT + 1))
    else
        echo -e "  ${GREEN}✓${NC} ${FILE}"
    fi
done

# Check file count limit
if [ "$FILE_COUNT" -gt "$MAX_FILES" ]; then
    VIOLATIONS="${VIOLATIONS}  ${RED}✗${NC} Too many files changed: ${FILE_COUNT} > ${MAX_FILES}\n"
    VIOLATION_COUNT=$((VIOLATION_COUNT + 1))
fi

# Report results
echo ""

if [ "$VIOLATION_COUNT" -gt 0 ]; then
    echo -e "${RED}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${RED}║              SCOPE VIOLATION - COMMIT BLOCKED                ║${NC}"
    echo -e "${RED}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo "Task: ${TASK_ID}"
    echo "Violations: ${VIOLATION_COUNT}"
    echo ""
    echo "Out-of-scope changes:"
    echo -e "$VIOLATIONS"
    echo ""
    echo "To fix:"
    echo "  1. Revert out-of-scope files:"
    for FILE in $CHANGED_FILES; do
        # Check if this file had a violation (simplified check)
        ALLOWED=false
        for ALLOWED_FILE in $ALLOWED_FILES; do
            if [ "$FILE" = "$ALLOWED_FILE" ]; then
                ALLOWED=true
                break
            fi
        done
        for PATTERN in $ALLOWED_PATTERNS; do
            REGEX=$(echo "$PATTERN" | sed 's/\*\*/.*/' | sed 's/\*/.*/g')
            if [[ "$FILE" =~ ^${REGEX}$ ]]; then
                ALLOWED=true
                break
            fi
        done
        if [ "$ALLOWED" = false ]; then
            echo "     git checkout -- ${FILE}"
        fi
    done
    echo ""
    echo "  2. Or update task scope if changes are truly required"
    echo "  3. Or create a separate task for out-of-scope work"
    echo ""
    echo "If you noticed issues outside your task scope, log them to:"
    echo "  .devteam/out-of-scope-observations.md"
    echo ""
    exit 1
else
    echo -e "${GREEN}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║              SCOPE CHECK PASSED                              ║${NC}"
    echo -e "${GREEN}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo "All ${FILE_COUNT} files are within task scope."
    exit 0
fi
