# DevTeam Plan Command

**Command:** `/devteam:plan`

You conduct interactive requirements gathering, create a PRD, and generate a development plan with tasks and sprints.

## Usage

```bash
/devteam:plan                                # Start interactive planning
/devteam:plan "Build a task manager"         # Start with description
/devteam:plan --from spec.md                 # Load from single spec file
/devteam:plan --from specs/                  # Load from folder of spec files
/devteam:plan --from existing                # Auto-detect existing docs in project
```

## File-Based Specification Support

### Supported File Formats

| Format | Extensions | Best For |
|--------|------------|----------|
| Markdown | `.md` | Human-readable specs, PRDs |
| YAML | `.yaml`, `.yml` | Structured specs, existing PRDs |
| JSON | `.json` | API specs, structured data |
| Plain Text | `.txt` | Simple requirements lists |
| PDF | `.pdf` | Formal documents (extracted) |

### Single File Mode (`--from file.md`)

Reads a specification file and extracts:
- Project description
- Features/requirements (from headers, lists)
- Technical constraints
- User stories
- Acceptance criteria

**Example Input (`project-spec.md`):**
```markdown
# Task Manager App

## Overview
A simple task management app for teams.

## Features
- User authentication with OAuth
- Create, edit, delete tasks
- Assign tasks to team members
- Due date reminders

## Technical Requirements
- Backend: FastAPI
- Database: PostgreSQL
- Frontend: React + TypeScript
```

**Process:**
1. Read and parse file
2. Extract structured information
3. Confirm understanding with user (brief)
4. Skip redundant interview questions
5. Generate PRD from extracted data

### Folder Mode (`--from specs/`)

Reads all spec files from a folder and merges them:

```
specs/
├── overview.md           # Project overview
├── features/
│   ├── auth.md          # Authentication spec
│   ├── tasks.md         # Task management spec
│   └── notifications.md # Notification spec
├── api-design.yaml      # API specification
└── wireframes.md        # UI descriptions
```

**Process:**
1. Scan folder recursively
2. Categorize files by type/content
3. Merge into unified understanding
4. Resolve conflicts (ask user if ambiguous)
5. Generate comprehensive PRD

### Auto-Detect Mode (`--from existing`)

Searches project for existing documentation:

**Search locations:**
```
docs/                    # Common docs folder
documentation/           # Alternative name
spec/                    # Spec folder
specifications/          # Alternative name
requirements/            # Requirements folder
*.md in root            # README, CONTRIBUTING, etc.
.github/                # Issue templates, etc.
```

**Process:**
1. Scan project structure
2. Find and list discovered docs
3. Ask user to confirm which to use
4. Parse and extract requirements
5. Fill gaps with brief questions

### File Parsing Examples

**From Markdown with headers:**
```markdown
# Feature: User Authentication

## Requirements
- [ ] OAuth 2.0 support (Google, GitHub)
- [ ] Session management
- [ ] Password reset flow

## Acceptance Criteria
1. User can sign in with Google
2. Session persists for 7 days
3. Password reset email sent within 1 minute
```

→ Extracted as:
```yaml
feature:
  name: User Authentication
  requirements:
    - OAuth 2.0 support (Google, GitHub)
    - Session management
    - Password reset flow
  acceptance_criteria:
    - User can sign in with Google
    - Session persists for 7 days
    - Password reset email sent within 1 minute
```

**From YAML directly:**
```yaml
# Already structured - use as-is
project:
  name: Task Manager
features:
  - name: Authentication
    priority: must_have
```

**From JSON (OpenAPI):**
```json
{
  "openapi": "3.0.0",
  "paths": {
    "/tasks": { "get": {...}, "post": {...} }
  }
}
```

→ Extract API endpoints as features

### User Confirmation

After parsing file-based specs, always confirm:

```
📄 Loaded specification from: project-spec.md

Extracted:
  • Project: Task Manager App
  • Features: 4 identified
  • Tech Stack: FastAPI + PostgreSQL + React
  • Constraints: None specified

Is this correct? (yes/edit/add more)
```

If `edit`: Allow user to modify extracted data
If `add more`: Continue with remaining interview questions

## Your Process

This command combines PRD generation and sprint planning into a single workflow.

### Phase 0: Git Repository Check (REQUIRED)

Before any planning, verify git repository exists:

```bash
# Check for git repository
git rev-parse --git-dir 2>/dev/null
```

**If NOT a git repository:**

```
┌──────────────────────────────────────────────────────────────┐
│  📁 Git Repository Required                                  │
│                                                              │
│  DevTeam requires a git repository for:                      │
│  • Change tracking and rollback                              │
│  • Parallel plan execution (worktrees)                       │
│  • Safe merge of feature branches                            │
│  • Circuit breaker recovery                                  │
│                                                              │
│  Initialize a git repository now? (yes/no): _                │
└──────────────────────────────────────────────────────────────┘
```

If user says **yes**:
```bash
git init
git add .
git commit -m "Initial commit before DevTeam planning"
echo "✅ Git repository initialized"
```

If user says **no**:
```
❌ Cannot proceed without git repository.

To initialize manually:
  git init
  git add .
  git commit -m "Initial commit"

Then run /devteam:plan again.
```

**If git repo exists but has uncommitted changes:**

```
⚠️  Uncommitted Changes Detected

You have uncommitted changes in your working directory.
It's recommended to commit before planning.

Options:
  1. Commit changes now (recommended)
  2. Stash changes temporarily
  3. Continue anyway (changes tracked but not snapshotted)

Select option (1/2/3): _
```

Option 1:
```bash
git add -A
git commit -m "Pre-planning snapshot"
echo "✅ Changes committed"
```

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
