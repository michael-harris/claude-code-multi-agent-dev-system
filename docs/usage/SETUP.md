# Multi-Agent Development System - Template Documentation

**Version:** 2.1 (Pragmatic Approach)
**Agents:** 27 specialized AI agents with T1/T2 quality tiers
**Orchestration:** Claude Code manually coordinates agents via slash commands

---

## This is a Template Repository

This repository contains a ready-to-use multi-agent development system. Everything is already set up:

- `.claude/agents/` - 27 agent definitions
- `.claude/commands/` - 3 slash commands
- `.claude/settings.json` - Configuration
- `docs/` - Documentation structure
- Agent definitions are markdown files with instructions
- Slash commands are prompts that tell Claude how to orchestrate

## Quick Start

```bash
# 1. Clone or copy this template
git clone <this-repo>
cd cs-archiver

# 2. Start planning with slash commands:
/prd                # Interactive Q&A to create PRD
/planning           # Break PRD into tasks and organize sprints

# 3. Execute sprint (Claude orchestrates):
/sprint SPRINT-001  # Claude manually coordinates all agents
```

---

## System Architecture

### 27 Specialized Agents (T1/T2 Quality Tiers)

**Planning (3 agents):**
- `prd-generator` - Interactive PRD with tech stack selection
- `task-graph-analyzer` - Dependency-aware task breakdown
- `sprint-planner` - Sprint organization with sequencing

**Orchestration (3 agents):**
- `sprint-orchestrator` - Manages entire sprint execution
- `task-orchestrator` - Coordinates task workflows
- `requirements-validator` - Quality gate (100% validation)

**Database (6 agents):**
- `database-designer` - Language-agnostic schema design
- `database-developer-python-t1` - SQLAlchemy/Alembic (Haiku)
- `database-developer-python-t2` - SQLAlchemy/Alembic (Sonnet)
- `database-developer-typescript-t1` - Prisma/TypeORM (Haiku)
- `database-developer-typescript-t2` - Prisma/TypeORM (Sonnet)

**Backend API (9 agents):**
- `api-designer` - Language-agnostic API specs
- `api-developer-python-t1` - FastAPI/Django (Haiku)
- `api-developer-python-t2` - FastAPI/Django (Sonnet)
- `api-developer-typescript-t1` - Express/NestJS (Haiku)
- `api-developer-typescript-t2` - Express/NestJS (Sonnet)
- `backend-code-reviewer-python` - Python-specific review
- `backend-code-reviewer-typescript` - TypeScript-specific review

**Frontend (4 agents):**
- `frontend-designer` - React/Next.js architecture
- `frontend-developer-t1` - TypeScript implementation (Haiku)
- `frontend-developer-t2` - TypeScript implementation (Sonnet)
- `frontend-code-reviewer` - Code quality review

**Generic Python (2 agents):**
- `python-developer-generic-t1` - Utilities, scripts, CLI tools (Haiku)
- `python-developer-generic-t2` - Utilities, scripts, CLI tools (Sonnet)

**Quality & Docs (3 agents):**
- `test-writer` - Comprehensive test coverage
- `security-auditor` - Security analysis
- `documentation-coordinator` - Technical documentation

**Developer Tiers:**
- T1 Developers (Haiku): Cost-optimized first attempts
- T2 Developers (Sonnet): Enhanced quality for complex fixes
- Automatic switching: T1 fails iteration 2 → T2 takes over iteration 3+

### Execution Flow (Pragmatic Orchestration)

```
User types: /sprint SPRINT-001
  ↓
Claude reads: .claude/commands/sprint.md (orchestration instructions)
  ↓
Claude orchestrates manually:
  → Reads sprint plan from docs/sprints/SPRINT-001.yaml
  → For each task in sequence:
    ↓
  Claude determines workflow type (fullstack/backend/frontend/python-generic)
    → Launches specialized agents using Task tool:
      • database-designer → database-developer-{lang}-t1
      • api-designer → api-developer-{lang}-t1
      • frontend-designer → frontend-developer-t1
      • test-writer → code-reviewers → security-auditor
    → Claude tracks iteration count manually
    → Claude implements T1→T2 switching:
      • Iteration 1-2: Launch T1 agents (Haiku)
      • Iteration 3+: Launch T2 agents (Sonnet)
    ↓
  Claude launches requirements-validator agent
    → Validator checks ALL acceptance criteria
    → PASS: Claude marks task complete, moves to next
    → FAIL: Claude notes gaps, increments iteration
      ↓
    Claude (Iteration 2)
      → Launches specific agents needed for gaps
      → Re-validates
      → Loops until PASS or max iterations (10)
  ↓
Sprint complete when Claude has orchestrated all tasks to completion
```

**Key Difference:** Claude manually coordinates everything using the Task tool and tracks state in responses.

---

## Directory Structure (Already Created)

This template repository already contains:

```bash
.claude/
├── agents/              # 27 agent definition files (markdown)
│   ├── planning/        # 3 planning agents
│   ├── orchestration/   # 3 orchestration agents
│   ├── database/        # 6 database agents (T1/T2 pairs)
│   ├── backend/         # 7 backend agents (T1/T2 + reviewers)
│   ├── frontend/        # 4 frontend agents (T1/T2 + reviewer)
│   ├── python/          # 2 Python generic agents (T1/T2)
│   └── quality/         # 3 quality agents
├── commands/            # 3 slash command files (markdown prompts)
│   ├── prd.md          # /prd command
│   ├── planning.md     # /planning command
│   └── sprint.md       # /sprint command
├── templates/           # Tech stack templates (for reference)
├── settings.json        # Agent model assignments
└── CLAUDE.md            # System overview for agents

docs/
├── planning/            # PRD and task definitions (created by agents)
│   └── tasks/           # Individual task files
├── sprints/             # Sprint definitions (created by agents)
├── features/            # Feature documentation
├── api/                 # API documentation
├── adrs/                # Architecture decision records
└── reviews/             # Code review reports

src/
├── backend/             # Backend source code (created by agents)
└── frontend/            # Frontend source code (created by agents)

tests/
├── backend/             # Backend tests (created by agents)
└── frontend/            # Frontend tests (created by agents)
```

**Note:** Agent definitions and commands already exist. You just use them.

---

## Configuration Files

### `.claude/settings.json`

```json
{
  "version": "2.1",
  "system_name": "multi-agent-dev-stack",
  "defaultModel": "claude-haiku-4-5",
  
  "agentModels": {
    "prd-generator": "claude-sonnet-4-5",
    "task-graph-analyzer": "claude-sonnet-4-5",
    "sprint-planner": "claude-sonnet-4-5",
    "sprint-orchestrator": "claude-opus-4-1",
    "task-orchestrator": "claude-sonnet-4-5",
    "requirements-validator": "claude-opus-4-1",
    
    "database-designer": "claude-opus-4-1",
    "database-developer-python-t1": "claude-haiku-4-5",
    "database-developer-python-t2": "claude-sonnet-4-5",
    "database-developer-typescript-t1": "claude-haiku-4-5",
    "database-developer-typescript-t2": "claude-sonnet-4-5",
    
    "api-designer": "claude-opus-4-1",
    "api-developer-python-t1": "claude-haiku-4-5",
    "api-developer-python-t2": "claude-sonnet-4-5",
    "api-developer-typescript-t1": "claude-haiku-4-5",
    "api-developer-typescript-t2": "claude-sonnet-4-5",
    "backend-code-reviewer-python": "claude-sonnet-4-5",
    "backend-code-reviewer-typescript": "claude-sonnet-4-5",
    
    "frontend-designer": "claude-opus-4-1",
    "frontend-developer-t1": "claude-haiku-4-5",
    "frontend-developer-t2": "claude-sonnet-4-5",
    "frontend-code-reviewer": "claude-sonnet-4-5",
    
    "python-developer-generic-t1": "claude-haiku-4-5",
    "python-developer-generic-t2": "claude-sonnet-4-5",
    
    "test-writer": "claude-sonnet-4-5",
    "security-auditor": "claude-opus-4-1",
    "documentation-coordinator": "claude-sonnet-4-5"
  },
  
  "costOptimization": {
    "enabled": true,
    "strategy": "complexity-based",
    "tiers": {
      "t1": "claude-haiku-4-5",
      "t2": "claude-sonnet-4-5",
      "design": "claude-opus-4-1"
    },
    "switching": {
      "iterations_before_t2": 2
    }
  },
  
  "validation": {
    "max_iterations": 10,
    "require_tests": true,
    "require_security_review": true,
    "require_documentation": true,
    "coverage_threshold": 80
  },
  
  "workflows": {
    "task_timeout_minutes": 60,
    "parallel_execution": true,
    "max_parallel_tasks": 3
  },
  
  "techStackTemplates": {
    "python-fastapi-react": {
      "backend": "Python + FastAPI",
      "frontend": "TypeScript + React",
      "database": "PostgreSQL + SQLAlchemy",
      "testing": "pytest + Jest"
    },
    "python-django-react": {
      "backend": "Python + Django",
      "frontend": "TypeScript + React",
      "database": "PostgreSQL + Django ORM",
      "testing": "pytest + Jest"
    },
    "typescript-express-nextjs": {
      "backend": "TypeScript + Express",
      "frontend": "TypeScript + Next.js",
      "database": "PostgreSQL + Prisma",
      "testing": "Jest"
    },
    "typescript-nestjs-nextjs": {
      "backend": "TypeScript + NestJS",
      "frontend": "TypeScript + Next.js",
      "database": "PostgreSQL + TypeORM",
      "testing": "Jest"
    }
  }
}
```

### `.claudeignore`

```
# Python
__pycache__/
*.pyc
*.pyo
*.pyd
.Python
*.so
*.egg
*.egg-info/
dist/
build/
venv/
env/
.venv/
.env

# JavaScript/TypeScript
node_modules/
npm-debug.log
yarn-error.log
.next/
out/
dist/
build/

# IDE
.vscode/
.idea/
*.swp
*.swo
.DS_Store

# Testing
.coverage
.pytest_cache/
htmlcov/
coverage/
.nyc_output/

# Database
*.db
*.sqlite
*.sqlite3

# Logs
*.log
logs/

# System files
.claude/workflows/
.claude/templates/
```

### `.claude/CLAUDE.md`

```markdown
# Multi-Agent Development System

You are part of a 27-agent automated development system with hierarchical orchestration and T1/T2 quality tiers.

## System Architecture

**Planning → Orchestration → Implementation (T1/T2) → Quality**

Sprint Orchestrator manages entire sprint, routing tasks to Task Orchestrator.
Task Orchestrator coordinates specialized implementation agents with automatic T1→T2 escalation.
Requirements Validator ensures 100% criterion satisfaction.

## Core Principles

1. **Specialization:** Each agent has specific domain expertise
2. **Quality Gates:** Requirements validator approves all work
3. **Iterative Refinement:** Failed validation triggers targeted fixes
4. **Cost Optimization:** T1 (Haiku) first, T2 (Sonnet) for complex fixes
5. **Stack Flexibility:** Python or TypeScript backends

## Your Role

Your specific instructions are in your agent definition file in `.claude/agents/`.

When working:
- Read task requirements from `docs/planning/tasks/TASK-XXX.yaml`
- Follow your specialized instructions precisely
- Produce high-quality, production-ready code
- Hand off work when your part completes
- If validation fails, address only specified gaps
- If you're T2: You're handling a complex scenario T1 couldn't resolve

## Quality Standards

- Test coverage ≥ 80%
- Security best practices followed
- Code follows language conventions
- Documentation complete and accurate
- All acceptance criteria 100% satisfied
```

---

## All Agent Definitions

Due to length, agent definitions are provided in a separate document. See **AGENTS.md** for complete markdown files for all 27 agents.

Key agents include:

### Planning Phase
- **prd-generator:** Interactive Q&A, determines tech stack early
- **task-graph-analyzer:** Breaks PRD into tasks with dependencies
- **sprint-planner:** Organizes tasks into sprint plans

### Orchestration Layer
- **sprint-orchestrator:** Executes entire sprint from one command
- **task-orchestrator:** Manages single task workflow and handoffs with T1/T2 switching
- **requirements-validator:** Quality gate ensuring 100% completion

### T1/T2 Developer Structure

All developer agents now have two tiers:

**T1 (Haiku) - First Attempts:**
- Database developers (Python/TypeScript)
- API developers (Python/TypeScript)
- Frontend developer
- Generic Python developer

**T2 (Sonnet) - Complex Fixes:**
- Same agents, enhanced reasoning
- Activated after T1 fails second validation
- Continues through remaining iterations

### Implementation Agents
- **Database:** Designer + Python T1/T2 + TypeScript T1/T2 developers
- **Backend:** Designer + Python T1/T2 + TypeScript T1/T2 developers + reviewers
- **Frontend:** Designer + T1/T2 developer + reviewer
- **Generic Python:** T1/T2 developers for utilities, scripts, CLI tools
- **Quality:** Test writer, security auditor, docs coordinator

---

## Slash Commands (Orchestration Prompts)

**IMPORTANT**: The pragmatic approach uses markdown slash commands instead of YAML workflows.

All command files already exist in `.claude/commands/`. When you type a slash command, Claude Code expands the markdown prompt and Claude manually orchestrates the agents using the Task tool.

**Available Commands:**

### 1. `/prd` - PRD Generation

**File:** `.claude/commands/prd.md`

**What it does:**
- Prompts Claude to act as the PRD Generator agent
- Claude conducts interactive Q&A following `.claude/agents/planning/prd-generator.md`
- Creates `docs/planning/PROJECT_PRD.yaml`

**How it works:**
1. User types `/prd`
2. Claude Code expands the prd.md prompt
3. Claude asks questions interactively
4. Claude writes PRD using Write tool
5. Claude tells user to run `/planning` next

**No automation** - Just a prompt telling Claude what to do.

### 2. `/planning` - Task & Sprint Planning

**File:** `.claude/commands/planning.md`

**What it does:**
- Prompts Claude to orchestrate task-graph-analyzer and sprint-planner agents
- Creates task files and sprint files

**How it works:**
1. User types `/planning`
2. Claude Code expands the planning.md prompt
3. Claude reads `docs/planning/PROJECT_PRD.yaml`
4. Claude launches task-graph-analyzer agent using Task tool
5. Agent creates `docs/planning/tasks/TASK-*.yaml` files
6. Claude launches sprint-planner agent using Task tool
7. Agent creates `docs/sprints/SPRINT-*.yaml` files
8. Claude tells user to run `/sprint SPRINT-001` next

**Manual orchestration** - Claude coordinates agents sequentially.

### 3. `/sprint SPRINT-ID` - Sprint Execution

**File:** `.claude/commands/sprint.md`

```yaml
name: sprint-execution
description: Execute complete sprint with all tasks
trigger: manual
command: /sprint execute SPRINT-{id}

parameters:
  - name: sprint_id
    type: string
    required: true
    description: Sprint identifier (e.g., SPRINT-001)

steps:
  - name: load-sprint-plan
    action: read_file
    file: docs/sprints/${sprint_id}.yaml
    output_var: sprint_plan
  
  - name: execute-sprint
    agent: sprint-orchestrator
    input:
      sprint_plan: ${sprint_plan}
      sprint_id: ${sprint_id}
    mode: orchestration
    
  - name: generate-completion-report
    depends_on: execute-sprint
    action: write_file
    file: docs/sprints/${sprint_id}-completion.md
    content: ${execute-sprint.completion_report}
    
  - name: notify-user
    action: message
    content: |
      Sprint ${sprint_id} complete!
      
      Report: docs/sprints/${sprint_id}-completion.md
      Status: docs/sprints/${sprint_id}-status.yaml
      
      Next sprint: /sprint execute ${next_sprint_id}
```

### 4. Task Execution Workflow

**File:** `.claude/workflows/task-execution.yaml`

```yaml
name: task-execution
description: Execute single task with validation loop and T1/T2 switching
trigger: internal
invoked_by: sprint-orchestrator

parameters:
  - name: task_id
    type: string
    required: true
  - name: sprint_id
    type: string
    required: true

steps:
  - name: load-task
    action: read_file
    file: docs/planning/tasks/${task_id}.yaml
    output_var: task_definition
  
  - name: execute-task
    agent: task-orchestrator
    input:
      task_id: ${task_id}
      task_definition: ${task_definition}
      sprint_id: ${sprint_id}
    mode: orchestration
    max_iterations: 10
    tier_switching:
      enabled: true
      t1_iterations: 2
      t2_iterations_plus: 3
    
  - name: update-task-status
    action: write_file
    file: docs/planning/tasks/${task_id}-status.yaml
    content: ${execute-task.status}
```

### 5. Fullstack Feature Workflow

**File:** `.claude/workflows/fullstack-feature.yaml`

```yaml
name: fullstack-feature
description: Complete feature with database, API, and frontend
trigger: internal
invoked_by: task-orchestrator

parameters:
  - name: task_id
  - name: task_definition
  - name: tech_stack
  - name: iteration
    default: 1
  - name: validation_gaps
    default: null

steps:
  - name: database-design
    agent: database-designer
    input:
      task: ${task_definition}
      requirements: ${task_definition.technical_requirements.database}
    output_var: db_schema
    skip_if: ${iteration > 1 AND "database" not in validation_gaps}
  
  - name: database-implementation
    agent: database-developer-${tech_stack.backend.language}-${tier}
    depends_on: database-design
    input:
      schema: ${db_schema}
      task: ${task_definition}
    tier_selection:
      iteration_1: t1
      iteration_2: t1
      iteration_3_plus: t2
    skip_if: ${iteration > 1 AND "database" not in validation_gaps}
  
  - name: api-design
    agent: api-designer
    input:
      task: ${task_definition}
      requirements: ${task_definition.technical_requirements.api}
      database_schema: ${db_schema}
    output_var: api_spec
    skip_if: ${iteration > 1 AND "api" not in validation_gaps}
  
  - name: api-implementation
    agent: api-developer-${tech_stack.backend.language}-${tier}
    depends_on: api-design
    input:
      api_spec: ${api_spec}
      task: ${task_definition}
    tier_selection:
      iteration_1: t1
      iteration_2: t1
      iteration_3_plus: t2
    skip_if: ${iteration > 1 AND "api" not in validation_gaps}
  
  - name: frontend-design
    agent: frontend-designer
    input:
      task: ${task_definition}
      requirements: ${task_definition.technical_requirements.frontend}
      api_spec: ${api_spec}
    output_var: ui_design
    skip_if: ${iteration > 1 AND "frontend" not in validation_gaps}
  
  - name: frontend-implementation
    agent: frontend-developer-${tier}
    depends_on: frontend-design
    input:
      ui_design: ${ui_design}
      api_spec: ${api_spec}
      task: ${task_definition}
      validation_gaps: ${validation_gaps.frontend}
    tier_selection:
      iteration_1: t1
      iteration_2: t1
      iteration_3_plus: t2
    
  - name: test-writing
    agent: test-writer
    depends_on: [database-implementation, api-implementation, frontend-implementation]
    input:
      task: ${task_definition}
      code_files: ${all_previous_outputs}
      tech_stack: ${tech_stack}
      validation_gaps: ${validation_gaps.tests}
  
  - name: backend-review
    agent: backend-code-reviewer-${tech_stack.backend.language}
    depends_on: [api-implementation, test-writing]
    input:
      code_files: [api, database, tests]
      requirements: ${task_definition}
    skip_if: ${iteration > 1 AND "backend" not in validation_gaps}
  
  - name: frontend-review
    agent: frontend-code-reviewer
    depends_on: [frontend-implementation, test-writing]
    input:
      code_files: [frontend, tests]
      requirements: ${task_definition}
    
  - name: security-audit
    agent: security-auditor
    depends_on: [backend-review, frontend-review]
    input:
      all_code: ${all_previous_outputs}
      requirements: ${task_definition}
    skip_if: ${iteration > 1 AND "security" not in validation_gaps}
  
  - name: validation
    agent: requirements-validator
    depends_on: security-audit
    input:
      task_id: ${task_id}
      task_definition: ${task_definition}
      all_work: ${all_previous_outputs}
      iteration: ${iteration}
    output_var: validation_result
  
  - name: handle-validation-result
    action: conditional
    condition: ${validation_result.result}
    branches:
      PASS:
        - action: return
          status: complete
          data: ${validation_result}
      
      FAIL:
        - action: check_iteration_limit
          max: 10
          current: ${iteration}
          on_exceeded:
            action: return
            status: failed
            reason: "Max iterations exceeded"
        
        - action: restart_workflow
          workflow: fullstack-feature
          parameters:
            task_id: ${task_id}
            task_definition: ${task_definition}
            tech_stack: ${tech_stack}
            iteration: ${iteration + 1}
            validation_gaps: ${validation_result.recommended_agents}
```

### 6. Backend-Only Workflow

**File:** `.claude/workflows/backend-only.yaml`

```yaml
name: backend-only
description: Backend and database changes only
trigger: internal
invoked_by: task-orchestrator

parameters:
  - name: task_id
  - name: task_definition
  - name: tech_stack
  - name: iteration
    default: 1

steps:
  - name: database-design
    agent: database-designer
  
  - name: database-implementation
    agent: database-developer-${tech_stack.backend.language}-${tier}
    tier_selection:
      iteration_1: t1
      iteration_2: t1
      iteration_3_plus: t2
  
  - name: api-design
    agent: api-designer
  
  - name: api-implementation
    agent: api-developer-${tech_stack.backend.language}-${tier}
    tier_selection:
      iteration_1: t1
      iteration_2: t1
      iteration_3_plus: t2
  
  - name: test-writing
    agent: test-writer
  
  - name: backend-review
    agent: backend-code-reviewer-${tech_stack.backend.language}
  
  - name: security-audit
    agent: security-auditor
  
  - name: validation
    agent: requirements-validator
  
  - name: handle-validation
    # Same validation loop as fullstack
```

### 7. Frontend-Only Workflow

**File:** `.claude/workflows/frontend-only.yaml`

```yaml
name: frontend-only
description: Frontend UI changes only
trigger: internal
invoked_by: task-orchestrator

parameters:
  - name: task_id
  - name: task_definition
  - name: iteration
    default: 1

steps:
  - name: frontend-design
    agent: frontend-designer
  
  - name: frontend-implementation
    agent: frontend-developer-${tier}
    tier_selection:
      iteration_1: t1
      iteration_2: t1
      iteration_3_plus: t2
  
  - name: test-writing
    agent: test-writer
  
  - name: frontend-review
    agent: frontend-code-reviewer
  
  - name: validation
    agent: requirements-validator
  
  - name: handle-validation
    # Same validation loop
```

### 8. Generic Python Development Workflow

**File:** `.claude/workflows/generic-python-development.yaml`

```yaml
name: generic-python-development
description: Non-backend Python development (utilities, scripts, CLI tools, algorithms)
trigger: internal
invoked_by: task-orchestrator

parameters:
  - name: task_id
  - name: task_definition
  - name: iteration
    default: 1
  - name: validation_gaps
    default: null

steps:
  - name: implement
    agent: python-developer-generic-${tier}
    action: implement_code
    input:
      task: ${task_definition}
      requirements: ${task_definition.technical_requirements}
    output: "src/utils/" or "src/scripts/" or "src/cli/" or "src/lib/"
    
    tier_selection:
      iteration_1: t1
      iteration_2: t1
      iteration_3_plus: t2

  - name: test
    agent: test-writer
    action: write_python_tests
    input:
      code: ${implementation_output}
      task: ${task_definition}
    output: "tests/"

  - name: security_audit
    agent: security-auditor
    action: audit_python
    input:
      code: ${implementation_output}
      task: ${task_definition}
    output: "docs/security/${task_id}-audit.md"

  - name: documentation
    agent: documentation-coordinator
    action: document_python
    input:
      code: ${implementation_output}
      task: ${task_definition}
    output: "docs/python/"

  - name: validation
    agent: requirements-validator
    input:
      task_id: ${task_id}
      task_definition: ${task_definition}
      all_work: ${all_previous_outputs}
      iteration: ${iteration}
    output_var: validation_result

  - name: handle-validation-result
    action: conditional
    condition: ${validation_result.result}
    branches:
      PASS:
        - action: return
          status: complete
      
      FAIL:
        - action: check_iteration_limit
          max: 10
          current: ${iteration}
          on_exceeded:
            action: return
            status: failed
        
        - action: restart_workflow
          workflow: generic-python-development
          parameters:
            task_id: ${task_id}
            task_definition: ${task_definition}
            iteration: ${iteration + 1}
            validation_gaps: ${validation_result.recommended_agents}

output:
  artifacts:
    python_implementation: "src/"
    tests: "tests/"
    security_audit: "docs/security/"
    documentation: "docs/python/"
```

---

## Example Usage

### Complete Development Flow

```bash
# 1. Initialize project
cd my-new-project
git init

# 2. Set up multi-agent system
# (Give SETUP.md to Claude Code)

# 3. Create PRD interactively
/prd generate

# PRD Generator asks:
> What integrations do you need?
User: "TensorFlow for ML predictions, Stripe for payments"

> Recommendation: Python + FastAPI backend
> Proceed? [Y/n]
User: Y

# ... more Q&A ...

# PRD saved to docs/planning/PROJECT_PRD.yaml

# 4. Generate tasks and sprints
/planning analyze
# Creates TASK-001.yaml, TASK-002.yaml, etc.

/planning sprints  
# Creates SPRINT-001.yaml, SPRINT-002.yaml, etc.

# 5. Execute first sprint
/sprint execute SPRINT-001

# Sprint Orchestrator starts:
# [10:00] Starting SPRINT-001: Authentication & Core Features
# [10:01] TASK-001 started (fullstack: auth system)
# [10:05]   database-designer complete
# [10:12]   database-developer-python-t1 complete
# [10:15]   api-designer complete
# [10:25]   api-developer-python-t1 complete
# [10:30]   frontend-designer complete
# [10:45]   frontend-developer-t1 complete
# [10:50]   test-writer complete
# [10:55]   backend-code-reviewer complete
# [11:00]   frontend-code-reviewer complete
# [11:05]   security-auditor complete
# [11:10]   requirements-validator: FAIL
#           Gap: Error handling incomplete
# [11:15]   frontend-developer-t1 (iteration 2) - fixing gaps
# [11:25]   test-writer (iteration 2)
# [11:30]   requirements-validator: FAIL
#           Gap: Complex edge case in auth flow
# [11:35]   frontend-developer-t2 (iteration 3) - T2 takes over
# [11:50]   requirements-validator: PASS ✓
# [11:51] TASK-001 complete (3 iterations, 1.85 hours, T1→T2 switch)
#
# [11:51] TASK-002 started (python-generic: data processing utility)
# ...

# 6. Sprint completes
# Sprint SPRINT-001 complete!
# Duration: 2 days (estimated: 5 days)
# All 5 tasks validated and approved
# T1→T2 switches: 2 tasks
#
# Report: docs/sprints/SPRINT-001-completion.md

# 7. Continue with next sprint
/sprint execute SPRINT-002
```

### Task Status Checking

```bash
# Check sprint status
/sprint status SPRINT-001

# Output:
Sprint: SPRINT-001 - Authentication & Core
Status: In Progress (40% complete)

Tasks:
  ✓ TASK-001: Auth System (3 iterations, T1→T2, complete)
  ⟳ TASK-002: User Profiles (iteration 1, T1, frontend-developer)
  ⏸ TASK-003: Password Reset (waiting on TASK-002)
  ⏸ TASK-004: Email Verification (waiting on TASK-001)
  ⏸ TASK-005: Admin Dashboard (waiting on TASK-002)

Current: Working on TASK-002 user profile UI
Bottleneck: None
ETA: Tomorrow 3pm
```

---

## System Benefits

### For Developers

1. **Zero Context Switching:** Orchestrators handle agent coordination
2. **Quality Guaranteed:** Nothing ships without validation
3. **Stack Flexibility:** Choose Python or TypeScript based on needs
4. **Cost Optimized:** T1 (Haiku) for straightforward work, T2 (Sonnet) for complex
5. **Comprehensive Testing:** Automated test generation and validation

### For Project Management

1. **Predictable Execution:** Sprints run automatically start to finish
2. **Real-time Visibility:** Track progress at sprint and task level
3. **Quality Metrics:** Coverage, iterations, validation status, T1/T2 ratios
4. **Dependency Handling:** System respects task dependencies automatically
5. **Complete Documentation:** Auto-generated at every level

### For Code Quality

1. **Iterative Refinement:** Validation loops ensure excellence
2. **Specialized Review:** Language-specific code reviewers
3. **Security Built-in:** Every task gets security audit
4. **Test Coverage:** 80%+ coverage enforced
5. **Best Practices:** Each agent follows framework conventions
6. **Quality Escalation:** T2 agents handle complex scenarios

---

## Next Steps

After setup:

1. **Read AGENTS.md** for complete agent specifications
2. **Read USAGE.md** for detailed command reference
3. **Read WORKFLOWS.md** for process documentation
4. **Start your first project** with `/prd generate`

---

## Support

- **Documentation:** See README.md in repository
- **Agent Details:** See AGENTS.md
- **Usage Reference:** See USAGE.md
- **Workflow Details:** See WORKFLOWS.md

---

**System ready for initialization. Give this document to Claude Code to set up your multi-agent development environment.**
