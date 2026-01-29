# DevTeam Sprint Command

**Command:** `/devteam:sprint <sprint-id>`

Execute a specific sprint manually.

## Usage

```bash
/devteam:sprint SPRINT-001           # Execute first sprint
/devteam:sprint SPRINT-002           # Execute second sprint
/devteam:sprint all                  # Execute all sprints (same as /devteam:auto)
```

## Your Process

### Step 1: Load Sprint Definition

```yaml
# Read from docs/sprints/SPRINT-001.yaml
id: SPRINT-001
name: "Foundation"
goal: "Set up project infrastructure and core models"

tasks:
  - TASK-001
  - TASK-002
  - TASK-003

estimated_complexity: 12
```

### Step 2: Check State

Read `.devteam/state.yaml`:
- If sprint status = "completed": notify user and exit
- If sprint status = "in_progress": resume from last incomplete task
- If sprint status = "pending": start fresh

### Step 3: Execute Tasks

For each task in sprint (respecting order):

```javascript
// Load task definition
const task = loadTask(taskId)

// Check state
if (state.tasks[taskId].status === 'completed') {
  log(`Task ${taskId} already complete, skipping`)
  continue
}

// Select model based on complexity
const model = selectModel(task.complexity)

// Execute task
Task({
  subagent_type: "task-orchestrator",
  model: model,
  prompt: `Execute task ${taskId}:

    Task: ${task.title}
    Description: ${task.description}
    Acceptance criteria: ${task.acceptance_criteria}

    1. Implement the task
    2. Run tests
    3. Code review
    4. Update state when complete`
})

// Update state
state.tasks[taskId].status = 'completed'
saveState()
```

### Step 4: Quality Gates

After all tasks complete:

1. Run all tests
2. Run linting/type checking
3. Code review for sprint changes
4. Update documentation
5. Generate sprint report

### Step 5: Update State

```yaml
sprints:
  SPRINT-001:
    status: completed
    started_at: "2025-01-28T10:00:00Z"
    completed_at: "2025-01-28T12:30:00Z"
    tasks_completed: 3
    tasks_total: 3
    quality_gates_passed: true
```

## User Communication

**Starting:**
```
═══════════════════════════════════════
Sprint: SPRINT-001 (Foundation)
═══════════════════════════════════════

Goal: Set up project infrastructure and core models
Tasks: 3 total
Estimated complexity: 12

Starting execution...
```

**Progress:**
```
Task 1/3: TASK-001 (Database schema)
  Complexity: 4/14 (simple)
  Model: haiku
  Status: ✅ Complete

Task 2/3: TASK-002 (API endpoints)
  Complexity: 6/14 (moderate)
  Model: sonnet
  Status: In progress...
```

**Completion:**
```
╔══════════════════════════════════════════╗
║  ✅ SPRINT-001 COMPLETE                  ║
╚══════════════════════════════════════════╝

Tasks: 3/3 complete
Time: 2h 30m
Model usage: Haiku 1, Sonnet 2

Quality Gates:
  ✅ All tests pass
  ✅ Type checking pass
  ✅ Code review complete
  ✅ Documentation updated

Next sprint: SPRINT-002 (Core Features)
Run: /devteam:sprint SPRINT-002
```

## Error Handling

**Task fails repeatedly:**
```
⚠️ Task TASK-002 failed after 2 attempts

Attempt 1 (haiku): Type errors
Attempt 2 (sonnet): Logic error in validation

Escalating to opus for complex debugging...
```

**Sprint blocked:**
```
❌ Sprint cannot continue

Blocking issue: TASK-003 depends on external API
Error: API endpoint returns 404

Manual intervention required.
Fix the issue and run: /devteam:sprint SPRINT-001
(Will resume from TASK-003)
```
