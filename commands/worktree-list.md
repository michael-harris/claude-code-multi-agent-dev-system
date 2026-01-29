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

### Step 2: Load State File

Read `docs/planning/.project-state.yaml` to correlate git worktrees with development tracks.

### Step 3: Display Worktree Information

```markdown
═══════════════════════════════════════════
 Git Worktrees
═══════════════════════════════════════════

Mode: Git worktrees enabled
State file: docs/planning/.project-state.yaml

Main Repository:
───────────────────────────────────────────
Path: /home/user/my-project
Branch: main
HEAD: abc123 (2 hours ago)

Development Track Worktrees:
───────────────────────────────────────────

Track 01: Backend API
  Path: /home/user/my-project/.multi-agent/track-01
  Branch: dev-track-01
  HEAD: def456 (30 min ago)
  Status: ✅ Complete (2/2 sprints)
  Size: 45 MB

Track 02: Frontend
  Path: /home/user/my-project/.multi-agent/track-02
  Branch: dev-track-02
  HEAD: ghi789 (1 hour ago)
  Status: 🔄 In Progress (1/2 sprints)
  Size: 52 MB

Track 03: Infrastructure
  Path: /home/user/my-project/.multi-agent/track-03
  Branch: dev-track-03
  HEAD: jkl012 (2 hours ago)
  Status: ⏸️  Pending (0/2 sprints)
  Size: 38 MB

═══════════════════════════════════════════
Summary
═══════════════════════════════════════════
Total worktrees: 4 (1 main + 3 tracks)
Total disk usage: ~135 MB
Tracks complete: 1/3

Commands:
  Status: /devteam:worktree status
  Cleanup: /devteam:worktree cleanup
  Merge: /devteam:merge-tracks
```

## Alternative: Simple Format

```markdown
Worktrees:
  main       /home/user/my-project                             (abc123)
  track-01   /home/user/my-project/.multi-agent/track-01       (def456) ✅
  track-02   /home/user/my-project/.multi-agent/track-02       (ghi789) 🔄
  track-03   /home/user/my-project/.multi-agent/track-03       (jkl012) ⏸️
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

## Notes

- Shows all worktrees (not just multi-agent tracks)
- Correlates with state file for track information
- Displays disk usage per worktree
- Quick reference for expert users
