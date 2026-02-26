---
name: devteam-test
description: Coordinate test writing and execution across the project. Launches the Test Coordinator to orchestrate language-specific test writers and verification agents.
argument-hint: [target] [--type <unit|integration|e2e>] [--scope <path>] [--coverage] [--threshold <pct>] [--eco]
user-invocable: true
allowed-tools: Read, Glob, Grep, Bash, Task
model: opus
---

Current session: !`source "${CLAUDE_PLUGIN_ROOT}/scripts/state.sh" && get_current_session 2>/dev/null || echo "No active session"`
Active sprint: !`source "${CLAUDE_PLUGIN_ROOT}/scripts/state.sh" && get_kv_state "active_sprint" 2>/dev/null || echo "None"`
Failure count: !`source "${CLAUDE_PLUGIN_ROOT}/scripts/state.sh" && get_kv_state "consecutive_failures" 2>/dev/null || echo "0"`

# DevTeam Test Command

**Command:** `/devteam:test [target] [options]`

Coordinate test writing and execution across the project. Launches the Test Coordinator to orchestrate language-specific test writers and verification agents.

## Usage

```bash
# Write tests for current task
/devteam:test

# Write tests for specific files
/devteam:test "src/api/auth.ts"

# Write specific test types
/devteam:test --type unit
/devteam:test --type integration
/devteam:test --type e2e

# Write tests for a scope
/devteam:test --scope "src/services/"

# Run existing tests and fill coverage gaps
/devteam:test --coverage
/devteam:test --coverage --threshold 80

# Cost-optimized
/devteam:test --eco
```

## Options

| Option | Description |
|--------|-------------|
| `--type <type>` | Test type: unit, integration, e2e, all |
| `--scope <path>` | Limit to specific files/directories |
| `--coverage` | Analyze coverage and fill gaps |
| `--threshold <pct>` | Coverage threshold percentage (default: 80) |
| `--eco` | Cost-optimized execution |

## Your Process

### Phase 0: Initialize Session

```bash
source "${CLAUDE_PLUGIN_ROOT}/scripts/state.sh"
source "${CLAUDE_PLUGIN_ROOT}/scripts/events.sh"

SESSION_ID=$(start_session "/devteam:test $*" "test")
log_session_started "/devteam:test $*" "test"
```

### Phase 1: Launch Test Coordinator

Delegate to the `quality:test-coordinator` agent, which will:

1. Analyze target code to determine test needs
2. Select appropriate test writers based on language
3. Coordinate unit, integration, and e2e test writing
4. Run tests and verify they pass
5. Report coverage metrics

```javascript
const result = await Task({
    subagent_type: "quality:test-coordinator",
    prompt: `Test coordination request:

        Target: ${target || 'current task files'}
        Type: ${type || 'all'}
        Scope: ${scope || 'auto-detect'}
        Coverage mode: ${coverageMode}
        Threshold: ${threshold || 80}

        Coordinate test writers to produce:
        1. Unit tests for individual functions/methods
        2. Integration tests for component interactions
        3. E2E tests for critical user flows
        4. Edge case and error handling tests
        5. Coverage report and gap analysis`
})
```

### Phase 2: Verification

- Run all generated tests
- Verify tests pass
- Check coverage meets threshold
- Report any flaky tests

### Phase 3: Completion

```javascript
log_session_ended('completed', 'Test writing complete')
end_session('completed', 'Success')
```

## See Also

- `/devteam:review` - Code review before testing
- `/devteam:implement` - Implement features to test
- `/devteam:status` - Check test progress
