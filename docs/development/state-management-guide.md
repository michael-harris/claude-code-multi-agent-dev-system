# State Management Guide for Agents

This guide explains how agents should manage progress tracking state files.

## State File Operations

### Creating a State File

When starting a new project/devteam:feature/devteam:issue, create a state file:

```yaml
# docs/planning/.project-state.yaml
version: "1.0"
type: project
created_at: "2025-10-31T10:00:00Z"
updated_at: "2025-10-31T10:00:00Z"

parallel_tracks:
  enabled: false
  total_tracks: 1
  max_possible_tracks: 1

tasks: {}
sprints: {}

current_execution: null

statistics:
  total_tasks: 0
  completed_tasks: 0
  in_progress_tasks: 0
  pending_tasks: 0
  total_sprints: 0
  completed_sprints: 0
  t1_tasks: 0
  t2_tasks: 0
```

### Loading State

Before executing sprints or resuming work:

1. Check if state file exists at expected path
2. If exists, read and parse YAML
3. If not exists, create new state file
4. Validate schema version

### Updating State

After completing a task:

```yaml
tasks:
  TASK-001:
    status: completed
    completed_at: "2025-10-31T10:30:00Z"
    tier_used: T1
    iterations: 2
    validation_result: PASS
```

After completing a sprint:

```yaml
sprints:
  SPRINT-001-01:
    status: completed
    completed_at: "2025-10-31T11:30:00Z"
    tasks_completed: 5
    tasks_total: 5
    track: 1
    quality_gates_passed: true
```

### Determining Resume Point

To find where to resume:

```python
# Pseudocode
def get_resume_point(state, track=None):
    if track:
        # Find sprints for specific track
        track_sprints = filter(sprint for sprint in state.sprints if sprint.track == track)
        # Find first non-completed sprint
        pending_sprints = filter(s for s in track_sprints if s.status != "completed")
        return pending_sprints[0] if pending_sprints else None
    else:
        # Find first non-completed sprint across all tracks
        pending_sprints = filter(s for s in state.sprints if s.status != "completed")
        return pending_sprints[0] if pending_sprints else None
```

## Parallel Track Management

### Calculating Max Possible Tracks

**Algorithm: Critical Path Analysis**

```python
# Pseudocode
def calculate_max_tracks(tasks, dependencies):
    # 1. Build dependency graph
    graph = build_graph(tasks, dependencies)

    # 2. Find all root tasks (no dependencies)
    roots = [task for task in tasks if not task.dependencies]

    # 3. Find independent chains
    chains = []
    for root in roots:
        chain = traverse_dependency_chain(root, graph)
        chains.append(chain)

    # 4. Find tasks that can run in parallel
    parallel_groups = find_parallel_tasks(graph)

    # 5. Max tracks = max parallel tasks at any point
    max_parallel = max(len(group) for group in parallel_groups)

    return max_parallel

# Example:
# Tasks: A, B, C, D, E, F
# Dependencies: A→C→E, B→D→F
# Result: 2 tracks (A-C-E can run parallel to B-D-F)
```

**Implementation in task-graph-analyzer:**

1. After creating all task files
2. Analyze dependency graph
3. Calculate max possible tracks
4. Include in output report:
   ```
   Max possible parallel development tracks: 3

   Reasoning:
   - Chain 1 (5 tasks): TASK-001 → TASK-003 → TASK-007 → TASK-011 → TASK-015
   - Chain 2 (4 tasks): TASK-002 → TASK-005 → TASK-009 → TASK-013
   - Chain 3 (3 tasks): TASK-004 → TASK-008 → TASK-012
   - Independent tasks: TASK-006, TASK-010, TASK-014

   If you plan with 3 tracks, all chains can run in parallel.
   If you plan with >3 tracks, some tracks will have idle time.
   ```

### Assigning Tasks to Tracks

**Algorithm: Balanced Track Assignment**

```python
# Pseudocode
def assign_tasks_to_tracks(tasks, dependencies, num_tracks):
    # 1. Identify dependency chains
    chains = identify_chains(tasks, dependencies)

    # 2. Calculate total hours per chain
    chain_hours = [(chain, sum(task.estimated_hours for task in chain)) for chain in chains]

    # 3. Sort by hours (longest first)
    chain_hours.sort(key=lambda x: x[1], reverse=True)

    # 4. Assign chains to tracks using bin packing
    tracks = [[] for _ in range(num_tracks)]
    track_hours = [0] * num_tracks

    for chain, hours in chain_hours:
        # Find track with least hours
        min_track = track_hours.index(min(track_hours))
        tracks[min_track].extend(chain)
        track_hours[min_track] += hours

    # 5. Create sprint files per track
    for track_num, track_tasks in enumerate(tracks, start=1):
        create_sprint_files_for_track(track_tasks, track_num)

    return tracks
```

**Sprint File Naming:**

```yaml
# docs/sprints/SPRINT-001-01.yaml (Sprint 1, Track 1)
id: SPRINT-001-01
name: "Foundation - Track 1"
track: 1
tasks:
  - TASK-001
  - TASK-003
  - TASK-007

# docs/sprints/SPRINT-001-02.yaml (Sprint 1, Track 2)
id: SPRINT-001-02
name: "Foundation - Track 2"
track: 2
tasks:
  - TASK-002
  - TASK-005
  - TASK-009
```

## Agent Implementation Guide

### task-graph-analyzer Agent

**New responsibilities:**

1. Calculate max possible parallel tracks
2. Report to user in summary
3. Update state file with max_possible_tracks

**Output format:**

```markdown
Task analysis complete!

Created 15 tasks in docs/planning/tasks/

Dependency Analysis:
- Total dependency chains: 3
- Critical path length: 5 tasks (20 hours)
- Max possible parallel tracks: 3

If you want to enable parallel development, run:
/devteam:planning 3

This will organize tasks into 3 parallel development tracks.
```

### sprint-planner Agent

**New inputs:**

- Number of desired tracks (from command parameter)
- Task dependency graph
- Max possible tracks (from task-graph-analyzer)

**New responsibilities:**

1. Check if requested tracks > max possible
   - If yes, use max possible and warn user
2. Assign tasks to tracks using balanced algorithm
3. Create sprint files with track suffix: `SPRINT-XXX-YY`
4. Initialize state file with track configuration

**Output format:**

```markdown
Sprint planning complete!

Parallel Development Configuration:
- Requested tracks: 5
- Max possible tracks: 3
- Using: 3 tracks

Track Distribution:
- Track 1: 6 tasks (24 hours) - SPRINT-001-01, SPRINT-002-01
- Track 2: 5 tasks (20 hours) - SPRINT-001-02, SPRINT-002-02
- Track 3: 4 tasks (16 hours) - SPRINT-001-03, SPRINT-002-03

To execute all tracks in parallel:
- Terminal 1: /devteam:sprint all 01
- Terminal 2: /devteam:sprint all 02
- Terminal 3: /devteam:sprint all 03

Or execute sequentially:
/devteam:sprint all
```

### sprint-orchestrator Agent

**New responsibilities:**

1. **Load state** at start
2. **Check for resume point** based on track
3. **Skip completed sprints**
4. **Update state** after each sprint completion
5. **Save state** regularly

**Resume logic:**

```python
# Pseudocode for sprint-orchestrator
def execute_sprints(sprint_id_or_all, track=None):
    # Load state
    state = load_state("project")

    if sprint_id_or_all == "all":
        # Get resume point
        resume_sprint = get_resume_point(state, track)

        if resume_sprint:
            print(f"Resuming from {resume_sprint.id}")
            # Skip to resume point
            sprints_to_run = get_sprints_from(resume_sprint, track)
        else:
            print("All sprints complete!")
            return
    else:
        # Executing specific sprint
        sprint = sprint_id_or_all

        # Check if already completed
        if state.sprints[sprint].status == "completed":
            print(f"{sprint} already completed. Skipping.")
            return

        sprints_to_run = [sprint]

    # Execute sprints
    for sprint in sprints_to_run:
        execute_single_sprint(sprint, state)
        mark_sprint_complete(state, sprint)
        save_state(state)

def execute_single_sprint(sprint_id, state):
    # Read sprint definition
    sprint = read_sprint_file(sprint_id)

    # Execute each task
    for task_id in sprint.tasks:
        # Check if task already completed
        if task_id in state.tasks and state.tasks[task_id].status == "completed":
            print(f"  {task_id} already completed. Skipping.")
            continue

        # Execute task
        result = execute_task(task_id)

        # Update state
        update_task_status(state, task_id, "completed",
                          tier_used=result.tier,
                          iterations=result.iterations)
        save_state(state)
```

### task-orchestrator Agent

**New responsibilities:**

1. Update task status in state file after completion
2. Record tier usage (T1/T2)
3. Record iteration count
4. Record validation result

**State update after task completion:**

```yaml
tasks:
  TASK-005:
    status: completed
    completed_at: "2025-10-31T11:45:00Z"
    started_at: "2025-10-31T11:00:00Z"
    duration_minutes: 45
    tier_used: T1
    iterations: 2
    validation_result: PASS
    acceptance_criteria_met: 5
    acceptance_criteria_total: 5
```

## Command Parameter Handling

### /devteam:planning Command

```markdown
# Old
/devteam:planning

# New (with optional tracks parameter)
/devteam:planning          # Default: 1 track
/devteam:planning 3        # Request 3 tracks
/devteam:planning 10       # Request 10 tracks (will use max possible if less)
```

**Implementation in planning.md:**

```markdown
## Your Process

### Step 0: Parse Parameters
Extract number of tracks from command (default: 1)

### Step 1: Task Analysis
[existing steps...]

After task analysis:
- Calculate max possible tracks
- Report to user

### Step 2: Sprint Planning
Pass number of tracks to sprint-planner:
- If tracks > 1, enable parallel development
- sprint-planner will create track-specific sprint files
- Initialize state file with track configuration
```

### /devteam:sprint all Command

```markdown
# Old
/devteam:sprint all

# New (with optional track parameter)
/devteam:sprint all        # Execute all tracks sequentially
/devteam:sprint all 01     # Execute only track 1
/devteam:sprint all 02     # Execute only track 2
```

**Implementation in sprint-all.md:**

```markdown
## Your Process

### Step 0: Parse Parameters
Extract track number from command (default: all tracks)

### Step 1: Load State
Load state file and determine resume point for specified track(s)

### Step 2: Execute Sprints
- If track specified: execute only sprints for that track
- If no track: execute all sprints (all tracks) sequentially
- Skip completed sprints
- Resume from last incomplete sprint
```

## State File Examples

### Single Track Project

```yaml
version: "1.0"
type: project
created_at: "2025-10-31T10:00:00Z"
updated_at: "2025-10-31T15:30:00Z"

parallel_tracks:
  enabled: false
  total_tracks: 1
  max_possible_tracks: 3

tasks:
  TASK-001:
    status: completed
    completed_at: "2025-10-31T11:00:00Z"
    tier_used: T1
    iterations: 2
  TASK-002:
    status: in_progress
    started_at: "2025-10-31T15:00:00Z"
    tier_used: T1
    iterations: 1

sprints:
  SPRINT-001:
    status: completed
    completed_at: "2025-10-31T12:00:00Z"
    tasks_completed: 5
    tasks_total: 5
  SPRINT-002:
    status: in_progress
    started_at: "2025-10-31T15:00:00Z"
    tasks_completed: 1
    tasks_total: 6

current_execution:
  command: sprint-all
  track: null
  current_sprint: SPRINT-002
  current_task: TASK-002

statistics:
  total_tasks: 15
  completed_tasks: 6
  in_progress_tasks: 1
  pending_tasks: 8
  total_sprints: 3
  completed_sprints: 1
  t1_tasks: 5
  t2_tasks: 1
```

### Multi-Track Project

```yaml
version: "1.0"
type: project
created_at: "2025-10-31T10:00:00Z"
updated_at: "2025-10-31T15:30:00Z"

parallel_tracks:
  enabled: true
  total_tracks: 3
  max_possible_tracks: 3
  track_info:
    1:
      name: "Backend Track"
      estimated_hours: 40
      completed_hours: 32
    2:
      name: "Frontend Track"
      estimated_hours: 35
      completed_hours: 35
    3:
      name: "Infrastructure Track"
      estimated_hours: 25
      completed_hours: 15

tasks:
  TASK-001:
    status: completed
    track: 1
    completed_at: "2025-10-31T11:00:00Z"
    tier_used: T1
  TASK-002:
    status: completed
    track: 2
    completed_at: "2025-10-31T11:30:00Z"
    tier_used: T1

sprints:
  SPRINT-001-01:  # Track 1
    status: completed
    track: 1
    completed_at: "2025-10-31T12:00:00Z"
    tasks_completed: 5
    tasks_total: 5
  SPRINT-001-02:  # Track 2
    status: completed
    track: 2
    completed_at: "2025-10-31T13:00:00Z"
    tasks_completed: 4
    tasks_total: 4
  SPRINT-001-03:  # Track 3
    status: in_progress
    track: 3
    started_at: "2025-10-31T14:00:00Z"
    tasks_completed: 2
    tasks_total: 3
  SPRINT-002-01:  # Track 1
    status: pending
    track: 1
    tasks_total: 6

current_execution:
  command: sprint-all
  track: 3
  current_sprint: SPRINT-001-03
  current_task: TASK-015

statistics:
  total_tasks: 25
  completed_tasks: 15
  in_progress_tasks: 1
  pending_tasks: 9
  total_sprints: 9  # 3 sprints × 3 tracks
  completed_sprints: 2
  t1_tasks: 12
  t2_tasks: 3
```

## Error Handling

### State File Corruption

If state file is corrupted or invalid:

1. Backup corrupted file: `.project-state.yaml.backup`
2. Create fresh state file
3. Mark all sprints as "pending"
4. Warn user: "State file was corrupted. Created fresh state. All sprints marked as pending."

### Concurrent Execution Conflicts

If two agents try to modify state simultaneously:

1. Implement file locking (create `.project-state.lock`)
2. Wait for lock to release (max 60 seconds)
3. If timeout, warn user about potential conflict
4. Suggest running tracks in separate sessions to avoid conflicts

## Testing State Management

### Manual Testing

1. Create test project with /devteam:planning 3
2. Run /devteam:sprint all 01 and interrupt mid-sprint
3. Resume with /devteam:sprint all 01
4. Verify it continues from correct point
5. Check state file for correct status

### State File Validation

Agents should validate:
- Version matches expected version
- Required fields present
- Status values are valid (completed, in_progress, pending)
- Track numbers are consistent
- Sprint IDs match expected format
