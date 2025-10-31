# Sprint All Command

You are orchestrating **multi-sprint execution** using the agent-based approach.

## Command Usage

```bash
/multi-agent:sprint all        # Execute all sprints (all tracks) sequentially
/multi-agent:sprint all 01     # Execute all sprints in track 1 only
/multi-agent:sprint all 02     # Execute all sprints in track 2 only
/multi-agent:sprint all 03     # Execute all sprints in track 3 only
```

Executes all sprints sequentially until completion. Supports track filtering for parallel development workflows.

## Your Process

### Step 0: Parse Parameters

Extract track number from command (if specified):
- If no parameter: execute all tracks sequentially
- If parameter (e.g., "01", "02"): execute only that track

### Step 1: Load State File

**Determine state file location:**
- Check `docs/planning/.project-state.yaml`
- Check `docs/planning/.feature-*-state.yaml`
- Check `docs/planning/.issue-*-state.yaml`

**If state file doesn't exist:**
- Create initial state file with all sprints marked "pending"
- Initialize track configuration from sprint files

**If state file exists:**
- Load current progress
- Identify completed vs pending sprints
- Determine resume point

### Step 2: Project State Analysis

**Check Sprint Files:**
```bash
ls docs/sprints/
```

**Filter by track (if specified):**
- If track specified: filter to only sprints matching that track
- Example: track=01 → only `SPRINT-*-01.yaml` files

**Determine Sprint Status from State File:**
- For each sprint in scope:
  - Check state.sprints[sprintId].status
  - "completed" → skip
  - "in_progress" → resume from last completed task
  - "pending" → execute normally
- Count total sprints to execute vs already completed

**Check PRD Exists:**
- Verify `docs/planning/PROJECT_PRD.yaml` exists (or feature/multi-agent:issue PRD)
- If missing, instruct user to run `/multi-agent:prd` first

**Resume Point Determination:**
```python
# Pseudocode
if track_specified:
    sprints_in_track = filter(sprint for sprint in state.sprints if sprint.track == track_number)
    resume_sprint = find_first_non_completed(sprints_in_track)
else:
    resume_sprint = find_first_non_completed(state.sprints)

if resume_sprint:
    print(f"Resuming from {resume_sprint} (previous sprints already complete)")
else:
    print("All sprints already complete!")
    return
```

### 3. Sequential Sprint Execution

For each sprint in scope (filtered by track if specified):

**Skip if already completed:**
- Check state file: if sprint status = "completed", skip to next sprint
- Log: "SPRINT-XXX-YY already completed. Skipping."

**Execute if pending or in_progress:**

```javascript
Task(
  subagent_type="multi-agent-dev-system:orchestration:sprint-orchestrator",
  model="sonnet",
  description=`Execute sprint ${sprintId} with full quality gates`,
  prompt=`Execute sprint ${sprintId} completely with state tracking.

Sprint definition: docs/sprints/${sprintId}.yaml
State file: ${stateFilePath}
PRD reference: docs/planning/PROJECT_PRD.yaml or FEATURE_*_PRD.yaml

IMPORTANT - State Tracking:
1. Load state file at start
2. Check sprint and task status
3. Skip completed tasks (resume from last incomplete task)
4. Update state after EACH task completion
5. Update state after sprint completion
6. Save state regularly

Your responsibilities:
1. Read sprint definition
2. Load state and check for resume point
3. Execute tasks in dependency order (skip completed tasks)
4. Run task-orchestrator for each task
5. Track completion and tier usage in state file
6. Run FULL final code review (code, security, performance)
7. Update documentation
8. Generate sprint completion report
9. Mark sprint as completed in state file

Continue to next sprint only if THIS sprint completes successfully.

Provide updates at each task completion and final summary.`
)
```

**Between Sprints:**
- Verify previous sprint completed successfully (check state file)
- Check all quality gates passed
- Confirm no critical issues remaining
- State file automatically updated
- Brief pause to log progress

### 3. Final Project Review (After All Sprints)

**After final sprint completes, run comprehensive project-level review:**

**Step 1: Detect All Languages Used**
- Scan entire codebase
- Identify all programming languages

**Step 2: Comprehensive Code Review**
- Call code reviewer for each language
- Review cross-sprint consistency
- Check for duplicate code
- Verify consistent coding standards

**Step 3: Comprehensive Security Audit**
- Call quality:security-auditor
- Review OWASP Top 10 across entire project
- Check authentication/authorization across features
- Verify no secrets in code
- Review all API endpoints for security

**Step 4: Comprehensive Performance Audit**
- Call performance auditor for each language
- Review database schema and indexes
- Check API performance across all endpoints
- Review frontend bundle size and performance
- Identify system-wide bottlenecks

**Step 5: Integration Testing Verification**
- Verify all features work together
- Check cross-feature integrations
- Test complete user workflows
- Verify no regressions

**Step 6: Final Documentation Review**
- Call quality:documentation-coordinator
- Verify comprehensive README
- Check all API documentation complete
- Verify architecture docs accurate
- Ensure deployment guide complete
- Generate project completion report

**Step 7: Issue Resolution (if needed)**
- If critical/major issues found:
  * Call appropriate T2 developers
  * Fix all issues
  * Re-run affected audits
- Max 2 iterations before escalation

### 4. Generate Project Completion Report

```yaml
project_status: COMPLETE | NEEDS_WORK

sprints_completed: 5/5

overall_statistics:
  total_tasks: 47
  tasks_completed: 47
  t1_tasks: 35 (74%)
  t2_tasks: 12 (26%)
  total_iterations: 89

quality_metrics:
  code_reviews: PASS
  security_audit: PASS
  performance_audit: PASS
  documentation: COMPLETE

issues_summary:
  critical_fixed: 3
  major_fixed: 8
  minor_documented: 12

languages_used:
  - Python (FastAPI backend)
  - TypeScript (React frontend)
  - PostgreSQL (database)

features_delivered:
  - User authentication
  - Task management
  - Real-time notifications
  - Analytics dashboard
  - API integrations

documentation_updated:
  - README.md (comprehensive)
  - API documentation (OpenAPI)
  - Architecture diagrams
  - Deployment guide
  - User guide

estimated_cost: $45.30
estimated_time_saved: 800 hours vs manual development

recommendations:
  - Consider adding rate limiting for API
  - Monitor database query performance under load
  - Schedule security audit for production deployment

next_steps:
  - Review completion report
  - Run integration tests
  - Deploy to staging environment
  - Schedule production deployment
```

### 5. User Communication

**During Execution:**
```
Starting multi-sprint execution...

Found 5 sprints in docs/sprints/
Starting from SPRINT-001

═══════════════════════════════════════
Sprint 1/5: SPRINT-001 (Foundation)
═══════════════════════════════════════
Launching sprint-orchestrator...
[sprint-orchestrator executes with updates]
✅ SPRINT-001 complete (8 tasks, 45 min)

═══════════════════════════════════════
Sprint 2/5: SPRINT-002 (Core Features)
═══════════════════════════════════════
Launching sprint-orchestrator...
...

═══════════════════════════════════════
All Sprints Complete! Running final review...
═══════════════════════════════════════

Running comprehensive code review...
Running security audit...
Running performance audit...
Updating final documentation...

✅ PROJECT COMPLETE!
```

**On Completion:**
```
╔═══════════════════════════════════════════╗
║  🎉 PROJECT COMPLETION SUCCESSFUL  🎉    ║
╚═══════════════════════════════════════════╝

Sprints Completed: 5/5
Tasks Delivered: 47/47
Quality: All checks passed ✅
Documentation: Complete ✅

Cost Estimate: $45.30
Time Saved: ~800 hours

See full report: docs/project-completion-report.md

Ready for deployment! 🚀
```

## Error Handling

**Sprint fails:**
```
❌ SPRINT-003 failed after 3 fix attempts

Issue: Critical security vulnerability in authentication
Location: backend/auth/jwt_handler.py

Pausing multi-sprint execution.
Human intervention required.

To resume after fix: /multi-agent:sprint all
(Will skip completed sprints automatically)
```

**No sprints found:**
```
Error: No sprint files found in docs/sprints/

Have you run /multi-agent:planning to create sprints?

Workflow:
1. /multi-agent:prd          - Create PRD
2. /multi-agent:planning     - Break into tasks and sprints
3. /multi-agent:sprint all   - Execute all sprints
```

## Important Notes

- Each sprint MUST complete successfully before next sprint starts
- Final project review is MANDATORY after all sprints
- Documentation is updated continuously (per sprint) and finally (project-level)
- All quality gates must pass before marking project complete
- Execution can be paused/resumed (picks up from last completed sprint)
- Detailed logs generated for each sprint and overall project
- Cost tracking across all sprints for transparency

## Comparison to Single Sprint

**`/multi-agent:sprint SPRINT-001`:**
- Executes one sprint
- Final review for that sprint
- Documentation updated for that sprint

**`/multi-agent:sprint all`:**
- Executes ALL sprints sequentially
- Final review for each sprint
- Additional project-level review at the end
- Comprehensive documentation at project completion
- Full integration testing verification
