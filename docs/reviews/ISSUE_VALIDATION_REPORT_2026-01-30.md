# Outstanding Issues Validation Report
**Date:** 2026-01-30
**Reviewer:** Claude Code Session

## Executive Summary

This report validates previously identified issues and documents additional findings discovered during a thorough codebase review.

| Category | Original Issues | Confirmed | Fixed/Outdated | New Issues Found |
|----------|-----------------|-----------|----------------|------------------|
| Critical Shell Bugs | 5 | **5** | 0 | 0 |
| Plugin.json Issues | 2 | 1 | 1 | 2 |
| Command Redundancies | 5 | 2 | 2 | 1 |
| Documentation Errors | 3 | **3** | 0 | 1 |
| Accessibility Overlap | 1 | Partial | - | 0 |
| Inconsistencies | 5 | **5** | 0 | 1 |
| Unnecessary Files | 2 | **1** | 1 | 0 |

---

## CRITICAL: Shell Script Bugs (ALL CONFIRMED)

### 1. `scripts/events.sh:237` - Undefined Variable ⚠️ CONFIRMED

**Location:** `scripts/events.sh:237`

```bash
# Line 231-237: $esc_task_id used but never defined
local esc_session_id esc_agent esc_model
esc_session_id=$(sql_escape "$session_id")
esc_agent=$(sql_escape "$agent")
esc_model=$(sql_escape "$model")
# MISSING: esc_task_id=$(sql_escape "$task_id")

VALUES ('$esc_session_id', '$esc_agent', '$esc_model', '$esc_task_id', ...)
#                                                       ^^^ UNDEFINED
```

**Impact:** SQL corruption, potential empty values inserted.

**Fix:** Add `esc_task_id=$(sql_escape "$task_id")` at line 235.

---

### 2. `scripts/events.sh:341` - Unescaped Variable ⚠️ CONFIRMED

**Location:** `scripts/events.sh:341`

```bash
# Line 331-341: $esc_error_type used but error_type never escaped
local esc_session_id esc_agent esc_error_message
# MISSING: esc_error_type=$(sql_escape "$error_type")

error_type = '$esc_error_type'  # ← Uses undefined escaped version
```

**Impact:** SQL corruption, potential injection if error_type contains quotes.

**Fix:** Add `esc_error_type=$(sql_escape "$error_type")` at line 335.

---

### 3. `scripts/state.ps1` - SQL Injection Vulnerability ⚠️ CONFIRMED

**Location:** `scripts/state.ps1` (entire file)

**Problem:** No escaping anywhere in the PowerShell script. All user inputs directly interpolated into SQL queries.

**Affected functions:**
- `Start-DevTeamSession` (line 56-59): `$Command`, `$CommandType`, `$ExecutionMode`
- `Stop-DevTeamSession` (line 71-77): `$Status`, `$ExitReason`
- `Get-SessionState` (line 107): `$Field`, `$SessionId`
- `Set-SessionState` (line 159-163): `$Field`, `$Value`, `$SessionId`
- `Enable-BugCouncil` (line 242-249): `$Reason`

**Impact:** SQL injection vulnerability allowing arbitrary SQL execution.

**Fix:** Create `Invoke-SqlEscape` function and apply to all string interpolations:

```powershell
function Invoke-SqlEscape {
    param([string]$Value)
    return $Value -replace "'", "''"
}
```

---

### 4. `hooks/scope-check.ps1:119` - Wildcard Matching Bug ⚠️ CONFIRMED

**Location:** `hooks/scope-check.ps1:119`

```powershell
# Line 118-119
$normalizedDir = $forbiddenDir.TrimEnd('/\')
if ($file -like "$normalizedDir*" ...) {
#              ^^^ BUG: "src" would match "srcfile.txt"
```

**Impact:** False positives - files like `srcfile.txt` would be blocked when `src/` is forbidden.

**Fix:**
```powershell
if ($file -like "$normalizedDir/*" -or $file -like "$normalizedDir\*") {
```

---

### 5. `hooks/stop-hook.sh:99` - macOS Incompatibility ⚠️ CONFIRMED

**Location:** `hooks/stop-hook.sh:99`

```bash
# Line 99
sed -i "s/\"total_iterations\": [0-9]*/\"total_iterations\": $ITERATIONS/" "$CIRCUIT_BREAKER_FILE"
```

**Impact:** Script fails on macOS with "invalid command code" error.

**Fix:** Use portable syntax:
```bash
sed -i.bak "s/\"total_iterations\": [0-9]*/\"total_iterations\": $ITERATIONS/" "$CIRCUIT_BREAKER_FILE" && rm -f "${CIRCUIT_BREAKER_FILE}.bak"
# Or use temp file approach for full portability
```

---

## Plugin.json Issues

### 1. Agent Count Mismatch 🔄 PARTIALLY OUTDATED

| Location | Claims | Actual |
|----------|--------|--------|
| `plugin.json:4` | 126 agents | ✅ Correct |
| `README.md:3` | 106 agents | ❌ Outdated |

**Actual count:** 126 agent files (verified via `find`)

**Status:** plugin.json is correct; README.md needs update.

---

### 2. Mobile Code Reviewers Model Tier ⚠️ CONFIRMED

| Agent | plugin.json | Agent File | Expected |
|-------|-------------|------------|----------|
| `mobile:ios-code-reviewer` | `sonnet` | `claude-sonnet-4-5` | `opus` |
| `mobile:android-code-reviewer` | `sonnet` | `claude-sonnet-4-5` | `opus` |
| `mobile:ios-designer` | `sonnet` | `claude-sonnet-4-5` | `opus` |
| `mobile:android-designer` | `sonnet` | `claude-sonnet-4-5` | `opus` |

**Context:** All other code reviewers (backend, frontend, database) use `opus`.

**Recommendation:** Upgrade mobile reviewers to `opus` for consistency.

---

### 3. NEW: Model Specification Mismatch ⚠️ NEW FINDING

**Problem:** plugin.json model specifications don't match agent file headers.

**plugin.json uses:** `haiku`, `sonnet`, `opus`

**Agent .md files use varied formats:**
- `Dynamic (based on task complexity)` - 27 agents
- `claude-sonnet-4-5` - 38 agents
- `Dynamic (sonnet-opus based on complexity)` - 3 agents

**Examples of mismatch:**

| Agent | plugin.json | Agent File |
|-------|-------------|------------|
| `frontend:developer` | `sonnet` | `Dynamic (based on task complexity)` |
| `mobile:ios-developer` | `sonnet` | `Dynamic (based on task complexity)` |
| `database:designer` | `opus` | `claude-sonnet-4-5` |

**Impact:** Unclear which model will actually be used.

---

## Command Redundancies

### 1. `/devteam:bug` vs `/devteam:issue` - VALID DISTINCTION

- `/devteam:bug` - Local bug fixing with full interview workflow
- `/devteam:issue` - GitHub issues, fetches from GH API

**Status:** Not a bug - they serve different purposes.

---

### 2. Interview Logic ⚠️ CONFIRMED - Inconsistent Naming

| Command | Flag |
|---------|------|
| `/devteam:bug` | `--no-interview` |
| `/devteam:implement` | `--no-interview` |
| `/devteam:plan` | `--skip-interview` |

**Recommendation:** Standardize to `--no-interview` or `--skip-interview` everywhere.

---

### 3. State Storage - VALID ARCHITECTURE

- SQLite: Structured data, events, metrics, queries
- YAML: Human-readable config, state snapshots

**Status:** Intentional design - not a bug.

---

### 4. Skills System - 🔄 OUTDATED

- Skills ARE referenced and used via `/devteam:skill` and `/devteam:skills` commands
- 18 skills are defined in plugin.json and matching files exist

**Status:** Issue was outdated/incorrect.

---

## Documentation Errors

### 1. `skills/README.md` - Non-existent Files ⚠️ CONFIRMED

**7 incorrect file references found (more than the "4+" originally reported):**

| Documented | Actual File | Status |
|------------|-------------|--------|
| `error-debugger.md` | `debugger.md` | ❌ Wrong name |
| `documentation-writer.md` | - | ❌ Doesn't exist |
| `e2e-testing.md` | `e2e-tester.md` | ❌ Wrong name |
| `test-data-generator.md` | - | ❌ Doesn't exist |
| `accessibility-auditor.md` | `accessibility-checker.md` | ❌ Wrong name |
| `component-designer.md` | - | ❌ Doesn't exist |
| `task-decomposer.md` | - | ❌ Doesn't exist |

---

### 2. README.md `/devteam:auto` Command ⚠️ CONFIRMED

**Problem:**
- `README.md` extensively documents `/devteam:auto` (40+ references)
- **No `commands/devteam-auto.md` file exists**
- Per `docs/releases/ENHANCEMENTS_V3.0.md:16`: `/devteam:auto` was renamed to `/devteam:implement`
- README.md was never fully updated

**Affected documentation:**
- `README.md`
- `commands/README.md`
- `.devteam/parallel-instances.md`
- `hooks/README.md`
- `install-local.sh`
- Multiple other files

---

### 3. `devteam-bug.md` `--no-interview` Flag - VALID

- Flag IS documented at line 37
- Implementation is in the markdown instructions
- **Status:** Not a bug - works as designed.

---

### 4. NEW: README Agent Count Mismatch ⚠️ NEW FINDING

- `README.md:3` says "106 specialized AI agents"
- `plugin.json:4` says "126-agent automated development system"
- Actual count: 126 agents

---

## Accessibility Overlap

### `skills/quality/accessibility-checker.md` vs `skills/frontend/accessibility-expert.md`

**Analysis:**

| Aspect | accessibility-checker | accessibility-expert |
|--------|----------------------|---------------------|
| **Purpose** | Audit existing code | Build accessible-first |
| **Focus** | WCAG compliance testing | Component implementation |
| **Triggers** | `accessibility_audit`, `wcag_compliance` | `frontend_development`, `component_creation` |
| **Output** | Audit reports | Implemented components |

**Overlap areas (~30-40%, not 60%):**
- ARIA implementation guidance
- Keyboard navigation patterns
- WCAG references

**Status:** Different purposes, but could benefit from clearer delineation. Both files include "See Also" references to each other.

---

## Inconsistencies (ALL CONFIRMED)

### 1. Model Specifications
- **plugin.json:** `sonnet`, `opus`, `haiku` only
- **Agent files:** `Dynamic`, `claude-sonnet-4-5`, conditional descriptions
- **27 agents** use "Dynamic" model not reflected in plugin.json

### 2. Agent File Detail Levels
- Range: 11 lines to 800+ lines
- Some agents are stubs, others are comprehensive

### 3. Output Formats
- Box-drawing characters in some commands
- Markdown in others
- YAML in status outputs
- No consistent standard defined

### 4. Option Naming

| Pattern | Commands |
|---------|----------|
| `--no-interview` | bug, implement |
| `--skip-interview` | plan |
| `--skip-research` | plan |

### 5. Complexity Scales
- Categorical: `simple`, `moderate`, `complex` (in commands)
- Numerical: `1-14` (in config files)
- No mapping defined

---

## Unnecessary Files

### 1. `agents/ux/README.md` ⚠️ CONFIRMED

- README in agent directory (non-standard location)
- Other agent categories don't have READMEs
- Contains useful documentation but inconsistent placement

### 2. Deprecated Commands - 🔄 RESOLVED

- `/devteam:auto` files don't exist (correctly removed)
- But documentation references weren't updated (see Documentation Errors)

---

## Additional Issues Found

### 1. No Haiku Model Used in plugin.json
- Plugin.json defines only `sonnet` and `opus` models
- Documentation mentions `haiku` for cost optimization
- No agents actually assigned to `haiku` tier in plugin.json

### 2. Orphaned Documentation References
- `README.md:624` references `/devteam:security "Audit authentication system"` - command doesn't exist

---

## Prioritized Fix Recommendations

### Immediate (Critical)
1. Fix `scripts/events.sh:237` - Add `esc_task_id=$(sql_escape "$task_id")`
2. Fix `scripts/events.sh:341` - Add `esc_error_type=$(sql_escape "$error_type")`
3. Add SQL escaping function to `scripts/state.ps1`
4. Fix `hooks/scope-check.ps1:119` wildcard pattern
5. Fix `hooks/stop-hook.sh:99` for macOS compatibility

### High Priority
6. Update `README.md` agent count from 106 to 126
7. Update all `/devteam:auto` references to `/devteam:implement`
8. Update `skills/README.md` with correct file names
9. Standardize mobile code reviewer model tiers to `opus`
10. Reconcile plugin.json models with agent file models

### Medium Priority
11. Standardize interview flag naming (`--no-interview` everywhere)
12. Add missing skill files or remove documentation references
13. Add priority/deconfliction rules for overlapping skills
14. Move or remove `agents/ux/README.md`

### Low Priority
15. Standardize output formats across commands
16. Define complexity scale mapping
17. Add haiku model tier agents for cost optimization
18. Document state storage architecture decision
