# Progress Tracking & Parallel Development Design

## Overview

This document describes the progress tracking and parallel development track system for the multi-agent development framework.

## Progress Tracking State

### State File Location

Progress is tracked in YAML state files:
- **Project-level**: `docs/planning/.project-state.yaml`
- **Feature-level**: `docs/planning/.feature-{featureId}-state.yaml`
- **Issue-level**: `docs/planning/.issue-{issueId}-state.yaml`

### State File Schema

```yaml
version: "1.0"
type: project | feature | issue
created_at: "2025-10-31T10:00:00Z"
updated_at: "2025-10-31T12:30:00Z"

# Parallel development configuration
parallel_tracks:
  enabled: true
  total_tracks: 3
  max_possible_tracks: 5  # Based on dependency analysis

# Task completion tracking
tasks:
  TASK-001:
    status: completed
    completed_at: "2025-10-31T10:30:00Z"
    tier_used: T1
    iterations: 2
  TASK-002:
    status: completed
    completed_at: "2025-10-31T11:00:00Z"
    tier_used: T2
    iterations: 3
  TASK-003:
    status: in_progress
    started_at: "2025-10-31T12:00:00Z"
    tier_used: T1
    iterations: 1

# Sprint completion tracking
sprints:
  SPRINT-001-01:  # Sprint 1, Track 1
    status: completed
    completed_at: "2025-10-31T11:30:00Z"
    tasks_completed: 5
    tasks_total: 5
    track: 1
  SPRINT-001-02:  # Sprint 1, Track 2
    status: in_progress
    started_at: "2025-10-31T12:00:00Z"
    tasks_completed: 2
    tasks_total: 4
    track: 2
  SPRINT-002-01:
    status: pending
    tasks_total: 6
    track: 1

# Current execution context
current_execution:
  command: sprint-all
  track: 1
  current_sprint: SPRINT-002-01
  current_task: TASK-011

# Statistics
statistics:
  total_tasks: 25
  completed_tasks: 10
  in_progress_tasks: 1
  pending_tasks: 14
  total_sprints: 6
  completed_sprints: 1
  t1_tasks: 7
  t2_tasks: 3
```

## Parallel Development Tracks

### Track Numbering

- **Sprint format**: `SPRINT-{number}-{track}`
  - Example: `SPRINT-001-01`, `SPRINT-001-02`, `SPRINT-002-01`
  - Track number is always 2 digits (01, 02, 03, etc.)

- **Task format**: `TASK-{number}` (unchanged)
  - Tasks are assigned to tracks during sprint planning
  - Multiple tracks can work on different tasks in parallel

### Dependency Analysis

The `task-graph-analyzer` calculates the maximum possible parallel tracks:

1. **Build dependency graph** of all tasks
2. **Calculate critical path** (longest chain of dependencies)
3. **Identify independent chains** (tasks that can run in parallel)
4. **Determine max tracks** = number of independent chains that can run simultaneously

**Example:**
```
Tasks: A, B, C, D, E, F, G
Dependencies:
  A → C → E
  B → D → F
  G (independent)

Max possible tracks: 3
- Track 1: A → C → E
- Track 2: B → D → F
- Track 3: G
```

If user requests 5 tracks but max possible is 3, system uses 3 and warns user.

### Track Assignment Algorithm

Sprint planner distributes tasks across tracks:

1. **Group by dependency chains**
2. **Balance workload** across tracks (aim for equal hours per track)
3. **Respect dependencies** (dependent tasks stay in same track)
4. **Maximize parallelization** (independent tasks go to different tracks)

## Resume Functionality

### Command Behavior

**`/devteam:sprint all`** - Resume from last completed sprint (all tracks)
**`/devteam:sprint all 01`** - Resume track 1 from last completed sprint in track 1
**`/devteam:sprint all 02`** - Resume track 2 from last completed sprint in track 2

### Resume Logic

1. Read state file
2. Find last completed sprint for specified track (or all tracks)
3. Skip completed sprints
4. Resume from first pending/in_progress sprint
5. Continue until all sprints complete

**Example:**
```yaml
# User runs: /devteam:sprint all 01

# State shows:
sprints:
  SPRINT-001-01: completed
  SPRINT-002-01: in_progress (3/5 tasks done)
  SPRINT-003-01: pending

# System behavior:
# - Skip SPRINT-001-01 (already complete)
# - Resume SPRINT-002-01 (start from task 4)
# - Continue to SPRINT-003-01
```

## State Management API

### Core Functions

```python
# Initialize state
create_state(type: str, id: str) -> StateFile

# Load state
load_state(type: str, id: str) -> StateFile | None

# Update task status
update_task_status(state: StateFile, task_id: str, status: str, **metadata)

# Update sprint status
update_sprint_status(state: StateFile, sprint_id: str, status: str, **metadata)

# Mark sprint complete
mark_sprint_complete(state: StateFile, sprint_id: str, summary: dict)

# Get resume point
get_resume_point(state: StateFile, track: int | None) -> str

# Calculate max tracks
calculate_max_parallel_tracks(dependency_graph: dict) -> int
```

## Implementation Plan

### Phase 1: Core State Management
- Create state file utilities
- Implement load/save/update functions
- Add state schema validation

### Phase 2: Planning Updates
- Update task-graph-analyzer to calculate max tracks
- Update sprint-planner to assign tasks to tracks
- Modify /devteam:planning, /devteam:feature, /devteam:issue commands

### Phase 3: Execution Updates
- Update sprint-orchestrator to use state
- Update task-orchestrator to record progress
- Modify /devteam:sprint and /devteam:sprint-all commands

### Phase 4: Documentation
- Update README with new features
- Create examples showing parallel tracks
- Document state file format

## Benefits

1. **Resumability**: Never lose progress, resume from any point
2. **Parallel Development**: Multiple teams/agents can work simultaneously
3. **Progress Visibility**: Always know what's completed vs pending
4. **Historical Record**: State files provide audit trail
5. **Flexible Execution**: Run all tracks or specific tracks

## Example Workflows

### Workflow 1: Single Track (Traditional)
```bash
/devteam:prd
/devteam:planning          # No tracks specified = single track
/devteam:sprint all        # Execute all sprints sequentially
```

### Workflow 2: Parallel Tracks
```bash
/devteam:prd
/devteam:planning 3        # Request 3 parallel tracks
# System: "Created 3 development tracks (max possible: 5)"

# Run tracks in parallel (in separate sessions)
/devteam:sprint all 01     # Terminal 1: Track 1
/devteam:sprint all 02     # Terminal 2: Track 2
/devteam:sprint all 03     # Terminal 3: Track 3
```

### Workflow 3: Resume After Interruption
```bash
/devteam:sprint all 01     # Starts executing track 1
# ... system crashes at SPRINT-003-01 ...

/devteam:sprint all 01     # Resume
# System: "Resuming from SPRINT-003-01 (SPRINT-001-01, SPRINT-002-01 already complete)"
```

### Workflow 4: Feature with Tracks
```bash
/devteam:feature Add user authentication system
# Prompt: "How many parallel development tracks? (default: 1)"
# User: "2"

# System creates:
# - docs/planning/tasks/FEATURE-001-TASK-*.yaml
# - docs/sprints/FEATURE-001-SPRINT-001-01.yaml
# - docs/sprints/FEATURE-001-SPRINT-001-02.yaml
# - docs/planning/.feature-001-state.yaml
```

## Migration

Existing projects without state files:
- System detects missing state file
- Creates state file with all sprints marked "pending"
- User can proceed normally, system will track from that point
