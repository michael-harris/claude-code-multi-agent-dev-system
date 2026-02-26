---
name: worktree-status
description: Show detailed status of all development track worktrees. Debug/Expert command for worktree diagnostics.
argument-hint: [track-number]
user-invocable: true
allowed-tools: Read, Glob, Grep, Bash
model: haiku
---

Git worktrees: !`git worktree list 2>/dev/null || echo "Not a git repository"`
Worktree mode: !`source "${CLAUDE_PLUGIN_ROOT}/scripts/state.sh" && get_kv_state "parallel_tracks.mode" 2>/dev/null || echo "unknown"`
Native worktrees: !`ls -d .claude/worktrees/*/ 2>/dev/null || echo "None"`
Legacy worktrees: !`ls -d .multi-agent/track-*/ 2>/dev/null || echo "None"`

# Worktree Status Command

**Debug/Expert Command** - Shows detailed status of all development track worktrees.

> **Note:** This command is rarely needed. Worktrees are managed automatically by `/devteam:implement`. Use this only for debugging worktree issues.

## Command Usage

```bash
/devteam:worktree status         # Show all worktree status
/devteam:worktree status 01      # Show status for specific track
```

## Your Process

### Step 1: Load State from SQLite

Query the SQLite database (`.devteam/devteam.db`) to get worktree configuration:

```bash
source "${CLAUDE_PLUGIN_ROOT}/scripts/state.sh"

# Check worktree mode
mode=$(get_state "parallel_tracks.mode")
```

If not worktree mode:
```
This project is not using git worktrees (mode: state-only)

No worktrees to show status for.
```

### Step 2: Collect Worktree Information

For each track in the state database:

```bash
track_num = "01"
worktree_path = ".multi-agent/track-01"
branch_name = "dev-track-01"

# Check if worktree exists
if [ -d "$worktree_path" ]; then
    exists = true

    cd "$worktree_path"

    # Get git status
    current_branch = $(git rev-parse --abbrev-ref HEAD)
    uncommitted = $(git status --porcelain | wc -l)
    ahead = $(git rev-list --count @{u}..HEAD 2>/dev/null || echo "N/A")
    behind = $(git rev-list --count HEAD..@{u} 2>/dev/null || echo "N/A")

    # Get sprint status from SQLite database
    sprints = get_sprints_for_track(track_num)  # via: source "${CLAUDE_PLUGIN_ROOT}/scripts/state.sh"
    completed_sprints = count(s for s in sprints if s.status == "completed")
    total_sprints = len(sprints)

    # Get task status from SQLite database
    tasks = get_tasks_for_track(track_num)  # via: source "${CLAUDE_PLUGIN_ROOT}/scripts/state.sh"
    completed_tasks = count(t for t in tasks if t.status == "completed")
    total_tasks = len(tasks)

else
    exists = false
fi
```

### Step 3: Display Status

**For all tracks:**

```
Development Track Status

Mode: Git worktrees (physical isolation)
Base path: .multi-agent/

Track 1: Backend API
Status: ACTIVE
Location: .multi-agent/track-01/
Branch: dev-track-01 (current)
Progress: 2/2 sprints complete (7/7 tasks)
Git status:
  Uncommitted changes: 0
  Ahead of remote: 3 commits
  Behind remote: 0
  Action: Push recommended

Track 2: Frontend
Status: IN PROGRESS
Location: .multi-agent/track-02/
Branch: dev-track-02 (current)
Progress: 1/2 sprints complete (4/6 tasks)
Git status:
  Uncommitted changes: 5 files
  Ahead of remote: 2 commits
  Behind remote: 0
  Action: Commit and push needed

Track 3: Infrastructure
Status: PENDING
Location: .multi-agent/track-03/
Branch: dev-track-03 (current)
Progress: 0/2 sprints complete (0/5 tasks)
Git status:
  Uncommitted changes: 0
  Ahead of remote: 0
  Behind remote: 0
  Action: Clean

Summary
Total tracks: 3
Complete: 1
In progress: 1
Pending: 1

Warnings:
  Track 1: Unpushed commits (backup recommended)
  Track 2: Uncommitted changes (commit before merge)

Next steps:
  Track 2: /devteam:implement --sprint all 02
  Track 3: /devteam:implement --sprint all 03
  After all complete: /devteam:merge-tracks
```

**For specific track:**

```
Track 01: Backend API

Worktree Information:
Location: .multi-agent/track-01/
Branch: dev-track-01 (current: dev-track-01)
Status: Active

Progress:
Sprints: 2/2 complete
  SPRINT-001-01: Foundation (5 tasks)          [done]
  SPRINT-002-01: Advanced Features (2 tasks)   [done]

Tasks: 7/7 complete
  TASK-001: Database schema design             [done]
  TASK-004: User authentication API            [done]
  TASK-008: Product catalog API                [done]
  TASK-012: Shopping cart API                   [done]
  TASK-016: Payment integration                [done]
  TASK-006: Email notifications                [done]
  TASK-018: Admin dashboard API                [done]

Git Status:
Uncommitted changes: 0
Staged files: 0
Commits ahead of remote: 3
Commits behind remote: 0

Recent commits:
  abc123 (2 hours ago) Complete TASK-018: Admin dashboard
  def456 (3 hours ago) Complete TASK-016: Payment integration
  ghi789 (4 hours ago) Complete SPRINT-001-01

Actions Needed:
  Push commits to remote (backup)
    git push origin dev-track-01

Ready for merge:
  All sprints complete
  All tasks complete
  No uncommitted changes
  Not pushed (recommended before merge)

When ready:
  /devteam:merge-tracks
```

## Error Handling

**Worktree missing:**
```
Track 02: Frontend

Status: ERROR - Worktree not found

Expected location: .multi-agent/track-02/
Expected branch: dev-track-02

The worktree appears to be missing or was removed.

To recreate:
  git worktree add .multi-agent/track-02 -b dev-track-02

Or recreate all with:
  /devteam:planning 3 --use-worktrees
```

**Wrong branch:**
```
Track 01: Backend API

Status: WARNING - Branch mismatch

Location: .multi-agent/track-01/
Expected branch: dev-track-01
Current branch: main

The worktree is on the wrong branch.

To fix:
  cd .multi-agent/track-01/
  git checkout dev-track-01
```

## Worktree Sources

Check worktrees from both sources:
1. **Native Claude Code worktrees**: `.claude/worktrees/` (from `isolation: worktree`)
2. **Legacy DevTeam worktrees**: `.multi-agent/track-*/` (from manual management)

## Notes

- This command is read-only (no changes made)
- Shows aggregate status for quick health check
- Warns about issues that could block merging
- Useful before running merge-tracks

## See Also

- `/devteam:worktree-list` - Quick list of all worktrees
- `/devteam:worktree-cleanup` - Clean up worktrees
- `/devteam:merge-tracks` - Merge all tracks
