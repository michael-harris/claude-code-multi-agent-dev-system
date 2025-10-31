# Planning Command

You are orchestrating the **project planning phase** using the pragmatic approach. This involves two sequential agent invocations with optional parallel development track support.

## Command Usage

```bash
/multi-agent:planning           # Single track (default)
/multi-agent:planning 3         # Request 3 parallel development tracks
/multi-agent:planning 5         # Request 5 parallel tracks (will use max possible if less)
```

## Your Process

### Step 0: Parse Parameters

Extract the number of requested parallel tracks from the command:
- If no parameter provided: tracks = 1 (single track mode)
- If parameter provided: tracks = requested number
- Pass this to sprint-planner in Step 2

### Step 1: Task Analysis
1. Read `docs/planning/PROJECT_PRD.yaml`
2. Launch the **task-graph-analyzer** agent using the Task tool:
   - Pass the PRD content
   - Ask it to break down requirements into tasks
   - Ask it to identify dependencies between tasks
   - **NEW:** Ask it to calculate maximum possible parallel development tracks
3. Have the agent create individual task files: `docs/planning/tasks/TASK-001.yaml`, `TASK-002.yaml`, etc.
4. Have the agent create `docs/planning/task-dependency-graph.md` showing relationships
5. **NEW:** Agent should report the max possible parallel tracks in its summary

### Step 2: Sprint Planning
1. After task analysis completes, launch the **sprint-planner** agent using the Task tool:
   - Pass all task definitions
   - Pass the dependency graph
   - **NEW:** Pass number of requested tracks (from Step 0)
   - **NEW:** Pass max possible tracks (from Step 1)
   - Ask it to organize tasks into sprints
2. **NEW:** If tracks > 1:
   - Have agent create sprint files with track suffix: `docs/sprints/SPRINT-XXX-YY.yaml`
   - Have agent initialize state file: `docs/planning/.project-state.yaml`
   - Example: `SPRINT-001-01.yaml`, `SPRINT-001-02.yaml` for 2 tracks
3. **NEW:** If tracks = 1 (default):
   - Have agent create traditional sprint files: `docs/sprints/SPRINT-001.yaml`, `SPRINT-002.yaml`, etc.
   - Still initialize state file for progress tracking

## Agent References

- Task Graph Analyzer: `.claude/agents/multi-agent:planning/task-graph-analyzer.md`
- Sprint Planner: `.claude/agents/multi-agent:planning/multi-agent:sprint-planner.md`

## After Completion

### Report Format - Single Track Mode

```
Planning complete!

Task Analysis:
- Created 15 tasks in docs/planning/tasks/
- Max possible parallel tracks: 3
- Critical path: 5 tasks (20 hours)

Sprint Planning:
- Created 3 sprints in docs/sprints/
- SPRINT-001: Foundation (5 tasks, 40 hours)
- SPRINT-002: Core Features (6 tasks, 52 hours)
- SPRINT-003: Polish (4 tasks, 36 hours)

Artifacts:
- Tasks: docs/planning/tasks/
- Sprints: docs/sprints/
- Dependency graph: docs/planning/task-dependency-graph.md
- State file: docs/planning/.project-state.yaml

Ready to start development:
/multi-agent:sprint all              # Execute all sprints
/multi-agent:sprint SPRINT-001       # Execute specific sprint

Tip: For parallel development, try:
/multi-agent:planning 3              # Re-run with 3 tracks for faster execution
```

### Report Format - Parallel Track Mode

```
Planning complete!

Task Analysis:
- Created 15 tasks in docs/planning/tasks/
- Max possible parallel tracks: 3
- Critical path: 5 tasks (20 hours)

Sprint Planning:
- Requested tracks: 5
- Max possible: 3
- Using: 3 tracks

Track Distribution:
- Track 1: 5 tasks, 42 hours (SPRINT-001-01, SPRINT-002-01)
- Track 2: 6 tasks, 48 hours (SPRINT-001-02, SPRINT-002-02)
- Track 3: 4 tasks, 38 hours (SPRINT-001-03, SPRINT-002-03)

Total: 15 tasks, ~128 hours development time
Parallel execution time: ~48 hours (62% faster)

Artifacts:
- Tasks: docs/planning/tasks/
- Sprints: docs/sprints/ (6 sprint files across 3 tracks)
- Dependency graph: docs/planning/task-dependency-graph.md
- State file: docs/planning/.project-state.yaml

Ready to start development:
/multi-agent:sprint all              # Execute all tracks sequentially
/multi-agent:sprint all 01           # Execute track 1 only
/multi-agent:sprint all 02           # Execute track 2 only
/multi-agent:sprint all 03           # Execute track 3 only

Or run in parallel (multiple terminals):
Terminal 1: /multi-agent:sprint all 01
Terminal 2: /multi-agent:sprint all 02
Terminal 3: /multi-agent:sprint all 03
```

## Important Notes

- Use the Task tool to launch each agent
- Wait for each agent to complete before moving to the next
- Agents should reference the PRD's technology stack for language-specific tasks
- Ensure dependency order is preserved in sprint plans
