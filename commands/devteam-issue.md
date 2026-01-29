# DevTeam Issue Command

**Command:** `/devteam:issue <number>`

Fix a GitHub issue by number. Automatically fetches details and implements a fix.

## Usage

```bash
/devteam:issue 123             # Fix GitHub issue #123
/devteam:issue 456 --council   # Force Bug Council for complex diagnosis
```

## Your Process

### Phase 0: Initialize State Tracking

Before starting, create/update `.devteam/state.yaml`:

```yaml
version: "3.0"

metadata:
  created_at: "[timestamp]"
  project_name: "Issue #123 Fix"
  project_type: issue

issue:
  number: 123
  title: "[from GitHub]"
  type: bug | security | performance | enhancement
  severity: critical | high | medium | low
  complexity: simple | moderate | complex

current_execution:
  command: "/devteam:issue 123"
  phase: diagnosis

autonomous_mode:
  enabled: true
  max_iterations: 20            # Lower for issues
  current_iteration: 0
  circuit_breaker:
    consecutive_failures: 0
    max_failures: 3             # Lower tolerance for issues
    state: closed
```

### Phase 1: Fetch Issue Details

```bash
# Fetch issue from GitHub
gh issue view 123 --json title,body,labels,comments,state

# Extract key information
- Title
- Description
- Steps to reproduce
- Labels (bug, enhancement, security, etc.)
- Comments (may have additional context)
```

### Phase 2: Classify Issue

**Determine issue type:**
- `bug` - Something broken
- `security` - Security vulnerability
- `performance` - Performance degradation
- `enhancement` - Small feature request

**Determine severity:**
- `critical` - System down, security vulnerability, data loss
- `high` - Major functionality broken
- `medium` - Important but workaround exists
- `low` - Minor issue

**Determine complexity:**
- `simple` - Clear cause, straightforward fix (1-2 files)
- `moderate` - Requires investigation, multiple files
- `complex` - Architectural issue, needs deep analysis

### Phase 3: Bug Council (for complex bugs)

**Activate Bug Council if:**
- Complexity is `complex`
- Issue has no clear reproduction steps
- Multiple failed fix attempts
- `--council` flag specified

**Bug Council Process:**

```javascript
// Spawn 5 diagnostic agents in parallel
const councilResults = await Promise.all([
  Task({
    subagent_type: "diagnosis/root-cause-analyst",
    model: "opus",
    prompt: `Analyze issue #${issueNumber}:
      Title: ${title}
      Description: ${body}

      Provide diagnosis with:
      - Root cause analysis
      - Evidence
      - Recommended fix
      - Confidence score (0-1)`
  }),

  Task({
    subagent_type: "diagnosis/code-archaeologist",
    model: "opus",
    prompt: `Investigate git history for issue #${issueNumber}...`
  }),

  Task({
    subagent_type: "diagnosis/pattern-matcher",
    model: "opus",
    prompt: `Search codebase for similar patterns...`
  }),

  Task({
    subagent_type: "diagnosis/systems-thinker",
    model: "opus",
    prompt: `Analyze system interactions...`
  }),

  Task({
    subagent_type: "diagnosis/adversarial-tester",
    model: "opus",
    prompt: `Find edge cases and related failures...`
  })
])

// Ranked-choice voting
const proposals = councilResults.map(r => r.proposal)
const votes = councilResults.map(r => r.ranking)
const winner = calculateRankedChoice(proposals, votes)

console.log(`Bug Council Decision: ${winner.approach}`)
console.log(`Consensus: ${winner.votes}/${councilResults.length}`)
```

**Bug Council Output:**
```yaml
bug_council:
  activated: true
  issue_number: 123

  proposals:
    A:
      agent: root_cause_analyst
      diagnosis: "Null reference in guest user handling"
      confidence: 0.85
    B:
      agent: code_archaeologist
      diagnosis: "Regression from commit abc123"
      confidence: 0.78
    C:
      agent: pattern_matcher
      diagnosis: "Inconsistent optional chaining"
      confidence: 0.92
    D:
      agent: systems_thinker
      diagnosis: "AuthContext contract violation"
      confidence: 0.80
    E:
      agent: adversarial_tester
      diagnosis: "Multiple paths to same failure"
      confidence: 0.75

  voting:
    method: ranked_choice
    winner: C
    consensus: "Strong (4/5 ranked C in top 2)"

  selected_approach:
    diagnosis: "Inconsistent optional chaining across 4 locations"
    fix: "Add optional chaining to all user.settings accesses"
    prevention: "Add eslint rule for optional chaining"
```

### Phase 4: Implement Fix

**Simple/Moderate Issues (no council):**
```javascript
Task({
  subagent_type: "task-orchestrator",
  model: "dynamic",  // Based on complexity
  prompt: `Fix issue #${issueNumber}:

    Issue: ${title}
    Root cause: ${diagnosis}

    1. Implement fix
    2. Add regression tests
    3. Run existing tests
    4. Code review

    Update state after each step.`
})
```

**Complex Issues (with council):**
```javascript
Task({
  subagent_type: "task-orchestrator",
  model: "sonnet",
  prompt: `Fix issue #${issueNumber} using Bug Council decision:

    Selected approach: ${councilDecision.approach}
    Locations: ${councilDecision.locations}

    1. Apply fix to all identified locations
    2. Implement prevention measures
    3. Add comprehensive regression tests
    4. Run full test suite
    5. Security audit (if applicable)

    Follow council recommendations exactly.`
})
```

### Phase 4.5: Model Escalation (on failure)

If fix attempt fails:

```yaml
model_escalation:
  # Issue-specific escalation (faster than project work)
  consecutive_failures:
    simple_issue:
      haiku_to_sonnet: 1      # Escalate quickly
      sonnet_to_opus: 1
      opus_to_council: 2      # Activate Bug Council
    moderate_issue:
      sonnet_to_opus: 1
      opus_to_council: 2
    complex_issue:
      # Already at opus, go to council after 2 failures
      opus_to_council: 2
```

**Update state on escalation:**
```yaml
issue:
  fix_attempts:
    - attempt: 1
      model: haiku
      result: fail
      reason: "Test still failing"
    - attempt: 2
      model: sonnet
      result: fail
      reason: "Introduced regression"
    - attempt: 3
      model: opus
      result: pass
```

### Phase 5: Verify & Document

1. Run all tests
2. Verify issue is resolved
3. Check no regressions
4. Update documentation if behavior changed
5. Add changelog entry

### Phase 6: GitHub Integration

```bash
# Comment on issue with fix details
gh issue comment 123 --body "Fixed in commit $(git rev-parse HEAD)

**Root Cause:**
${diagnosis}

**Fix:**
${fixDescription}

**Testing:**
- Added regression test
- All existing tests pass

**Prevention:**
${preventionMeasures}"

# Close issue
gh issue close 123 --reason completed
```

## User Communication

**Starting:**
```
🔍 Fetching issue #123...

Issue: Login fails for guest users
Labels: bug, high-priority
Status: open

Analyzing issue complexity...
  Type: bug
  Severity: high
  Complexity: complex

🧠 Activating Bug Council for deep analysis...
```

**Bug Council Progress:**
```
═══════════════════════════════════════
Bug Council Deliberation
═══════════════════════════════════════

Spawning 5 diagnostic agents...

[A] Root Cause Analyst    ━━━━━━━━━━ analyzing...
[B] Code Archaeologist    ━━━━━━━━━━ analyzing...
[C] Pattern Matcher       ━━━━━━━━━━ analyzing...
[D] Systems Thinker       ━━━━━━━━━━ analyzing...
[E] Adversarial Tester    ━━━━━━━━━━ analyzing...

All analyses complete. Conducting ranked-choice vote...

Proposal Rankings:
  C (Pattern Matcher): 11 points ⭐ Winner
  D (Systems Thinker): 10 points
  A (Root Cause):      16 points
  E (Adversarial):     16 points
  B (Archaeologist):   22 points

Council Decision: Proposal C
"Inconsistent optional chaining across 4 locations"
Consensus: Strong (4/5 ranked in top 2)
```

**Implementation:**
```
═══════════════════════════════════════
Implementing Fix
═══════════════════════════════════════

Applying fix to:
  ✅ UserService.java:142
  ✅ ProfileController.java:89
  ✅ SettingsPage.tsx:45
  ✅ AccountApi.ts:112

Adding prevention:
  ✅ ESLint rule for optional chaining

Running tests...
  ✅ 234/234 tests pass
  ✅ New regression test added

Code review...
  ✅ Approved
```

**Completion:**
```
╔══════════════════════════════════════════╗
║  ✅ ISSUE #123 RESOLVED                  ║
╚══════════════════════════════════════════╝

Issue: Login fails for guest users

Root Cause: Inconsistent optional chaining
Fix: Added ?. operator to 4 locations
Prevention: Added ESLint rule

Files Changed:
  • UserService.java
  • ProfileController.java
  • SettingsPage.tsx
  • AccountApi.ts
  • .eslintrc.js (new rule)

Tests: 235 pass (1 new)

GitHub issue #123 closed automatically.
```

## Cost Estimation

**Simple bug (no council):**
- Analysis: ~$0.20
- Implementation: ~$0.50
- Testing: ~$0.30
- **Total: ~$1.00**

**Complex bug (with council):**
- Council (5x Opus): ~$3.50
- Implementation: ~$1.50
- Testing: ~$0.50
- **Total: ~$5.50**
