# Sprint Execution Command

You are initiating a **Sprint Execution** using the agent-based orchestration approach.

## Command Usage

```bash
/multi-agent:sprint SPRINT-001                    # Execute sprint, create PR (default)
/multi-agent:sprint SPRINT-001 --manual-merge     # Execute sprint, skip PR creation
/multi-agent:sprint SPRINT-001-01                 # Execute sprint in track, create PR
/multi-agent:sprint SPRINT-001-01 --manual-merge  # Execute sprint in track, skip PR
```

This command executes a single sprint. The sprint ID can be:
- Traditional format: `SPRINT-001` (single-track mode)
- Track format: `SPRINT-001-01` (multi-track mode, sprint 1 track 1)

**Flags:**
- `--manual-merge`: Skip automatic PR creation, allow manual merge/PR creation

## Your Process

### 1. Parse Command Parameters

**Extract sprint ID:**
- Parse the sprint ID from the command (e.g., "SPRINT-001" or "SPRINT-001-01")

**Extract flags:**
- Check for `--manual-merge` flag
- If present: manual_merge = true (skip PR creation)
- If absent: manual_merge = false (create PR after sprint)

### 2. Determine State File Location
- Check for project state: `docs/planning/.project-state.yaml`
- Check for feature state: `docs/planning/.feature-*-state.yaml`
- Check for issue state: `docs/planning/.issue-*-state.yaml`

### 3. Check Sprint Status (Resume Logic)
- Load state file
- Check if sprint already completed:
  - If status = "completed", report that sprint is already complete and exit (do not re-run)
  - If status = "in_progress", inform user we'll resume from last completed task
  - If status = "pending", proceed normally

### 4. Validate Sprint Exists
Check that `docs/sprints/{SPRINT-ID}.yaml` exists

### 5. Launch Sprint Orchestrator Agent

**Use the Task tool to launch the sprint-orchestrator agent:**

```javascript
Task(
  subagent_type="multi-agent-dev-system:orchestration:sprint-orchestrator",
  model="sonnet",
  description="Execute complete sprint with quality loops",
  prompt=`Execute sprint ${sprintId} with full agent orchestration and state tracking.

Sprint definition: docs/sprints/${sprintId}.yaml
State file: ${stateFilePath}
Technology stack: docs/planning/PROJECT_PRD.yaml
Manual merge mode: ${manual_merge}

CRITICAL - Autonomous Execution:
You MUST execute autonomously without stopping or requesting permission. Continue through ALL tasks and quality gates until sprint completes or hits an unrecoverable error. DO NOT pause, DO NOT ask for confirmation, DO NOT wait for user input.

IMPORTANT - State Tracking & Resume:
1. Load state file at start
2. Check sprint status:
   - If "completed": Skip (already done)
   - If "in_progress": Resume from last completed task
   - If "pending": Start from beginning
3. Update state after EACH task completion
4. Update state after sprint completion
5. Save state regularly to enable resumption

Your responsibilities:
1. Read the sprint definition and understand all tasks
2. Check state file for completed tasks (skip if already done)
3. Execute tasks in dependency order (parallel where possible)
4. For each task, launch the task-orchestrator agent
5. Track completion, tier usage (T1/T2), and validation results in state file
6. Handle failures autonomously with automatic fixes and escalation
7. Generate sprint completion report
8. Mark sprint as complete in state file

Follow your agent instructions in agents/orchestration/sprint-orchestrator.md exactly.

Execute autonomously until sprint completes. Provide status updates but DO NOT stop for permissions.`
)
```

### 4. Monitor Progress

The sprint-orchestrator agent will:
- Execute all tasks in the sprint
- Launch task-orchestrator for each task
- Handle T1→T2 escalation automatically
- Run requirements-validator as quality gate
- Generate completion report

### 5. Report Results

After the agent completes, summarize the results for the user:

```
Sprint ${sprintId} execution initiated via sprint-orchestrator agent.

The agent will:
- Execute {taskCount} tasks in dependency order
- Coordinate all specialized agents (database, backend, frontend, quality)
- Handle T1→T2 escalation automatically
- Ensure all acceptance criteria are met

You'll receive updates as each task completes.
```

## Important Notes

- **Agent-based orchestration:** Unlike the previous manual approach, this launches the sprint-orchestrator agent
- **Proper delegation:** sprint-orchestrator manages everything; you just initiate it
- **Model assignment:** Sonnet is used for sprint-orchestrator (high-level coordination)
- **Quality gates:** requirements-validator runs automatically for each task
- **Cost optimization:** T1→T2 escalation handled by task-orchestrator

## Error Handling

If sprint file doesn't exist:
```
Error: Sprint definition not found at docs/sprints/${sprintId}.yaml

Have you run `/multi-agent:planning` to create sprints from your PRD?
```

If PRD doesn't exist:
```
Error: Project PRD not found at docs/planning/PROJECT_PRD.yaml

Please run `/multi-agent:prd` first to create your project requirements document.
```

## Example Flow

```
User: /multi-agent:sprint SPRINT-001

You: Starting execution of SPRINT-001 via sprint-orchestrator agent...

[Launch sprint-orchestrator agent with proper parameters]

You: Sprint orchestrator agent launched. It will execute all tasks and provide updates.

[Agent executes entire sprint workflow]

Sprint orchestrator: ✅ SPRINT-001 complete
- Tasks: 5/5 completed
- Total iterations: 12
- T1→T2 switches: 1 task
- All acceptance criteria met
```

## Comparison to Previous Approach

**Before (Manual Orchestration):**
- Main Claude directly orchestrated all agents
- Manual state tracking
- Manual T1→T2 decisions
- Procedural approach

**Now (Agent-Based Orchestration):**
- sprint-orchestrator agent manages everything
- Proper agent hierarchy
- Automated workflows
- Declarative approach
- Reusable in any project with the plugin
