# Sprint All Command

You are orchestrating **multi-sprint execution** using the agent-based approach.

## Command Usage

`/sprint all` - Executes all sprints sequentially until project completion

## Your Process

### 1. Project State Analysis

**Check Sprint Files:**
```bash
ls docs/sprints/
```

**Determine Sprint Status:**
- Read each `SPRINT-XXX.yaml` file
- Check for completion markers (if any)
- Identify which sprint to start from
- Count total sprints to execute

**Check PRD Exists:**
- Verify `docs/planning/PROJECT_PRD.yaml` exists
- If missing, instruct user to run `/prd` first

### 2. Sequential Sprint Execution

For each sprint (SPRINT-001, SPRINT-002, etc.):

```javascript
Task(
  subagent_type="multi-agent-dev-system:orchestration:sprint-orchestrator",
  model="opus",
  description=`Execute sprint ${sprintId} with full quality gates`,
  prompt=`Execute sprint ${sprintId} completely.

Sprint definition: docs/sprints/${sprintId}.yaml
PRD reference: docs/planning/PROJECT_PRD.yaml

Your responsibilities:
1. Read sprint definition
2. Execute all tasks in dependency order
3. Run task-orchestrator for each task
4. Track completion and tier usage
5. Run FULL final code review (code, security, performance)
6. Update documentation
7. Generate sprint completion report

Continue to next sprint only if THIS sprint completes successfully.

Provide updates at each task completion and final summary.`
)
```

**Between Sprints:**
- Verify previous sprint completed successfully
- Check all quality gates passed
- Confirm no critical issues remaining
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

To resume after fix: /sprint all
(Will skip completed sprints automatically)
```

**No sprints found:**
```
Error: No sprint files found in docs/sprints/

Have you run /planning to create sprints?

Workflow:
1. /prd          - Create PRD
2. /planning     - Break into tasks and sprints
3. /sprint all   - Execute all sprints
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

**`/sprint SPRINT-001`:**
- Executes one sprint
- Final review for that sprint
- Documentation updated for that sprint

**`/sprint all`:**
- Executes ALL sprints sequentially
- Final review for each sprint
- Additional project-level review at the end
- Comprehensive documentation at project completion
- Full integration testing verification
