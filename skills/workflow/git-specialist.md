# Git Specialist Skill

Expert git operations for complex version control scenarios.

## Activation

This skill activates when:
- Git operations needed
- Merge conflicts arise
- Branch management required
- History needs cleaning

## Common Operations

### Branch Management

```bash
# Create feature branch
git checkout -b feature/user-auth

# Rename branch
git branch -m old-name new-name

# Delete local branch
git branch -d branch-name
git branch -D branch-name  # Force delete

# Delete remote branch
git push origin --delete branch-name

# List branches
git branch -a  # All
git branch -r  # Remote only
git branch --merged  # Merged branches
```

### Commit Operations

```bash
# Amend last commit (message only)
git commit --amend -m "New message"

# Amend last commit (include staged changes)
git commit --amend --no-edit

# Undo last commit (keep changes)
git reset --soft HEAD~1

# Undo last commit (discard changes)
git reset --hard HEAD~1

# Create fixup commit (for rebase)
git commit --fixup=<commit-hash>
```

### Rebasing

```bash
# Interactive rebase last 5 commits
git rebase -i HEAD~5

# Rebase onto main
git rebase main

# Continue after fixing conflicts
git rebase --continue

# Abort rebase
git rebase --abort

# Autosquash fixup commits
git rebase -i --autosquash main
```

### Cherry-picking

```bash
# Cherry-pick single commit
git cherry-pick <commit-hash>

# Cherry-pick range
git cherry-pick <start>..<end>

# Cherry-pick without committing
git cherry-pick -n <commit-hash>
```

### Stashing

```bash
# Stash changes
git stash

# Stash with message
git stash push -m "WIP: feature work"

# List stashes
git stash list

# Apply most recent stash
git stash pop

# Apply specific stash
git stash apply stash@{2}

# Create branch from stash
git stash branch new-branch stash@{0}
```

## Conflict Resolution

### Identify Conflicts

```bash
# Show conflicting files
git diff --name-only --diff-filter=U

# Show conflict markers
grep -r "<<<<<<< HEAD" .
```

### Resolution Strategies

```bash
# Accept ours (current branch)
git checkout --ours path/to/file
git add path/to/file

# Accept theirs (incoming branch)
git checkout --theirs path/to/file
git add path/to/file

# Manual merge with tool
git mergetool
```

### Complex Merge Example

```bash
# Merge with strategy
git merge feature-branch -X ours  # Prefer current
git merge feature-branch -X theirs  # Prefer incoming

# Merge squash (combine all commits)
git merge --squash feature-branch
git commit -m "Merge feature: user authentication"
```

## History Investigation

```bash
# Find who changed a line
git blame file.py

# Search commit messages
git log --grep="bug fix"

# Search code changes
git log -S "function_name" --oneline

# Show changes in commit
git show <commit-hash>

# Show file at specific commit
git show <commit-hash>:path/to/file

# Find when bug was introduced
git bisect start
git bisect bad  # Current commit is bad
git bisect good <known-good-commit>
# Git will checkout commits to test
git bisect good  # or git bisect bad
# Continue until bug found
git bisect reset
```

## Cleanup Operations

```bash
# Remove untracked files (dry run)
git clean -n

# Remove untracked files
git clean -f

# Remove untracked files and directories
git clean -fd

# Remove ignored files too
git clean -fdx

# Garbage collection
git gc --aggressive

# Remove old reflog entries
git reflog expire --expire=now --all
git gc --prune=now
```

## Advanced Workflows

### Split Commit

```bash
# Start interactive rebase
git rebase -i HEAD~3

# Mark commit as 'edit'
# After stopping:
git reset HEAD~1
git add file1.py
git commit -m "Part 1"
git add file2.py
git commit -m "Part 2"
git rebase --continue
```

### Combine Commits

```bash
# Interactive rebase
git rebase -i HEAD~3

# Change 'pick' to 'squash' or 'fixup'
# pick abc123 First commit
# squash def456 Second commit
# squash ghi789 Third commit
```

### Move Commits to Different Branch

```bash
# Cherry-pick to new branch
git checkout -b new-branch
git cherry-pick <commit1> <commit2>

# Remove from old branch
git checkout old-branch
git reset --hard HEAD~2
```

## Git Hooks

```bash
# Pre-commit hook example
#!/bin/sh
# .git/hooks/pre-commit

# Run linting
npm run lint
if [ $? -ne 0 ]; then
    echo "Linting failed!"
    exit 1
fi

# Check for secrets
git diff --cached --name-only | xargs grep -l "API_KEY\|SECRET" && {
    echo "Potential secret detected!"
    exit 1
}
```

## Worktree Management

```bash
# Add worktree for parallel work
git worktree add ../feature-branch feature/new-feature

# List worktrees
git worktree list

# Remove worktree
git worktree remove ../feature-branch
```

## Recovery Operations

```bash
# Recover deleted branch
git reflog
git checkout -b recovered-branch <commit-hash>

# Recover deleted stash
git fsck --unreachable | grep commit | cut -d' ' -f3 | xargs git show

# Recover file from history
git checkout <commit-hash> -- path/to/file
```

## Quality Checks

- [ ] Clean history (no "fix typo" commits)
- [ ] Meaningful commit messages
- [ ] No merge commits in feature branches
- [ ] No sensitive data in history
- [ ] Proper branch naming
