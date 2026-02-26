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
📋 No plans found.

Create a new plan with:
  /devteam:plan "Project description"

Or create a feature plan:
  /devteam:plan --feature "Feature description"
```

### Step 2: Display Plan List

```
╔══════════════════════════════════════════════════════════════╗
║  📋 DEVELOPMENT PLANS                                        ║
╚══════════════════════════════════════════════════════════════╝

Active: feature-notifications

┌──────────────────────────────────────────────────────────────┐
│ #  │ Name                 │ Type    │ Status      │ Progress │
├──────────────────────────────────────────────────────────────┤
│ 1  │ Task Manager App     │ project │ ✅ complete │ 5/5      │
│ 2  │ Push Notifications   │ feature │ 🔄 active   │ 1/2      │ ← ACTIVE
│ 3  │ Dark Mode Support    │ feature │ 📋 planned  │ 0/1      │
└──────────────────────────────────────────────────────────────┘

Commands:
  /devteam:select <#>     Select a plan to work on
  /devteam:implement           Execute the active plan
  /devteam:plan --feature Create new feature plan
  /devteam:archive <#>    Archive a completed plan (planned, not yet implemented)
```

### Status Icons

| Icon | Status | Meaning |
|------|--------|---------|
| 📋 | `planned` | Plan created, not started |
| 🔄 | `in_progress` | Currently being executed |
| ✅ | `complete` | All sprints finished |
| ⏸️ | `paused` | Execution paused |
| ❌ | `failed` | Circuit breaker triggered |
| 📦 | `archived` | Moved to archive |

### With `--all` Flag

Include archived plans:

```
╔══════════════════════════════════════════════════════════════╗
║  📋 DEVELOPMENT PLANS (including archived)                   ║
╚══════════════════════════════════════════════════════════════╝

Active Plans:
│ #  │ Name                 │ Type    │ Status      │ Progress │
│ 1  │ Task Manager App     │ project │ ✅ complete │ 5/5      │
│ 2  │ Push Notifications   │ feature │ 🔄 active   │ 1/2      │
│ 3  │ Dark Mode Support    │ feature │ 📋 planned  │ 0/1      │

Archived Plans:
│ 4  │ Old Dashboard        │ feature │ 📦 archived │ 2/2      │
│ 5  │ Cancelled Auth       │ feature │ 📦 archived │ 0/3      │
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
  ✅ TASK-001: Create notification schema
  ✅ TASK-002: Add notification API endpoints
  🔄 TASK-003: Implement push service
  📋 TASK-004: Add notification preferences UI

Run /devteam:implement to continue execution.
```
