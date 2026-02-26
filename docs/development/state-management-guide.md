# State Management Guide for Agents

> **Note:** This is a historical development document, updated to reflect the current architecture. The T1/T2 tier system and YAML state files described in the original version have been replaced. State is now managed via SQLite at `.devteam/devteam.db`. Planning documents (PRD, tasks, sprints) use JSON format. Model assignments (haiku/sonnet/opus) are explicit in agent YAML frontmatter and plugin.json. Escalation is handled by orchestrator agents via LLM instructions.

This guide explains how agents should manage progress tracking state.

## State Storage

All execution state is stored in the SQLite database at `.devteam/devteam.db`. The previous YAML state files (`.project-state.yaml`, `.feature-*-state.yaml`, `.issue-*-state.yaml`) have been replaced by SQLite tables.

### Key Tables

- **`sessions`** - Execution sessions (one per command invocation)
- **`session_state`** - Key-value state storage for sessions
- **`tasks`** - Task tracking for scope validation and progress
- **`plans`** - Plan tracking with links to plan JSON files on disk
- **`events`** - Full event log for debugging and analytics

See [SQLITE_SCHEMA.md](../SQLITE_SCHEMA.md) for the complete schema.

## State Operations

### Initializing State

When starting a new project/feature/issue, initialize the database:

```bash
# Initialize the database (creates .devteam/devteam.db)
bash scripts/db-init.sh

# In agent scripts, source the state helper
source scripts/state.sh

# Start a new session
SESSION_ID=$(start_session "/devteam:implement" "implement")
```

### Reading State

```bash
source scripts/state.sh

# Get a session field
phase=$(get_state "current_phase")

# Query task status directly
sqlite3 .devteam/devteam.db "SELECT status FROM tasks WHERE id = 'TASK-001';"

# Get sprint progress
sqlite3 .devteam/devteam.db "SELECT * FROM v_sprint_progress;"
```

### Updating State

After completing a task:

```bash
source scripts/state.sh

# Update session phase
set_phase "executing"

# Set arbitrary state
set_state "current_task" "TASK-001"

# Track tokens
add_tokens 1000 500 15  # input, output, cost_cents

# End session
end_session "completed" "All tasks done"
```

Task status is tracked in the `tasks` table:

```sql
-- Mark task complete
UPDATE tasks SET status = 'completed', completed_at = CURRENT_TIMESTAMP
WHERE id = 'TASK-005';

-- Record attempt
INSERT INTO task_attempts (task_id, attempt_number, model, agent, status)
VALUES ('TASK-005', 2, 'sonnet', 'api-developer-python', 'success');
```

### Determining Resume Point

To find where to resume:

```bash
source scripts/state.sh

# Query for pending/in-progress tasks in a sprint
sqlite3 .devteam/devteam.db "
  SELECT id, name, status FROM tasks
  WHERE sprint_id = 'SPRINT-001' AND status != 'completed'
  ORDER BY sequence;
"

# Get current session status
sqlite3 .devteam/devteam.db "SELECT * FROM v_current_session;"
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
# Dependencies: A->C->E, B->D->F
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
   - Chain 1 (5 tasks): TASK-001 -> TASK-003 -> TASK-007 -> TASK-011 -> TASK-015
   - Chain 2 (4 tasks): TASK-002 -> TASK-005 -> TASK-009 -> TASK-013
   - Chain 3 (3 tasks): TASK-004 -> TASK-008 -> TASK-012
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

```json
// docs/sprints/SPRINT-001-01.json (Sprint 1, Track 1)
{
  "id": "SPRINT-001-01",
  "name": "Foundation - Track 1",
  "track": 1,
  "tasks": ["TASK-001", "TASK-003", "TASK-007"]
}

// docs/sprints/SPRINT-001-02.json (Sprint 1, Track 2)
{
  "id": "SPRINT-001-02",
  "name": "Foundation - Track 2",
  "track": 2,
  "tasks": ["TASK-002", "TASK-005", "TASK-009"]
}
```

## Agent Implementation Guide

### task-graph-analyzer Agent

**New responsibilities:**

1. Calculate max possible parallel tracks
2. Report to user in summary
3. Store track info in the SQLite database via `set_state()`

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
4. Initialize session state in SQLite with track configuration

### sprint-orchestrator Agent

**New responsibilities:**

1. **Load state** from SQLite at start
2. **Check for resume point** based on track
3. **Skip completed sprints**
4. **Update state** in SQLite after each sprint completion
5. **Save state** regularly

**Resume logic:**

```python
# Pseudocode for sprint-orchestrator
def execute_sprints(sprint_id_or_all, track=None):
    # Load state from SQLite
    # source scripts/state.sh; get_state "current_phase"

    if sprint_id_or_all == "all":
        # Query SQLite for resume point
        # SELECT * FROM tasks WHERE sprint_id LIKE 'SPRINT-%-{track}'
        #   AND status != 'completed' ORDER BY sequence LIMIT 1
        resume_sprint = get_resume_point(track)

        if resume_sprint:
            print(f"Resuming from {resume_sprint.id}")
            sprints_to_run = get_sprints_from(resume_sprint, track)
        else:
            print("All sprints complete!")
            return
    else:
        sprint = sprint_id_or_all
        if is_completed(sprint):
            print(f"{sprint} already completed. Skipping.")
            return
        sprints_to_run = [sprint]

    for sprint in sprints_to_run:
        execute_single_sprint(sprint)
        # Update SQLite: UPDATE tasks SET status = 'completed' ...
        # set_state "current_sprint" next_sprint
```

### task-loop Agent

**New responsibilities:**

1. Update task status in SQLite after completion
2. Record model used (haiku/sonnet/opus)
3. Record iteration count
4. Record validation result

**State update after task completion (via SQLite):**

```bash
source scripts/state.sh

# Update task status
sqlite3 .devteam/devteam.db "
  UPDATE tasks SET
    status = 'completed',
    completed_at = CURRENT_TIMESTAMP,
    actual_iterations = 2,
    assigned_model = 'sonnet',
    result_summary = 'PASS - all criteria met'
  WHERE id = 'TASK-005';
"
```

## Error Handling

### Database Corruption

If the SQLite database is corrupted or invalid:

1. Back up corrupted file: `cp .devteam/devteam.db .devteam/devteam.db.backup`
2. Reinitialize: `bash scripts/db-init.sh`
3. All sessions and state will be reset
4. Warn user: "Database was corrupted. Reinitialized. Previous state backed up."

### Concurrent Execution Conflicts

SQLite provides built-in locking for concurrent access. If two agents try to modify state simultaneously:

1. SQLite WAL mode handles concurrent reads
2. Write contention is handled by SQLite's busy timeout
3. For parallel tracks in separate sessions, each operates on different task rows
4. Suggest running tracks in separate sessions to minimize contention

## Testing State Management

### Manual Testing

1. Create test project with /devteam:planning 3
2. Run /devteam:sprint all 01 and interrupt mid-sprint
3. Resume with /devteam:sprint all 01
4. Verify it continues from correct point
5. Check database for correct status: `sqlite3 .devteam/devteam.db "SELECT * FROM v_sprint_progress;"`

### Database Validation

Agents should validate:
- Database exists and is accessible
- Required tables present (check schema version)
- Status values are valid (completed, in_progress, pending)
- Sprint IDs match expected format
- Task dependencies are consistent
