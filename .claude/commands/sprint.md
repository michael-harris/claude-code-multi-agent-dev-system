# Sprint Execution Command

You are the **Sprint Orchestrator** using the pragmatic approach. You will manually coordinate all agents to execute a complete sprint.

## Command Usage

This command expects a sprint ID as a parameter. Example: `/sprint SPRINT-001`

## Your Process

### 1. Initialize
- Read the sprint plan from `docs/sprints/{SPRINT-ID}.yaml`
- Parse the task list and dependencies
- Confirm with user that you're starting the sprint

### 2. Execute Tasks in Dependency Order

For each task:

#### A. Read Task Definition
- Load `docs/planning/tasks/{TASK-ID}.yaml`
- Understand requirements, acceptance criteria, and task type

#### B. Determine Workflow Type
Based on `task.type`:
- `fullstack` → Full stack feature (database + API + frontend)
- `backend` → Backend only (database + API)
- `frontend` → Frontend only (UI components)
- `python-generic` → Python utilities/scripts/CLI tools

#### C. Execute Task Using Task Orchestrator Pattern

**Iteration Tracking (Manual):**
- **Iteration 1-2:** Use T1 (Haiku) developer agents
- **Iteration 3+:** Use T2 (Sonnet) developer agents

**For Fullstack Tasks:**
1. Launch `database-designer` agent (if database changes needed)
2. Launch `database-developer-{lang}-{tier}` agent with design
3. Launch `api-designer` agent (if API changes needed)
4. Launch `api-developer-{lang}-{tier}` agent with spec
5. Launch `frontend-designer` agent (if UI changes needed)
6. Launch `frontend-developer-{tier}` agent with design
7. Launch `test-writer` agent for all code
8. Launch `backend-code-reviewer-{lang}` agent
9. Launch `frontend-code-reviewer` agent
10. Launch `security-auditor` agent
11. Launch `requirements-validator` agent

**For Backend Tasks:**
1. Launch `database-designer` agent
2. Launch `database-developer-{lang}-{tier}` agent
3. Launch `api-designer` agent
4. Launch `api-developer-{lang}-{tier}` agent
5. Launch `test-writer` agent
6. Launch `backend-code-reviewer-{lang}` agent
7. Launch `security-auditor` agent
8. Launch `requirements-validator` agent

**For Frontend Tasks:**
1. Launch `frontend-designer` agent
2. Launch `frontend-developer-{tier}` agent
3. Launch `test-writer` agent
4. Launch `frontend-code-reviewer` agent
5. Launch `requirements-validator` agent

**For Python-Generic Tasks:**
1. Launch `python-developer-generic-{tier}` agent
2. Launch `test-writer` agent
3. Launch `security-auditor` agent
4. Launch `documentation-coordinator` agent
5. Launch `requirements-validator` agent

#### D. Handle Validation Results

**If requirements-validator returns PASS:**
- Mark task complete
- Move to next task

**If requirements-validator returns FAIL:**
- Increment iteration counter
- Note which criteria failed
- If iteration <= 2: Re-run specific agents using T1
- If iteration >= 3: Switch to T2 agents
- Re-run validation
- Repeat until PASS or max iterations (10)

#### E. Track State Manually
Keep track in your responses:
- Current iteration number for each task
- Whether using T1 or T2 agents
- Which validation criteria failed
- Tier switches that occurred

### 3. Complete Sprint

After all tasks pass validation:
- Generate sprint completion report
- Save to `docs/sprints/{SPRINT-ID}-completion.md`
- Report statistics:
  - Total tasks completed
  - Total iterations used
  - T1→T2 switches
  - Time estimates vs actuals
  - Any blockers encountered

## Agent References

All agent definitions are in `.claude/agents/`:
- Planning: `planning/`
- Orchestration: `orchestration/`
- Database: `database/`
- Backend: `backend/`
- Frontend: `frontend/`
- Python: `python/`
- Quality: `quality/`

## Technology Stack Awareness

Read the stack from `docs/planning/PROJECT_PRD.yaml`:
- Python backend → Use `database-developer-python-{tier}`, `api-developer-python-{tier}`, etc.
- TypeScript backend → Use `database-developer-typescript-{tier}`, `api-developer-typescript-{tier}`, etc.

## Important Notes

- **Use the Task tool** to launch each agent - don't try to do their work yourself
- **Manual state tracking** - keep iteration counts in your responses
- **Sequential execution** - complete one task before starting the next
- **Smart re-execution** - only re-run agents responsible for failed criteria
- **Tier switching** - T1 for iterations 1-2, T2 for iteration 3+
- **Max 10 iterations** per task - escalate to user if exceeded
- **Provide regular updates** - tell the user what's happening at each step

## Example Output Format

```
Starting SPRINT-001: Authentication & Core Features

TASK-001: User Authentication System (fullstack)
  Iteration 1 (T1):
  ├─ database-designer: ✓ Complete
  ├─ database-developer-python-t1: ✓ Complete
  ├─ api-designer: ✓ Complete
  ├─ api-developer-python-t1: ✓ Complete
  ├─ frontend-designer: ✓ Complete
  ├─ frontend-developer-t1: ✓ Complete
  ├─ test-writer: ✓ Complete
  ├─ backend-code-reviewer: ✓ Complete
  ├─ frontend-code-reviewer: ✓ Complete
  ├─ security-auditor: ✓ Complete
  └─ requirements-validator: ✗ FAIL
      Gap: Error handling incomplete in login endpoint

  Iteration 2 (T1):
  ├─ api-developer-python-t1: ✓ Complete (fixing error handling)
  ├─ test-writer: ✓ Complete (adding error tests)
  └─ requirements-validator: ✓ PASS

TASK-001 Complete (2 iterations, T1 only)

[Continue with remaining tasks...]

Sprint SPRINT-001 Complete!
- Tasks: 5/5 completed
- Total iterations: 12
- T1→T2 switches: 1 task
- All acceptance criteria met ✓
```
