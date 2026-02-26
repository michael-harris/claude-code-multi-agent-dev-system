---
name: devteam-issue-new
description: Create a new GitHub issue with proper formatting, labels, and context from the codebase.
argument-hint: "<description>" [--label <label>] [--assignee <user>]
user-invocable: true
allowed-tools: Read, Glob, Grep, Bash
model: sonnet
---

Repository: !`gh repo view --json nameWithOwner -q .nameWithOwner 2>/dev/null || echo "No GitHub repo detected"`
Recent issues: !`gh issue list --limit 5 --json number,title,labels -q '.[] | "#\(.number) \(.title) [\(.labels | map(.name) | join(", "))]"' 2>/dev/null || echo "No issues found"`

# DevTeam Issue New Command

**Command:** `/devteam:issue-new "<description>"`

Create a new GitHub issue with proper formatting and labels.

## Usage

```bash
/devteam:issue-new "Login button not working on mobile"
/devteam:issue-new "Add dark mode support" --label enhancement
/devteam:issue-new "Critical: SQL injection in user search" --label security
```

## Your Process

### Step 1: Analyze Description

Parse the issue description from `$ARGUMENTS` to determine:

**Issue type** (from keywords):
- "not working", "broken", "error" -> `bug`
- "add", "implement", "feature" -> `enhancement`
- "slow", "timeout", "performance" -> `performance`
- "security", "vulnerability", "injection" -> `security`, `priority: high`
- "critical", "urgent" -> add `priority: high`

**Affected area** (if detectable):
- "login", "auth", "user" -> `area: authentication`
- "API", "endpoint", "request" -> `area: backend`
- "UI", "button", "page", "mobile" -> `area: frontend`
- "database", "query", "data" -> `area: database`

### Step 2: Gather Additional Context

Search codebase for related files and check for similar existing issues:

```bash
# Search for related code
grep -r "keyword" --include="*.py" --include="*.ts" -l

# Check for similar issues
gh issue list --search "description keywords"

# Check recent commits in related area
git log --oneline -10 -- related/paths/
```

### Step 3: Format Issue

Create well-structured issue body with:
- Description
- Steps to Reproduce (for bugs)
- Expected vs Actual Behavior (for bugs)
- Proposed Solution (for enhancements)
- Related Code (files found in Step 2)

### Step 4: Create Issue

```bash
gh issue create \
  --title "${title}" \
  --body "${body}" \
  --label "${labels}"
```

### Step 5: Report to User

Show created issue number, URL, labels, and suggest next steps:
- `/devteam:issue <number>` to fix automatically
- `gh issue view <number>` to view on GitHub

## Labels Applied Automatically

| Detected Keywords | Labels Applied |
|------------------|----------------|
| bug, error, broken, not working | `bug` |
| add, feature, implement | `enhancement` |
| slow, performance, timeout | `performance` |
| security, vulnerability, injection | `security`, `priority: high` |
| critical, urgent | `priority: high` |
| docs, documentation | `documentation` |

## Options

- `--label <label>`: Add specific label
- `--assignee <user>`: Assign to user
- `--project <name>`: Add to project
- `--milestone <name>`: Add to milestone

## See Also

- `/devteam:issue` - Fix an existing issue automatically
- `/devteam:bug` - Diagnose and fix bugs with Bug Council
