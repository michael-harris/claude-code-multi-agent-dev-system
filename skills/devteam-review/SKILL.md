---
name: devteam-review
description: Run a coordinated code review across multiple reviewers. Launches the Code Review Coordinator to orchestrate language-specific and domain-specific reviewers.
argument-hint: [target] [--scope <path>] [--focus <security|performance|architecture>] [--pr <number>] [--eco]
user-invocable: true
allowed-tools: Read, Glob, Grep, Bash, Task
model: opus
---

Current session: !`source "${CLAUDE_PLUGIN_ROOT}/scripts/state.sh" && get_current_session 2>/dev/null || echo "No active session"`
Active sprint: !`source "${CLAUDE_PLUGIN_ROOT}/scripts/state.sh" && get_kv_state "active_sprint" 2>/dev/null || echo "None"`
Failure count: !`source "${CLAUDE_PLUGIN_ROOT}/scripts/state.sh" && get_kv_state "consecutive_failures" 2>/dev/null || echo "0"`

# DevTeam Review Command

**Command:** `/devteam:review [target] [options]`

Run a coordinated code review across multiple reviewers. Launches the Code Review Coordinator to orchestrate language-specific and domain-specific reviewers.

## Usage

```bash
# Review current changes (staged + unstaged)
/devteam:review

# Review specific files
/devteam:review "src/api/auth.ts" "src/models/user.ts"

# Review specific scope
/devteam:review --scope "src/api/"

# Review with specific focus
/devteam:review --focus security
/devteam:review --focus performance
/devteam:review --focus architecture

# Review a PR
/devteam:review --pr 42
```

## Options

| Option | Description |
|--------|-------------|
| `--scope <path>` | Limit review to specific files/directories |
| `--focus <area>` | Focus on: security, performance, architecture, correctness, all |
| `--pr <number>` | Review a specific pull request |
| `--severity <level>` | Minimum severity to report: critical, warning, info |
| `--eco` | Cost-optimized execution |

## Your Process

### Phase 0: Initialize Session

```bash
source "${CLAUDE_PLUGIN_ROOT}/scripts/state.sh"
source "${CLAUDE_PLUGIN_ROOT}/scripts/events.sh"

SESSION_ID=$(start_session "/devteam:review $*" "review")
log_session_started "/devteam:review $*" "review"
```

### Phase 1: Launch Code Review Coordinator

Delegate to the `orchestration:code-review-coordinator` agent, which will:

1. Detect languages and frameworks in the target files
2. Select appropriate language-specific code reviewers
3. Run database reviewers if schema changes are detected
4. Aggregate findings across all reviewers
5. Produce a unified review report with severity ratings

```javascript
const result = await Task({
    subagent_type: "orchestration:code-review-coordinator",
    prompt: `Code review request:

        Target: ${target || 'current changes'}
        Scope: ${scope || 'auto-detect'}
        Focus: ${focus || 'all'}

        Coordinate reviewers to check:
        1. Code correctness and logic errors
        2. Security vulnerabilities
        3. Performance issues
        4. Code style and best practices
        5. Test coverage gaps
        6. Documentation needs`
})
```

### Phase 2: Report

Output a review report showing:
- Summary of findings by severity
- File-by-file review comments
- Recommended changes
- Overall code quality assessment

## See Also

- `/devteam:implement` - Implement review feedback
- `/devteam:bug` - Fix bugs found during review
- `/devteam:test` - Run tests to verify fixes
