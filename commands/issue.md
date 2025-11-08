# Issue Command

You are implementing a **complete issue resolution workflow** from bug report to fix.

## Command Usage

`/multi-agent:issue [issue description or GitHub issue URL]` - Complete bug fix workflow
`/multi-agent:issue [issue description] --tracks N` - Same workflow with N parallel tracks (rare for small issues)

Examples:
- `/multi-agent:issue https://github.com/user/repo/issues/123`
- `/multi-agent:issue Fix memory leak in WebSocket handler`
- `/multi-agent:issue Users can't login after password reset`
- `/multi-agent:issue API returns 500 error for /users endpoint with pagination`
- `/multi-agent:issue Refactor authentication system for better performance --tracks 2`

Note: Most issues are small enough that tracks=1 (default) is sufficient. Parallel tracks are useful only for large, complex issues that span multiple independent components.

## Your Process

This is a **macro command** for rapid issue resolution.

### Phase 1: Issue Analysis

**Gather Information:**

If GitHub URL provided:
```javascript
// Use gh CLI to fetch issue details
Task(
  subagent_type="general-purpose",
  model="sonnet",
  description="Fetch GitHub issue details",
  prompt=`Fetch issue details:

gh issue view ${issueNumber} --json title,body,labels,comments

Extract:
- Issue title
- Description
- Steps to reproduce
- Expected vs actual behavior
- Labels/tags
- Related code references
`
)
```

If description provided:
- Analyze issue description
- Identify affected components
- Determine severity (critical/high/medium/low)
- Identify issue type (bug/performance/security/enhancement)

### Phase 2: Create Lightweight PRD

**Generate focused PRD:**
```javascript
Task(
  subagent_type="multi-agent:planning:prd-generator",
  model="sonnet",
  description="Create issue PRD",
  prompt=`Create focused PRD for issue resolution:

ISSUE: ${issueDescription}

Create lightweight PRD:
- Problem statement
- Root cause (if known)
- Solution approach
- Acceptance criteria:
  * Issue is resolved
  * No regressions introduced
  * Tests added to prevent recurrence
- Testing requirements
- Affected components

Output: docs/planning/ISSUE_${issueId}_PRD.yaml

Keep it concise - this is a bug fix, not a feature.
`
)
```

### Phase 3: Task Creation & Sprint Planning

**Create tasks and organize into sprint:**

```javascript
// First, create tasks
Task(
  subagent_type="multi-agent:planning:task-graph-analyzer",
  model="sonnet",
  description="Create issue resolution tasks",
  prompt=`Create tasks for issue resolution:

Issue PRD: docs/planning/ISSUE_${issueId}_PRD.yaml

Create tasks in: docs/planning/tasks/
Prefix task IDs with ISSUE-${issueId}-

Task breakdown should include:
- Investigate and identify root cause
- Implement fix
- Add/update tests
- Verify no regressions

Most issues will be 1 task, but complex issues may require multiple tasks with dependencies.
Identify all dependencies between tasks.
`
)

// Then, organize into sprint
Task(
  subagent_type="multi-agent:planning:sprint-planner",
  model="sonnet",
  description="Organize issue tasks into sprint",
  prompt=`Organize issue resolution tasks into a sprint:

Tasks: docs/planning/tasks/ISSUE-${issueId}-*
Dependencies: Check task files for dependencies
Requested parallel tracks: 1 (single-track for issues)

Create sprint: docs/sprints/ISSUE_${issueId}_SPRINT-001.yaml
Initialize state file: docs/planning/.issue-${issueId}-state.yaml

Even if there's only 1 task, create a proper sprint structure to ensure consistent workflow.
Balance sprint capacity and respect dependencies.
`
)
```

### Phase 4: Execute Sprint

**Launch sprint orchestrator:**
```javascript
Task(
  subagent_type="multi-agent:orchestration:sprint-orchestrator",
  model="sonnet",
  description="Execute issue resolution sprint",
  prompt=`Execute sprint for issue ${issueId}:

Sprint file: docs/sprints/ISSUE_${issueId}_SPRINT-001.yaml
State file: docs/planning/.issue-${issueId}-state.yaml
Technology stack: docs/planning/PROJECT_PRD.yaml or ISSUE_${issueId}_PRD.yaml

CRITICAL - Autonomous Execution:
You MUST execute autonomously without stopping or requesting permission. Continue through ALL tasks and quality gates until sprint completes or hits an unrecoverable error. DO NOT pause, DO NOT ask for confirmation, DO NOT wait for user input.

IMPORTANT - State Tracking & Resume:
1. Load state file at start
2. Check sprint status (skip if completed, resume if in_progress)
3. Update state after EACH task completion
4. Save state regularly to enable resumption

Workflow for each task:
1. Investigate root cause (use appropriate language developer)
2. Implement fix (T1 first, escalate to T2 if needed)
3. Run code reviewer
4. Run security auditor (if security issue)
5. Run performance auditor (if performance issue)
6. Add tests to prevent regression
7. Verify fix with requirements validator
8. Run workflow compliance check

Use T2 agents directly if:
- Critical severity
- Security vulnerability
- Complex root cause

Execute autonomously until sprint completes.
`
)
```

### Phase 5: Verification & Documentation

**Comprehensive verification:**
```
1. Run all existing tests (no regressions)
2. Verify specific issue is resolved
3. Check related functionality still works
4. Security scan if relevant
5. Performance check if relevant
```

**Update documentation:**
- Add to changelog
- Update relevant docs if behavior changed
- Add comments in code if complex fix

**GitHub integration (if issue from GitHub):**
```bash
# Comment on issue with fix details
gh issue comment ${issueNumber} --body "Fixed in commit ${commitHash}

Changes:
- [describe fix]

Testing:
- [tests added]

Verification:
- [how to verify]"

# Close issue
gh issue close ${issueNumber}
```

### User Communication

**Starting:**
```
🔍 Issue Resolution Workflow Started

Issue: ${issueDescription}

Phase 1/5: Analyzing issue...
  Identifying affected components...
  Determining severity: ${severity}
```

**Progress:**
```
✅ Phase 1/5: Analysis complete
   Root cause: Memory leak in event handler (handlers/websocket.py)
   Severity: High

📋 Phase 2/5: Creating resolution plan...
   ✅ Generated focused PRD

📋 Phase 3/5: Planning sprint...
   ✅ Created 2 resolution tasks
   ✅ Organized into sprint ISSUE_001_SPRINT-001

🔨 Phase 4/5: Executing sprint...
   Sprint 1/1: ISSUE_001_SPRINT-001

   Task 1/2: Investigate and fix root cause
      Investigating root cause...
      ✅ Found: Goroutine leak, missing context cancellation

      Implementing fix (T1 agent)...
      ✅ Added context.WithCancel()
      ✅ Added proper cleanup

      Running code review...
      ✅ Code review passed

   Task 2/2: Add regression tests
      Adding tests...
      ✅ Added regression test
      ✅ Test confirms fix works

   Running workflow compliance check...
   ✅ Workflow compliance verified

   ✅ Sprint complete

✅ Phase 5/5: Verification...
   ✅ All existing tests pass
   ✅ Issue resolved
   ✅ No regressions
```

**Completion:**
```
╔══════════════════════════════════════════╗
║  ✅ ISSUE RESOLVED  ✅                  ║
╚══════════════════════════════════════════╝

Issue: Memory leak in WebSocket handler

Resolution Summary:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Root Cause: Goroutine leak - missing cancellation
Fix: Added context.WithCancel() and cleanup
Impact: Prevents memory leak under load

Changes:
  • handlers/websocket.go (modified)
  • handlers/websocket_test.go (added tests)

Testing:
  • Added regression test
  • Verified fix with load test
  • All existing tests passing

Documentation:
  • Changelog updated
  • Code comments added

Ready to commit and deploy! 🚀

${githubIssueUrl ? `GitHub issue #${issueNumber} will be closed automatically.` : ''}

Next steps:
1. Review changes
2. Run additional manual tests if needed
3. Deploy to staging
4. Monitor for any issues
```

## Issue Type Handling

### Bug Fix (standard)
```
Workflow: Analyze → Plan → Create Sprint → Execute Sprint → Verify
Agents: sprint-orchestrator → task-orchestrator → Developer (T1/T2) → Reviewer → Validator
Sprint: Usually 1 sprint with 1-2 tasks
```

### Security Vulnerability (critical)
```
Workflow: Analyze → Plan → Create Sprint → Execute Sprint (T2) → Security audit → Verify
Agents: sprint-orchestrator → Developer T2 → Security auditor → Validator
Priority: IMMEDIATE
Sprint: 1 sprint, T2 agents used immediately
```

### Performance Issue
```
Workflow: Analyze → Profile → Plan → Create Sprint → Execute Sprint → Benchmark → Verify
Agents: sprint-orchestrator → Developer → Performance auditor → Validator
Include: Before/after benchmarks
Sprint: 1 sprint with profiling + optimization tasks
```

### Enhancement/Small Feature
```
(Consider using /multi-agent:feature instead for larger enhancements)
This command better for: Quick fixes, small improvements, single-component changes
Sprint: 1 sprint with 1-3 tasks
```

## Error Handling

**Cannot reproduce:**
```
⚠️  Could not reproduce issue

Steps taken:
1. Followed reproduction steps
2. Checked with multiple scenarios
3. Reviewed recent changes

Possible reasons:
- Issue may be environment-specific
- May require specific data/state
- May have been fixed in another change

Recommendation:
- Provide more details on reproduction
- Share logs/error messages
- Specify environment details
```

**Fix introduces regression:**
```
❌ Verification failed: Regression detected

Fix resolved original issue ✅
BUT broke existing functionality ❌

Failed test: test_user_authentication
Error: Login fails after fix

Rolling back and retrying with different approach...
```

**Complex issue needs decomposition:**
```
⚠️  Issue is complex, may require multiple changes

Issue affects:
- WebSocket handler (backend)
- React component (frontend)
- Database queries (performance)

Recommendation:
1. Use /multi-agent:issue for WebSocket fix (blocking)
2. Use /multi-agent:issue for React component separately
3. Use /multi-agent:feature for query optimization (larger scope)

Or proceed as single complex issue? (y/n)
```

## Advanced Usage

**With GitHub CLI:**
```
/multi-agent:issue https://github.com/myorg/myrepo/issues/456
(Automatically fetches details, closes issue when fixed)
```

**Security issue:**
```
/multi-agent:issue CRITICAL: SQL injection in /api/users endpoint
(System prioritizes, uses T2 agents, runs security audit)
```

**Performance issue:**
```
/multi-agent:issue API response time degraded from 200ms to 3000ms
(System profiles, identifies bottleneck, optimizes)
```

## Workflow Diagram

```
User: /multi-agent:issue Fix login timeout

    ↓
1. Analyze Issue
    ├── Identify affected code
    ├── Determine severity
    └── Find root cause
    ↓
2. Create Fix Plan (lightweight PRD)
    ↓
3. Create Tasks & Sprint
    ├── Break into tasks (task-graph-analyzer)
    ├── Organize into sprint (sprint-planner)
    └── Create state file for tracking
    ↓
4. Execute Sprint
    ├── Sprint orchestrator manages execution
    ├── For each task:
    │   ├── Developer (T1 or T2)
    │   ├── Code review
    │   ├── Security audit (if needed)
    │   ├── Performance audit (if needed)
    │   ├── Tests added
    │   └── Requirements validation
    ├── Workflow compliance check
    └── Runtime verification
    ↓
5. Verify
    ├── No regressions
    ├── Issue resolved
    └── All tests pass
    ↓
✅ Issue Resolved
    └── (Close GitHub issue if applicable)
```

## Cost Estimation

**Simple bug fix:**
- Analysis + plan: ~$0.30
- Implementation: ~$0.50-1.50
- Testing + review: ~$0.40
- **Total: ~$1-2**

**Complex bug fix:**
- Analysis + plan: ~$0.50
- Implementation: ~$2-5
- Testing + review: ~$1
- **Total: ~$4-7**

**Critical security fix:**
- Analysis: ~$0.70
- Implementation (T2): ~$3-6
- Security audit: ~$1.50
- Testing: ~$1
- **Total: ~$6-10**

Time saved: **80-90% vs manual debugging and fixing**
