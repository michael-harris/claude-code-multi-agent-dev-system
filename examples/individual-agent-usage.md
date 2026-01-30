# Individual Agent Usage Examples

This guide shows how to use specific agents for targeted tasks without running full sprints.

---

## Scenario 1: Quick Database Schema Design

**Use Case:** You need to design a database schema before starting implementation.

### Agent to Use
`database:designer` (Opus)

### Code
```javascript
Task(
  subagent_type="multi-agent:database:designer",
  model="opus",
  description="Design user profile schema",
  prompt=`Design a normalized database schema for user profiles with the following requirements:

- Users can have one profile
- Profile includes: bio (text), avatar_url (string), location (string), social_links (array)
- Users can follow other users (many-to-many)
- Track when relationships were created

Provide the schema in YAML format following your standard output structure.`
)
```

### Expected Output
```yaml
# docs/design/database/user-profile-schema.yaml

tables:
  users:
    columns:
      id: {type: UUID, primary: true}
      email: {type: STRING, unique: true}
      created_at: {type: TIMESTAMP}
    indexes:
      - {columns: [email], unique: true}

  profiles:
    columns:
      id: {type: UUID, primary: true}
      user_id: {type: UUID, foreign_key: users.id, null: false}
      bio: {type: TEXT}
      avatar_url: {type: STRING}
      location: {type: STRING}
      social_links: {type: JSONB}
      updated_at: {type: TIMESTAMP}
    relationships:
      - {type: one-to-one, target: users, on_delete: CASCADE}
    indexes:
      - {columns: [user_id], unique: true}

  user_follows:
    columns:
      id: {type: UUID, primary: true}
      follower_id: {type: UUID, foreign_key: users.id}
      following_id: {type: UUID, foreign_key: users.id}
      created_at: {type: TIMESTAMP}
    relationships:
      - {type: many-to-one, target: users, foreign_key: follower_id}
      - {type: many-to-one, target: users, foreign_key: following_id}
    indexes:
      - {columns: [follower_id, following_id], unique: true}
    constraints:
      - {type: check, condition: "follower_id != following_id"}
```

---

## Scenario 2: Implement Database Models from Design

**Use Case:** You have a schema design and need to implement SQLAlchemy models.

### Agent to Use
`database:developer-python-t1` (Haiku) → Escalate to T2 if issues

### Code (T1 First)
```javascript
Task(
  subagent_type="multi-agent:database:developer-python-t1",
  model="haiku",
  description="Implement user profile SQLAlchemy models",
  prompt=`Implement SQLAlchemy models based on the schema design in docs/design/database/user-profile-schema.yaml

Requirements:
- Use SQLAlchemy 2.0 style
- Include __repr__ methods
- Add type hints
- Create Alembic migration

Project uses:
- Python 3.11+
- SQLAlchemy 2.0
- Alembic for migrations
- PostgreSQL database`
)
```

### If T1 Has Issues → Escalate to T2
```javascript
Task(
  subagent_type="multi-agent:database:developer-python-t2",
  model="sonnet",
  description="Fix complex relationship issues in models",
  prompt=`Review and fix the SQLAlchemy models created by T1 agent.

Issues identified:
- Circular import between User and Profile models
- user_follows self-referential relationship not properly configured
- Missing cascade deletes on relationships

Fix these issues while maintaining all other requirements.`
)
```

---

## Scenario 3: API Design Review

**Use Case:** You've manually written an API and want an expert review.

### Agent to Use
`backend:api-designer` (Opus)

### Code
```javascript
Task(
  subagent_type="multi-agent:backend:api-designer",
  model="opus",
  description="Review and improve API design",
  prompt=`Review the following API design and provide recommendations:

Current Endpoints:
- POST /users - Create user
- GET /users/:id - Get user
- POST /users/:id/profile - Create profile
- GET /users/:id/followers - Get followers
- POST /follow/:id - Follow user

Issues I'm concerned about:
1. Is the URL structure RESTful?
2. Should profile be a separate endpoint or nested?
3. How to handle unfollowing?
4. Pagination for followers list?

Provide a complete, improved API specification in YAML format.`
)
```

---

## Scenario 4: Implement API Endpoint

**Use Case:** You have an API specification and need implementation.

### Agent to Use
`backend:api-developer-python-t1` (Haiku)

### Code
```javascript
Task(
  subagent_type="multi-agent:backend:api-developer-python-t1",
  model="haiku",
  description="Implement user profile API endpoints",
  prompt=`Implement the following FastAPI endpoints based on docs/design/api/profile-api.yaml:

1. POST /api/profiles - Create user profile
2. GET /api/profiles/:user_id - Get profile
3. PUT /api/profiles/:user_id - Update profile
4. POST /api/users/:user_id/follow - Follow user
5. DELETE /api/users/:user_id/follow - Unfollow user
6. GET /api/users/:user_id/followers - List followers (paginated)

Requirements:
- Use Pydantic for validation
- Add JWT authentication
- Include error handling
- Add rate limiting (10 req/min for follows)
- Use async database queries

Project structure:
- Routes in backend/routes/
- Schemas in backend/schemas/
- Use existing auth middleware from backend/middleware/auth.py`
)
```

---

## Scenario 5: Security Audit

**Use Case:** You want a security review of authentication code.

### Agent to Use
`quality:security-auditor` (Opus)

### Code
```javascript
Task(
  subagent_type="multi-agent:quality:security-auditor",
  model="opus",
  description="Security audit of authentication system",
  prompt=`Perform a comprehensive security audit of the authentication system:

Files to review:
- backend/routes/auth.py
- backend/middleware/auth.py
- backend/utils/jwt.py
- backend/models/user.py

Focus areas:
1. Password handling and hashing
2. JWT token security
3. Session management
4. Input validation
5. SQL injection risks
6. OWASP Top 10 compliance

Provide detailed report with:
- Severity levels (CRITICAL/HIGH/MEDIUM/LOW)
- CWE references
- Specific remediation code
- Security best practices recommendations`
)
```

### Expected Output
```markdown
# Security Audit Report

## CRITICAL Issues

### 1. JWT Secret Hardcoded (CWE-798)
**File:** backend/utils/jwt.py:12
**Code:**
\`\`\`python
SECRET_KEY = "my-secret-key-12345"
\`\`\`

**Risk:** Anyone with access to codebase can forge tokens

**Remediation:**
\`\`\`python
from os import getenv
SECRET_KEY = getenv("JWT_SECRET_KEY")
if not SECRET_KEY:
    raise ValueError("JWT_SECRET_KEY must be set")
\`\`\`

### 2. No Rate Limiting on Login (CWE-307)
**File:** backend/routes/auth.py:45
**Risk:** Brute force attack possible

**Remediation:**
\`\`\`python
from slowapi import Limiter

@router.post("/login")
@limiter.limit("5/minute")
async def login(credentials: LoginSchema):
    ...
\`\`\`

## HIGH Issues

### 3. Weak Password Requirements
...

[Complete report continues]
```

---

## Scenario 6: Generate Tests for Existing Code

**Use Case:** You have implemented features but need comprehensive tests.

### Agent to Use
`quality:test-writer` (Sonnet)

### Code
```javascript
Task(
  subagent_type="multi-agent:quality:test-writer",
  model="sonnet",
  description="Create test suite for profile API",
  prompt=`Create comprehensive tests for the profile API endpoints:

Files to test:
- backend/routes/profiles.py
- backend/routes/follows.py

Requirements:
- Unit tests for each endpoint
- Test success cases
- Test validation errors
- Test authentication failures
- Test edge cases (following yourself, duplicate follows)
- Integration tests for follow/unfollow flow
- Target: 85%+ code coverage

Use:
- pytest
- pytest-asyncio
- Factory pattern for test data
- Fixtures for database and auth

Place tests in tests/test_profiles.py and tests/test_follows.py`
)
```

---

## Scenario 7: Create Frontend Component

**Use Case:** You need a React component implemented from a design.

### Steps

**Step 1: Design Phase**
```javascript
Task(
  subagent_type="multi-agent:frontend:designer",
  model="opus",
  description="Design user profile component",
  prompt=`Design a UserProfile React component with:

Requirements:
- Display user info (name, bio, avatar, location)
- Follow/Unfollow button
- Show follower/following counts (clickable)
- Edit button (only for own profile)
- Responsive (mobile & desktop)
- Accessibility compliant

Provide component specification in YAML format.`
)
```

**Step 2: Implementation (T1)**
```javascript
Task(
  subagent_type="multi-agent:frontend:developer-t1",
  model="haiku",
  description="Implement UserProfile component",
  prompt=`Implement the UserProfile component based on docs/design/frontend/user-profile-component.yaml

Requirements:
- TypeScript + React
- Use Tailwind for styling
- Fetch data with React Query
- Proper loading and error states
- ARIA labels for accessibility
- Mobile responsive
- Handle follow/unfollow with optimistic updates

Create:
- src/components/UserProfile.tsx
- src/components/UserProfile.test.tsx (basic tests)
- src/types/user.ts (if needed)`
)
```

---

## Scenario 8: Code Review

**Use Case:** You want your Python backend code reviewed before committing.

### Agent to Use
`backend:code-reviewer-python` (Sonnet)

### Code
```javascript
Task(
  subagent_type="multi-agent:backend:code-reviewer-python",
  model="sonnet",
  description="Review profile management code",
  prompt=`Review the following Python files for quality and best practices:

Files:
- backend/routes/profiles.py
- backend/services/profile_service.py
- backend/models/profile.py

Review for:
- Code quality (PEP 8, type hints, docstrings)
- Security issues
- Performance concerns (N+1 queries, etc.)
- Error handling
- FastAPI best practices
- Async/await usage

Provide categorized issues: CRITICAL / MAJOR / MINOR`
)
```

---

## Scenario 9: Create CLI Tool

**Use Case:** You need a Python CLI tool for data processing.

### Agent to Use
`python:developer-generic-t1` (Haiku)

**Note:** Use python agents for utilities, NOT for backend API code

### Code
```javascript
Task(
  subagent_type="multi-agent:python:developer-generic-t1",
  model="haiku",
  description="Create user data export CLI tool",
  prompt=`Create a CLI tool that exports user data to various formats:

Requirements:
- Tool name: export-users
- Arguments:
  - --format: json, csv, or excel
  - --output: output file path
  - --filter: optional filter (active, inactive, all)
- Connect to PostgreSQL database (read-only)
- Progress bar for large exports
- Error handling for database connection
- Use Click for CLI framework
- Type hints throughout
- Logging to file

Database connection string from environment: DATABASE_URL

Create:
- src/cli/export_users.py
- src/cli/exporters/ (json, csv, excel modules)
- tests/test_export_users.py`
)
```

---

## Scenario 10: Generate Documentation

**Use Case:** You've built features and need comprehensive documentation.

### Agent to Use
`quality:documentation-coordinator` (Sonnet)

### Code
```javascript
Task(
  subagent_type="multi-agent:quality:documentation-coordinator",
  model="sonnet",
  description="Create complete project documentation",
  prompt=`Generate comprehensive documentation for the TaskFlow project:

Components to document:
1. API Endpoints (backend/routes/)
2. Database Schema (backend/models/)
3. React Components (src/components/)
4. Setup and Installation

Create:
- docs/api/README.md - Complete API reference
  - All endpoints with examples
  - Request/response schemas
  - Authentication
  - Error codes

- docs/database/schema.md - Database documentation
  - All tables with columns
  - Relationships
  - Indexes
  - Migration guide

- docs/components/README.md - Frontend components
  - Component usage
  - Props interface
  - Examples

- docs/SETUP.md - Setup guide
  - Prerequisites
  - Installation steps
  - Environment variables
  - Running locally
  - Running tests

- README.md - Project overview
  - Features
  - Tech stack
  - Quick start
  - Development guide`
)
```

---

## Best Practices for Individual Agent Usage

### 1. Choose the Right Tier
- **Start with T1 (Haiku)** for implementation agents
- **Use Opus** for design decisions and audits
- **Escalate to T2 (Sonnet)** only when needed

### 2. Provide Context
- Reference existing files
- Specify project structure
- Include technology stack details
- Mention specific requirements

### 3. Be Specific
- Clear, actionable prompts
- Specific file paths for output
- Concrete examples when possible
- Acceptance criteria if applicable

### 4. Iterate When Needed
- Review agent output
- Provide feedback if issues found
- Launch same agent again with specific fixes
- Or escalate to T2 for complex issues

### 5. Use Agents Sequentially
- Design → Implementation → Testing → Review
- Each agent builds on previous work
- Don't skip quality checks (review, security, tests)

---

## Cost Comparison by Scenario

| Scenario | Agent | Model | Approx. Cost | Time |
|----------|-------|-------|--------------|------|
| Schema Design | database:designer | Opus | $0.05 | 2-3 min |
| Implement Models (T1) | database:developer-python-t1 | Haiku | $0.003 | 5-8 min |
| Implement Models (T2) | database:developer-python-t2 | Sonnet | $0.01 | 5-8 min |
| API Design | backend:api-designer | Opus | $0.04 | 3-5 min |
| API Implementation (T1) | backend:api-developer-python-t1 | Haiku | $0.01 | 8-12 min |
| Security Audit | quality:security-auditor | Opus | $0.08 | 8-10 min |
| Write Tests | quality:test-writer | Sonnet | $0.02 | 10-15 min |
| Frontend Design | frontend:designer | Opus | $0.03 | 3-5 min |
| Frontend Impl (T1) | frontend:developer-t1 | Haiku | $0.01 | 10-15 min |
| Code Review | backend:code-reviewer-python | Sonnet | $0.02 | 5-8 min |
| CLI Tool (T1) | python:developer-generic-t1 | Haiku | $0.005 | 8-12 min |
| Documentation | quality:documentation-coordinator | Sonnet | $0.03 | 10-15 min |

**Total for all scenarios:** ~$0.30

---

## When to Use Individual Agents vs Full Workflow

### Use Individual Agents When:
- Quick, isolated tasks
- Reviewing existing code
- Generating documentation post-development
- Prototyping or experimenting
- Adding single features to existing project
- Security audits
- One-off scripts or utilities

### Use Full Workflow (/devteam:plan → /devteam:implement) When:
- Starting new projects
- Building complete features from scratch
- Need coordination between multiple components
- Want automatic T1→T2 escalation
- Need requirements validation
- Building something with dependencies
- Want cost optimization with quality gates

---

## Quick Reference

```javascript
// Design Agents (Opus) - Architecture & Specs
database:designer
backend:api-designer
frontend:designer

// T1 Developers (Haiku) - Try First
database:developer-{python,typescript}-t1
backend:api-developer-{python,typescript}-t1
frontend:developer-t1
python:developer-generic-t1

// T2 Developers (Sonnet) - Complex Cases
database:developer-{python,typescript}-t2
backend:api-developer-{python,typescript}-t2
frontend:developer-t2
python:developer-generic-t2

// Quality & Review (Sonnet/Opus)
quality:test-writer                    // Sonnet
quality:security-auditor               // Opus
quality:documentation-coordinator      // Sonnet
backend:code-reviewer-{python,typescript}  // Sonnet
frontend:code-reviewer                 // Sonnet

// Orchestration (Sonnet/Opus)
orchestration:task-orchestrator        // Sonnet
orchestration:sprint-orchestrator      // Opus
orchestration:requirements-validator   // Opus
```
