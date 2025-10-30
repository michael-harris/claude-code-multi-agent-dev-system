# Multi-Agent Development System

A comprehensive 27-agent automated development system for Claude Code with hierarchical orchestration, T1/T2 quality tiers, and full-stack development capabilities.

## Overview

This plugin provides a complete multi-agent development workflow with:
- **Planning agents** for PRD generation, task breakdown, and sprint planning
- **Orchestration agents** for coordinating complex workflows with quality gates
- **Implementation agents** for database, backend, frontend, and Python development
- **Quality agents** for testing, security auditing, and documentation
- **T1/T2 cost optimization** with automatic escalation (Haiku → Sonnet)
- **Strict quality gates** ensuring 100% acceptance criteria satisfaction

## Installation

```bash
# From GitHub (Recommended)
/plugin marketplace add https://github.com/michael-harris/claude-code-multi-agent-dev-system
/plugin install multi-agent-dev-system

# Verify installation
/plugin list
```

## Quick Start

### Full Workflow (Recommended)

```bash
# 1. Generate comprehensive PRD
/prd

# 2. Break down into tasks and sprints
/planning

# 3. Execute a sprint
/sprint SPRINT-001
```

### Individual Agent Usage

You can also invoke any agent directly for specific tasks:

```javascript
// Design a database schema
Task({
  subagent_type: "multi-agent-dev-system:database:designer",
  model: "opus",
  prompt: "Design a normalized schema for user authentication with roles and permissions"
})

// Implement an API endpoint
Task({
  subagent_type: "multi-agent-dev-system:backend:api-developer-python-t1",
  model: "haiku",
  prompt: "Implement POST /api/users endpoint based on docs/design/api/users-api.yaml"
})

// Create React component
Task({
  subagent_type: "multi-agent-dev-system:frontend:developer-t1",
  model: "haiku",
  prompt: "Implement LoginForm component based on docs/design/frontend/login-components.yaml"
})

// Write comprehensive tests
Task({
  subagent_type: "multi-agent-dev-system:quality:test-writer",
  model: "sonnet",
  prompt: "Write unit and integration tests for user authentication API"
})
```

## Complete Agent Reference

### Planning Agents (3)

#### `planning:prd-generator` (Sonnet)
**Purpose:** Interactive PRD creation through structured Q&A with technology stack selection

**When to use:**
- Starting a new project or feature
- Need to document requirements comprehensively
- Want technology stack recommendations based on integrations

**What it does:**
- Conducts interactive interview about your project
- Asks about external integrations to recommend appropriate stack
- Creates comprehensive PRD in YAML format
- Outputs to `docs/planning/PROJECT_PRD.yaml`

**Example:**
```javascript
Task({
  subagent_type: "multi-agent-dev-system:planning:prd-generator",
  model: "sonnet",
  prompt: "Help me create a PRD for a project management tool with ML-powered task prioritization"
})
```

---

#### `planning:task-graph-analyzer` (Sonnet)
**Purpose:** Decomposes PRD into discrete, implementable tasks with dependency analysis

**When to use:**
- After completing PRD
- Need to break down features into implementable tasks
- Want dependency graph for parallel work

**What it does:**
- Reads PROJECT_PRD.yaml
- Creates individual task files (TASK-001.yaml, etc.)
- Identifies task types (fullstack, backend, frontend, database, python-generic, infrastructure)
- Analyzes dependencies and builds dependency graph
- Ensures tasks are sized appropriately (1-2 days max)

**Example:**
```javascript
Task({
  subagent_type: "multi-agent-dev-system:planning:task-graph-analyzer",
  model: "sonnet",
  prompt: "Analyze docs/planning/PROJECT_PRD.yaml and create task breakdown"
})
```

---

#### `planning:sprint-planner` (Sonnet)
**Purpose:** Organizes tasks into sprints based on dependencies and capacity

**When to use:**
- After task breakdown is complete
- Need to organize work into time-boxed sprints
- Want to respect task dependencies

**What it does:**
- Reads all task files from docs/planning/tasks/
- Groups tasks into sprints respecting dependencies
- Creates sprint files (SPRINT-001.yaml, etc.)
- Balances sprint capacity
- Generates sprint summary

**Example:**
```javascript
Task({
  subagent_type: "multi-agent-dev-system:planning:sprint-planner",
  model: "sonnet",
  prompt: "Create sprint plan from tasks in docs/planning/tasks/"
})
```

---

### Orchestration Agents (3)

#### `orchestration:sprint-orchestrator` (Opus)
**Purpose:** Manages entire sprint execution and coordinates task orchestrator

**When to use:**
- Executing a complete sprint
- Need high-level sprint coordination
- Want automatic task sequencing

**What it does:**
- Reads sprint file (e.g., SPRINT-001.yaml)
- Executes tasks in correct order based on dependencies
- Launches task-orchestrator for each task
- Tracks sprint progress
- Generates sprint completion report

**Example:**
```javascript
Task({
  subagent_type: "multi-agent-dev-system:orchestration:sprint-orchestrator",
  model: "opus",
  prompt: "Execute docs/planning/sprints/SPRINT-001.yaml"
})
```

---

#### `orchestration:task-orchestrator` (Sonnet)
**Purpose:** Coordinates specialized agents for single task with T1/T2 escalation

**When to use:**
- Implementing a single task
- Need multiple agents coordinated (designer → developer → tester)
- Want automatic T1→T2 escalation on failures

**What it does:**
- Reads task file (TASK-XXX.yaml)
- Selects appropriate workflow based on task type
- Executes workflow with T1 agents first
- Submits to requirements-validator
- Escalates to T2 agents if validation fails
- Iterates until all acceptance criteria met

**Example:**
```javascript
Task({
  subagent_type: "multi-agent-dev-system:orchestration:task-orchestrator",
  model: "sonnet",
  prompt: "Execute docs/planning/tasks/TASK-003.yaml"
})
```

---

#### `orchestration:requirements-validator` (Opus)
**Purpose:** Quality gate with strict acceptance criteria validation

**When to use:**
- Validating completed work against requirements
- Need strict quality gate (no compromises)
- Want detailed gap analysis for failures

**What it does:**
- Reads task acceptance criteria
- Examines all code, tests, and documentation
- Verifies EVERY criterion is 100% met
- Returns PASS or FAIL with specific gaps
- Never accepts "close enough"
- Enforces 80%+ test coverage

**Example:**
```javascript
Task({
  subagent_type: "multi-agent-dev-system:orchestration:requirements-validator",
  model: "opus",
  prompt: "Validate TASK-003 implementation against acceptance criteria in docs/planning/tasks/TASK-003.yaml"
})
```

---

### Database Agents (5)

#### `database:designer` (Opus)
**Purpose:** Designs normalized database schemas (language-agnostic)

**When to use:**
- Starting new database design
- Need normalized schema (3NF+)
- Want database-agnostic design specification

**What it does:**
- Designs normalized schemas (3NF minimum)
- Defines relationships and constraints
- Plans indexes for performance
- Creates migration strategy
- Outputs to docs/design/database/

**Example:**
```javascript
Task({
  subagent_type: "multi-agent-dev-system:database:designer",
  model: "opus",
  prompt: "Design schema for multi-tenant SaaS with organizations, users, roles, and permissions"
})
```

---

#### `database:developer-python-t1` (Haiku) **[T1]**
**Purpose:** Implements SQLAlchemy models and Alembic migrations (cost-optimized)

**When to use:**
- Implementing straightforward database schemas in Python
- Cost optimization is priority
- Schema design is already complete

**What it does:**
- Creates SQLAlchemy models from schema design
- Generates Alembic migrations
- Implements relationships (one-to-many, many-to-many)
- Adds validation and type hints
- Creates database utilities

**Example:**
```javascript
Task({
  subagent_type: "multi-agent-dev-system:database:developer-python-t1",
  model: "haiku",
  prompt: "Implement SQLAlchemy models from docs/design/database/users-schema.yaml"
})
```

---

#### `database:developer-python-t2` (Sonnet) **[T2]**
**Purpose:** Implements SQLAlchemy models and Alembic migrations (enhanced quality)

**When to use:**
- Complex database schemas
- T1 validation failed
- Need advanced SQLAlchemy features

**What it does:**
- Same as T1 but with enhanced quality
- Better handling of complex relationships
- Advanced SQLAlchemy patterns
- More robust migrations

**Example:**
```javascript
Task({
  subagent_type: "multi-agent-dev-system:database:developer-python-t2",
  model: "sonnet",
  prompt: "Implement complex multi-tenant SQLAlchemy models with row-level security"
})
```

---

#### `database:developer-typescript-t1` (Haiku) **[T1]**
**Purpose:** Implements Prisma/TypeORM models and migrations (cost-optimized)

**When to use:**
- TypeScript/Node.js backend
- Straightforward schema implementation
- Using Prisma or TypeORM

**What it does:**
- Creates Prisma schema or TypeORM entities
- Generates migrations
- Implements relationships
- Adds validation with class-validator

**Example:**
```javascript
Task({
  subagent_type: "multi-agent-dev-system:database:developer-typescript-t1",
  model: "haiku",
  prompt: "Implement Prisma schema from docs/design/database/users-schema.yaml"
})
```

---

#### `database:developer-typescript-t2` (Sonnet) **[T2]**
**Purpose:** Implements Prisma/TypeORM models and migrations (enhanced quality)

**When to use:**
- Complex TypeScript schema requirements
- T1 validation failed
- Need advanced Prisma/TypeORM features

**What it does:**
- Enhanced TypeScript database implementation
- Advanced relationship handling
- Better migration strategies
- Complex validation patterns

**Example:**
```javascript
Task({
  subagent_type: "multi-agent-dev-system:database:developer-typescript-t2",
  model: "sonnet",
  prompt: "Implement complex Prisma schema with polymorphic associations"
})
```

---

### Backend Agents (7)

#### `backend:api-designer` (Opus)
**Purpose:** Designs RESTful API specifications with OpenAPI (language-agnostic)

**When to use:**
- Designing new API endpoints
- Need OpenAPI specification
- Want language-agnostic API contract

**What it does:**
- Designs RESTful endpoints
- Defines request/response schemas
- Specifies error responses
- Documents authentication requirements
- Plans validation rules
- Outputs to docs/design/api/

**Example:**
```javascript
Task({
  subagent_type: "multi-agent-dev-system:backend:api-designer",
  model: "opus",
  prompt: "Design REST API for user management with authentication, CRUD, and role assignment"
})
```

---

#### `backend:api-developer-python-t1` (Haiku) **[T1]**
**Purpose:** Implements FastAPI/Django endpoints (cost-optimized)

**When to use:**
- Straightforward API implementation in Python
- Using FastAPI or Django REST Framework
- Cost optimization priority

**What it does:**
- Implements endpoints from API design
- Adds Pydantic validation
- Implements error handling
- Adds authentication/authorization
- Implements rate limiting

**Example:**
```javascript
Task({
  subagent_type: "multi-agent-dev-system:backend:api-developer-python-t1",
  model: "haiku",
  prompt: "Implement FastAPI endpoints from docs/design/api/users-api.yaml"
})
```

---

#### `backend:api-developer-python-t2` (Sonnet) **[T2]**
**Purpose:** Implements FastAPI/Django endpoints (enhanced quality)

**When to use:**
- Complex API requirements
- T1 validation failed
- Need advanced FastAPI/Django patterns

**What it does:**
- Enhanced Python API implementation
- Complex authentication patterns
- Advanced error handling
- Performance optimization
- Better async handling

**Example:**
```javascript
Task({
  subagent_type: "multi-agent-dev-system:backend:api-developer-python-t2",
  model: "sonnet",
  prompt: "Implement complex FastAPI with WebSocket support and advanced caching"
})
```

---

#### `backend:api-developer-typescript-t1` (Haiku) **[T1]**
**Purpose:** Implements Express/NestJS endpoints (cost-optimized)

**When to use:**
- TypeScript backend with Express or NestJS
- Straightforward API implementation
- Cost optimization priority

**What it does:**
- Implements TypeScript endpoints
- Adds validation with class-validator
- Implements middleware
- Adds authentication/authorization
- Implements rate limiting

**Example:**
```javascript
Task({
  subagent_type: "multi-agent-dev-system:backend:api-developer-typescript-t1",
  model: "haiku",
  prompt: "Implement Express.js endpoints from docs/design/api/users-api.yaml"
})
```

---

#### `backend:api-developer-typescript-t2` (Sonnet) **[T2]**
**Purpose:** Implements Express/NestJS endpoints (enhanced quality)

**When to use:**
- Complex TypeScript API requirements
- T1 validation failed
- Using advanced NestJS features

**What it does:**
- Enhanced TypeScript API implementation
- Advanced NestJS patterns (guards, interceptors)
- Complex dependency injection
- Better error handling
- Performance optimization

**Example:**
```javascript
Task({
  subagent_type: "multi-agent-dev-system:backend:api-developer-typescript-t2",
  model: "sonnet",
  prompt: "Implement NestJS microservice with event-driven architecture"
})
```

---

#### `backend:code-reviewer-python` (Sonnet)
**Purpose:** Reviews Python backend code for quality and security

**When to use:**
- After Python backend implementation
- Need code quality review
- Want security vulnerability check

**What it does:**
- Reviews Python code quality
- Checks FastAPI/Django best practices
- Identifies security vulnerabilities
- Reviews error handling
- Checks test coverage
- Suggests improvements

**Example:**
```javascript
Task({
  subagent_type: "multi-agent-dev-system:backend:code-reviewer-python",
  model: "sonnet",
  prompt: "Review Python API implementation in backend/routes/ for security and quality"
})
```

---

#### `backend:code-reviewer-typescript` (Sonnet)
**Purpose:** Reviews TypeScript backend code for quality and security

**When to use:**
- After TypeScript backend implementation
- Need code quality review
- Want TypeScript-specific issues identified

**What it does:**
- Reviews TypeScript code quality
- Checks Express/NestJS best practices
- Identifies security issues
- Reviews type safety
- Checks test coverage
- Suggests improvements

**Example:**
```javascript
Task({
  subagent_type: "multi-agent-dev-system:backend:code-reviewer-typescript",
  model: "sonnet",
  prompt: "Review TypeScript API in src/controllers/ for type safety and security"
})
```

---

### Frontend Agents (4)

#### `frontend:designer` (Opus)
**Purpose:** Designs UI/UX with component specifications

**When to use:**
- Starting new frontend feature
- Need component architecture
- Want design specifications

**What it does:**
- Designs component hierarchy
- Defines component interfaces (props)
- Plans state management
- Designs data flow
- Specifies styling approach
- Plans accessibility features
- Outputs to docs/design/frontend/

**Example:**
```javascript
Task({
  subagent_type: "multi-agent-dev-system:frontend:designer",
  model: "opus",
  prompt: "Design component architecture for dashboard with real-time data visualization"
})
```

---

#### `frontend:developer-t1` (Haiku) **[T1]**
**Purpose:** Implements React/Vue components (cost-optimized)

**When to use:**
- Straightforward component implementation
- Using React or Vue
- Cost optimization priority

**What it does:**
- Implements components from design specs
- Adds state management (Context/React Query)
- Implements forms with validation
- Adds accessibility features
- Implements responsive design
- Uses Tailwind CSS or styled-components

**Example:**
```javascript
Task({
  subagent_type: "multi-agent-dev-system:frontend:developer-t1",
  model: "haiku",
  prompt: "Implement LoginForm component from docs/design/frontend/auth-components.yaml"
})
```

---

#### `frontend:developer-t2` (Sonnet) **[T2]**
**Purpose:** Implements React/Vue components (enhanced quality)

**When to use:**
- Complex component requirements
- T1 validation failed
- Need advanced patterns

**What it does:**
- Enhanced component implementation
- Advanced state management
- Complex animations
- Better performance optimization
- Advanced accessibility

**Example:**
```javascript
Task({
  subagent_type: "multi-agent-dev-system:frontend:developer-t2",
  model: "sonnet",
  prompt: "Implement complex data table with virtual scrolling, sorting, filtering, and real-time updates"
})
```

---

#### `frontend:code-reviewer` (Sonnet)
**Purpose:** Reviews frontend code for quality, accessibility, and performance

**When to use:**
- After frontend implementation
- Need accessibility audit
- Want performance review

**What it does:**
- Reviews React/Vue code quality
- Checks accessibility (WCAG 2.1)
- Reviews performance patterns
- Checks responsive design
- Reviews state management
- Suggests improvements

**Example:**
```javascript
Task({
  subagent_type: "multi-agent-dev-system:frontend:code-reviewer",
  model: "sonnet",
  prompt: "Review React components in src/components/ for accessibility and performance"
})
```

---

### Python Generic Agents (2)

#### `python:developer-generic-t1` (Haiku) **[T1]**
**Purpose:** Implements Python utilities, scripts, CLI tools (cost-optimized)

**When to use:**
- Python scripts or utilities
- CLI tools
- Data processing scripts
- Cost optimization priority

**What it does:**
- Implements Python utilities
- Creates CLI tools with argparse/click
- Writes data processing scripts
- Adds proper error handling
- Includes type hints and docstrings

**Example:**
```javascript
Task({
  subagent_type: "multi-agent-dev-system:python:developer-generic-t1",
  model: "haiku",
  prompt: "Create a CLI tool for database migrations with rollback support"
})
```

---

#### `python:developer-generic-t2` (Sonnet) **[T2]**
**Purpose:** Implements Python utilities, scripts, CLI tools (enhanced quality)

**When to use:**
- Complex Python utilities
- T1 validation failed
- Need advanced Python features

**What it does:**
- Enhanced Python implementation
- Advanced async patterns
- Complex data processing
- Better error handling
- Performance optimization

**Example:**
```javascript
Task({
  subagent_type: "multi-agent-dev-system:python:developer-generic-t2",
  model: "sonnet",
  prompt: "Create advanced ETL pipeline with async processing and error recovery"
})
```

---

### Quality Agents (3)

#### `quality:test-writer` (Sonnet)
**Purpose:** Creates comprehensive test suites (unit, integration, e2e)

**When to use:**
- After implementation
- Need test coverage
- Want comprehensive test strategy

**What it does:**
- Writes unit tests (70%)
- Writes integration tests (20%)
- Writes e2e tests (10%)
- Uses pytest (Python) or Jest (TypeScript)
- Mocks external dependencies
- Ensures 80%+ coverage
- Tests edge cases and error scenarios

**Example:**
```javascript
Task({
  subagent_type: "multi-agent-dev-system:quality:test-writer",
  model: "sonnet",
  prompt: "Write comprehensive test suite for user authentication API including unit, integration, and e2e tests"
})
```

---

#### `quality:security-auditor` (Opus)
**Purpose:** Performs security audits and vulnerability scanning

**When to use:**
- After implementation
- Need security audit
- Want OWASP Top 10 compliance check

**What it does:**
- Audits for OWASP Top 10
- Checks authentication/authorization
- Reviews input validation
- Checks for injection vulnerabilities
- Reviews data protection
- Checks API security
- Provides remediation code

**Example:**
```javascript
Task({
  subagent_type: "multi-agent-dev-system:quality:security-auditor",
  model: "opus",
  prompt: "Perform security audit of authentication system and API endpoints"
})
```

---

#### `quality:documentation-coordinator` (Sonnet)
**Purpose:** Creates and maintains technical documentation

**When to use:**
- Need API documentation
- Want architecture documentation
- Need setup/deployment guides

**What it does:**
- Creates API documentation
- Writes architecture docs
- Creates setup guides
- Writes deployment documentation
- Generates README files
- Documents design decisions

**Example:**
```javascript
Task({
  subagent_type: "multi-agent-dev-system:quality:documentation-coordinator",
  model: "sonnet",
  prompt: "Create comprehensive API documentation for all user management endpoints"
})
```

---

## Workflow Commands

### `/prd` - Generate PRD
Interactive PRD creation with technology stack recommendation.

**What it does:**
1. Asks about external integrations
2. Recommends appropriate tech stack
3. Conducts structured interview
4. Generates PROJECT_PRD.yaml

**Output:** `docs/planning/PROJECT_PRD.yaml`

---

### `/planning` - Create Tasks and Sprints
Breaks down PRD into implementable tasks organized into sprints.

**What it does:**
1. Analyzes PROJECT_PRD.yaml
2. Creates individual task files
3. Builds dependency graph
4. Organizes into sprints

**Output:**
- `docs/planning/tasks/TASK-XXX.yaml`
- `docs/planning/sprints/SPRINT-XXX.yaml`
- `docs/planning/TASK_SUMMARY.md`

---

### `/sprint SPRINT-001` - Execute Sprint
Executes a complete sprint with full orchestration.

**What it does:**
1. Reads sprint file
2. Executes tasks in dependency order
3. Runs appropriate workflows
4. Validates with requirements-validator
5. Auto-escalates T1→T2 on failures

**Output:** Fully implemented and tested features

---

## Architecture

```
User
  ↓
Commands: /prd, /planning, /sprint
  ↓
Sprint Orchestrator (Opus)
  ├── Manages entire sprint
  ├── Sequences tasks by dependencies
  └── Launches Task Orchestrator for each task
      ↓
Task Orchestrator (Sonnet)
  ├── Selects workflow based on task type
  ├── Coordinates specialized agents
  ├── Implements T1/T2 switching
  └── Submits to Requirements Validator
      ↓
Specialized Agents (T1/T2)
  ├── Designer agents (Opus) - Schema, API, UI design
  ├── Developer agents (Haiku T1 / Sonnet T2) - Implementation
  ├── Code reviewers (Sonnet) - Quality review
  └── Quality agents (Sonnet/Opus) - Tests, security, docs
      ↓
Requirements Validator (Opus)
  ├── Quality gate (PASS/FAIL)
  ├── Validates 100% criteria satisfaction
  └── Triggers T1→T2 escalation if needed
```

## Cost Optimization: T1/T2 System

### How It Works

**Tier 1 (T1) - Haiku:**
- First attempt at implementation
- Cost-optimized model
- Handles ~70% of work successfully
- Fast execution

**Tier 2 (T2) - Sonnet:**
- Used for complex scenarios
- Enhanced quality
- Handles remaining ~30% after T1 escalation
- Used when T1 fails validation

### Automatic Escalation

```
Iteration 1: T1 developer → requirements-validator
  ├── PASS → Task complete ✓
  └── FAIL → Iteration 2

Iteration 2: T1 developer (retry) → requirements-validator
  ├── PASS → Task complete ✓
  └── FAIL → Escalate to T2

Iteration 3+: T2 developer → requirements-validator
  ├── PASS → Task complete ✓
  └── FAIL → T2 retry (max 5 iterations)
```

### Cost Savings

- **Without T1/T2:** All work uses Sonnet = 100% Sonnet cost
- **With T1/T2:** 70% Haiku + 30% Sonnet = **~60-70% cost reduction**

## Quality Gates

### Requirements Validator Standards

- ✅ **100% acceptance criteria met** (no compromises)
- ✅ **Test coverage ≥ 80%**
- ✅ **No security vulnerabilities** (OWASP Top 10)
- ✅ **Code follows language conventions**
- ✅ **Documentation complete**
- ✅ **All edge cases handled**

### Security Auditor Standards

- ✅ Proper authentication/authorization
- ✅ Input validation (SQL injection, XSS prevention)
- ✅ Data protection (encryption, HTTPS)
- ✅ API security (rate limiting, CORS)
- ✅ No hardcoded secrets
- ✅ Secure error handling

## Technology Stack Support

### Python Stack
- **Backend:** FastAPI or Django + SQLAlchemy
- **Database:** PostgreSQL + Alembic migrations
- **Testing:** pytest + pytest-cov
- **API Docs:** OpenAPI/Swagger

### TypeScript Stack
- **Backend:** Express or NestJS + Prisma/TypeORM
- **Frontend:** React or Next.js + Tailwind CSS
- **Database:** PostgreSQL + Prisma migrations
- **Testing:** Jest + React Testing Library

Stack selection happens during PRD generation based on project requirements and integrations.

## Usage Examples

### Example 1: Quick Database Schema

```javascript
// Design schema
Task({
  subagent_type: "multi-agent-dev-system:database:designer",
  model: "opus",
  prompt: "Design e-commerce schema: products, categories, orders, customers"
})

// Implement in Python
Task({
  subagent_type: "multi-agent-dev-system:database:developer-python-t1",
  model: "haiku",
  prompt: "Implement SQLAlchemy models from docs/design/database/ecommerce-schema.yaml"
})
```

### Example 2: Complete API Feature

```javascript
// 1. Design API
Task({
  subagent_type: "multi-agent-dev-system:backend:api-designer",
  model: "opus",
  prompt: "Design REST API for product catalog with search and filtering"
})

// 2. Implement API
Task({
  subagent_type: "multi-agent-dev-system:backend:api-developer-python-t1",
  model: "haiku",
  prompt: "Implement product catalog API from docs/design/api/products-api.yaml"
})

// 3. Write tests
Task({
  subagent_type: "multi-agent-dev-system:quality:test-writer",
  model: "sonnet",
  prompt: "Write tests for product catalog API"
})

// 4. Security audit
Task({
  subagent_type: "multi-agent-dev-system:quality:security-auditor",
  model: "opus",
  prompt: "Security audit product catalog API"
})
```

### Example 3: Frontend Component

```javascript
// 1. Design component
Task({
  subagent_type: "multi-agent-dev-system:frontend:designer",
  model: "opus",
  prompt: "Design product search component with filters and pagination"
})

// 2. Implement component
Task({
  subagent_type: "multi-agent-dev-system:frontend:developer-t1",
  model: "haiku",
  prompt: "Implement ProductSearch component from docs/design/frontend/search-components.yaml"
})

// 3. Review code
Task({
  subagent_type: "multi-agent-dev-system:frontend:code-reviewer",
  model: "sonnet",
  prompt: "Review ProductSearch component for accessibility and performance"
})
```

### Example 4: Python Utility

```javascript
Task({
  subagent_type: "multi-agent-dev-system:python:developer-generic-t1",
  model: "haiku",
  prompt: "Create CLI tool for exporting database to CSV with filtering options"
})
```

### Example 5: Validation Only

```javascript
Task({
  subagent_type: "multi-agent-dev-system:orchestration:requirements-validator",
  model: "opus",
  prompt: "Validate user authentication implementation against TASK-003.yaml acceptance criteria"
})
```

## Agent Selection Guide

### When designing (use Opus designers):
- `database:designer` - For database schemas
- `backend:api-designer` - For API contracts
- `frontend:designer` - For component architecture

### When implementing (start with T1):
- `database:developer-*-t1` - For database models
- `backend:api-developer-*-t1` - For API endpoints
- `frontend:developer-t1` - For React/Vue components
- `python:developer-generic-t1` - For utilities/scripts

### When implementation is complex (use T2):
- `*-t2` agents - Use directly for complex requirements

### When reviewing:
- `backend:code-reviewer-*` - For backend code quality
- `frontend:code-reviewer` - For frontend code quality

### When ensuring quality:
- `quality:test-writer` - For comprehensive tests
- `quality:security-auditor` - For security vulnerabilities
- `quality:documentation-coordinator` - For documentation
- `orchestration:requirements-validator` - For acceptance criteria validation

### When orchestrating:
- `orchestration:task-orchestrator` - For single task coordination
- `orchestration:sprint-orchestrator` - For sprint coordination
- Or use commands: `/prd`, `/planning`, `/sprint`

## Repository Structure

```
claude-code-multi-agent-dev-system/
├── agents/                          # 27 agent prompt files
│   ├── planning/                    # PRD, task analysis, sprint planning
│   ├── orchestration/               # Sprint & task orchestrators, validator
│   ├── database/                    # Schema design & implementation (Python/TS, T1/T2)
│   ├── backend/                     # API design & implementation (Python/TS, T1/T2)
│   ├── frontend/                    # UI design & implementation (T1/T2)
│   ├── python/                      # Generic Python development (T1/T2)
│   └── quality/                     # Testing, security, documentation
├── commands/                        # 3 workflow commands
│   ├── prd.md                       # /prd command
│   ├── planning.md                  # /planning command
│   └── sprint.md                    # /sprint command
├── examples/                        # Usage examples
│   ├── complete-workflow-example.md # Full workflow demonstration
│   └── individual-agent-usage.md    # Individual agent examples
├── .claude-plugin/                  # Plugin metadata
│   └── marketplace.json             # Marketplace configuration
├── plugin.json                      # Plugin manifest (27 agents, 3 commands)
├── install-local.sh                 # Local installation script
└── README.md                        # This file
```

When using the plugin in your projects, it generates:
```
your-project/
├── docs/
│   ├── planning/                    # PRDs, tasks, sprints
│   │   ├── PROJECT_PRD.yaml
│   │   ├── tasks/TASK-*.yaml
│   │   └── sprints/SPRINT-*.yaml
│   └── design/                      # Design specifications
│       ├── database/                # Schema designs
│       ├── api/                     # API specifications
│       └── frontend/                # Component designs
├── src/                             # Generated application code
│   ├── backend/                     # API implementation
│   └── frontend/                    # React/Vue components
└── tests/                           # Generated tests
    ├── backend/                     # API tests
    └── frontend/                    # Component tests
```

## Features Summary

✅ **27 specialized agents** across planning, implementation, and quality
✅ **Hierarchical orchestration** with sprint and task coordinators
✅ **T1/T2 cost optimization** with automatic escalation (60-70% cost savings)
✅ **Strict quality gates** ensuring 100% acceptance criteria satisfaction
✅ **Full-stack support** for Python and TypeScript
✅ **Comprehensive testing** with 80%+ coverage requirement
✅ **Security auditing** with OWASP Top 10 compliance
✅ **Language-agnostic design** phase (database, API, frontend)
✅ **Workflow commands** for end-to-end automation
✅ **Individual agent access** for specific tasks

## License

MIT License - See LICENSE file for details

## Contributing

This plugin is part of the Claude Code ecosystem. For issues or suggestions, please visit:
https://github.com/michael-harris/claude-code-multi-agent-dev-system/issues

## Support

- **Documentation:** This README and `examples/` directory
- **Issues:** https://github.com/michael-harris/claude-code-multi-agent-dev-system/issues
- **Claude Code Docs:** https://docs.claude.com/en/docs/claude-code

---

**Start building with AI agents today!**

Install the plugin and run `/prd` to get started with your first AI-powered development project.
