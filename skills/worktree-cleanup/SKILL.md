---
name: worktree-cleanup
description: Manually clean up development track worktrees. Debug/Expert command - rarely needed as worktrees are cleaned up automatically.
argument-hint: [track-number] [--all]
user-invocable: true
allowed-tools: Read, Glob, Grep, Bash
model: haiku
---

# Worktree Cleanup Command

**Debug/Expert Command** - Manually clean up development track worktrees.

> **Note:** This command is rarely needed. Worktrees are cleaned up automatically after `/devteam:implement` merges all tracks. Use this only if automatic cleanup failed or you need manual control.

## Command Usage

```bash
/devteam:worktree cleanup            # Clean up all worktrees
/devteam:worktree cleanup 01         # Clean up specific track
/devteam:worktree cleanup --all      # Clean up worktrees AND delete branches
```

## Warning

This command is destructive. Use with caution.

## Your Process

### Step 1: Load State and Validate

1. Load state from SQLite database (`.devteam/devteam.db`) via `source scripts/state.sh`
2. Verify worktree mode enabled
3. If specific track, verify track exists
4. Check if tracks are complete (warning if not)

### Step 2: Safety Checks

For each worktree to be removed:

```bash
cd "$worktree_path"

# Check for uncommitted changes
if [ -n "$(git status --porcelain)" ]; then
    echo "ERROR: Uncommitted changes in $worktree_path"
    echo "  Please commit or stash changes first"
    exit 1
fi

# Check if pushed to remote
if git status | grep "Your branch is ahead"; then
    echo "WARNING: Unpushed commits in $worktree_path"
    echo "  Recommend pushing before cleanup"
    read -p "Continue anyway? (y/N): " confirm
    if [ "$confirm" != "y" ]; then
        exit 1
    fi
fi
```

### Step 3: Remove Worktrees

For each worktree:

```bash
cd "$MAIN_REPO"

echo "Removing worktree: $worktree_path"
git worktree remove "$worktree_path"

if [ $? -eq 0 ]; then
    echo "Removed: $worktree_path"
else
    echo "Failed to remove: $worktree_path"
    echo "  Try: git worktree remove --force $worktree_path"
fi
```

### Step 4: Remove Empty Directory

```bash
if [ -d ".multi-agent" ] && [ -z "$(ls -A .multi-agent)" ]; then
    rmdir .multi-agent
    echo "Removed empty .multi-agent/ directory"
fi
```

### Step 5: Optionally Delete Branches

If `--all` flag:

```bash
for track in tracks:
    branch = "dev-track-${track:02d}"

    # Safety: verify branch is merged
    if git branch --merged | grep -q "$branch"; then
        git branch -d "$branch"
        echo "Deleted branch: $branch"
    else
        echo "Branch $branch not fully merged - keeping for safety"
        echo "  To force delete: git branch -D $branch"
    fi
done
```

### Step 6: Update State in SQLite

```bash
# Update state in SQLite database (.devteam/devteam.db)
source scripts/state.sh

set_kv_state "cleanup_info.cleaned_at" "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
set_kv_state "cleanup_info.worktrees_removed" "1,2,3"
set_kv_state "cleanup_info.branches_deleted" "true"  # or "false"
```

## Output Format

**Success:**
```
Worktree Cleanup

Cleaning up worktrees for all tracks...

Track 1:
  Verified no uncommitted changes
  Warning: 3 unpushed commits
  Worktree removed: .multi-agent/track-01/

Track 2:
  Verified no uncommitted changes
  Verified pushed to remote
  Worktree removed: .multi-agent/track-02/

Track 3:
  Verified no uncommitted changes
  Verified pushed to remote
  Worktree removed: .multi-agent/track-03/

Removed .multi-agent/ directory

Branches kept (to remove: use --all flag):
  - dev-track-01
  - dev-track-02
  - dev-track-03

Cleanup complete!
```

**With --all flag:**
```
Worktree Cleanup (Including Branches)

Cleaning up worktrees and branches...

Worktrees:
  Removed: .multi-agent/track-01/
  Removed: .multi-agent/track-02/
  Removed: .multi-agent/track-03/
  Removed: .multi-agent/ directory

Branches:
  Deleted: dev-track-01 (was merged)
  Deleted: dev-track-02 (was merged)
  Deleted: dev-track-03 (was merged)

All worktrees and branches removed!

Note: Development history is still in main branch commits.
```

## Error Handling

**Uncommitted changes:**
```
Cannot clean up worktree: .multi-agent/track-02/

Uncommitted changes detected:
  M  src/components/Header.tsx
  M  src/pages/Dashboard.tsx
  ?? src/components/NewFeature.tsx

Please commit or stash these changes:
  cd .multi-agent/track-02/
  git add .
  git commit -m "Final changes"

Or force removal (WILL LOSE CHANGES):
  git worktree remove --force .multi-agent/track-02/
```

**Track not complete:**
```
WARNING: Cleaning up incomplete tracks

Track 2 progress: 1/2 sprints complete (4/6 tasks)
Track 3 progress: 0/2 sprints complete (0/5 tasks)

Are you sure you want to remove these worktrees?
Work will be lost unless already committed.

To continue: /devteam:worktree cleanup --force
```

## Safety Notes

- Always checks for uncommitted changes
- Warns about unpushed commits
- Won't delete unmerged branches (without -D flag)
- Can be undone if branches kept (recreate worktree)
- Updates SQLite state database for audit trail
