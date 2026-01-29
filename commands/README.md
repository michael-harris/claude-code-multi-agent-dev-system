# DevTeam Commands

Slash commands for the DevTeam multi-agent development system.

## Command Overview

| Command | Description |
|---------|-------------|
| `/devteam:plan` | Interactive planning - creates PRD, tasks, and sprints |
| `/devteam:auto` | Autonomous execution until project/feature complete |
| `/devteam:list` | List all plans and their status |
| `/devteam:select` | Select a plan to work on |
| `/devteam:sprint <id>` | Execute a specific sprint |
| `/devteam:issue <#>` | Fix a GitHub issue by number |
| `/devteam:issue-new "<desc>"` | Create a new GitHub issue |

## Quick Start

### New Project

```bash
# 1. Plan your project (interactive)
/devteam:plan "Build a task manager"

# 2. Execute autonomously
/devteam:auto
```

### Add a Feature (to existing project)

```bash
# 1. Create feature plan
/devteam:plan --feature "Add dark mode support"

# 2. Execute the feature
/devteam:auto
```

### Multiple Features

```bash
# Plan several features
/devteam:plan --feature "Add notifications"
/devteam:plan --feature "Add dark mode"

# List all plans
/devteam:list

# Select which one to work on
/devteam:select notifications

# Execute selected plan
/devteam:auto
```

### From Spec File

```bash
# Plan from existing specification
/devteam:plan --from project-spec.md
/devteam:plan --from specs/              # Folder of specs
```

### Fix a Bug

```bash
# Fix GitHub issue #123
/devteam:issue 123
```

### Create Issue

```bash
# Create and track a new issue
/devteam:issue-new "Login button broken on mobile"
```

## Command Details

### /devteam:plan

Combines PRD generation and sprint planning:
1. Interactive requirements interview
2. Technology stack selection
3. PRD generation (`docs/planning/PROJECT_PRD.yaml`)
4. Task breakdown (`docs/planning/tasks/`)
5. Sprint organization (`docs/sprints/`)
6. State file initialization (`.devteam/state.yaml`)

### /devteam:auto

Autonomous execution mode:
- Executes all sprints continuously
- Uses stop hooks to prevent premature exit
- Circuit breaker prevents infinite loops
- Dynamic model selection for cost optimization
- Session memory preserved across compaction
- Outputs `EXIT_SIGNAL: true` when complete

### /devteam:sprint

Manual sprint execution:
- Execute specific sprint by ID
- Automatic state tracking and resume
- Quality gates between sprints
- Supports `all` to execute all sprints

### /devteam:issue

Fix GitHub issues:
- Fetches issue details from GitHub
- Classifies severity and complexity
- **Bug Council** for complex bugs (5 Opus agents)
- Automatic fix implementation
- Closes issue when complete

### /devteam:issue-new

Create GitHub issues:
- Parses description for type/severity
- Auto-applies labels
- Well-formatted issue template
- Suggests next steps

### /devteam:list

View all development plans:
- Shows active plan indicator
- Status and progress for each plan
- Filter by type (`--type feature`)
- Include archived (`--all`)

### /devteam:select

Select a plan to work on:
- By number: `/devteam:select 2`
- By name: `/devteam:select dark-mode`
- Partial match supported
- Shows plan details after selection

## Plan Management

DevTeam supports multiple concurrent plans:

```
.devteam/plans/
├── index.yaml                    # Master plan index
├── project-taskmanager/          # Original project
├── feature-notifications/        # Feature 1
└── feature-dark-mode/            # Feature 2
```

### Plan Types

| Type | Description | Use Case |
|------|-------------|----------|
| `project` | Full new project | Starting from scratch |
| `feature` | Addition to existing | New functionality |
| `enhancement` | Improvement | Optimization/refactor |

### Plan Lifecycle

```
planned → in_progress → complete → (archive)
                    ↘ failed → (retry/abandon)
```

## State Management

Each plan has its own state file:
- `.devteam/plans/<plan-id>/state.yaml`

State tracks:
- Progress (sprints, tasks)
- Model selection history
- Circuit breaker status
- Session memory references

## Migration from /multi-agent

| Old Command | New Command |
|-------------|-------------|
| `/devteam:prd` | `/devteam:plan` |
| `/devteam:planning` | `/devteam:plan` |
| `/devteam:sprint all` | `/devteam:auto` |
| `/devteam:sprint <id>` | `/devteam:sprint <id>` |
| `/devteam:issue` | `/devteam:issue` |
| `/devteam:feature` | `/devteam:plan` (then auto) |

## Legacy Commands

The following commands are deprecated but still functional:
- `prd.md` → Use `/devteam:plan`
- `planning.md` → Use `/devteam:plan`
- `sprint-all.md` → Use `/devteam:auto`
- `feature.md` → Use `/devteam:plan`
