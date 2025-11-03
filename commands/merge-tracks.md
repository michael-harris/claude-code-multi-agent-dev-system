# Merge Tracks Command

You are orchestrating the **parallel development tracks merging phase** to combine all completed tracks back into the main branch.

## Command Usage

```bash
/multi-agent:merge-tracks                      # Merge all tracks, create PR, cleanup worktrees (default)
/multi-agent:merge-tracks --manual-merge       # Merge all tracks, skip PR, cleanup worktrees
/multi-agent:merge-tracks --keep-worktrees     # Merge, create PR, keep worktrees
/multi-agent:merge-tracks --delete-branches    # Merge, create PR, cleanup worktrees & branches
/multi-agent:merge-tracks --dry-run            # Show what would be merged without doing it
```

**Flags:**
- `--manual-merge`: Skip automatic PR creation after merge, allow manual PR creation
- `--keep-worktrees`: Keep worktrees after merge (default: delete)
- `--delete-branches`: Delete track branches after merge (default: keep)
- `--dry-run`: Preview merge plan without executing

## Prerequisites

This command only works for projects planned with git worktrees (`--use-worktrees` flag).

**Pre-flight checks:**
1. State file must exist with worktree mode enabled
2. All tracks must be complete (all sprints in all tracks marked "completed")
3. No uncommitted changes in any worktree
4. All worktrees should have pushed to remote (optional but recommended)

## Your Process

### Step 0: Parse Parameters

Extract flags from command:
- `--manual-merge`: Skip PR creation after merge (default: false)
- `--keep-worktrees`: Do not delete worktrees after merge (default: false)
- `--delete-branches`: Delete track branches after merge (default: false)
- `--dry-run`: Show merge plan without executing (default: false)

### Step 1: Load State and Validate

1. **Load state file** (`docs/planning/.project-state.yaml`)

2. **Verify worktree mode:**
   ```python
   if state.parallel_tracks.mode != "worktrees":
       error("This project was not planned with worktrees. Nothing to merge.")
       suggest("/multi-agent:sprint all  # All work already in main branch")
       exit(1)
   ```

3. **Verify all tracks complete:**
   ```python
   incomplete_tracks = []
   for track_id, track_info in state.parallel_tracks.track_info.items():
       track_sprints = filter(s for s in state.sprints if s.track == track_id)
       if any(sprint.status != "completed" for sprint in track_sprints):
           incomplete_tracks.append(track_id)

   if incomplete_tracks:
       error(f"Cannot merge: Tracks {incomplete_tracks} not complete")
       suggest(f"/multi-agent:sprint all {incomplete_tracks[0]:02d}  # Complete remaining tracks")
       exit(1)
   ```

4. **Check for uncommitted changes:**
   ```bash
   for track in tracks:
       cd $worktree_path
       if [ -n "$(git status --porcelain)" ]; then
           error("Uncommitted changes in $worktree_path")
           suggest("Commit or stash changes before merging")
           exit(1)
       fi
   ```

5. **Check remote push status (warning only):**
   ```bash
   for track in tracks:
       cd $worktree_path
       if git status | grep "Your branch is ahead"; then
           warn("Track $track has unpushed commits - recommend pushing for backup")
       fi
   ```

### Step 2: Create Pre-Merge Backup

**Safety measure:**
```bash
# Return to main directory
cd $MAIN_REPO

# Create backup tag
git tag pre-merge-backup-$(date +%Y%m%d-%H%M%S)

echo "✓ Created backup tag: pre-merge-backup-YYYYMMDD-HHMMSS"
echo "  (To restore: git reset --hard <tag-name>)"
```

### Step 3: Show Merge Plan (Dry-Run)

If `--dry-run` flag:

```markdown
Merge Plan
═══════════════════════════════════════

Tracks to merge: 3
- Track 1 (dev-track-01): 7 commits, 15 files changed
- Track 2 (dev-track-02): 5 commits, 12 files changed
- Track 3 (dev-track-03): 4 commits, 8 files changed

Merge strategy: Sequential merge (track-01 → track-02 → track-03)
Target branch: main (or current branch)

Potential conflicts: 2 files
- src/config.yaml (modified in tracks 01 and 02)
- package.json (modified in tracks 01 and 03)

After merge:
- Delete worktrees: YES (default)
- Delete branches: NO (use --delete-branches to enable)

To proceed with merge:
/multi-agent:merge-tracks
```

Exit without merging.

### Step 4: Launch Track Merger Agent

If not dry-run, launch the **track-merger** agent:

```javascript
Task(
  subagent_type="multi-agent:orchestration:track-merger",
  model="sonnet",
  description="Merge all development tracks intelligently",
  prompt=`Merge all development tracks back to main branch.

State file: docs/planning/.project-state.yaml

Your responsibilities:
1. Verify all pre-flight checks passed
2. Ensure we're on the correct base branch (main or specified)
3. Merge each track branch sequentially:
   - Track 1: dev-track-01
   - Track 2: dev-track-02
   - Track 3: dev-track-03
4. Handle merge conflicts intelligently (use context from PRD and tasks)
5. Run integration tests after each merge
6. Create merge commit messages that reference track work
7. Tag the final merged state
8. Create pull request (unless --manual-merge)
9. Clean up worktrees (unless --keep-worktrees)
10. Optionally delete track branches (if --delete-branches)
11. Update state file to mark merge complete
12. Generate merge completion report

Flags:
- manual_merge: ${manual_merge}
- keep_worktrees: ${keep_worktrees}
- delete_branches: ${delete_branches}

Provide detailed progress updates and final summary.`
)
```

### Step 5: Post-Merge Verification

After track-merger completes:

1. **Run final project review** (same as sprint-all completion):
   - Comprehensive code review across all languages
   - Security audit
   - Performance audit
   - Integration testing
   - Documentation review

2. **Update state file:**
   ```yaml
   merge_info:
     merged_at: "2025-11-03T15:30:00Z"
     tracks_merged: [1, 2, 3]
     merge_commit: "abc123def456"
     conflicts_resolved: 2
     worktrees_cleaned: true
     branches_deleted: false
   ```

3. **Generate completion report** in `docs/merge-completion-report.md`

## Report Formats

### Successful Merge

```markdown
╔═══════════════════════════════════════════╗
║  🎉 TRACK MERGE SUCCESSFUL  🎉           ║
╚═══════════════════════════════════════════╝

Parallel Development Complete!

Tracks Merged: 3
- Track 1 (Backend): dev-track-01 → main
- Track 2 (Frontend): dev-track-02 → main
- Track 3 (Infrastructure): dev-track-03 → main

Merge Statistics:
- Total commits merged: 16
- Files changed: 35
- Conflicts resolved: 2
- Merge strategy: Sequential
- Merge commit: abc123def456

Quality Checks:
✅ Code review: PASS
✅ Security audit: PASS
✅ Performance audit: PASS
✅ Integration tests: PASS
✅ Documentation: Complete

Cleanup:
✅ Worktrees removed: .multi-agent/track-01/, track-02/, track-03/
⚠️  Branches kept: dev-track-01, dev-track-02, dev-track-03
    (Use --delete-branches to remove)

Final state:
- Working branch: main
- All parallel work now integrated
- Backup tag: pre-merge-backup-20251103-153000

Ready for deployment! 🚀

Full report: docs/merge-completion-report.md
```

### Merge with Conflicts

```markdown
⚠️  MERGE COMPLETED WITH MANUAL RESOLUTION REQUIRED

Tracks Merged: 2/3
- ✅ Track 1 (Backend): Merged successfully
- ✅ Track 2 (Frontend): Merged successfully
- ⚠️  Track 3 (Infrastructure): Conflicts detected

Conflicts in Track 3:
1. src/config.yaml (lines 45-52)
   - Track 01 changes: Database connection settings
   - Track 03 changes: Deployment configuration
   - Resolution needed: Combine both changes

2. package.json (line 23)
   - Track 01 changes: Added express dependency
   - Track 03 changes: Added docker dependency
   - Resolution needed: Include both dependencies

To resolve:
1. Edit the conflicted files manually
2. Run tests to verify
3. Commit the resolution: git commit
4. Re-run: /multi-agent:merge-tracks

Backup available: pre-merge-backup-20251103-153000
```

## Error Handling

**Incomplete tracks:**
```
Error: Cannot merge - incomplete tracks detected

Track 2 status: 1/2 sprints complete
Track 3 status: 0/2 sprints complete

Complete all tracks before merging:
/multi-agent:sprint all 02
/multi-agent:sprint all 03

Then retry: /multi-agent:merge-tracks
```

**Not worktree mode:**
```
Error: This project was not planned with git worktrees

Your project uses state-only mode for track separation.
All work is already in the main branch - no merge needed.

Project is complete! Run final review if needed:
/multi-agent:sprint all
```

**Uncommitted changes:**
```
Error: Uncommitted changes in worktree .multi-agent/track-02/

Please commit or stash changes before merging:
cd .multi-agent/track-02/
git status
git add .
git commit -m "Final changes before merge"

Then retry: /multi-agent:merge-tracks
```

## Important Notes

- Always creates backup tag before merge (safety)
- Merges tracks sequentially (not all at once)
- Intelligently resolves conflicts using PRD/task context
- Runs full quality checks after merge
- Default: deletes worktrees, keeps branches
- Use --delete-branches carefully (branches are lightweight and provide history)
- Can be re-run if interrupted (idempotent after conflicts resolved)
