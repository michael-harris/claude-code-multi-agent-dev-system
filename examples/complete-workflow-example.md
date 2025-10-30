# Complete Workflow Example: Task Management App

This example shows the complete multi-agent workflow from idea to deployment.

## Overview

**Goal:** Build a task management application with user authentication, task CRUD, and real-time updates.

**Timeline:** ~2-3 sprints (80-120 hours of implementation)

**Tech Stack:** Python (FastAPI) + React (TypeScript)

---

## Phase 1: Requirements Gathering

### Command
```
/prd
```

### Interactive Session

**Agent (prd-generator):**
> What external services, libraries, or APIs will you integrate with?

**You:**
> We'll use PostgreSQL for the database, Redis for caching, and possibly WebSockets for real-time updates.

**Agent:**
> Based on your requirements, I recommend:
>
> Backend: Python + FastAPI
> - Excellent async support for WebSockets
> - Great performance for real-time features
> - Rich ecosystem for Redis integration
>
> Frontend: TypeScript + React
> Database: PostgreSQL + SQLAlchemy
> Testing: pytest + Jest
>
> Does this work for you?

**You:**
> Yes, perfect.

**Agent:**
> Great! Now, what problem are you solving, and for whom?

**You:**
> Small teams need a simple, fast task management tool. Current solutions are too complex or lack real-time collaboration.

*(Interview continues for 5-10 minutes covering users, features, constraints)*

### Output

**File Created:** `docs/planning/PROJECT_PRD.yaml`

```yaml
project:
  name: "TaskFlow"
  version: "0.1.0"

technology:
  backend:
    language: python
    framework: fastapi
    reasoning: "Async support for WebSockets, excellent performance"
  frontend:
    framework: react
  database:
    system: postgresql
    orm: sqlalchemy

requirements:
  must_have:
    - id: REQ-001
      description: "User authentication system"
      acceptance_criteria:
        - Users can register with email/password
        - Users can log in and receive JWT token
        - Token expires after 24 hours
        - Password requirements: min 8 chars, 1 number
      priority: critical

    - id: REQ-002
      description: "Task CRUD operations"
      acceptance_criteria:
        - Users can create tasks with title, description, due date
        - Users can update task status (todo/in-progress/done)
        - Users can delete their own tasks
        - Tasks are filterable by status
      priority: critical

    - id: REQ-003
      description: "Real-time task updates"
      acceptance_criteria:
        - Changes to tasks broadcast to all connected users
        - Uses WebSocket connection
        - Reconnection handling on network issues
      priority: high
```

---

## Phase 2: Task Planning

### Command
```
/planning
```

### What Happens

**Step 1: Task Graph Analyzer (Sonnet)**

Analyzes PRD and creates:

```yaml
# docs/planning/tasks/TASK-001.yaml
id: TASK-001
name: "User Authentication System"
type: fullstack
estimated_hours: 12
dependencies: []
acceptance_criteria:
  - User registration endpoint working
  - Login endpoint returns JWT
  - Token validation middleware working
  - Password hashing implemented
  - Test coverage ≥ 80%
```

**15 tasks created total:**
- TASK-001: User Authentication (fullstack)
- TASK-002: Database schema for tasks (database)
- TASK-003: Task CRUD API (backend)
- TASK-004: Task list UI (frontend)
- TASK-005: Task creation form (frontend)
- TASK-006: WebSocket infrastructure (backend)
- TASK-007: Real-time updates (fullstack)
- ... (8 more tasks)

**Step 2: Sprint Planner (Sonnet)**

Organizes into sprints:

```yaml
# docs/sprints/SPRINT-001.yaml
id: SPRINT-001
name: "Foundation & Authentication"
estimated_hours: 40
tasks:
  - TASK-001  # User Authentication (no dependencies)
  - TASK-002  # Database schema (can run parallel)
```

```yaml
# docs/sprints/SPRINT-002.yaml
id: SPRINT-002
name: "Core Task Management"
estimated_hours: 48
tasks:
  - TASK-003  # Depends on TASK-001, TASK-002
  - TASK-004  # Depends on TASK-003
  - TASK-005  # Depends on TASK-003
```

```yaml
# docs/sprints/SPRINT-003.yaml
id: SPRINT-003
name: "Real-time Features & Polish"
estimated_hours: 32
tasks:
  - TASK-006  # WebSocket infrastructure
  - TASK-007  # Real-time updates (depends on TASK-006)
  - ... (polish tasks)
```

---

## Phase 3: Sprint Execution

### Command
```
/sprint SPRINT-001
```

### Detailed Execution Flow

**Sprint Orchestrator (Opus) launches...**

#### Task: TASK-001 - User Authentication System

**Task Orchestrator (Sonnet) coordinates:**

**Iteration 1 (T1 Agents - Haiku):**

1. **Database Designer (Opus)** - 2 minutes
   ```yaml
   Output: docs/design/database/TASK-001-schema.yaml

   tables:
     users:
       columns:
         id: {type: UUID, primary: true}
         email: {type: STRING, unique: true}
         password_hash: {type: STRING}
         created_at: {type: TIMESTAMP}
   ```

2. **Database Developer Python T1 (Haiku)** - 5 minutes
   ```python
   Output: backend/models/user.py

   class User(Base):
       __tablename__ = "users"
       id = Column(UUID, primary_key=True)
       email = Column(String, unique=True, nullable=False)
       password_hash = Column(String, nullable=False)
       created_at = Column(DateTime, default=datetime.utcnow)
   ```

   ```python
   Output: migrations/versions/001_create_users.py
   ```

3. **API Designer (Opus)** - 3 minutes
   ```yaml
   Output: docs/design/api/TASK-001-api.yaml

   endpoints:
     - path: /api/auth/register
       method: POST
       request_body:
         email: {type: string, format: email}
         password: {type: string, min_length: 8}
       responses:
         201: {user_id: uuid, token: string}
         400: {error: string}
   ```

4. **API Developer Python T1 (Haiku)** - 8 minutes
   ```python
   Output: backend/routes/auth.py

   @router.post("/register")
   async def register(data: RegisterSchema):
       # Hash password
       # Create user
       # Generate JWT
       return {"user_id": user.id, "token": token}
   ```

   *Issue: Missing rate limiting, weak password validation*

5. **Frontend Designer (Opus)** - 3 minutes
   ```yaml
   Output: docs/design/frontend/TASK-001-components.yaml

   components:
     LoginForm:
       props: {onSubmit: function}
       state: [email, password, isSubmitting, errors]
   ```

6. **Frontend Developer T1 (Haiku)** - 10 minutes
   ```tsx
   Output: src/components/LoginForm.tsx

   export function LoginForm({ onSubmit }) {
     // Form implementation
   }
   ```

   *Issue: Missing accessibility labels, no keyboard navigation*

7. **Test Writer (Sonnet)** - 12 minutes
   ```python
   Output: tests/test_auth.py

   def test_register_success():
       # Test implementation

   def test_register_duplicate_email():
       # Test implementation
   ```

   Coverage: 75% ⚠️

8. **Backend Code Reviewer Python (Sonnet)** - 5 minutes
   ```
   Issues Found:
   - MAJOR: Rate limiting not implemented
   - MAJOR: Password validation too weak
   - MINOR: Missing docstrings
   ```

9. **Frontend Code Reviewer (Sonnet)** - 5 minutes
   ```
   Issues Found:
   - CRITICAL: Missing aria-labels on inputs
   - MAJOR: No keyboard navigation
   - MINOR: Loading state not accessible
   ```

10. **Security Auditor (Opus)** - 8 minutes
    ```
    CRITICAL Issues:
    - No rate limiting on registration (brute force risk)
    - Password requirements too weak
    - JWT secret hardcoded (CWE-798)

    HIGH Issues:
    - No email validation
    - Missing CORS configuration
    ```

11. **Requirements Validator (Opus)** - 5 minutes
    ```yaml
    result: FAIL
    outstanding_requirements:
      - criterion: "Password requirements: min 8 chars, 1 number"
        gap: "Only checks length, not number requirement"
        recommended_agent: "api-developer-python"
        complexity: "straightforward"

      - criterion: "Test coverage ≥ 80%"
        current: 75%
        gap: "Missing tests for edge cases"
        recommended_agent: "test-writer"
        complexity: "straightforward"
    ```

**Iteration 2 (Still T1 - Haiku):**

Task Orchestrator re-runs specific agents:

1. **API Developer Python T1 (Haiku)** - 5 minutes
   - Adds password validation with regex
   - Adds rate limiting decorator
   - Moves JWT secret to environment variable

2. **Test Writer (Sonnet)** - 8 minutes
   - Adds edge case tests
   - Coverage now: 82% ✅

3. **Requirements Validator (Opus)** - 5 minutes
   ```yaml
   result: FAIL
   outstanding_requirements:
      - criterion: "Token expires after 24 hours"
        gap: "JWT expiration set to 7 days"
        recommended_agent: "api-developer-python"
        complexity: "straightforward"
   ```

**Iteration 3 (Still T1 - Haiku):**

1. **API Developer Python T1 (Haiku)** - 2 minutes
   - Changes JWT expiration to 24 hours

2. **Requirements Validator (Opus)** - 5 minutes
   ```yaml
   result: PASS
   all_criteria_met: true
   test_coverage: 82%
   security_issues: 0
   iterations: 3
   tier_used: T1
   ```

**✅ TASK-001 Complete (3 iterations, T1 only, ~90 minutes)**

---

### Summary of SPRINT-001

```
Sprint SPRINT-001: Foundation & Authentication
Status: ✅ COMPLETED

TASK-001: User Authentication System (fullstack)
├─ Iterations: 3
├─ Tier: T1 (Haiku)
├─ Time: ~90 minutes
├─ Cost: ~$0.50 (estimated)
└─ Result: PASS

TASK-002: Database Schema for Tasks (database)
├─ Iterations: 2
├─ Tier: T1 (Haiku)
├─ Time: ~45 minutes
├─ Cost: ~$0.20 (estimated)
└─ Result: PASS

Sprint Summary:
- Tasks: 2/2 completed
- Total iterations: 5
- T1→T2 escalations: 0
- Total time: ~2.5 hours
- Estimated cost: ~$0.70
- All acceptance criteria met: ✅
```

---

## Phase 4: Continue with Remaining Sprints

```bash
/sprint SPRINT-002
```

*Similar detailed workflow for core task management features*

```bash
/sprint SPRINT-003
```

*Real-time features and polish*

---

## Final Deliverables

After 3 sprints (~80 hours of implementation, compressed to days with automation):

### Code Structure
```
TaskFlow/
├── backend/
│   ├── models/
│   │   ├── user.py
│   │   └── task.py
│   ├── routes/
│   │   ├── auth.py
│   │   ├── tasks.py
│   │   └── websocket.py
│   ├── schemas/
│   ├── utils/
│   └── main.py
├── frontend/
│   ├── src/
│   │   ├── components/
│   │   │   ├── LoginForm.tsx
│   │   │   ├── TaskList.tsx
│   │   │   └── TaskForm.tsx
│   │   ├── contexts/
│   │   ├── lib/
│   │   └── App.tsx
├── tests/
│   ├── backend/
│   └── frontend/
├── docs/
│   ├── api/
│   ├── database/
│   └── SETUP.md
└── migrations/
```

### Quality Metrics
- ✅ Test coverage: 84%
- ✅ Security audit: 0 critical issues
- ✅ All WCAG 2.1 accessibility standards met
- ✅ Code review: All issues resolved
- ✅ Documentation: Complete

### Features Delivered
- ✅ User registration and authentication
- ✅ JWT-based session management
- ✅ Full task CRUD operations
- ✅ Real-time updates via WebSockets
- ✅ Responsive UI (mobile & desktop)
- ✅ Comprehensive error handling
- ✅ Rate limiting and security hardening

---

## Cost Analysis

**Traditional Approach (All Senior Devs):**
- 80 hours × $150/hour = $12,000
- Timeline: 2-3 weeks

**All-Opus AI Approach:**
- ~8,000 AI interactions × $0.015 = $120
- Timeline: 2-3 days
- BUT: Less optimal, no cost tiers

**Multi-Agent T1/T2 Approach:**
- T1 (70% of work): ~5,600 interactions × $0.001 = $5.60
- T2 (20% of work): ~1,600 interactions × $0.003 = $4.80
- Opus (10% of work): ~800 interactions × $0.015 = $12
- **Total: ~$22.40**
- Timeline: 2-3 days
- Quality: Same as all-Opus (requirements validator ensures it)

**Savings:** 60-70% vs all-Opus, 99.8% vs human developers

---

## Key Takeaways

1. **PRD phase is crucial** - Good requirements = good results
2. **T1 handles most work** - Only escalates when needed
3. **Quality gates work** - Requirements validator caught 12 issues
4. **Cost optimization is real** - $22 vs $120 vs $12,000
5. **Documentation is automatic** - No extra effort needed
6. **Security is built-in** - Security auditor catches vulnerabilities
7. **Accessibility is guaranteed** - Frontend reviewer enforces WCAG 2.1

## Next Steps

- Deploy to production
- Set up CI/CD pipeline
- Configure monitoring and logging
- Plan feature roadmap (use /prd again!)
