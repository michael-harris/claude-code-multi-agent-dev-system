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

Parse the issue description to determine:

**Issue type:**
- Keywords like "not working", "broken", "error" → `bug`
- Keywords like "add", "implement", "feature" → `enhancement`
- Keywords like "slow", "timeout", "performance" → `performance`
- Keywords like "security", "vulnerability", "injection" → `security`
- Keywords like "critical", "urgent", "ASAP" → add `priority: high`

**Affected area (if detectable):**
- "login", "auth", "user" → `area: authentication`
- "API", "endpoint", "request" → `area: backend`
- "UI", "button", "page", "mobile" → `area: frontend`
- "database", "query", "data" → `area: database`

### Step 2: Gather Additional Context

If needed, investigate the codebase to add context:

```javascript
// Search for related code
const relatedFiles = await grep(description.keywords)

// Check for similar issues
const similarIssues = await gh('issue list --search "${description}"')

// Check recent commits in related area
const recentChanges = await git('log --oneline -10 -- ${relatedPaths}')
```

### Step 3: Format Issue

Create well-structured issue body:

```markdown
## Description

[Clear description of the issue]

## Steps to Reproduce

1. [Step 1]
2. [Step 2]
3. [Step 3]

## Expected Behavior

[What should happen]

## Actual Behavior

[What actually happens]

## Environment

- OS: [if relevant]
- Browser: [if relevant]
- Version: [if relevant]

## Additional Context

[Any additional information, screenshots, logs]

## Related Code

[Files that might be related]

---
*Created via DevTeam*
```

### Step 4: Create Issue

```bash
gh issue create \
  --title "${title}" \
  --body "${body}" \
  --label "${labels}" \
  --assignee "${assignee}"  # Optional
```

### Step 5: Report to User

```
╔══════════════════════════════════════════╗
║  📝 ISSUE CREATED                        ║
╚══════════════════════════════════════════╝

Issue #127: Login button not working on mobile

Labels: bug, area: frontend, priority: medium
URL: https://github.com/user/repo/issues/127

To fix this issue automatically:
  /devteam:issue 127
```

## Examples

### Bug Report
```bash
/devteam:issue-new "Users get 500 error when uploading large files"
```
Creates:
```markdown
## Description

Users encounter a 500 Internal Server Error when attempting to upload large files.

## Steps to Reproduce

1. Navigate to the upload page
2. Select a file larger than [threshold]
3. Click upload
4. Observe 500 error

## Expected Behavior

File should upload successfully or show a helpful error message if too large.

## Actual Behavior

Server returns 500 error with no helpful message.

## Related Code

Potentially related files:
- `backend/routes/upload.py`
- `backend/services/file_service.py`

---
*Created via DevTeam*
```

### Enhancement Request
```bash
/devteam:issue-new "Add dark mode support"
```
Creates:
```markdown
## Description

Add support for dark mode theme to improve user experience and accessibility.

## Proposed Solution

1. Add theme toggle in settings
2. Implement dark color palette
3. Persist user preference
4. Respect system preference as default

## Benefits

- Reduced eye strain in low-light conditions
- Battery savings on OLED displays
- Modern user experience

## Related Code

Potentially related files:
- `frontend/src/styles/theme.ts`
- `frontend/src/context/ThemeContext.tsx`

---
*Created via DevTeam*
```

### Security Issue
```bash
/devteam:issue-new "SQL injection possible in user search"
```
Creates:
```markdown
## ⚠️ Security Issue

**Type:** SQL Injection
**Severity:** High
**Area:** Backend - User Search

## Description

Potential SQL injection vulnerability in the user search functionality.

## Impact

An attacker could potentially:
- Read unauthorized data
- Modify or delete data
- Escalate privileges

## Recommendation

1. Use parameterized queries
2. Validate and sanitize input
3. Implement input length limits

## Related Code

Potentially affected files:
- `backend/routes/users.py`
- `backend/services/search_service.py`

**Note:** This issue should be treated as high priority.

---
*Created via DevTeam*
```

## Labels Applied Automatically

| Detected Keywords | Labels Applied |
|------------------|----------------|
| bug, error, broken, not working | `bug` |
| add, feature, implement | `enhancement` |
| slow, performance, timeout | `performance` |
| security, vulnerability, injection | `security`, `priority: high` |
| critical, urgent | `priority: high` |
| minor, low priority | `priority: low` |
| docs, documentation | `documentation` |

## Options

```bash
--label <label>    # Add specific label
--assignee <user>  # Assign to user
--project <name>   # Add to project
--milestone <name> # Add to milestone
--draft            # Create as draft
```

## Integration

After creating, suggest next steps:

```
Issue created successfully!

Next steps:
  • /devteam:issue 127  - Fix this issue automatically
  • gh issue view 127   - View on GitHub
  • gh issue edit 127   - Edit issue details
```
