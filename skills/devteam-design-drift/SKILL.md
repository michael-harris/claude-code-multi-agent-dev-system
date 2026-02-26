---
name: devteam-design-drift
description: Detect design inconsistencies and drift from the design system. Launches the Design Drift Detector to analyze the codebase for deviations.
argument-hint: [--scope <path>] [--check <colors|typography|spacing|layout|all>] [--fix] [--threshold <strict|normal|relaxed>]
user-invocable: true
allowed-tools: Read, Edit, Write, Glob, Grep, Bash, Task
model: sonnet
---

Current session: !`source "${CLAUDE_PLUGIN_ROOT}/scripts/state.sh" && get_current_session 2>/dev/null || echo "No active session"`
Active sprint: !`source "${CLAUDE_PLUGIN_ROOT}/scripts/state.sh" && get_kv_state "active_sprint" 2>/dev/null || echo "None"`
Failure count: !`source "${CLAUDE_PLUGIN_ROOT}/scripts/state.sh" && get_kv_state "consecutive_failures" 2>/dev/null || echo "0"`

# DevTeam Design Drift Command

**Command:** `/devteam:design-drift [scope] [options]`

Detect design inconsistencies and drift from the design system. Launches the Design Drift Detector to analyze the codebase for deviations.

## Usage

```bash
# Full codebase scan
/devteam:design-drift

# Scan specific directory
/devteam:design-drift --scope "src/components/"

# Check specific design aspect
/devteam:design-drift --check colors
/devteam:design-drift --check typography
/devteam:design-drift --check spacing

# Generate remediation plan
/devteam:design-drift --fix
```

## Options

| Option | Description |
|--------|-------------|
| `--scope <path>` | Limit scan to specific files/directories |
| `--check <aspect>` | Focus on: colors, typography, spacing, layout, all |
| `--fix` | Generate remediation tasks for detected drift |
| `--threshold <level>` | Drift tolerance: strict, normal, relaxed |

## Your Process

### Phase 0: Initialize Session

```bash
source "${CLAUDE_PLUGIN_ROOT}/scripts/state.sh"
source "${CLAUDE_PLUGIN_ROOT}/scripts/events.sh"

SESSION_ID=$(start_session "/devteam:design-drift $*" "design-drift")
log_session_started "/devteam:design-drift $*" "design-drift"
```

### Phase 1: Launch Design Drift Detector

Delegate to the `ux:design-drift-detector` agent, which will:

1. Scan codebase for design token usage
2. Compare implementations against design system specifications
3. Identify hardcoded values that should use tokens
4. Detect inconsistent patterns across components
5. Generate a drift report with severity ratings

```javascript
const result = await Task({
    subagent_type: "ux:design-drift-detector",
    prompt: `Design drift analysis:

        Scope: ${scope || 'full codebase'}
        Check: ${aspect || 'all'}
        Threshold: ${threshold || 'normal'}

        Analyze for:
        1. Hardcoded colors/fonts/spacing that should use design tokens
        2. Inconsistent component patterns
        3. Deviations from established design system
        4. Accessibility regressions
        5. Cross-platform inconsistencies`
})
```

### Phase 2: Report

Output a drift report showing:
- Number of drift instances found
- Severity breakdown (critical, warning, info)
- Affected files and locations
- Recommended fixes

### Phase 3: Remediation (if --fix)

If `--fix` is specified, create remediation tasks for each drift instance.

## See Also

- `/devteam:design` - Coordinate design work
- `/devteam:implement` - Implement design fixes
- `/devteam:status` - Check progress
