# Plan Management System

This system handles multiple plans, plan archival, and feature additions to existing projects.

## Problem Statement

Users may:
1. Plan a new project, then add features later
2. Plan multiple features in parallel
3. Want to revisit or modify previous plans
4. Accidentally overwrite work by running `/devteam:plan` twice

## Solution: Named Plans with Lifecycle Management

### Plan Types

```yaml
plan_types:
  project:
    description: "Full project from scratch"
    creates: "Full PRD, all tasks, all sprints"
    scope: "Entire codebase"

  feature:
    description: "New feature for existing project"
    creates: "Feature spec, feature tasks, feature sprint(s)"
    scope: "Feature-specific files only"
    requires: "Existing project or codebase"

  enhancement:
    description: "Improvement to existing feature"
    creates: "Enhancement spec, limited tasks"
    scope: "Specific files/modules"
```

### Directory Structure

```
.devteam/
├── plans/
│   ├── index.yaml                    # Master plan index
│   ├── project-taskmanager/          # Project plan
│   │   ├── PRD.yaml
│   │   ├── tasks/
│   │   ├── sprints/
│   │   └── state.yaml
│   ├── feature-notifications/        # Feature plan
│   │   ├── spec.yaml
│   │   ├── tasks/
│   │   ├── sprints/
│   │   └── state.yaml
│   └── feature-dark-mode/            # Another feature plan
│       ├── spec.yaml
│       ├── tasks/
│       ├── sprints/
│       └── state.yaml
│
├── archive/                          # Completed/abandoned plans
│   └── feature-old-dashboard/
│       ├── spec.yaml
│       └── state.yaml (status: archived)
│
└── active-plan.txt                   # Points to current active plan
```

### Plan Index (`plans/index.yaml`)

```yaml
version: "1.0"

plans:
  project-taskmanager:
    type: project
    name: "Task Manager Application"
    created: "2025-01-20T10:00:00Z"
    status: completed
    sprints_total: 5
    sprints_completed: 5

  feature-notifications:
    type: feature
    name: "Push Notifications"
    created: "2025-01-25T14:00:00Z"
    status: in_progress
    parent_plan: project-taskmanager  # Links to parent project
    sprints_total: 2
    sprints_completed: 1

  feature-dark-mode:
    type: feature
    name: "Dark Mode Support"
    created: "2025-01-28T09:00:00Z"
    status: planned
    parent_plan: project-taskmanager
    sprints_total: 1
    sprints_completed: 0

active_plan: feature-notifications    # Currently selected plan
```

### Command Updates

#### `/devteam:plan` - New Usage

```bash
# New project (creates named plan)
/devteam:plan "Task Manager App"
# → Creates: .devteam/plans/project-taskmanager/

# New feature for existing project
/devteam:plan --feature "Add notifications"
# → Creates: .devteam/plans/feature-notifications/
# → Links to parent project automatically

# Enhancement to existing feature
/devteam:plan --enhance "Improve notification delivery"
# → Creates: .devteam/plans/enhancement-notification-delivery/

# With explicit name
/devteam:plan --name "dark-mode" --feature "Add dark mode"
# → Creates: .devteam/plans/feature-dark-mode/
```

#### `/devteam:list` - New Command

```bash
/devteam:list
```

Output:
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

Archived: 1 plan(s) in .devteam/archive/

Commands:
  /devteam:select 2       # Select a plan by number
  /devteam:select dark    # Select by name (partial match)
  /devteam:archive 1      # Archive completed plan
  /devteam:plan --feature # Create new feature plan
```

#### `/devteam:select` - New Command

```bash
/devteam:select 2                    # By number
/devteam:select notifications        # By name (partial match)
/devteam:select feature-dark-mode    # By full ID
```

Output:
```
✅ Selected plan: Push Notifications (feature-notifications)

Status: in_progress
Progress: Sprint 1/2 complete, Sprint 2 in progress
Current task: TASK-003 (Implement FCM integration)

Run /devteam:auto to continue execution.
```

#### `/devteam:auto` - Updated Behavior

```bash
/devteam:auto                 # Execute ACTIVE plan
/devteam:auto --plan dark     # Execute specific plan
```

If no active plan:
```
⚠️  No active plan selected.

Available plans:
  1. Task Manager App (complete)
  2. Push Notifications (in_progress)
  3. Dark Mode Support (planned)

Select a plan: /devteam:select <number>
Or create new: /devteam:plan
```

### Workflow: Adding Second Feature

```
User: /devteam:plan --feature "Add dark mode support"

System:
📋 Creating new feature plan...

I detected an existing project: Task Manager App
This feature will be added to that project.

Feature: Dark Mode Support
Type: feature
Parent: project-taskmanager

[Brief requirements questions specific to dark mode...]

✅ Feature plan created: feature-dark-mode

Files created:
  • .devteam/plans/feature-dark-mode/spec.yaml
  • .devteam/plans/feature-dark-mode/tasks/TASK-*.yaml
  • .devteam/plans/feature-dark-mode/sprints/SPRINT-001.yaml
  • .devteam/plans/feature-dark-mode/state.yaml

This plan is now ACTIVE.

Run /devteam:auto to execute, or /devteam:list to see all plans.
```

### Plan Selection Disambiguation

If user runs `/devteam:auto` with multiple in-progress plans:

```
⚠️  Multiple plans in progress:

  1. Push Notifications (Sprint 2/2)
  2. Dark Mode Support (Sprint 1/1)

Which plan do you want to execute?
  - Enter number (1 or 2)
  - Or run: /devteam:auto --plan <name>

>
```

### Archival

When a plan completes:

```
╔══════════════════════════════════════════════════════════════╗
║  🎉 PLAN COMPLETE: Push Notifications                        ║
╚══════════════════════════════════════════════════════════════╝

All sprints executed successfully.

Archive this plan? (yes/no)
  - Yes: Move to .devteam/archive/ (keeps record, clears active list)
  - No: Keep in plans/ (can re-run or modify)

>
```

### Migration from Current Structure

If user has existing `docs/planning/` structure:

```bash
/devteam:plan "New feature"

System detects:
  • docs/planning/PROJECT_PRD.yaml exists
  • docs/sprints/ contains completed sprints
  • .devteam/state.yaml shows project complete

Migrating to new plan structure...
  → Moving existing PRD to .devteam/plans/project-legacy/
  → Creating new feature plan: feature-new-feature
  → Setting feature-new-feature as active

Migration complete. Your existing work is preserved.
```

### State File Location

Each plan has its own state file:
- `.devteam/plans/project-taskmanager/state.yaml`
- `.devteam/plans/feature-notifications/state.yaml`

The global `.devteam/state.yaml` is replaced by plan-specific state files.

### Preventing Overwrites

When `/devteam:plan` is run:

1. Check if plans exist in `.devteam/plans/`
2. If yes, ask: "Create new feature plan or new project?"
3. If new project, warn: "This will create a separate project plan"
4. Never overwrite without explicit confirmation

```
⚠️  Existing plans detected:
  - project-taskmanager (complete)
  - feature-notifications (in_progress)

What would you like to do?
  1. Add a new FEATURE to Task Manager App
  2. Create a completely NEW PROJECT
  3. Cancel

>
```
