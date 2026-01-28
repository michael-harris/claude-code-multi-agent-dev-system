# DevTeam Plan Command

**Command:** `/devteam:plan`

You conduct interactive requirements gathering, create a PRD, and generate a development plan with tasks and sprints.

## Usage

```bash
/devteam:plan                           # Start interactive planning
/devteam:plan "Build a task manager"    # Start with description
```

## Your Process

This command combines PRD generation and sprint planning into a single workflow.

### Phase 1: Requirements Interview

**Technology Stack Selection (FIRST):**
1. Ask: "What external services, APIs, or integrations will you need?"
2. Based on answer, recommend Python or TypeScript with reasoning:
   - Python: Better for data processing, ML, scientific computing
   - TypeScript: Better for web apps, real-time features, npm ecosystem
3. Confirm with user
4. Document choice

**Requirements Gathering (ONE question at a time):**
1. "What problem are you solving?"
2. "Who are the primary users?"
3. "What are the must-have features?"
4. "What are the nice-to-have features?"
5. "What scale do you expect? (users, data volume)"
6. "Any specific constraints? (timeline, budget, compliance)"
7. "How will you measure success?"

**Be efficient:** If user provides comprehensive initial description, skip questions already answered.

### Phase 2: Generate PRD

Create `docs/planning/PROJECT_PRD.yaml`:

```yaml
version: "1.0"
project_name: "[Name]"
created: "[Date]"

technology_stack:
  primary_language: python | typescript
  backend_framework: fastapi | django | express | nestjs
  frontend_framework: react | vue | svelte | none
  database: postgresql | mongodb | sqlite
  orm: sqlalchemy | prisma | typeorm | drizzle
  package_manager: uv | npm | pnpm

problem_statement: |
  [Clear description of the problem]

solution_overview: |
  [How this project solves it]

users:
  primary:
    - type: "[User type]"
      needs: ["need1", "need2"]
  secondary:
    - type: "[User type]"
      needs: ["need1"]

features:
  must_have:
    - id: F001
      name: "[Feature name]"
      description: "[Description]"
      acceptance_criteria:
        - "[Criterion 1]"
        - "[Criterion 2]"
  nice_to_have:
    - id: F010
      name: "[Feature name]"
      description: "[Description]"

non_functional_requirements:
  performance:
    - "[Requirement]"
  security:
    - "[Requirement]"
  scalability:
    - "[Requirement]"

constraints:
  timeline: "[if specified]"
  budget: "[if specified]"
  compliance: "[if specified]"

success_metrics:
  - "[Metric 1]"
  - "[Metric 2]"
```

### Phase 3: Task Breakdown

Generate tasks in `docs/planning/tasks/`:

**For each must-have feature:**
1. Analyze complexity
2. Break into implementation tasks
3. Identify dependencies
4. Assign complexity scores (1-14)

**Task file format (`TASK-XXX.yaml`):**
```yaml
id: TASK-001
title: "[Task title]"
description: |
  [Detailed description]

feature_ref: F001
task_type: backend | frontend | database | fullstack | testing | infrastructure

complexity:
  score: 6  # 0-14 scale
  factors:
    files_affected: 4
    estimated_lines: 150
    new_dependencies: 1
    risk_flags: []

dependencies:
  - TASK-000  # Setup task

acceptance_criteria:
  - "[Criterion 1]"
  - "[Criterion 2]"

suggested_agent: backend_developer | frontend_developer | ...
```

### Phase 4: Sprint Planning

Organize tasks into sprints in `docs/sprints/`:

**Sprint organization rules:**
1. Respect dependencies (dependent tasks in later sprints)
2. Balance complexity across sprints
3. Group related tasks
4. First sprint = foundation/setup

**Sprint file format (`SPRINT-001.yaml`):**
```yaml
id: SPRINT-001
name: "[Sprint name]"
goal: "[Sprint goal]"

tasks:
  - TASK-001
  - TASK-002
  - TASK-003

estimated_complexity: 15  # Sum of task complexity scores

dependencies:
  sprints: []  # First sprint has none

quality_gates:
  - All tests pass
  - No type errors
  - Code review complete
```

### Phase 5: Initialize State File

Create `.devteam/state.yaml`:

```yaml
version: "3.0"

metadata:
  created_at: "[timestamp]"
  project_name: "[name]"
  project_type: project

sprints:
  SPRINT-001:
    status: pending
    tasks_total: 3
  SPRINT-002:
    status: pending
    tasks_total: 4
  # ...

tasks:
  TASK-001:
    status: pending
    complexity:
      score: 6
      tier: moderate

current_execution:
  command: null
  current_sprint: null
  current_task: null
  phase: planning_complete
```

## Output Summary

After completion, display:

```
╔══════════════════════════════════════════╗
║  📋 PROJECT PLAN COMPLETE                ║
╚══════════════════════════════════════════╝

Project: [Name]

Technology Stack:
  • Backend: [Language + Framework]
  • Frontend: [Framework]
  • Database: [Database + ORM]

Planning Summary:
  • Features: [X] must-have, [Y] nice-to-have
  • Tasks: [N] total tasks
  • Sprints: [M] sprints planned
  • Estimated complexity: [score]

Files created:
  • docs/planning/PROJECT_PRD.yaml
  • docs/planning/tasks/TASK-*.yaml ([N] files)
  • docs/sprints/SPRINT-*.yaml ([M] files)
  • .devteam/state.yaml

Next steps:
  1. Review the PRD and tasks
  2. Run /devteam:auto to execute autonomously
  3. Or run /devteam:sprint SPRINT-001 for first sprint only
```

## Important Notes

- Ask ONE question at a time
- Be conversational but efficient
- Provide technology recommendations with reasoning
- Don't generate files until you have all required information
- Initialize state file for progress tracking
