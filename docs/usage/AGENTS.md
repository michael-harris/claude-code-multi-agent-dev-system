# Complete Agent Definitions

All 27 specialized agents in the multi-agent development system.

**How Agents Work in Pragmatic Approach:**
- Agent definitions are markdown files in `.claude/agents/`
- Claude uses the Task tool to launch agents (e.g., `Task tool with subagent_type="prd-generator"`)
- Each agent receives the markdown definition as their prompt
- Agents do their work and return results to Claude
- Claude coordinates handoffs between agents manually

---

## Planning Layer (3 Agents)

### 1. PRD Generator
**File:** `.claude/agents/prd-generator.md`
**Model:** claude-sonnet-4-5
**Purpose:** Interactive PRD creation through structured Q&A

**Technology Stack Selection (REQUIRED FIRST):**
- Ask about integrations (ML libraries, APIs, data tools)
- Ask about team background  
- Recommend Python for: ML/data science, heavy processing, async operations
- Recommend TypeScript for: Full JS team, microservices, real-time features
- Choose framework: FastAPI/Django (Python) or Express/NestJS (TypeScript)

**Interview Phases:**
1. Technology Stack (REQUIRED)
2. Problem and Solution (REQUIRED)
3. Users and Use Cases (REQUIRED)
4. Technical Context (REQUIRED)
5. Success Criteria (REQUIRED)
6. Constraints (REQUIRED)
7. Details (CONDITIONAL)

**Output:** `docs/planning/PROJECT_PRD.yaml`

**Next Steps:** Guide user to run `/planning analyze` and `/planning sprints`

---

### 2. Task Analyzer  
**File:** `.claude/agents/task-analyzer.md`
**Model:** claude-sonnet-4-5
**Purpose:** Decompose PRD into discrete, implementable tasks

**Process:**
1. Read PROJECT_PRD.yaml
2. Identify task types: database, api, frontend, fullstack, infrastructure, python-generic
3. Break down requirements into 1-2 day tasks
4. Determine dependencies (database→API→frontend)
5. Generate TASK-XXX.yaml files

**Task Types:**
- `fullstack`: Complete feature with database, API, and frontend
- `backend`: API and database without frontend
- `frontend`: UI components using existing API
- `database`: Schema and models only
- `python-generic`: Python utilities, scripts, CLI tools, algorithms
- `infrastructure`: CI/CD, deployment, configuration

**Task Size Guidelines:**
- Complexity 1-2 (Simple): 4-8 hours
- Complexity 3 (Medium): 1-2 days
- Complexity 4-5 (Complex): 2-3 days MAX

**Output:** `docs/planning/tasks/TASK-XXX.yaml` for each task

---

### 3. Sprint Planner
**File:** `.claude/agents/sprint-planner.md`  
**Model:** claude-sonnet-4-5
**Purpose:** Organize tasks into logical sprints

**Process:**
1. Read all TASK-XXX.yaml files
2. Build dependency graph
3. Group tasks into sprints (40-60 hours each)
4. Respect dependencies across sprints

**Sprint Composition:**
- Sprint 1: Foundation (auth, core models, basic API)
- Sprint 2-N: Feature groups
- Final Sprint: Polish, docs, deployment

**Output:** `docs/sprints/SPRINT-XXX.yaml`

---

## Orchestration Layer (3 Agents)

### 4. Sprint Orchestrator
**File:** `.claude/agents/sprint-orchestrator.md`
**Model:** claude-opus-4-1
**Purpose:** Manages entire sprint execution with quality loops

**Responsibilities:**
1. Read sprint definition
2. Execute tasks in dependency order
3. Call task-orchestrator for each task
4. Monitor validation results
5. Handle failures and retries
6. Generate sprint summary

**Failure Handling:**
- Task fails validation: Pause sprint, generate failure report, request human intervention
- Blocking task fails: Identify blocked tasks, calculate impact, recommend remediation
- Non-blocking task fails: Continue with other tasks, flag for later

**Commands:** `/sprint execute|status|pause|resume|force-complete|report`

---

### 5. Task Orchestrator
**File:** `.claude/agents/task-orchestrator.md`
**Model:** claude-sonnet-4-5
**Purpose:** Coordinates single task workflow with iterative quality validation

**Execution Process:**
1. Read task requirements
2. Determine workflow type from task.type field:
   - `fullstack` → fullstack-feature workflow
   - `backend` → api-development workflow
   - `frontend` → frontend-development workflow
   - `database` → database-only workflow
   - `python-generic` → generic-python-development workflow
   - `infrastructure` → infrastructure workflow
3. Execute workflow with specialized agents
4. Submit to requirements-validator
5. Implement T1→T2 switching logic (see below)
6. If still fails after max iterations: escalate to human

**T1→T2 Switching Logic:**
- **Iteration 1:** Use T1 developer agents (Haiku)
- **Validation fails → Iteration 2:** T1 attempts fixes
  - If **validation passes:** Task complete
  - If **validation fails:** Switch to T2 for iteration 3+
- **Iteration 3+:** Use T2 developer agents (Sonnet) for all subsequent attempts

**Smart Re-execution:**
- Only re-run agents responsible for failed validation criteria
- Example: If "API missing error handling" → only re-run backend developer
- Example: If "Tests incomplete" → only re-run test writer
- Track which tier (T1/T2) is currently active per developer type

**Output:** `docs/execution/TASK-XXX-execution.yaml`

---

### 6. Requirements Validator
**File:** `.claude/agents/requirements-validator.md`
**Model:** claude-opus-4-1
**Purpose:** Quality gate with strict acceptance criteria validation

**Validation Process:**
1. Read task acceptance criteria from TASK-XXX.yaml
2. Examine all code, tests, and documentation
3. Verify EACH criterion is 100% met
4. Return PASS or FAIL with specific gaps and recommended agents

**For Each Criterion:**
- ✅ Check code implementation (correct, edge cases handled)
- ✅ Check tests exist and pass
- ✅ Check documentation complete

**Gap Analysis:**
When validation fails, identify:
- Which specific acceptance criteria are not met
- Which agents need to address each gap
- Whether issues are straightforward fixes or complex problems
- Recommended next steps

**Rules:**
- Acceptance criteria are binary: 100% met or FAIL
- Never pass with unmet criteria
- Never accept "close enough"
- Never skip security validation
- Never allow untested code

**Output:** PASS or detailed FAIL with specific gaps, affected criteria, and recommended agents

---

## Database Layer (6 Agents - T1 and T2)

### 7. Database Designer
**File:** `.claude/agents/database-designer.md`
**Model:** claude-opus-4-1  
**Purpose:** Language-agnostic database schema design

**Responsibilities:**
1. Design normalized schema (3NF minimum)
2. Define relationships and constraints
3. Plan indexes for query performance
4. Design migrations strategy
5. Document design decisions

**Normalization Rules:**
- ✅ Every table has primary key
- ✅ No repeating groups
- ✅ All non-key attributes depend on the key
- ✅ No transitive dependencies
- ✅ Many-to-many via junction tables

**Output:**
1. `docs/design/database/TASK-XXX-schema.yaml` - Schema definition
2. `docs/design/database/TASK-XXX-design.md` - Design rationale
3. `docs/design/database/TASK-XXX-migrations.md` - Migration plan

---

### 8. Database Developer Python T1
**File:** `.claude/agents/database-developer-python-t1.md`
**Model:** claude-haiku-4-5
**Purpose:** SQLAlchemy models and Alembic migrations (cost-optimized)

**Responsibilities:**
1. Create SQLAlchemy models from schema design
2. Generate Alembic migrations
3. Implement relationships (one-to-many, many-to-many)
4. Add validation
5. Create database utilities (get_db, Base, SessionLocal)

**Implementation:**
- Use UUID primary keys
- Add indexes as specified in design
- Implement cascade delete where appropriate
- Use proper column types (UUID, String, DateTime, Boolean)
- Add `__repr__` methods for debugging

**Quality Checks:**
- ✅ Models match schema design exactly
- ✅ All indexes created in migration
- ✅ Relationships properly defined
- ✅ Migration is reversible (up/down)
- ✅ Type hints added
- ✅ Docstrings included

**Output:**
1. `backend/models/[entity].py` - SQLAlchemy models
2. `migrations/versions/XXX_[description].py` - Alembic migration
3. `backend/database.py` - Database utilities

---

### 9. Database Developer Python T2
**File:** `.claude/agents/database-developer-python-t2.md`
**Model:** claude-sonnet-4-5
**Purpose:** SQLAlchemy models and Alembic migrations (enhanced quality)

**Responsibilities:**
Identical to T1, but with higher reasoning capability for:
- Complex relationship modeling
- Advanced constraint handling
- Migration edge cases
- Performance optimization decisions

**When Used:**
- Activated when T1 fails validation after first fix attempt
- Continues through remaining iterations
- Same quality checks as T1, better at handling complex scenarios

**Output:** Same as T1

---

### 10. Database Developer TypeScript T1
**File:** `.claude/agents/database-developer-typescript-t1.md`
**Model:** claude-haiku-4-5
**Purpose:** Prisma schema and TypeORM entities (cost-optimized)

**Responsibilities:**
1. Create Prisma schema or TypeORM entities
2. Generate migrations  
3. Implement relationships
4. Add validation
5. Create database utilities

**Prisma Implementation:**
- Update `prisma/schema.prisma` with models
- Use `@map` for snake_case database columns
- Add `@@index` directives as needed
- Generate migrations with `npx prisma migrate dev`
- Create Prisma client instance

**TypeORM Implementation:**
- Create entity classes with decorators
- Use `@Entity`, `@Column`, `@PrimaryGeneratedColumn`
- Add `@Index` decorators for indexes
- Create migrations with up/down methods
- Handle UUID generation

**Quality Checks:**
- ✅ Schema matches design exactly
- ✅ All indexes created
- ✅ Relationships properly defined
- ✅ Migration is reversible
- ✅ Type safety enforced
- ✅ camelCase for TypeScript, snake_case for database

**Output:**
- **Prisma:** schema.prisma, migrations SQL, client.ts
- **TypeORM:** Entity files, migration files, connection.ts

---

### 11. Database Developer TypeScript T2
**File:** `.claude/agents/database-developer-typescript-t2.md`
**Model:** claude-sonnet-4-5
**Purpose:** Prisma schema and TypeORM entities (enhanced quality)

**Responsibilities:**
Identical to T1, but with higher reasoning capability for:
- Complex TypeScript type definitions
- Advanced Prisma schema patterns
- Migration complexity
- Type safety edge cases

**When Used:**
- Activated when T1 fails validation after first fix attempt
- Continues through remaining iterations

**Output:** Same as T1

---

## Backend API Layer (9 Agents - Designer + T1/T2 + Reviewers)

### 12. API Designer
**File:** `.claude/agents/api-designer.md`
**Model:** claude-opus-4-1
**Purpose:** Language-agnostic REST API contract design

**Responsibilities:**
1. Design API endpoints (RESTful conventions)
2. Define request/response schemas
3. Specify error responses
4. Document authentication requirements
5. Plan validation rules

**RESTful Conventions:**
- GET for retrieval
- POST for creation
- PUT/PATCH for updates
- DELETE for deletion
- `/api/{resource}` for collections
- `/api/{resource}/{id}` for single items

**Status Codes:**
- 200: Success, 201: Created
- 400: Bad request, 401: Unauthorized, 403: Forbidden
- 404: Not found, 429: Rate limit, 500: Server error

**Output:**
1. `docs/design/api/TASK-XXX-api.yaml` - Complete API contract
2. `docs/design/api/TASK-XXX-design.md` - Design rationale

---

### 13. API Developer Python T1
**File:** `.claude/agents/api-developer-python-t1.md`
**Model:** claude-haiku-4-5
**Purpose:** FastAPI or Django REST Framework implementation (cost-optimized)

**Responsibilities:**
1. Implement API endpoints from design
2. Add request validation (Pydantic models)
3. Implement error handling
4. Add authentication/authorization
5. Implement rate limiting
6. Add logging

**FastAPI Implementation:**
- Use `APIRouter` for route organization
- Define Pydantic models for request/response
- Use `Depends()` for dependency injection
- Implement proper exception handling
- Add rate limiting decorators
- Use proper HTTP status codes
- Add comprehensive docstrings

**Django REST Framework:**
- Create view functions or ViewSets
- Use serializers for validation
- Implement throttling classes
- Add permission classes
- Handle exceptions properly

**Quality Checks:**
- ✅ Matches API design exactly
- ✅ All validation rules implemented
- ✅ All error responses implemented
- ✅ Authentication/authorization correct
- ✅ Rate limiting configured
- ✅ Logging added
- ✅ Type hints included
- ✅ Docstrings complete

**Output:**
1. `backend/routes/[resource].py` or `backend/views/[resource].py`
2. `backend/schemas/[resource].py` - Pydantic models
3. `backend/utils/[utility].py` - Helper functions

---

### 14. API Developer Python T2
**File:** `.claude/agents/api-developer-python-t2.md`
**Model:** claude-sonnet-4-5
**Purpose:** FastAPI or Django REST Framework implementation (enhanced quality)

**Responsibilities:**
Identical to T1, but with higher reasoning capability for:
- Complex business logic
- Advanced error handling patterns
- Performance optimization
- Security edge cases

**When Used:**
- Activated when T1 fails validation after first fix attempt
- Continues through remaining iterations

**Output:** Same as T1

---

### 15. API Developer TypeScript T1
**File:** `.claude/agents/api-developer-typescript-t1.md`
**Model:** claude-haiku-4-5
**Purpose:** Express or NestJS implementation (cost-optimized)

**Responsibilities:**
1. Implement API endpoints
2. Add request validation (express-validator or class-validator)
3. Implement error handling
4. Add authentication/authorization
5. Implement rate limiting
6. Add logging

**Express Implementation:**
- Create route handlers
- Use express-validator for validation
- Implement express-rate-limit
- Add error handling middleware
- Proper async/await usage
- Type safety with TypeScript

**NestJS Implementation:**
- Create controllers with decorators
- Use DTOs with class-validator
- Implement guards for authentication
- Use ThrottlerGuard for rate limiting
- Create services for business logic
- Dependency injection

**Quality Checks:**
- ✅ Matches API design exactly
- ✅ All validation rules implemented
- ✅ All error responses implemented
- ✅ Authentication/authorization correct
- ✅ Rate limiting configured
- ✅ Logging added
- ✅ Type safety enforced
- ✅ Swagger/OpenAPI docs (NestJS)

**Output:**
- **Express:** routes/*.routes.ts, middleware/*.ts, types/*.ts
- **NestJS:** controllers, services, DTOs, modules

---

### 16. API Developer TypeScript T2
**File:** `.claude/agents/api-developer-typescript-t2.md`
**Model:** claude-sonnet-4-5
**Purpose:** Express or NestJS implementation (enhanced quality)

**Responsibilities:**
Identical to T1, but with higher reasoning capability for:
- Complex TypeScript patterns
- Advanced middleware composition
- Decorator patterns (NestJS)
- Type safety edge cases

**When Used:**
- Activated when T1 fails validation after first fix attempt
- Continues through remaining iterations

**Output:** Same as T1

---

### 17. Backend Code Reviewer (Python)
**File:** `.claude/agents/backend-code-reviewer-python.md`
**Model:** claude-sonnet-4-5
**Purpose:** Python-specific code review for FastAPI/Django

**Review Checklist:**

**Code Quality:**
- ✅ Type hints used consistently
- ✅ Docstrings for all functions
- ✅ PEP 8 style guide followed
- ✅ No code duplication
- ✅ Functions are single-purpose
- ✅ Appropriate use of async/await

**Security:**
- ✅ No SQL injection vulnerabilities
- ✅ Password hashing (never plain text)
- ✅ Input validation on all endpoints
- ✅ No hardcoded secrets
- ✅ CORS configured properly
- ✅ Rate limiting implemented
- ✅ Error messages don't leak sensitive data

**FastAPI/Django Best Practices:**
- ✅ Proper dependency injection
- ✅ Pydantic models for validation
- ✅ Database sessions managed correctly
- ✅ Response models defined
- ✅ Appropriate status codes

**Performance:**
- ✅ Database queries optimized
- ✅ No N+1 query problems
- ✅ Proper use of eager loading
- ✅ Async used for I/O operations

**Output:** PASS or FAIL with categorized issues (critical/major/minor)

---

### 18. Backend Code Reviewer (TypeScript)
**File:** `.claude/agents/backend-code-reviewer-typescript.md`
**Model:** claude-sonnet-4-5
**Purpose:** TypeScript-specific code review for Express/NestJS

**Review Checklist:**

**Code Quality:**
- ✅ TypeScript strict mode enabled
- ✅ No `any` types (except where necessary)
- ✅ Interfaces/types defined for all data structures
- ✅ No code duplication
- ✅ Proper async/await usage

**Security:**
- ✅ No SQL injection vulnerabilities
- ✅ Password hashing (bcrypt/argon2)
- ✅ Input validation on all endpoints
- ✅ No hardcoded secrets
- ✅ Helmet middleware configured (Express)
- ✅ Rate limiting implemented

**Express/NestJS Best Practices:**
- ✅ Proper error handling middleware
- ✅ Validation using libraries (express-validator, class-validator)
- ✅ Proper dependency injection (NestJS)
- ✅ DTOs for request/response (NestJS)
- ✅ Swagger/OpenAPI docs (NestJS)

**TypeScript Specific:**
- ✅ Strict null checks enabled
- ✅ No type assertions without justification
- ✅ Enums used where appropriate
- ✅ Generic types used effectively

**Output:** PASS or FAIL with categorized issues and recommendations

---

## Frontend Layer (4 Agents - Designer + T1/T2 + Reviewer)

### 19. Frontend Designer
**File:** `.claude/agents/frontend-designer.md`
**Model:** claude-opus-4-1
**Purpose:** React/Next.js component architecture

**Responsibilities:**
1. Design component hierarchy
2. Define component interfaces (props)
3. Plan state management (Context API, React Query)
4. Design data flow
5. Specify styling approach (Tailwind, CSS modules)

**Design Principles:**
- Component reusability (extract common UI patterns)
- Single responsibility (each component does one thing)
- Props over state (data down, callbacks up)
- Composition over inheritance
- Accessibility first (ARIA labels, keyboard navigation)
- Mobile responsive (design mobile-first)

**Output:**
1. `docs/design/frontend/TASK-XXX-components.yaml` - Component specs
2. `docs/design/frontend/TASK-XXX-design.md` - Design rationale
3. `docs/design/frontend/TASK-XXX-wireframes.md` - ASCII wireframes

---

### 20. Frontend Developer T1
**File:** `.claude/agents/frontend-developer-t1.md`
**Model:** claude-haiku-4-5
**Purpose:** React/Next.js TypeScript implementation (cost-optimized)

**Responsibilities:**
1. Implement React components from design
2. Add TypeScript types
3. Implement form validation
4. Add error handling
5. Implement API integration
6. Add accessibility features (ARIA labels, keyboard nav)

**Implementation Best Practices:**
- Use functional components with hooks
- Implement proper loading states
- Add error boundaries
- Use React Query for API calls
- Implement proper form validation
- Add aria-label and role attributes
- Ensure keyboard navigation
- Mobile responsive (Tailwind classes)

**Quality Checks:**
- ✅ Matches component design exactly
- ✅ All TypeScript types defined
- ✅ Form validation implemented
- ✅ Error handling complete
- ✅ Loading states handled
- ✅ Accessibility features added
- ✅ Mobile responsive
- ✅ No console errors/warnings

**Output:**
1. `src/components/[Component].tsx`
2. `src/contexts/[Context].tsx` - Context providers
3. `src/lib/[utility].ts` - Utility functions
4. `src/types/[type].ts` - Type definitions

---

### 21. Frontend Developer T2
**File:** `.claude/agents/frontend-developer-t2.md`
**Model:** claude-sonnet-4-5
**Purpose:** React/Next.js TypeScript implementation (enhanced quality)

**Responsibilities:**
Identical to T1, but with higher reasoning capability for:
- Complex state management patterns
- Advanced React patterns
- Performance optimization
- Complex TypeScript types

**When Used:**
- Activated when T1 fails validation after first fix attempt
- Continues through remaining iterations

**Output:** Same as T1

---

### 22. Frontend Code Reviewer
**File:** `.claude/agents/frontend-code-reviewer.md`
**Model:** claude-sonnet-4-5
**Purpose:** React/TypeScript code review specialist

**Review Checklist:**

**Code Quality:**
- ✅ TypeScript types properly defined
- ✅ No `any` types without justification
- ✅ Components properly typed
- ✅ Props interfaces exported
- ✅ No code duplication

**React Best Practices:**
- ✅ Proper use of hooks
- ✅ No infinite re-render loops
- ✅ Keys on list items
- ✅ Proper dependency arrays
- ✅ No direct state mutation
- ✅ Proper cleanup in useEffect
- ✅ Memoization where appropriate

**Accessibility (WCAG 2.1):**
- ✅ Semantic HTML elements
- ✅ ARIA labels on interactive elements
- ✅ Keyboard navigation works
- ✅ Focus indicators visible
- ✅ Alt text on images
- ✅ Form labels properly associated
- ✅ Error messages announced
- ✅ Color contrast meets standards

**Performance:**
- ✅ No unnecessary re-renders
- ✅ Lazy loading for heavy components
- ✅ Image optimization
- ✅ Bundle size reasonable

**Security:**
- ✅ No XSS vulnerabilities
- ✅ Proper input sanitization

**User Experience:**
- ✅ Loading states shown
- ✅ Error states handled
- ✅ Form validation clear
- ✅ Mobile responsive

**Output:** PASS or FAIL with categorized issues

---

## Generic Python Development Layer (2 Agents)

### 23. Python Developer Generic T1
**File:** `.claude/agents/python-developer-generic-t1.md`
**Model:** claude-haiku-4-5
**Purpose:** Non-backend Python development (utilities, scripts, CLI tools, algorithms)

**Scope:**
- Data processing utilities
- File manipulation scripts
- CLI tools (Click, Typer, argparse)
- Automation scripts
- Algorithm implementations
- Helper libraries
- System administration scripts
- Data transformation pipelines
- **NOT:** Backend API development (use api-developer-python)

**Responsibilities:**
1. Implement Python code from task requirements
2. Add proper error handling
3. Add input validation where applicable
4. Create CLI interfaces if needed
5. Add logging
6. Write clear docstrings
7. Type hints throughout

**Best Practices:**
- Follow PEP 8 style guide
- Use type hints consistently
- Comprehensive error handling
- Input validation for user inputs
- Clear documentation
- Modular design
- Reusable functions

**Quality Checks:**
- ✅ Code matches requirements
- ✅ Type hints on all functions
- ✅ Docstrings for all public functions
- ✅ Error handling for edge cases
- ✅ Input validation where needed
- ✅ PEP 8 compliant
- ✅ No security issues (path traversal, command injection)
- ✅ Logging appropriately used

**Output:**
1. `src/utils/[module].py` - Utility modules
2. `src/scripts/[script].py` - Standalone scripts
3. `src/cli/[tool].py` - CLI tools
4. `src/lib/[library].py` - Reusable libraries

---

### 24. Python Developer Generic T2
**File:** `.claude/agents/python-developer-generic-t2.md`
**Model:** claude-sonnet-4-5
**Purpose:** Non-backend Python development (enhanced quality)

**Responsibilities:**
Identical to T1, but with higher reasoning capability for:
- Complex algorithm implementation
- Advanced Python patterns
- Performance optimization
- Complex data structures
- Architectural decisions

**When Used:**
- Activated when T1 fails validation after first fix attempt
- Continues through remaining iterations

**Output:** Same as T1

---

## Quality & Documentation Layer (3 Agents)

### 25. Test Writer
**File:** `.claude/agents/test-writer.md`
**Model:** claude-sonnet-4-5
**Purpose:** Comprehensive test suite creation (unit, integration, e2e)

**Test Strategy:**
- **Unit Tests (70% coverage):** Individual functions, edge cases, mocks
- **Integration Tests (20% coverage):** API endpoints, database interactions, auth
- **E2E Tests (10% coverage):** Critical user flows, happy paths, error scenarios

**Python Testing (pytest):**
- Test user models
- Test API endpoints (success, validation, errors)
- Test authentication flows
- Test rate limiting
- Test utility functions and scripts
- Mock database with fixtures
- Mock external dependencies

**TypeScript Testing (Jest + Testing Library):**
- Test form validation
- Test login flow (success, failure, loading)
- Test error display
- Test accessibility (labels, ARIA, screen readers)
- Mock API calls

**Quality Checks:**
- ✅ All acceptance criteria have tests
- ✅ Edge cases covered
- ✅ Error cases tested
- ✅ All tests pass
- ✅ No flaky tests
- ✅ Good test names
- ✅ Tests are maintainable

**Output:**
1. `tests/test_[module].py` (Python)
2. `src/__tests__/[Component].test.tsx` (TypeScript)
3. `tests/integration/test_[feature].py`
4. `tests/e2e/test_[flow].spec.ts` (Playwright/Cypress)

---

### 26. Security Auditor
**File:** `.claude/agents/security-auditor.md`
**Model:** claude-opus-4-1
**Purpose:** Security vulnerability detection and mitigation

**Security Checklist:**

**Authentication & Authorization:**
- ✅ Password hashing (bcrypt, argon2)
- ✅ JWT tokens properly signed
- ✅ Token expiration configured
- ✅ Authorization checks on all protected routes
- ✅ Role-based access control

**Input Validation:**
- ✅ All user inputs validated
- ✅ SQL injection prevention (parameterized queries/ORM)
- ✅ XSS prevention (input sanitization, CSP headers)
- ✅ Command injection prevention
- ✅ Path traversal prevention

**Data Protection:**
- ✅ Sensitive data encrypted at rest
- ✅ HTTPS enforced
- ✅ Secrets in environment variables
- ✅ No sensitive data in logs
- ✅ Database credentials secured

**API Security:**
- ✅ Rate limiting implemented
- ✅ CORS configured properly
- ✅ Security headers set (Helmet)
- ✅ Error messages don't leak info

**Session Management:**
- ✅ Secure cookies (HttpOnly, Secure, SameSite)
- ✅ Session timeout configured
- ✅ CSRF protection implemented

**Script/Utility Security:**
- ✅ Path traversal prevention in file operations
- ✅ Command injection prevention in subprocess calls
- ✅ Input validation on CLI arguments
- ✅ Privilege escalation prevention

**OWASP Top 10 Coverage:**
1. Broken Access Control
2. Cryptographic Failures
3. Injection
4. Insecure Design
5. Security Misconfiguration
6. Vulnerable Components
7. Authentication Failures
8. Data Integrity Failures
9. Logging Failures
10. SSRF

**Output:** Security scan with CRITICAL/HIGH/MEDIUM/LOW issues, CWE references, and remediation code

**Never Approve:**
- ❌ Missing authentication on protected routes
- ❌ SQL injection vulnerabilities
- ❌ XSS vulnerabilities
- ❌ Hardcoded secrets
- ❌ Plain text passwords
- ❌ Command injection vulnerabilities
- ❌ Path traversal vulnerabilities

---

### 27. Documentation Coordinator
**File:** `.claude/agents/documentation-coordinator.md`
**Model:** claude-sonnet-4-5
**Purpose:** Comprehensive documentation generation

**Documentation Types:**

**1. API Documentation:**
- Endpoint descriptions
- Request/response schemas with examples
- Error responses with codes
- Authentication requirements
- Rate limits

**2. Database Documentation:**
- Table descriptions
- Column definitions with types/constraints
- Indexes and their purpose
- Relationships (one-to-many, many-to-many)
- Migration history

**3. Component Documentation:**
- Component purpose and usage
- Props interface with descriptions
- Features list
- Validation rules
- Error handling
- Accessibility features

**4. Python Module Documentation:**
- Module purpose
- Function/class descriptions
- Parameters and return types
- Usage examples
- CLI tool usage

**5. Setup Guide:**
- Prerequisites
- Installation steps (backend + frontend)
- Environment variables
- Database migrations
- Running development server

**Quality Checks:**
- ✅ All public APIs documented
- ✅ All database tables documented
- ✅ All React components documented
- ✅ All public Python functions documented
- ✅ Setup guide complete
- ✅ Examples provided
- ✅ Clear and accurate
- ✅ Up-to-date with implementation

**Output:**
1. `docs/api/README.md` - API documentation
2. `docs/database/schema.md` - Database documentation
3. `docs/components/[Component].md` - Component docs
4. `docs/python/[module].md` - Python module docs
5. `docs/SETUP.md` - Setup guide
6. `README.md` - Project overview

---

## Summary

**Total: 27 Agents**

| Layer | Count | Agents |
|-------|-------|--------|
| Planning | 3 | PRD Generator, Task Analyzer, Sprint Planner |
| Orchestration | 3 | Sprint Orchestrator, Task Orchestrator, Requirements Validator |
| Database | 6 | Designer, Python T1/T2, TypeScript T1/T2 |
| Backend API | 9 | Designer, Python T1/T2, TypeScript T1/T2, Python Reviewer, TypeScript Reviewer |
| Frontend | 4 | Designer, Developer T1/T2, Reviewer |
| Generic Python | 2 | Generic T1/T2 |
| Quality | 3 | Test Writer, Security Auditor, Documentation Coordinator |

**Model Distribution:**
- **Opus 4.1 (4 agents):** Database Designer, API Designer, Frontend Designer, Security Auditor, Requirements Validator, Sprint Orchestrator
- **Sonnet 4.5 (13 agents):** All T2 developers (6), all reviewers (3), coordinators (2), planners (2)
- **Haiku 4.5 (10 agents):** All T1 developers (6), test writer (1), documentation (1), task orchestrator (1), performance optimizer (1)

**T1 → T2 Switching:**
- Iteration 1: T1 attempts implementation
- Validation fails → Iteration 2: T1 fixes
- Validation still fails → Iteration 3+: T2 takes over

Each agent includes:
- ✅ Clear responsibilities and scope
- ✅ Specific inputs and outputs
- ✅ Quality checklist
- ✅ Error handling guidance
- ✅ Best practices
- ✅ Example code/output formats
