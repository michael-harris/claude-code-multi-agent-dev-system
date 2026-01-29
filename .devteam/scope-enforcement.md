# Scope Enforcement System

Ensures agents ONLY modify code directly required for their assigned task.

## Core Principle

**"Touch nothing you weren't asked to touch."**

Every agent must operate under strict scope constraints. Changes outside the defined scope are blocked, not just discouraged.

## Layer 1: Task Scope Definition

Every task MUST define explicit scope boundaries:

```yaml
# docs/planning/tasks/TASK-XXX.yaml
id: TASK-042
title: "Fix user authentication timeout"
description: "Users are logged out after 5 minutes instead of 30"

# EXPLICIT SCOPE DEFINITION (REQUIRED)
scope:
  # Files that CAN be modified
  allowed_files:
    - "src/auth/session.ts"
    - "src/auth/middleware.ts"
    - "src/config/auth.config.ts"

  # Patterns that CAN be modified (glob)
  allowed_patterns:
    - "src/auth/**/*.ts"
    - "tests/auth/**/*.test.ts"

  # Files that MUST NOT be touched (even if in allowed patterns)
  forbidden_files:
    - "src/auth/oauth.ts"  # Not related to session timeout
    - "src/auth/permissions.ts"

  # Directories completely off-limits
  forbidden_directories:
    - "src/api/"
    - "src/database/"
    - "src/ui/"

  # Maximum files that can be modified
  max_files_changed: 5

  # Reason for scope (helps agents understand boundaries)
  scope_rationale: |
    This task is specifically about session timeout configuration.
    Only session management and auth middleware should be touched.
    Do NOT refactor other auth code even if you notice issues.
```

## Layer 2: Agent Prompt Constraints

**Add to EVERY agent prompt:**

```markdown
## CRITICAL: Scope Constraints

You are authorized to modify ONLY these files:
${task.scope.allowed_files.join('\n')}

You are FORBIDDEN from modifying:
${task.scope.forbidden_files.join('\n')}
${task.scope.forbidden_directories.join('\n')}

### Strict Rules

1. **NEVER touch code outside your scope** - Even if you notice bugs, improvements, or "quick fixes" in other files, DO NOT modify them.

2. **NEVER refactor adjacent code** - Do not clean up, improve, or reorganize code near your changes unless it's required for your specific task.

3. **NEVER add features beyond scope** - If your task is "fix bug X", do not also "add feature Y" even if it seems helpful.

4. **NEVER update unrelated tests** - Only modify tests directly related to your changes.

5. **NEVER update unrelated documentation** - Only update docs for code you actually changed.

6. **If you notice issues outside scope:**
   - DO NOT fix them
   - Log them to: `.devteam/out-of-scope-observations.md`
   - Continue with your assigned task only

### Before ANY file modification, ask yourself:
1. Is this file in my allowed_files or allowed_patterns?
2. Is this change REQUIRED to complete my specific task?
3. Would my task fail without this change?

If ANY answer is "no", DO NOT make the change.
```

## Layer 3: Scope Validator Agent

A dedicated agent that validates all changes before they're accepted:

```markdown
# Scope Validator Agent

**Model:** haiku (fast, cheap validation)
**Purpose:** Enforce strict scope compliance

## Your Role

You validate that changes made by other agents stay within scope.
You have VETO POWER over any out-of-scope changes.

## Validation Process

1. Receive: task_id, files_changed, diff

2. Load task scope from: docs/planning/tasks/{task_id}.yaml

3. For EACH file in files_changed:

   a. Check if file is in allowed_files → PASS
   b. Check if file matches allowed_patterns → PASS
   c. Check if file is in forbidden_files → FAIL
   d. Check if file is in forbidden_directories → FAIL
   e. Otherwise → FAIL (not explicitly allowed)

4. For EACH change in diff:

   a. Is this change REQUIRED for the task?
   b. Or is this "nice to have" / cleanup / refactoring?
   c. If not required → FLAG for review

5. Check max_files_changed limit

## Output

```yaml
validation_result:
  status: PASS | FAIL | REVIEW_NEEDED

  files_validated:
    - file: "src/auth/session.ts"
      status: PASS
      reason: "In allowed_files"

    - file: "src/api/users.ts"
      status: FAIL
      reason: "In forbidden_directories (src/api/)"

  scope_violations:
    - file: "src/utils/helpers.ts"
      violation: "File not in scope"
      action: "REVERT changes to this file"

    - file: "src/auth/session.ts"
      line: 45-52
      violation: "Refactored unrelated function"
      action: "REVERT lines 45-52, keep only timeout fix"

  required_actions:
    - "Revert changes to src/utils/helpers.ts"
    - "Revert refactoring in src/auth/session.ts:45-52"
```

## Enforcement

- If status = FAIL: Changes are BLOCKED
- Agent must revert out-of-scope changes
- Only in-scope changes can proceed
```

## Layer 4: Pre-Commit Hook

Automated enforcement at commit time:

```bash
#!/bin/bash
# hooks/scope-check.sh

set -e

TASK_ID=$(cat .devteam/current-task.txt 2>/dev/null || echo "")

if [ -z "$TASK_ID" ]; then
    echo "Warning: No task context. Allowing commit."
    exit 0
fi

TASK_FILE="docs/planning/tasks/${TASK_ID}.yaml"

if [ ! -f "$TASK_FILE" ]; then
    echo "Warning: Task file not found. Allowing commit."
    exit 0
fi

# Get changed files
CHANGED_FILES=$(git diff --cached --name-only)

# Extract allowed patterns from task file
ALLOWED_FILES=$(grep -A 100 "allowed_files:" "$TASK_FILE" | grep "^    - " | sed 's/^    - "//' | sed 's/"$//' | head -20)
ALLOWED_PATTERNS=$(grep -A 100 "allowed_patterns:" "$TASK_FILE" | grep "^    - " | sed 's/^    - "//' | sed 's/"$//' | head -20)
FORBIDDEN_FILES=$(grep -A 100 "forbidden_files:" "$TASK_FILE" | grep "^    - " | sed 's/^    - "//' | sed 's/"$//' | head -20)
FORBIDDEN_DIRS=$(grep -A 100 "forbidden_directories:" "$TASK_FILE" | grep "^    - " | sed 's/^    - "//' | sed 's/"$//' | head -20)

VIOLATIONS=""

for FILE in $CHANGED_FILES; do
    ALLOWED=false

    # Check forbidden first
    for FORBIDDEN in $FORBIDDEN_FILES; do
        if [ "$FILE" = "$FORBIDDEN" ]; then
            VIOLATIONS="$VIOLATIONS\n  FORBIDDEN: $FILE (in forbidden_files)"
            continue 2
        fi
    done

    for FORBIDDEN_DIR in $FORBIDDEN_DIRS; do
        if [[ "$FILE" == "$FORBIDDEN_DIR"* ]]; then
            VIOLATIONS="$VIOLATIONS\n  FORBIDDEN: $FILE (in forbidden_directories: $FORBIDDEN_DIR)"
            continue 2
        fi
    done

    # Check allowed
    for ALLOWED_FILE in $ALLOWED_FILES; do
        if [ "$FILE" = "$ALLOWED_FILE" ]; then
            ALLOWED=true
            break
        fi
    done

    if [ "$ALLOWED" = false ]; then
        for PATTERN in $ALLOWED_PATTERNS; do
            if [[ "$FILE" == $PATTERN ]]; then
                ALLOWED=true
                break
            fi
        done
    fi

    if [ "$ALLOWED" = false ]; then
        VIOLATIONS="$VIOLATIONS\n  OUT OF SCOPE: $FILE"
    fi
done

if [ -n "$VIOLATIONS" ]; then
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║              SCOPE VIOLATION - COMMIT BLOCKED                ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo ""
    echo "Task: $TASK_ID"
    echo ""
    echo "The following files are outside the task scope:"
    echo -e "$VIOLATIONS"
    echo ""
    echo "Options:"
    echo "  1. Revert out-of-scope changes: git checkout -- <file>"
    echo "  2. Update task scope if changes are truly required"
    echo "  3. Create separate task for out-of-scope work"
    echo ""
    exit 1
fi

echo "✓ Scope check passed. All changes within task boundaries."
exit 0
```

## Layer 5: Runtime File Access Control

Track and limit file access during task execution:

```yaml
# .devteam/state.yaml additions
current_task:
  id: TASK-042
  scope:
    allowed_files: [...]
    forbidden_files: [...]

file_access_log:
  - timestamp: "2025-01-28T10:15:00Z"
    file: "src/auth/session.ts"
    action: read
    allowed: true

  - timestamp: "2025-01-28T10:16:00Z"
    file: "src/api/users.ts"
    action: read
    allowed: true  # Reading is OK

  - timestamp: "2025-01-28T10:17:00Z"
    file: "src/api/users.ts"
    action: write
    allowed: false  # BLOCKED - not in scope
    blocked_reason: "File in forbidden_directories"

scope_violations:
  - timestamp: "2025-01-28T10:17:00Z"
    file: "src/api/users.ts"
    attempted_action: write
    agent: "backend-developer"
    blocked: true
```

## Layer 6: Out-of-Scope Observations Log

Instead of fixing issues they notice, agents log them:

```markdown
# .devteam/out-of-scope-observations.md

## Observations During TASK-042 (Session Timeout Fix)

### Observed by: backend-developer
### Date: 2025-01-28

#### 1. Potential Bug in OAuth Handler
- **File:** src/auth/oauth.ts:145
- **Issue:** Token refresh doesn't handle network errors
- **Severity:** Medium
- **Action:** Did NOT fix (out of scope). Recommend creating separate task.

#### 2. Code Smell in User API
- **File:** src/api/users.ts:67
- **Issue:** N+1 query pattern
- **Severity:** Low (performance)
- **Action:** Did NOT fix (out of scope). Logged for future optimization.

#### 3. Missing Type Annotation
- **File:** src/auth/middleware.ts:23
- **Issue:** Parameter 'req' implicitly has 'any' type
- **Severity:** Low
- **Action:** Did NOT fix (not required for task). Would require touching unrelated code.

---
*These observations should be triaged and converted to tasks if needed.*
```

## Implementation Checklist

### 1. Update Task Schema
Add required `scope` field to all task definitions.

### 2. Update All Agent Prompts
Add scope constraint section to every agent.

### 3. Create Scope Validator Agent
`agents/orchestration/scope-validator.md`

### 4. Add Pre-Commit Hook
`hooks/scope-check.sh`

### 5. Update Task Orchestrator
- Load scope before task execution
- Pass scope to all agents
- Run scope validator after each change
- Block out-of-scope changes

### 6. Create Observations Log Template
`.devteam/out-of-scope-observations.md`

## Summary

| Layer | Purpose | Enforcement |
|-------|---------|-------------|
| Task Scope Definition | Define boundaries | Required field |
| Agent Prompt Constraints | Instruct agents | In every prompt |
| Scope Validator Agent | Verify compliance | After each change |
| Pre-Commit Hook | Block violations | At commit time |
| Runtime Access Control | Track access | During execution |
| Observations Log | Capture side-findings | Instead of fixing |

**Result:** Agents can ONLY modify files explicitly allowed for their task. All other changes are blocked, not just discouraged.
