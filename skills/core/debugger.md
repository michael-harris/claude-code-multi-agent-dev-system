# Debugger Skill

**Skill ID:** `core:debugger`
**Category:** Core
**Model:** `sonnet`

## Purpose

Systematic debugging and issue diagnosis. Provides structured approaches to finding and fixing bugs through methodical investigation.

## Capabilities

### 1. Stack Trace Analysis
- Parse error messages and stack traces
- Identify root cause from exception chains
- Trace execution flow through call stack

### 2. Breakpoint Strategy
- Suggest strategic breakpoint locations
- Binary search debugging approach
- State inspection recommendations

### 3. Log Analysis
- Parse log files for error patterns
- Correlate timestamps across services
- Identify anomalies in log sequences

### 4. Reproduction Steps
- Create minimal reproduction cases
- Isolate environmental factors
- Document reproduction steps

## Activation Triggers

```yaml
triggers:
  keywords:
    - debug
    - breakpoint
    - stack trace
    - exception
    - error
    - crash
    - investigate

  task_types:
    - debugging
    - bug_investigation
    - error_analysis
```

## Process

### Step 1: Gather Information

```javascript
const debugContext = {
    error_message: getErrorMessage(),
    stack_trace: getStackTrace(),
    recent_changes: getGitDiff('HEAD~5'),
    logs: getRecentLogs(),
    environment: getEnvironmentInfo()
}
```

### Step 2: Hypothesize

Generate ranked hypotheses:
1. Most likely cause based on error type
2. Recent code changes that could cause issue
3. Environmental factors
4. Edge cases or race conditions

### Step 3: Systematic Investigation

```yaml
investigation_order:
  - step: Reproduce the issue
    verify: Can trigger consistently

  - step: Check obvious causes
    verify: Typos, null references, type errors

  - step: Review recent changes
    verify: git bisect if needed

  - step: Add diagnostic logging
    verify: Narrow down location

  - step: Test hypotheses
    verify: One at a time
```

### Step 4: Fix and Verify

```javascript
// Apply fix
const fix = implementFix(rootCause)

// Verify fix addresses issue
await runTests()
await reproduceIssue() // Should fail now

// Verify no regressions
await runFullTestSuite()
```

## Output Format

```yaml
debug_report:
  issue:
    description: "Brief description"
    reproduction: "Steps to reproduce"

  investigation:
    hypotheses:
      - hypothesis: "Description"
        likelihood: high | medium | low
        tested: true | false
        result: "Findings"

  root_cause:
    description: "Root cause explanation"
    location: "file:line"
    evidence: "How we confirmed this"

  fix:
    description: "What was changed"
    files_modified: ["list"]
    verification: "How fix was verified"

  prevention:
    - "How to prevent similar issues"
```

## See Also

- `agents/diagnosis/root-cause-analyst.md` - Bug Council root cause analysis
- `skills/testing/test-generator.md` - Generate tests to prevent regression
