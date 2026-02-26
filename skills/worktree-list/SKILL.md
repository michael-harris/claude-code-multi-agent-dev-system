---
name: worktree-list
description: List all git worktrees with development track information. Debug/Expert command for worktree diagnostics.
argument-hint: ""
user-invocable: true
allowed-tools: Read, Glob, Grep, Bash
model: haiku
---

Git worktrees: !`git worktree list 2>/dev/null || echo "Not a git repository"`
Native worktrees: !`ls -d .claude/worktrees/*/ 2>/dev/null || echo "None"`
Legacy worktrees: !`ls -d .multi-agent/track-*/ 2>/dev/null || echo "None"`
State DB exists: !`test -f .devteam/devteam.db && echo "yes" || echo "no"`

# Worktree List Command

**Debug/Expert Command** - List all git worktrees with development track information.

> **Note:** This command is rarely needed. Worktrees are managed automatically by `/devteam:implement`. Use this only for debugging worktree issues.

## Command Usage

```bash
/devteam:worktree list           # List all worktrees
```

## Your Process

### Step 1: Get Git Worktrees

```bash
# Get all git worktrees
git worktree list --porcelain
```

### Step 2: Load State from SQLite

Query the SQLite database (`.devteam/devteam.db`) to correlate git worktrees with development tracks:

```bash
source "${CLAUDE_PLUGIN_ROOT}/scripts/state.sh"
# Track info available via get_state "parallel_tracks.track_info.*"
```

### Step 3: Display Worktree Information

```
Git Worktrees

Mode: Git worktrees enabled
State database: .devteam/devteam.db

Main Repository:
Path: /home/user/my-project
Branch: main
HEAD: abc123 (2 hours ago)

Development Track Worktrees:

Track 01: Backend API
  Path: /home/user/my-project/.multi-agent/track-01
  Branch: dev-track-01
  HEAD: def456 (30 min ago)
  Status: Complete (2/2 sprints)
  Size: 45 MB

Track 02: Frontend
  Path: /home/user/my-project/.multi-agent/track-02
  Branch: dev-track-02
  HEAD: ghi789 (1 hour ago)
  Status: In Progress (1/2 sprints)
  Size: 52 MB

Track 03: Infrastructure
  Path: /home/user/my-project/.multi-agent/track-03
  Branch: dev-track-03
  HEAD: jkl012 (2 hours ago)
  Status: Pending (0/2 sprints)
  Size: 38 MB

Summary
Total worktrees: 4 (1 main + 3 tracks)
Total disk usage: ~135 MB
Tracks complete: 1/3

Commands:
  Status: /devteam:worktree status
  Cleanup: /devteam:worktree cleanup
  Merge: /devteam:merge-tracks
```

## Alternative: Simple Format

```
Worktrees:
  main       /home/user/my-project                             (abc123)
  track-01   /home/user/my-project/.multi-agent/track-01       (def456) complete
  track-02   /home/user/my-project/.multi-agent/track-02       (ghi789) active
  track-03   /home/user/my-project/.multi-agent/track-03       (jkl012) pending
```

## Error Handling

**No worktrees:**
```
No development track worktrees found.

This project is using state-only mode (not git worktrees).

To use worktrees:
  /devteam:plan (worktrees are auto-configured for multi-track plans)
```

**Git command fails:**
```
Error: Could not list git worktrees

Make sure you're in a git repository:
  git status

If git is not working, check git installation:
  git --version
```

## Worktree Sources

Display worktrees from both sources:
1. **Native Claude Code worktrees**: `.claude/worktrees/` (from `isolation: worktree`)
2. **Legacy DevTeam worktrees**: `.multi-agent/track-*/` (from manual management)

## Notes

- Shows all worktrees (not just multi-agent tracks)
- Correlates with SQLite state database for track information
- Displays disk usage per worktree
- Quick reference for expert users

## See Also

- `/devteam:worktree-status` - Detailed worktree status
- `/devteam:worktree-cleanup` - Clean up worktrees
- `/devteam:merge-tracks` - Merge all tracks
