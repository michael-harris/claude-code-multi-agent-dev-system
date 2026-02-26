---
name: devteam-bug
description: Fix a bug with structured diagnostic workflow. Uses interview to clarify details and Bug Council for complex issues.
argument-hint: "<description>" [--council] [--severity <level>] [--scope <path>] [--skip-interview] [--eco]
user-invocable: true
allowed-tools: Read, Edit, Write, Glob, Grep, Bash, Task
model: opus
---

Current session: !`source "${CLAUDE_PLUGIN_ROOT}/scripts/state.sh" && get_current_session 2>/dev/null || echo "No active session"`
Active sprint: !`source "${CLAUDE_PLUGIN_ROOT}/scripts/state.sh" && get_kv_state "active_sprint" 2>/dev/null || echo "None"`
Failure count: !`source "${CLAUDE_PLUGIN_ROOT}/scripts/state.sh" && get_kv_state "consecutive_failures" 2>/dev/null || echo "0"`

# DevTeam Bug Command

**Command:** `/devteam:bug "<description>" [options]`

Fix a bug with structured diagnostic workflow. Uses interview to clarify details and Bug Council for complex issues.

## Usage

```bash
# Basic bug fix (will trigger interview for missing details)
/devteam:bug "Login fails for guest users"

# Force Bug Council activation
/devteam:bug "Memory leak in image processor" --council

# Specify severity
/devteam:bug "Payment processing timeout" --severity critical
/devteam:bug "Button color wrong" --severity low

# Limit scope
/devteam:bug "API returns 500" --scope "src/api/"

# Skip interview (if you have all details)
/devteam:bug "Null pointer in UserService.getProfile() when user.settings is undefined" --skip-interview

# Cost-optimized
/devteam:bug "Minor typo in error message" --eco
```

## Options

| Option | Description |
|--------|-------------|
| `--council` | Force Bug Council activation |
| `--severity <level>` | Set severity: critical, high, medium, low |
| `--scope <path>` | Limit search to specific files/directories |
| `--skip-interview` | Skip clarifying questions |
| `--eco` | Cost-optimized execution |
| `--model <model>` | Force starting model |

## Your Process

### Phase 0: Initialize Session

```bash
source "${CLAUDE_PLUGIN_ROOT}/scripts/state.sh"
source "${CLAUDE_PLUGIN_ROOT}/scripts/events.sh"

SESSION_ID=$(start_session "/devteam:bug \"$1\"" "bug")
log_session_started "/devteam:bug \"$1\"" "bug"
set_phase "interview"
```

### Phase 1: Interview (Clarify Bug Details)

**Always ask if missing from description:**

```yaml
bug_interview:
  required:
    - key: expected_behavior
      question: "What is the expected behavior?"
      skip_if: description contains "should" or "expected"

    - key: actual_behavior
      question: "What is the actual behavior?"
      skip_if: description contains "but" or "instead" or "actually"

  conditional:
    - key: repro_steps
      condition: description lacks step-by-step
      question: "What steps reproduce this issue?"

    - key: environment
      condition: could be environment-specific
      question: "What environment does this occur in? (browser, OS, version)"

    - key: frequency
      condition: not clear if consistent
      question: "Does this happen every time or intermittently?"

    - key: recent_changes
      condition: could be regression
      question: "Did this start recently? Any recent changes that might be related?"

    - key: error_message
      condition: no error mentioned
      question: "Are there any error messages or stack traces?"
```

**Interview flow:**

```javascript
async function runBugInterview(description) {
    log_interview_started('bug')
    const questions = []
    const responses = {}

    // Check what's missing from description
    if (!hasExpectedBehavior(description)) {
        const response = await ask("What is the expected behavior?")
        responses.expected_behavior = response
        questions.push('expected_behavior')
    }

    if (!hasActualBehavior(description)) {
        const response = await ask("What is the actual behavior?")
        responses.actual_behavior = response
        questions.push('actual_behavior')
    }

    // ... more conditional questions

    log_interview_completed(questions.length)
    return responses
}
```

### Phase 2: Classify Bug

**Determine severity:**
```yaml
severity_indicators:
  critical:
    - "security vulnerability"
    - "data loss"
    - "system down"
    - "production"
    - "payment"
    - "authentication bypass"

  high:
    - "major functionality broken"
    - "affects all users"
    - "no workaround"
    - "blocking"

  medium:
    - "workaround exists"
    - "affects some users"
    - "degraded experience"

  low:
    - "cosmetic"
    - "typo"
    - "minor"
    - "edge case"
```

**Determine complexity:**
```yaml
complexity_indicators:
  simple:
    - single file likely
    - clear error message
    - obvious fix
    - similar bug fixed before

  moderate:
    - multiple files
    - requires investigation
    - unclear root cause

  complex:
    - architectural issue
    - race condition
    - intermittent
    - cross-system
    - no reproduction steps
```

### Phase 3: Create Bug Record

```sql
INSERT INTO bugs (
    session_id,
    description,
    severity,
    complexity,
    status
) VALUES (
    'session-xxx',
    'Login fails for guest users when settings is null',
    'high',
    'moderate',
    'in_progress'
);
```

### Phase 4: Bug Council (if needed)

**Activate Bug Council if:**
- Complexity is `complex`
- `--council` flag specified
- 2+ failed fix attempts
- Severity is `critical`

```javascript
if (shouldActivateBugCouncil(bug)) {
    log_bug_council_activated(reason)
    set_phase('bug_council')

    // Spawn 5 diagnostic agents in parallel
    const councilResults = await Promise.all([
        Task({
            subagent_type: "diagnosis:root-cause-analyst",
            model: "opus",
            prompt: `Analyze bug: ${bug.description}

                Expected: ${bug.expected_behavior}
                Actual: ${bug.actual_behavior}
                Repro: ${bug.repro_steps}

                Provide:
                - Root cause hypothesis
                - Evidence supporting hypothesis
                - Recommended fix approach
                - Confidence score (0-1)`
        }),

        Task({
            subagent_type: "diagnosis:code-archaeologist",
            model: "opus",
            prompt: `Investigate git history for: ${bug.description}

                Look for:
                - Recent changes to affected areas
                - When behavior changed
                - Related commits
                - Previous similar fixes`
        }),

        Task({
            subagent_type: "diagnosis:pattern-matcher",
            model: "opus",
            prompt: `Search codebase for patterns related to: ${bug.description}

                Find:
                - Similar code patterns
                - Related bugs/fixes
                - Anti-patterns that might cause this
                - Inconsistencies in handling`
        }),

        Task({
            subagent_type: "diagnosis:systems-thinker",
            model: "opus",
            prompt: `Analyze system interactions for: ${bug.description}

                Consider:
                - Component dependencies
                - Data flow
                - State management
                - Integration points`
        }),

        Task({
            subagent_type: "diagnosis:adversarial-tester",
            model: "opus",
            prompt: `Find edge cases for: ${bug.description}

                Test:
                - Boundary conditions
                - Null/undefined scenarios
                - Race conditions
                - Security implications`
        })
    ])

    // Ranked-choice voting
    const decision = synthesizeCouncilDecision(councilResults)
    log_bug_council_completed(decision.approach, decision.votes)

    return decision
}
```

**Council output format:**

```yaml
bug_council_decision:
  winning_proposal:
    agent: diagnosis:pattern-matcher
    diagnosis: "Inconsistent null checking across 4 locations"
    confidence: 0.92

  votes:
    diagnosis:pattern-matcher: 11 points (winner)
    diagnosis:systems-thinker: 10 points
    diagnosis:root-cause-analyst: 16 points
    diagnosis:adversarial-tester: 16 points
    diagnosis:code-archaeologist: 22 points

  consensus: "Strong (4/5 ranked winner in top 2)"

  recommended_fix:
    approach: "Add optional chaining to all user.settings accesses"
    locations:
      - "src/services/UserService.ts:142"
      - "src/controllers/ProfileController.ts:89"
      - "src/components/SettingsPage.tsx:45"
      - "src/api/AccountApi.ts:112"
    prevention: "Add eslint rule for optional chaining on nullable types"
```

### Phase 5: Implement Fix

**Simple bugs (no council):**

```javascript
set_phase('implementing')

const result = await Task({
    subagent_type: "orchestration:task-loop",
    model: selectModel(bug.complexity),
    prompt: `Fix bug: ${bug.description}

        Root cause: ${diagnosis.root_cause}

        Requirements:
        1. Fix the bug
        2. Add regression test
        3. Verify existing tests pass
        4. Document the fix

        Scope: ${bug.scope || 'auto-detect'}`
})

log_agent_completed(result.agent, result.model, result.files_changed)
```

**Complex bugs (with council):**

```javascript
const result = await Task({
    subagent_type: "orchestration:task-loop",
    model: "opus",
    prompt: `Implement Bug Council decision:

        Decision: ${councilDecision.approach}
        Locations: ${councilDecision.locations.join(', ')}

        Steps:
        1. Apply fix to ALL identified locations
        2. Implement prevention measures: ${councilDecision.prevention}
        3. Add comprehensive regression tests
        4. Run full test suite
        5. Verify fix resolves the issue

        Follow council recommendations exactly.`
})
```

### Phase 6: Quality Gates

Same as `/devteam:implement` - run tests, lint, typecheck.

### Phase 7: Update Bug Record

```sql
UPDATE bugs
SET status = 'resolved',
    root_cause = 'Inconsistent null checking',
    fix_summary = 'Added optional chaining to 4 locations',
    files_changed = '["src/services/UserService.ts", ...]',
    prevention_measures = 'Added eslint rule',
    resolved_at = CURRENT_TIMESTAMP,
    council_activated = TRUE
WHERE session_id = 'session-xxx';
```

### Phase 8: Completion

```javascript
log_session_ended('completed', 'Bug fixed')
end_session('completed', 'Success')

console.log(`
╔══════════════════════════════════════════════════╗
║  BUG FIXED                                       ║
╚══════════════════════════════════════════════════╝

Bug: ${bug.description}

Root Cause: ${diagnosis.root_cause}

Fix Applied:
${filesChanged.map(f => `  - ${f}`).join('\n')}

Prevention:
  ${prevention}

Tests:
  ${testCount} existing tests pass
  ${newTestCount} regression tests added

${councilActivated ? `
Bug Council: Activated
  Decision: ${councilDecision.approach}
  Consensus: ${councilDecision.consensus}
` : ''}

Cost: $${totalCost}

EXIT_SIGNAL: true
`)
```

## Model Escalation for Bugs

Bugs have faster escalation than features:

| Complexity | Initial Model | Escalation Path |
|------------|---------------|-----------------|
| Simple | haiku | haiku -> sonnet (1 fail) -> opus (1 fail) |
| Moderate | sonnet | sonnet -> opus (1 fail) -> council (2 fails) |
| Complex | opus | opus -> council (2 fails) |
| Critical | opus | opus -> council (immediate if complex) |

## User Communication

**Interview:**
```
Bug Report Interview

Bug: Login fails for guest users

I need a few more details to diagnose this effectively:

Q1: What is the expected behavior?
> Users should be able to browse as guests without logging in

Q2: What error message do you see?
> "Cannot read property 'settings' of undefined"

Thank you! Starting diagnosis...
```

**Council deliberation:**
```
Bug Council Deliberation

Spawning 5 diagnostic agents...

[A] Root Cause Analyst    Complete
[B] Code Archaeologist    Complete
[C] Pattern Matcher       Complete
[D] Systems Thinker       Complete
[E] Adversarial Tester    Complete

Conducting ranked-choice vote...

Rankings:
  C (Pattern Matcher): 11 points - Winner
  D (Systems Thinker): 10 points
  A (Root Cause):      16 points
  E (Adversarial):     16 points
  B (Archaeologist):   22 points

Council Decision: Proposal C
"Inconsistent optional chaining across 4 locations"

Consensus: Strong (4/5 ranked in top 2)

Proceeding with implementation...
```

## See Also

- `/devteam:issue` - Fix GitHub issues (use when you have a GitHub issue number to reference)
- `/devteam:implement` - General implementation
- `/devteam:status` - Check progress

> **When to use `/devteam:bug` vs `/devteam:issue`:** Use `/devteam:bug` for locally-discovered bugs without a GitHub issue. Use `/devteam:issue` when fixing a tracked GitHub issue by number.
