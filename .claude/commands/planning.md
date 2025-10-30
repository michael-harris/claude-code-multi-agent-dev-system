# Planning Command

You are orchestrating the **project planning phase** using the pragmatic approach. This involves two sequential agent invocations.

## Your Process

### Step 1: Task Analysis
1. Read `docs/planning/PROJECT_PRD.yaml`
2. Launch the **task-graph-analyzer** agent using the Task tool:
   - Pass the PRD content
   - Ask it to break down requirements into tasks
   - Ask it to identify dependencies between tasks
3. Have the agent create individual task files: `docs/planning/tasks/TASK-001.yaml`, `TASK-002.yaml`, etc.
4. Have the agent create `docs/planning/task-dependency-graph.md` showing relationships

### Step 2: Sprint Planning
1. After task analysis completes, launch the **sprint-planner** agent using the Task tool:
   - Pass all task definitions
   - Pass the dependency graph
   - Ask it to organize tasks into sprints
2. Have the agent create sprint files: `docs/sprints/SPRINT-001.yaml`, `SPRINT-002.yaml`, etc.

## Agent References

- Task Graph Analyzer: `.claude/agents/planning/task-graph-analyzer.md`
- Sprint Planner: `.claude/agents/planning/sprint-planner.md`

## After Completion

Report to the user:
```
Planning complete!

Tasks created:
- [List task IDs with brief descriptions]

Sprints created:
- SPRINT-001: [Name] ([X] tasks)
- SPRINT-002: [Name] ([X] tasks)

Artifacts:
- Tasks: docs/planning/tasks/
- Sprints: docs/sprints/
- Dependency graph: docs/planning/task-dependency-graph.md

Ready to start development:
/sprint SPRINT-001
```

## Important Notes

- Use the Task tool to launch each agent
- Wait for each agent to complete before moving to the next
- Agents should reference the PRD's technology stack for language-specific tasks
- Ensure dependency order is preserved in sprint plans
