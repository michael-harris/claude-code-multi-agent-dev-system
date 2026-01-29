# Parallel Task Execution

DevTeam supports running up to 3 tasks concurrently to speed up development.

## How It Works

### Task Eligibility

A task can run in parallel if:
1. It has no pending dependencies
2. It doesn't modify shared resources
3. It's not marked as sequential

### Parallel Groups

Tasks with the same `parallel_group` can run together:

```yaml
tasks:
  TASK-001:
    parallel_eligible: true
    parallel_group: 1
    dependencies: []  # No dependencies

  TASK-002:
    parallel_eligible: true
    parallel_group: 1
    dependencies: []  # No dependencies

  TASK-003:
    parallel_eligible: false  # Sequential
    dependencies: [TASK-001, TASK-002]
```

### Task Types for Parallelization

**Parallelizable (typically safe):**
- Testing (unit tests, integration tests)
- Documentation
- Frontend components (independent)
- Backend endpoints (independent)

**Sequential (must run alone):**
- Database migrations
- Security changes
- Deployment
- Shared configuration changes

## Execution Model

### Slot-Based Execution

```
┌─────────────────────────────────────────┐
│         Parallel Execution Slots        │
├─────────────────────────────────────────┤
│                                         │
│   Slot 1: [TASK-001] ████████░░ 80%     │
│   Slot 2: [TASK-002] ██████████ 100% ✓  │
│   Slot 3: [TASK-003] █████░░░░░ 50%     │
│                                         │
│   Queue: TASK-004, TASK-005, TASK-006   │
│                                         │
└─────────────────────────────────────────┘
```

### State Tracking

```yaml
parallel_execution:
  enabled: true
  max_concurrent: 3

  active_slots:
    - slot: 1
      task: TASK-001
      started_at: "2025-01-28T10:00:00Z"
      status: running
      model: sonnet

    - slot: 2
      task: TASK-002
      started_at: "2025-01-28T10:00:00Z"
      status: completed
      model: haiku

    - slot: 3
      task: TASK-003
      started_at: "2025-01-28T10:05:00Z"
      status: running
      model: sonnet

  queue:
    - TASK-004
    - TASK-005

  completed_this_round:
    - TASK-002
```

## Scheduling Algorithm

```python
def schedule_next_task(state):
    # Get available slots
    available_slots = [
        slot for slot in state.active_slots
        if slot.status in ['idle', 'completed']
    ]

    if not available_slots:
        return None  # All slots busy

    # Find eligible task from queue
    for task_id in state.queue:
        task = state.tasks[task_id]

        # Check dependencies
        deps_met = all(
            state.tasks[dep].status == 'completed'
            for dep in task.dependencies
        )

        if deps_met and task.parallel_eligible:
            return (available_slots[0], task_id)

    # Check for sequential task if no parallel tasks ready
    for task_id in state.queue:
        task = state.tasks[task_id]
        deps_met = all(
            state.tasks[dep].status == 'completed'
            for dep in task.dependencies
        )

        if deps_met and not any_slots_running():
            return (available_slots[0], task_id)

    return None
```

## Conflict Prevention

### File Lock Tracking

Track which files are being modified:

```yaml
file_locks:
  "src/models/user.py":
    task: TASK-001
    locked_at: "2025-01-28T10:00:00Z"

  "src/routes/auth.py":
    task: TASK-003
    locked_at: "2025-01-28T10:05:00Z"
```

### Conflict Detection

Before starting a task, check for conflicts:

```python
def can_start_task(task, state):
    task_files = task.files_affected  # From task definition

    for file in task_files:
        if file in state.file_locks:
            return False, f"File locked by {state.file_locks[file].task}"

    return True, None
```

## Configuration

In `.devteam/config.yaml`:

```yaml
parallel:
  enabled: true
  max_concurrent_tasks: 3

  # Task types that can run in parallel
  parallelizable:
    - testing
    - documentation
    - frontend
    - backend  # Only if no shared state

  # Task types that must run sequentially
  sequential:
    - database_migration
    - security
    - deployment
```

## User Communication

```
═══════════════════════════════════════
Parallel Execution: 3 tasks running
═══════════════════════════════════════

[Slot 1] TASK-001: User authentication
         Status: Testing (iteration 2)
         Model: sonnet

[Slot 2] TASK-002: Profile API
         Status: Complete ✓
         Model: haiku

[Slot 3] TASK-003: Settings page
         Status: Implementation
         Model: haiku

Queue: 2 tasks waiting
Next: TASK-004 (blocked by TASK-001)
```

## Benefits

- **Faster execution:** Up to 3x speedup for parallelizable work
- **Better resource utilization:** Don't wait for independent tasks
- **Automatic scheduling:** Dependencies respected automatically
- **Safe:** File locking prevents conflicts

## Limitations

- Max 3 concurrent tasks (prevents context overload)
- Shared resource tasks must be sequential
- Additional complexity in state management
- Not all task types can parallelize
