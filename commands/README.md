# DevTeam Commands

Slash commands for the DevTeam multi-agent development system.

## Command Overview

| Command | Description |
|---------|-------------|
| `/devteam:plan` | Interactive planning - creates PRD, tasks, and sprints |
| `/devteam:auto` | Autonomous execution until project complete |
| `/devteam:sprint <id>` | Execute a specific sprint |
| `/devteam:issue <#>` | Fix a GitHub issue by number |
| `/devteam:issue-new "<desc>"` | Create a new GitHub issue |

## Quick Start

### New Project

```bash
# 1. Plan your project (interactive)
/devteam:plan

# 2. Execute autonomously
/devteam:auto
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

## State Management

All commands use `.devteam/state.yaml` for:
- Progress tracking
- Resume capability
- Model selection history
- Sprint/task status

## Migration from /multi-agent

| Old Command | New Command |
|-------------|-------------|
| `/multi-agent:prd` | `/devteam:plan` |
| `/multi-agent:planning` | `/devteam:plan` |
| `/multi-agent:sprint all` | `/devteam:auto` |
| `/multi-agent:sprint <id>` | `/devteam:sprint <id>` |
| `/multi-agent:issue` | `/devteam:issue` |
| `/multi-agent:feature` | `/devteam:plan` (then auto) |

## Legacy Commands

The following commands are deprecated but still functional:
- `prd.md` → Use `/devteam:plan`
- `planning.md` → Use `/devteam:plan`
- `sprint-all.md` → Use `/devteam:auto`
- `feature.md` → Use `/devteam:plan`
