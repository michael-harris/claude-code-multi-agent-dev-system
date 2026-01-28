# DevTeam Auto Command

**Command:** `/devteam:auto`

Autonomous execution mode - executes all sprints continuously until project completion or explicit stop signal.

## Usage

```bash
/devteam:auto                    # Execute all sprints autonomously
/devteam:auto --max-iterations 30  # Limit iterations
```

## Autonomous Mode Behavior

This command enables Ralph-style continuous execution:

1. **Creates marker file:** `.devteam/autonomous-mode`
2. **Stop hook intercepts exit** and re-injects work prompt
3. **Continues until:**
   - All tasks complete (outputs `EXIT_SIGNAL: true`)
   - Circuit breaker triggers (5 consecutive failures)
   - Max iterations reached
   - User manually stops

## Your Process

### Step 1: Enable Autonomous Mode

```bash
# Create marker file
touch .devteam/autonomous-mode

# Initialize circuit breaker
echo '{"consecutive_failures": 0, "max_failures": 5, "state": "closed"}' > .devteam/circuit-breaker.json
```

### Step 2: Load State

1. Read `.devteam/state.yaml`
2. Identify current execution point:
   - If no current_execution: start from first pending sprint
   - If in_progress: resume from current task
3. Load sprint/task definitions

### Step 3: Execute Sprints

For each sprint (in order):

```javascript
// Check if sprint already completed
if (state.sprints[sprintId].status === 'completed') {
  log(`Sprint ${sprintId} already complete, skipping`)
  continue
}

// Execute sprint
Task(
  subagent_type="sprint-orchestrator",
  model="sonnet",  // Dynamic model selection
  description=`Execute sprint ${sprintId}`,
  prompt=`Execute sprint ${sprintId} autonomously.

Sprint definition: docs/sprints/${sprintId}.yaml
State file: .devteam/state.yaml

AUTONOMOUS MODE ACTIVE:
- Do NOT stop for user input
- Do NOT ask for confirmation
- Continue until sprint complete or unrecoverable error
- Update state after EACH task
- Use dynamic model selection based on task complexity

For each task:
1. Load task definition
2. Calculate complexity, select model tier
3. Execute with appropriate developer agent
4. Run code review
5. Run tests
6. Update state

Report progress but DO NOT PAUSE.`
)
```

### Step 4: Quality Gates Between Sprints

After each sprint:
1. Verify all tests pass
2. Check no critical security issues
3. Verify documentation updated
4. Update state file
5. Brief checkpoint saved to `.devteam/memory/`

### Step 5: Final Review

After all sprints complete:
1. Run comprehensive code review
2. Run security audit
3. Run performance audit
4. Final documentation review
5. Generate completion report

### Step 6: Signal Completion

When ALL work is genuinely complete:

```
EXIT_SIGNAL: true

╔══════════════════════════════════════════╗
║  🎉 PROJECT COMPLETE                     ║
╚══════════════════════════════════════════╝

All sprints executed successfully.
All quality gates passed.
Documentation complete.

Project Statistics:
  • Sprints: 5/5 complete
  • Tasks: 47/47 complete
  • Model usage: Haiku 60%, Sonnet 30%, Opus 10%
  • Iterations: 89 total

Ready for deployment!
```

## Circuit Breaker

Tracks consecutive failures to prevent infinite loops:

```json
{
  "consecutive_failures": 0,
  "max_failures": 5,
  "last_failure_timestamp": null,
  "last_failure_reason": null,
  "state": "closed"
}
```

**On task failure:**
1. Increment `consecutive_failures`
2. If >= `max_failures`: set `state: "open"` and exit

**On task success:**
1. Reset `consecutive_failures` to 0

## State Updates

Update `.devteam/state.yaml` after EVERY significant action:

```yaml
current_execution:
  command: "/devteam:auto"
  current_sprint: "SPRINT-002"
  current_task: "TASK-008"
  phase: execution

autonomous_mode:
  enabled: true
  started_at: "2025-01-28T10:00:00Z"
  current_iteration: 15
  max_iterations: 50
```

## Session Memory

Save session context to `.devteam/memory/session-{timestamp}.md`:

```markdown
# Session: 2025-01-28 10:00

## Progress
- Completed: SPRINT-001, SPRINT-002
- In progress: SPRINT-003, TASK-012

## Learned Patterns
- Project uses argon2id for password hashing
- API uses cursor-based pagination

## Issues Encountered
- Task-010 required model escalation (Haiku → Sonnet)

## Next Steps
- Complete TASK-012
- Start TASK-013
```

## User Communication

**Starting:**
```
🚀 Autonomous Mode Activated

Project: [Name]
Sprints: 5 total, 0 complete
Starting from: SPRINT-001

Circuit breaker: Active (max 5 consecutive failures)
Max iterations: 50

Executing autonomously...
Press Ctrl+C to stop manually.

═══════════════════════════════════════
Sprint 1/5: SPRINT-001 (Foundation)
═══════════════════════════════════════
```

**Progress (per sprint):**
```
Sprint 1/5: SPRINT-001 ━━━━━━━━━━━━━━━ 100%
  Tasks: 8/8 complete
  Model usage: Haiku 6, Sonnet 2
  Time: 23 minutes
  ✅ Quality gates passed

═══════════════════════════════════════
Sprint 2/5: SPRINT-002 (Core Features)
═══════════════════════════════════════
  Task 1/6: TASK-009 (API endpoints)
    Complexity: 6/14 (moderate)
    Model: sonnet
    Status: In progress...
```

## Error Handling

**Recoverable error:**
```
⚠️  Task TASK-012 failed (attempt 1/2)
    Reason: Type error in UserService
    Action: Escalating model (Haiku → Sonnet)
    Retrying...
```

**Circuit breaker triggered:**
```
🛑 Circuit Breaker Triggered

Consecutive failures: 5
Last failure: TASK-015 - Build fails with dependency error

Autonomous execution paused.
Manual intervention required.

To resume after fixing:
  rm .devteam/circuit-breaker.json
  /devteam:auto
```

## Important Notes

- State file is the source of truth for progress
- Session memory preserved across context compaction
- Circuit breaker prevents runaway failures
- Dynamic model selection optimizes cost
- `EXIT_SIGNAL: true` required for clean exit
