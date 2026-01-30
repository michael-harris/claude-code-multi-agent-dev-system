# DevTeam Select Command

**Command:** `/devteam:select`

Select a plan to work on. The selected plan becomes the active plan for `/devteam:implement`.

## Usage

```bash
/devteam:select 2                    # Select by number (from /devteam:list)
/devteam:select notifications        # Select by name (partial match)
/devteam:select feature-dark-mode    # Select by full plan ID
```

## Your Process

### Step 1: Identify Plan

**By number:**
```bash
/devteam:select 2
```
→ Look up plan #2 from index

**By partial name:**
```bash
/devteam:select dark
```
→ Search plans for "dark" in name/ID, confirm if multiple matches

**By full ID:**
```bash
/devteam:select feature-dark-mode
```
→ Direct lookup

### Step 2: Validate Plan

Check plan status:
- `planned` → Ready to start
- `in_progress` → Can resume
- `complete` → Warn user (can re-run but likely not needed)
- `archived` → Ask to unarchive first
- `failed` → Ask to reset circuit breaker

### Step 3: Update Active Plan

```bash
# Update index.yaml
active_plan: feature-dark-mode

# Update pointer file
echo "feature-dark-mode" > .devteam/active-plan.txt
```

### Step 4: Show Confirmation

```
✅ Selected plan: Dark Mode Support (feature-dark-mode)

Type: feature
Parent: project-taskmanager
Status: planned
Sprints: 1 total, 0 completed

Tasks:
  📋 TASK-001: Define dark mode color tokens
  📋 TASK-002: Create theme context
  📋 TASK-003: Update components for theme
  📋 TASK-004: Add theme toggle UI

Next steps:
  • /devteam:implement         Execute this plan
  • /devteam:plan --edit  Modify the plan
  • /devteam:list         See all plans
```

## Disambiguation

If partial match finds multiple plans:

```bash
/devteam:select mode
```

Output:
```
Multiple plans match "mode":

  1. feature-dark-mode (Dark Mode Support)
  2. feature-offline-mode (Offline Mode)

Enter number to select, or use full ID:
>
```

## Error Cases

**Plan not found:**
```
❌ No plan found matching "xyz"

Available plans:
  1. Task Manager App (project)
  2. Push Notifications (feature)
  3. Dark Mode Support (feature)

Use /devteam:list to see all plans.
```

**Selecting archived plan:**
```
⚠️  Plan "old-dashboard" is archived.

Would you like to:
  1. Unarchive and select it
  2. Cancel

>
```

**Selecting failed plan:**
```
⚠️  Plan "feature-auth" has a triggered circuit breaker.

Last failure: TASK-003 - Build error in AuthService
Consecutive failures: 5

Would you like to:
  1. Reset circuit breaker and retry
  2. Review failure logs first
  3. Cancel

>
```
