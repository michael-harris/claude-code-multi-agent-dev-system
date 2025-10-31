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
  subagent_type="multi-agent-dev-system:planning:prd-generator",
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

### Phase 3: Task Creation

**Create single task (most issues are 1 task):**

```javascript
Task(
  subagent_type="multi-agent-dev-system:planning:task-graph-analyzer",
  model="sonnet",
  description="Create issue resolution task",
  prompt=`Create task for issue resolution:

Issue PRD: docs/planning/ISSUE_${issueId}_PRD.yaml

Create task: docs/planning/tasks/ISSUE-${issueId}-001.yaml

Task should include:
- Investigate and identify root cause
- Implement fix
- Add/update tests
- Verify no regressions

If issue is complex, create multiple tasks with dependencies.
`
)
```

### Phase 4: Execute Fix

**Launch task orchestrator:**
```javascript
Task(
  subagent_type="multi-agent-dev-system:orchestration:task-orchestrator",
  model="sonnet",
  description="Execute issue fix",
  prompt=`Execute issue resolution:

Task: docs/planning/tasks/ISSUE-${issueId}-001.yaml

Workflow:
1. Investigate root cause (use appropriate language developer)
2. Implement fix (T1 first, escalate to T2 if needed)
3. Run code reviewer
4. Run security auditor (if security issue)
5. Run performance auditor (if performance issue)
6. Add tests to prevent regression
7. Verify fix with requirements validator

Use T2 agents directly if:
- Critical severity
- Security vulnerability
- Complex root cause
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

Phase 1/4: Analyzing issue...
  Identifying affected components...
  Determining severity: ${severity}
```

**Progress:**
```
✅ Phase 1: Analysis complete
   Root cause: Memory leak in event handler (handlers/websocket.py)
   Severity: High

📋 Phase 2: Creating resolution plan...
   ✅ Generated focused PRD
   ✅ Created fix task

🔨 Phase 3: Implementing fix...
   Investigating root cause...
   ✅ Found: Goroutine leak, missing context cancellation

   Implementing fix (T1 agent)...
   ✅ Added context.WithCancel()
   ✅ Added proper cleanup

   Running code review...
   ✅ Code review passed

   Adding tests...
   ✅ Added regression test
   ✅ Test confirms fix works

✅ Phase 4: Verification...
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
Workflow: Analyze → Fix → Test → Verify
Agents: Appropriate developer (T1/T2) → Reviewer → Validator
```

### Security Vulnerability (critical)
```
Workflow: Analyze → Fix (T2) → Security audit → Deploy urgently
Agents: Developer T2 → Security auditor → Validator
Priority: IMMEDIATE
```

### Performance Issue
```
Workflow: Profile → Optimize → Benchmark → Verify
Agents: Developer → Performance auditor → Validator
Include: Before/after benchmarks
```

### Enhancement/Small Feature
```
(Consider using /multi-agent:feature instead)
This command better for: Quick fixes, small improvements
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
3. Implement Fix
    ├── Developer (T1 or T2)
    ├── Code review
    ├── Tests added
    └── Validation
    ↓
4. Verify
    ├── No regressions
    ├── Issue resolved
    └── Tests pass
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
