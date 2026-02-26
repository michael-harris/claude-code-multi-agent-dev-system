---
name: devteam-list
description: List all development plans and their status.
argument-hint: [--all] [--type <feature|project>]
user-invocable: true
allowed-tools: Read, Glob, Grep, Bash
model: haiku
---

Session state: !`source "${CLAUDE_PLUGIN_ROOT}/scripts/state.sh" && get_current_session 2>/dev/null || echo "No active session"`
Recent events: !`sqlite3 .devteam/devteam.db "SELECT type, message FROM events ORDER BY created_at DESC LIMIT 10" 2>/dev/null || echo "No events"`

# DevTeam List Command

**Command:** `/devteam:list`

List all development plans and their status.

## Usage

```bash
/devteam:list                    # Show all plans
/devteam:list --all              # Include archived plans
/devteam:list --type feature     # Filter by type
```

## Your Process

### Step 1: Read Plan Index

```bash
# Load plan index
cat .devteam/plans/index.json
```

If no index exists:
```
No plans found.

Create a new plan with:
  /devteam:plan "Project description"

Or create a feature plan:
  /devteam:plan --feature "Feature description"
```

### Step 2: Display Plan List

```
DEVELOPMENT PLANS

Active: feature-notifications

 #  | Name                 | Type    | Status      | Progress
 1  | Task Manager App     | project | complete    | 5/5
 2  | Push Notifications   | feature | active      | 1/2       <- ACTIVE
 3  | Dark Mode Support    | feature | planned     | 0/1

Commands:
  /devteam:select <#>     Select a plan to work on
  /devteam:implement           Execute the active plan
  /devteam:plan --feature Create new feature plan
```

### Status Icons

| Icon | Status | Meaning |
|------|--------|---------|
| planned | `planned` | Plan created, not started |
| active | `in_progress` | Currently being executed |
| complete | `complete` | All sprints finished |
| paused | `paused` | Execution paused |
| failed | `failed` | Circuit breaker triggered |
| archived | `archived` | Moved to archive |

### With `--all` Flag

Include archived plans:

```
DEVELOPMENT PLANS (including archived)

Active Plans:
 #  | Name                 | Type    | Status      | Progress
 1  | Task Manager App     | project | complete    | 5/5
 2  | Push Notifications   | feature | active      | 1/2
 3  | Dark Mode Support    | feature | planned     | 0/1

Archived Plans:
 4  | Old Dashboard        | feature | archived    | 2/2
 5  | Cancelled Auth       | feature | archived    | 0/3
```

### Plan Details

When a plan is selected, show details:

```
Plan: Push Notifications (feature-notifications)
Type: feature
Parent: project-taskmanager
Created: 2025-01-25

Status: in_progress
Progress: Sprint 1/2 complete

Current Sprint: SPRINT-002 (FCM Integration)
Current Task: TASK-003 (Implement push service)

Tasks:
  TASK-001: Create notification schema         [done]
  TASK-002: Add notification API endpoints     [done]
  TASK-003: Implement push service             [active]
  TASK-004: Add notification preferences UI    [pending]

Run /devteam:implement to continue execution.
```

## See Also

- `/devteam:select` - Select a plan to work on
- `/devteam:implement` - Execute the active plan
- `/devteam:plan` - Create a new plan
