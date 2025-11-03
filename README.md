# Multi-Agent Development System

A Claude Code plugin providing **75 specialized AI agents** with hierarchical orchestration, T1/T2 cost optimization, runtime verification, and comprehensive support for **7 programming languages** across **10+ technology stacks**. Built for full-stack, multi-language development with progress tracking, parallel development capabilities, and automated runtime testing.

---

### 75 Specialized Agents

**Planning Agents (3)**
- **PRD Generator** - Interactive PRD creation with technology stack selection
- **Task Graph Analyzer** - Breaks PRD into tasks with dependency analysis
- **Sprint Planner** - Organizes tasks into executable sprints

**Orchestration Agents (4)**
- **Sprint Orchestrator** - Manages entire sprint execution with runtime verification (Sonnet)
- **Task Orchestrator** - Coordinates single task with T1/T2 escalation (Sonnet)
- **Requirements Validator** - Quality gate ensuring 100% criteria satisfaction and runtime checks (Sonnet)
- **Track Merger** - Intelligently merges parallel development tracks using git worktrees (Sonnet)

**Database Agents (15)** - *Expanded 3x for multi-language support*
- **Database Designer** - Schema design and normalization (Sonnet)
- **Database Developer Python T1/T2** - SQLAlchemy + Alembic (Haiku/Sonnet)
- **Database Developer TypeScript T1/T2** - Prisma/TypeORM (Haiku/Sonnet)
- **Database Developer Java T1/T2** - JPA/Hibernate + Flyway (Haiku/Sonnet)
- **Database Developer C# T1/T2** - Entity Framework Core + migrations (Haiku/Sonnet)
- **Database Developer Go T1/T2** - GORM + migrate (Haiku/Sonnet)
- **Database Developer Ruby T1/T2** - ActiveRecord + migrations (Haiku/Sonnet)
- **Database Developer PHP T1/T2** - Eloquent/Doctrine + migrations (Haiku/Sonnet)

**Backend Agents (22)** - *Expanded 3x for enterprise stacks*
- **API Designer** - RESTful API specifications with OpenAPI (Sonnet)
- **API Developer Python T1/T2** - FastAPI/Django/Flask endpoints (Haiku/Sonnet)
- **API Developer TypeScript T1/T2** - Express/NestJS/Fastify endpoints (Haiku/Sonnet)
- **API Developer Java T1/T2** - Spring Boot/Micronaut endpoints (Haiku/Sonnet)
- **API Developer C# T1/T2** - ASP.NET Core/Minimal API endpoints (Haiku/Sonnet)
- **API Developer Go T1/T2** - Gin/Echo/Fiber endpoints (Haiku/Sonnet)
- **API Developer Ruby T1/T2** - Rails/Sinatra/Grape endpoints (Haiku/Sonnet)
- **API Developer PHP T1/T2** - Laravel/Symfony/Slim endpoints (Haiku/Sonnet)
- **Backend Code Reviewers** - Python, TypeScript, Java, C#, Go, Ruby, PHP variants (Sonnet)

**Frontend Agents (4)**
- **Frontend Designer** - UI/UX component specifications (Sonnet)
- **Frontend Developer T1/T2** - React/Vue/Next.js/Angular implementation (Haiku/Sonnet)
- **Frontend Code Reviewer** - Accessibility, performance, best practices (Sonnet)

**Python Agents (2)**
- **Python Developer Generic T1/T2** - CLI tools, scripts, utilities (Haiku/Sonnet)

**Quality Agents (11)** - *Comprehensive quality assurance and runtime verification*
- **Test Writer** - Unit, integration, and e2e tests (Sonnet)
- **Security Auditor** - OWASP Top 10 compliance (Sonnet)
- **Documentation Coordinator** - Technical documentation (Sonnet)
- **Runtime Verifier** - Application launch verification and manual testing documentation (Sonnet)
- **Performance Auditor Python** - Python-specific performance optimization (Sonnet)
- **Performance Auditor TypeScript** - TypeScript/Node.js performance optimization (Sonnet)
- **Performance Auditor Java** - Java/Spring Boot performance optimization (Sonnet)
- **Performance Auditor C#** - .NET performance optimization (Sonnet)
- **Performance Auditor Go** - Go performance optimization (Sonnet)
- **Performance Auditor Ruby** - Ruby/Rails performance optimization (Sonnet)
- **Performance Auditor PHP** - PHP/Laravel performance optimization (Sonnet)

**Scripting Agents (4)** - *NEW*
- **PowerShell Developer T1/T2** - Windows automation, Azure, DSC (Haiku/Sonnet)
- **Shell Developer T1/T2** - Bash/Zsh automation scripts (Haiku/Sonnet)

**DevOps Agents (4)** - *NEW*
- **Docker Specialist** - Containerization, multi-stage builds, optimization (Sonnet)
- **Kubernetes Specialist** - K8s manifests, Helm, operators (Sonnet)
- **CI/CD Specialist** - GitHub Actions, GitLab CI, Jenkins (Sonnet)
- **Terraform Specialist** - Infrastructure as Code for AWS/Azure/GCP (Sonnet)

**Infrastructure Agents (2)** - *NEW*
- **Configuration Manager T1/T2** - Config files, secrets, env management (Haiku/Sonnet)

**Mobile Agents (4)** - *NEW*
- **iOS Developer T1/T2** - SwiftUI, UIKit, native iOS development (Haiku/Sonnet)
- **Android Developer T1/T2** - Kotlin, Jetpack Compose, native Android (Haiku/Sonnet)

### Cost Optimization (T1/T2 System)

**T1 Tier (Haiku)** - Cost-optimized first attempt
- Handles 70-80% of implementation work
- $0.001 per 1K tokens
- Automatic escalation on failure

**T2 Tier (Sonnet)** - Enhanced quality
- Handles complex scenarios after T1 validation fails
- 15-20% of work requiring deeper analysis
- $0.003 per 1K tokens

**Result: Significant cost optimization through intelligent model selection**

### Quality Gates

- **100% Criteria Satisfaction** - Requirements validator enforces acceptance criteria
- **Runtime Verification** - Applications must launch without errors before completion
- **Automated Testing** - All tests must pass (100% pass rate required)
- **Security First** - OWASP Top 10 audits on all implementations
- **80%+ Test Coverage** - Enforced by test writer agent
- **Code Review** - Language-specific reviewers for every implementation
- **Manual Testing Documentation** - Comprehensive testing guides for human verification
- **Iterative Refinement** - Max 5 iterations with T1→T2 escalation

### Supported Languages & Frameworks

This system now provides development coverage across **7 major programming languages** and **10+ development stacks**:

| Language | Frameworks | ORM/Database | Testing | Code Review |
|----------|-----------|--------------|---------|-------------|
| **Python** | FastAPI, Django, Flask | SQLAlchemy, Alembic | pytest, unittest | ✅ Sonnet |
| **TypeScript** | Express, NestJS, Fastify | Prisma, TypeORM | Jest, Vitest | ✅ Sonnet |
| **Java** | Spring Boot, Micronaut | JPA/Hibernate, Flyway | JUnit, TestNG | ✅ Sonnet |
| **C#** | ASP.NET Core, Minimal API | Entity Framework Core | xUnit, NUnit | ✅ Sonnet |
| **Go** | Gin, Echo, Fiber | GORM, migrate | testing, testify | ✅ Sonnet |
| **Ruby** | Rails, Sinatra, Grape | ActiveRecord | RSpec, minitest | ✅ Sonnet |
| **PHP** | Laravel, Symfony, Slim | Eloquent, Doctrine | PHPUnit, Pest | ✅ Sonnet |

**Frontend:**
- React, Vue.js, Next.js, Angular (TypeScript)
- Tailwind CSS, Material-UI, shadcn/ui
- Vite, webpack, turbopack

**Mobile:**
- **iOS**: SwiftUI, UIKit, Combine
- **Android**: Kotlin, Jetpack Compose, Coroutines

**Database:**
- PostgreSQL (primary), MySQL, SQLite, MongoDB

**DevOps & Infrastructure:**
- Docker, docker-compose, Kubernetes
- GitHub Actions, GitLab CI, Jenkins
- Terraform (AWS, Azure, GCP)
- PowerShell, Bash/Zsh scripting
- Configuration management (env, YAML, JSON, secrets)

### Development Stacks Supported

**Full-Stack Web Applications:**
1. **MEAN/MERN Stack** - MongoDB/Express/Angular or React/Node.js
2. **Python Stack** - FastAPI/Django + PostgreSQL + React
3. **Java Enterprise** - Spring Boot + PostgreSQL + Angular
4. **C# .NET Stack** - ASP.NET Core + SQL Server + React
5. **Go Stack** - Gin/Echo + PostgreSQL + Vue
6. **Ruby Stack** - Rails + PostgreSQL + React
7. **PHP Stack** - Laravel + MySQL + Vue

**Mobile Applications:**
8. **iOS Native** - SwiftUI + CoreData + REST APIs
9. **Android Native** - Kotlin + Room + Retrofit

**DevOps & Infrastructure:**
10. **Cloud Infrastructure** - Terraform + Docker + CI/CD
11. **Microservices** - Any language + Docker + Kubernetes config

**Scripting & Automation:**
12. **System Administration** - Bash/Python scripts + Terraform
13. **Data Processing** - Python + pandas + NumPy

### New Capabilities

**DevOps Integration**
- Containerization with Docker specialist (multi-stage builds, optimization)
- Kubernetes orchestration specialist (Helm charts, operators, manifests)
- CI/CD pipeline specialist for GitHub Actions, GitLab CI, Jenkins
- Infrastructure as Code with Terraform specialist for AWS, Azure, GCP
- Automated deployment workflows

**Mobile Development**
- Native iOS development with SwiftUI and UIKit
- Native Android development with Kotlin and Jetpack Compose
- RESTful API integration and local data persistence
- Platform-specific UI/UX best practices

**Scripting & Automation**
- PowerShell for Windows automation and Azure management
- Shell scripting for Linux/Unix system automation (Bash/Zsh)
- Configuration management for env files, YAML, JSON, secrets
- Build automation and deployment scripts
- Database migration and backup scripts

**Enterprise Language Support**
- Java enterprise applications with Spring Boot ecosystem
- C# .NET Core applications for Windows/Linux/macOS
- Go microservices with high-performance frameworks
- Ruby web applications with Rails conventions
- PHP applications with Laravel/Symfony frameworks

## Installation

### From GitHub (Recommended)

```bash
/plugin marketplace add https://github.com/michael-harris/claude-code-multi-agent-dev-system
/plugin install multi-agent-dev-system
```

### From Local Path (Development)

```bash
# Clone the repository
git clone https://github.com/michael-harris/claude-code-multi-agent-dev-system.git
cd claude-code-multi-agent-dev-system

# Install locally
./install-local.sh

# OR manually
/plugin marketplace add file:///absolute/path/to/claude-code-multi-agent-dev-system
/plugin install multi-agent-dev-system
```

### Verify Installation

```bash
/plugin list
# Should show: multi-agent-dev-system
```

## Quick Start

### Full Workflow

```bash
# 1. Generate PRD
/multi-agent:prd
# Interactive interview to create comprehensive PRD
# Output: docs/planning/PROJECT_PRD.yaml

# 2. Create tasks and sprints
/multi-agent:planning
# Breaks PRD into tasks with dependencies
# Organizes tasks into sprints
# Output: docs/planning/tasks/TASK-*.yaml
#         docs/sprints/SPRINT-*.yaml

# 3. Execute sprint
/multi-agent:sprint SPRINT-001
# Automated execution with quality loops
# T1 attempts first, escalates to T2 if needed
# Runtime verification ensures app launches without errors
# All automated tests must pass (100% pass rate)
# Manual testing guide generated for human verification
# Requirements validator ensures 100% criteria met
```

### Individual Agent Usage

```javascript
// Design database schema
Task(
  subagent_type="multi-agent:database:designer",
  model="opus",
  prompt="Design schema for user authentication with roles and permissions"
)

// Implement schema (T1 attempt)
Task(
  subagent_type="multi-agent:database:developer-python-t1",
  model="haiku",
  prompt="Implement the schema design from docs/api/database-schema.yaml using SQLAlchemy"
)

// If T1 fails validation, escalate to T2
Task(
  subagent_type="multi-agent:database:developer-python-t2",
  model="sonnet",
  prompt="Fix the implementation issues identified by the validator"
)

// Design API
Task(
  subagent_type="multi-agent:backend:api-designer",
  model="opus",
  prompt="Design REST API for user management"
)

// Security audit
Task(
  subagent_type="multi-agent:quality:security-auditor",
  model="opus",
  prompt="Audit the authentication implementation for OWASP Top 10 vulnerabilities"
)
```

## Progress Tracking & Parallel Development

### Progress Tracking (Resume Functionality)

All planning and execution workflows now include automatic progress tracking via state files:

**State Files:**
- Projects: `docs/planning/.project-state.yaml`
- Features: `docs/planning/.feature-{id}-state.yaml`
- Issues: `docs/planning/.issue-{id}-state.yaml`

**Resume Capabilities:**
- System tracks completion status of all tasks and sprints
- Automatically skips completed work when resuming
- Resume from any interruption point (system crash, manual stop, etc.)
- State files provide detailed audit trail of development progress

**Example:**
```bash
# Start sprint execution
/multi-agent:sprint all

# ... system interrupted at SPRINT-003 ...

# Resume from where you left off
/multi-agent:sprint all
# System: "Resuming from SPRINT-003 (SPRINT-001, SPRINT-002 already complete)"
```

### Parallel Development Tracks

Enable parallel development across independent task chains to dramatically reduce development time:

**Single Track (Default):**
```bash
/multi-agent:planning           # Creates sprints: SPRINT-001, SPRINT-002, SPRINT-003
/multi-agent:sprint all         # Sequential execution: ~128 hours
```

**Parallel Tracks - State-Only Mode:**
```bash
/multi-agent:planning 3         # Creates parallel tracks: SPRINT-001-01, SPRINT-001-02, SPRINT-001-03
                                # System calculates max possible tracks from dependencies
                                # Logical separation via state files

# Execute all tracks in parallel (different terminals/sessions):
/multi-agent:sprint all 01      # Terminal 1: Track 1 (~42 hours)
/multi-agent:sprint all 02      # Terminal 2: Track 2 (~48 hours)
/multi-agent:sprint all 03      # Terminal 3: Track 3 (~38 hours)

# Result: ~48 hours (62% faster than sequential)
```

**Parallel Tracks - Git Worktrees Mode (NEW):**
```bash
/multi-agent:planning 3 --use-worktrees
# Creates isolated git worktrees for true physical separation:
#  - .multi-agent/track-01/ (branch: dev-track-01)
#  - .multi-agent/track-02/ (branch: dev-track-02)
#  - .multi-agent/track-03/ (branch: dev-track-03)

# Each track works in its own directory - zero conflicts!
/multi-agent:sprint all 01      # Auto-switches to .multi-agent/track-01/
/multi-agent:sprint all 02      # Auto-switches to .multi-agent/track-02/
/multi-agent:sprint all 03      # Auto-switches to .multi-agent/track-03/

# After all tracks complete, merge them back:
/multi-agent:merge-tracks       # Intelligently merges all tracks, cleans up worktrees

# Expert commands (optional):
/multi-agent:worktree status    # Show detailed status of all worktrees
/multi-agent:worktree cleanup   # Manually clean up worktrees
```

**How It Works:**
1. **Task Graph Analyzer** calculates max parallel tracks from dependency analysis
2. **Sprint Planner** distributes tasks across tracks using balanced bin-packing algorithm
3. **Worktree Mode** (optional): Creates isolated git worktrees + branches for each track
4. **Track Merger** (worktrees only): Intelligently merges tracks back to main branch
5. Each track contains independent task chains that can execute simultaneously
6. If requested tracks > max possible, system uses max and warns user

**Benefits:**
- 50-70% reduction in wall-clock development time
- **State-Only Mode**: Simple, works in single directory, state files coordinate tracks
- **Worktree Mode**: True isolation, no file conflicts, git-native separation
- Ideal for projects with independent components (backend, frontend, infrastructure)
- State tracking enables resumption for any track independently
- Supports team collaboration (different tracks = different team members)

**Worktree Mode Advantages:**
- **Zero file conflicts** - each track in separate directory
- **Better git history** - separate branches with clear merge points
- **Safer parallel execution** - no risk of state file conflicts
- **Natural merge workflow** - git handles combining the work
- **Supports collaboration** - team members can work in isolated worktrees

### Development History Preservation

**Sprint and task files are intentionally preserved:**
- Provides complete development history and audit trail
- Shows decision-making process and evolution of requirements
- Valuable for debugging, rollback, and understanding context
- Can be manually removed if desired, but recommended to keep
- `.gitignore` can exclude state files (`.*.yaml`) if desired while keeping sprint definitions

## Architecture

### Hierarchical Orchestration

```
User → /multi-agent:prd, /multi-agent:planning, /multi-agent:sprint commands
   ↓
Sprint Orchestrator (Opus) - Manages entire sprint
   ↓
Task Orchestrator (Sonnet) - Coordinates single task with T1/T2 switching
   ↓
Specialized Agents (T1/T2) - Implement with automatic escalation
   ↓
Requirements Validator (Opus) - Quality gate (100% criteria met)
```

### T1→T2 Escalation Flow

```
Iteration 1: T1 agent (Haiku) attempts implementation
Iteration 2: T1 attempts fixes based on validator feedback
  → If PASS: Task complete ✅
  → If FAIL: Switch to T2 for iteration 3+

Iteration 3+: T2 agent (Sonnet) handles complexity

Max Iterations: 5 before human intervention required
```

### Quality Gate System

Every sprint passes through:
1. **Code Reviewers** - Language-specific quality checks
2. **Security Auditor** - OWASP Top 10 compliance
3. **Performance Auditors** - Language-specific optimization
4. **Runtime Verifier** - Application launch verification and testing
   - Builds and launches application (Docker or local)
   - Runs all automated tests (100% pass rate required)
   - Checks for runtime errors and exceptions
   - Documents manual testing procedures for humans
5. **Requirements Validator** - Binary pass/fail on acceptance criteria
6. **Test Writer** - 80%+ coverage requirement

**No sprint completes without 100% criteria satisfaction and successful runtime verification**

## Model Distribution

| Model | Count | Use Cases | Cost/1K Tokens |
|-------|-------|-----------|----------------|
| **Sonnet** | 53 | T2 developers, reviewers, orchestration, code review, performance auditing, runtime verification | $0.003 |
| **Haiku** | 22 | T1 developers (first attempt across all languages) | $0.001 |

**Total: 75 Agents**

**Note:** All agents now use Sonnet or Haiku for cost optimization. Previous Opus-only agents (orchestrators, designers, security auditor) have been migrated to Sonnet with maintained quality standards.

**Cost Optimization Logic:**
1. T1 (Haiku) attempts implementation first (70-80% success rate)
2. T2 (Sonnet) handles complex cases after T1 failure (15-20% of work)
3. Sonnet for design decisions, orchestration, and quality gates

**Multi-Language Scaling:**
- Each language gets T1/T2 developer pairs for database and backend work
- Language-specific code reviewers ensure quality standards
- Shared design agents (Sonnet) work across all languages
- Same cost optimization applies to Java, C#, Go, Ruby, PHP as Python/TypeScript

## Examples

### Example 1: Complete Workflow

See [examples/complete-workflow-example.md](examples/complete-workflow-example.md) for a detailed walkthrough of building a task management application from PRD to deployment.

### Example 2: Individual Agent Usage

See [examples/individual-agent-usage.md](examples/individual-agent-usage.md) for 10 targeted scenarios:
- Quick database schema design
- Implement database models from design
- API design review
- Implement API endpoint
- Security audit
- Generate tests for existing code
- Create frontend component
- Code review
- Create CLI tool
- Generate documentation

### Example 3: Multi-Language Projects

See [examples/multi-language-examples.md](examples/multi-language-examples.md) for examples demonstrating multi-language support:
- **Java Spring Boot** - Enterprise REST API with JPA
- **C# .NET Core** - Minimal API with Entity Framework
- **Go Microservice** - High-performance API with GORM
- **Ruby on Rails** - Convention-based web application
- **PHP Laravel** - Full-stack web application
- **iOS Swift** - Native mobile app with SwiftUI
- **Android Kotlin** - Native mobile app with Jetpack Compose
- **DevOps Pipeline** - Complete CI/CD with Docker and Terraform

### Example 4: Parallel Development Tracks

See [examples/parallel-tracks-example.md](examples/parallel-tracks-example.md) for a comprehensive walkthrough of using parallel development tracks to build an e-commerce platform with 50-70% reduction in wall-clock time.

## Agent Reference

Complete list of all 75 agents organized by category:

### Planning (3 agents)
- `planning:prd-generator` (Sonnet)
- `planning:task-graph-analyzer` (Sonnet)
- `planning:sprint-planner` (Sonnet)

### Orchestration (4 agents)
- `orchestration:sprint-orchestrator` (Sonnet)
- `orchestration:task-orchestrator` (Sonnet)
- `orchestration:requirements-validator` (Sonnet)
- `orchestration:track-merger` (Sonnet)

### Database (15 agents)
- `database:designer` (Sonnet)
- `database:developer-python-t1` (Haiku)
- `database:developer-python-t2` (Sonnet)
- `database:developer-typescript-t1` (Haiku)
- `database:developer-typescript-t2` (Sonnet)
- `database:developer-java-t1` (Haiku)
- `database:developer-java-t2` (Sonnet)
- `database:developer-csharp-t1` (Haiku)
- `database:developer-csharp-t2` (Sonnet)
- `database:developer-go-t1` (Haiku)
- `database:developer-go-t2` (Sonnet)
- `database:developer-ruby-t1` (Haiku)
- `database:developer-ruby-t2` (Sonnet)
- `database:developer-php-t1` (Haiku)
- `database:developer-php-t2` (Sonnet)

### Backend (22 agents)
- `backend:api-designer` (Sonnet)
- `backend:api-developer-python-t1` (Haiku)
- `backend:api-developer-python-t2` (Sonnet)
- `backend:api-developer-typescript-t1` (Haiku)
- `backend:api-developer-typescript-t2` (Sonnet)
- `backend:api-developer-java-t1` (Haiku)
- `backend:api-developer-java-t2` (Sonnet)
- `backend:api-developer-csharp-t1` (Haiku)
- `backend:api-developer-csharp-t2` (Sonnet)
- `backend:api-developer-go-t1` (Haiku)
- `backend:api-developer-go-t2` (Sonnet)
- `backend:api-developer-ruby-t1` (Haiku)
- `backend:api-developer-ruby-t2` (Sonnet)
- `backend:api-developer-php-t1` (Haiku)
- `backend:api-developer-php-t2` (Sonnet)
- `backend:code-reviewer-python` (Sonnet)
- `backend:code-reviewer-typescript` (Sonnet)
- `backend:code-reviewer-java` (Sonnet)
- `backend:code-reviewer-csharp` (Sonnet)
- `backend:code-reviewer-go` (Sonnet)
- `backend:code-reviewer-ruby` (Sonnet)
- `backend:code-reviewer-php` (Sonnet)

### Frontend (4 agents)
- `frontend:designer` (Sonnet)
- `frontend:developer-t1` (Haiku)
- `frontend:developer-t2` (Sonnet)
- `frontend:code-reviewer` (Sonnet)

### Python (2 agents)
- `python:developer-generic-t1` (Haiku)
- `python:developer-generic-t2` (Sonnet)

### Quality (11 agents)
- `quality:test-writer` (Sonnet)
- `quality:security-auditor` (Sonnet)
- `quality:documentation-coordinator` (Sonnet)
- `quality:runtime-verifier` (Sonnet)
- `quality:performance-auditor-python` (Sonnet)
- `quality:performance-auditor-typescript` (Sonnet)
- `quality:performance-auditor-java` (Sonnet)
- `quality:performance-auditor-csharp` (Sonnet)
- `quality:performance-auditor-go` (Sonnet)
- `quality:performance-auditor-ruby` (Sonnet)
- `quality:performance-auditor-php` (Sonnet)

### Scripting (4 agents) - NEW
- `scripting:powershell-developer-t1` (Haiku)
- `scripting:powershell-developer-t2` (Sonnet)
- `scripting:shell-developer-t1` (Haiku)
- `scripting:shell-developer-t2` (Sonnet)

### DevOps (4 agents) - NEW
- `devops:docker-specialist` (Sonnet)
- `devops:kubernetes-specialist` (Sonnet)
- `devops:cicd-specialist` (Sonnet)
- `devops:terraform-specialist` (Sonnet)

### Infrastructure (2 agents) - NEW
- `infrastructure:configuration-manager-t1` (Haiku)
- `infrastructure:configuration-manager-t2` (Sonnet)

### Mobile (4 agents) - NEW
- `mobile:ios-developer-t1` (Haiku)
- `mobile:ios-developer-t2` (Sonnet)
- `mobile:android-developer-t1` (Haiku)
- `mobile:android-developer-t2` (Sonnet)

## Repository Structure

```
claude-code-multi-agent-dev-system/
├── plugin.json              # Plugin manifest (75 agents, 6 commands)
├── README.md                # This file
├── LICENSE                  # MIT License
├── install-local.sh         # Local installation script
├── agents/                  # 75 agent definitions
│   ├── planning/           # PRD, task analysis, sprint planning (3)
│   ├── orchestration/      # Sprint/task orchestration, validation, track merging (4)
│   ├── database/           # Schema design + 7-language implementation (15)
│   │   ├── designer.md
│   │   ├── developer-python-t1.md
│   │   ├── developer-python-t2.md
│   │   ├── developer-typescript-t1.md
│   │   ├── developer-typescript-t2.md
│   │   ├── developer-java-t1.md
│   │   ├── developer-java-t2.md
│   │   ├── developer-csharp-t1.md
│   │   ├── developer-csharp-t2.md
│   │   ├── developer-go-t1.md
│   │   ├── developer-go-t2.md
│   │   ├── developer-ruby-t1.md
│   │   ├── developer-ruby-t2.md
│   │   ├── developer-php-t1.md
│   │   └── developer-php-t2.md
│   ├── backend/            # API design + 7-language implementation + review (22)
│   │   ├── api-designer.md
│   │   ├── api-developer-[language]-t1.md (7 languages)
│   │   ├── api-developer-[language]-t2.md (7 languages)
│   │   └── code-reviewer-[language].md (7 languages)
│   ├── frontend/           # UI design + implementation + review (4)
│   ├── python/             # Generic Python development (2)
│   ├── quality/            # Testing, security, documentation (3)
│   ├── scripting/          # PowerShell and Shell scripting (4) - NEW
│   │   ├── powershell-developer-t1.md
│   │   ├── powershell-developer-t2.md
│   │   ├── shell-developer-t1.md
│   │   └── shell-developer-t2.md
│   ├── devops/             # Docker, Kubernetes, CI/CD, Terraform (4) - NEW
│   │   ├── docker-specialist.md
│   │   ├── kubernetes-specialist.md
│   │   ├── cicd-specialist.md
│   │   └── terraform-specialist.md
│   ├── infrastructure/     # Configuration management (2) - NEW
│   │   ├── configuration-manager-t1.md
│   │   └── configuration-manager-t2.md
│   ├── quality/            # Testing, security, documentation, performance, runtime verification (11)
│   │   ├── test-writer.md
│   │   ├── security-auditor.md
│   │   ├── documentation-coordinator.md
│   │   ├── runtime-verifier.md
│   │   ├── performance-auditor-python.md
│   │   ├── performance-auditor-typescript.md
│   │   ├── performance-auditor-java.md
│   │   ├── performance-auditor-csharp.md
│   │   ├── performance-auditor-go.md
│   │   ├── performance-auditor-ruby.md
│   │   └── performance-auditor-php.md
│   └── mobile/             # iOS and Android (4) - NEW
│       ├── ios-developer-t1.md
│       ├── ios-developer-t2.md
│       ├── android-developer-t1.md
│       └── android-developer-t2.md
├── commands/               # 6 workflow commands
│   ├── prd.md             # Generate PRD
│   ├── planning.md        # Create tasks and sprints (with parallel tracks support)
│   ├── sprint.md          # Execute single sprint
│   ├── sprint-all.md      # Execute all sprints (with track filtering)
│   ├── feature.md         # Complete feature workflow (PRD → Planning → Implementation)
│   └── issue.md           # Complete issue resolution workflow
├── examples/              # Usage examples
│   ├── complete-workflow-example.md           # Full PRD-to-deployment walkthrough
│   ├── individual-agent-usage.md             # 10 targeted scenarios
│   ├── multi-language-examples.md            # Multi-language project examples
│   └── parallel-tracks-example.md            # Parallel development demonstration
└── docs/                  # Work directories and archives
    ├── development/       # Archived development history
    ├── adrs/              # Architecture Decision Records (generated)
    ├── api/               # API documentation (generated)
    ├── features/          # Feature specifications (generated)
    ├── planning/          # PRDs and tasks (generated)
    ├── reviews/           # Code reviews (generated)
    └── sprints/           # Sprint definitions (generated)
```

## Cost Analysis

### Plugin Development
- **Manual Development (75 agents)**: 250-350 hours × $150/hour = $37,500-52,500
- **AI-Assisted Build**: ~6 hours × $0.50/hour = $3.00
- **Savings**: 99.99%

### Using the Plugin (Per Project)

**Cost per sprint optimized with T1/T2 system:**
- T1/T2 system ensures only relevant language agents are used
- Most projects use 1-2 languages, not all 7
- Shared design agents (Sonnet) work across all languages

**Estimated project costs (using Sonnet/Haiku pricing):**
- **Small project (1 sprint, 1 language)**: ~$0.50-0.80
- **Medium project (3 sprints, 2 languages)**: ~$4-8
- **Large project (10 sprints, 3 languages)**: ~$20-35
- **Enterprise polyglot (20 sprints, 5+ languages)**: ~$60-100

**Multi-language example breakdown:**
- Database design (Sonnet): $0.30
- Database implementation Java (T1/T2): $0.25
- API design (Sonnet): $0.40
- API implementation Java (T1/T2): $0.35
- Frontend implementation (T1/T2): $0.40
- Runtime verification (Sonnet): $0.20
- Testing + Security (Sonnet): $0.50
- Code reviews (Sonnet): $0.25
- **Total per sprint**: ~$2.65

**Compared to:**
- Human developers: 99%+ savings
- Previous Opus-heavy approach: Significantly more cost-effective
- Single-language AI systems: Same cost, 7x language coverage

## Why This System?

### Multi-Language Development Support
- **7 Programming Languages**: Python, TypeScript, Java, C#, Go, Ruby, PHP
- **10+ Development Stacks**: From MEAN/MERN to Spring Boot to Rails
- **Consistent Quality**: Same T1/T2 optimization and quality gates across all languages
- **Language-Specific Expertise**: Dedicated code reviewers for each language

### Complete Development Lifecycle
- **Planning**: PRD generation, task breakdown, sprint planning
- **Implementation**: Database, backend, frontend, mobile
- **DevOps**: Containerization, CI/CD, infrastructure as code
- **Quality**: Security audits, testing, code review, documentation

### Additional Features
- **Mobile Development**: Native iOS (Swift) and Android (Kotlin)
- **DevOps Automation**: Docker, GitHub Actions, GitLab CI, Jenkins
- **Cloud Infrastructure**: Terraform for AWS, Azure, GCP
- **Scripting**: Shell and Python automation scripts

### Cost-Optimized Intelligence
- **75 Agents**: Specialized for every language and task
- **2-Tier System**: Haiku (fast/cheap) → Sonnet (balanced)
- **Smart Escalation**: T1 handles 70-80% of work, T2 only when needed
- **Significant Cost Savings**: Optimized model selection for each agent type

### Quality Without Compromise
- **100% Criteria Satisfaction**: Requirements validator enforces every acceptance criteria
- **Runtime Verification**: Applications must launch without errors
- **Automated Testing**: All tests must pass (100% pass rate required)
- **Security First**: OWASP Top 10 audits on all implementations
- **80%+ Test Coverage**: Automated test generation
- **Language-Specific Review**: Code reviewers for Python, TypeScript, Java, C#, Go, Ruby, PHP
- **Manual Testing Documentation**: Comprehensive guides for human verification

## Use Cases

**Greenfield Projects**
- Build full-stack applications from scratch in any supported language
- Generate PRD, design database and APIs, implement frontend/backend
- Deploy with Docker and CI/CD pipelines

**Multi-Language Enterprises**
- Microservices architecture with different languages per service
- Unified quality standards across Python, Java, Go, C# codebases
- Consistent code review and security practices

**Mobile + Backend**
- Native iOS/Android apps with backend APIs
- Choose optimal backend language (Python for ML, Go for performance, etc.)
- Automated API client generation and integration

**DevOps & Infrastructure**
- Containerize existing applications with Docker
- Create CI/CD pipelines for automated testing and deployment
- Provision cloud infrastructure with Terraform

**Legacy Modernization**
- Migrate from one language/framework to another
- Refactor monoliths to microservices
- Add tests and security audits to existing code

## Contributing

Contributions are welcome! Please feel free to submit issues or pull requests.

**Potential Contributions:**
- Additional language support (Rust, Scala, Kotlin backend, etc.)
- New agent categories (testing frameworks, monitoring, etc.)
- Language-specific example projects
- Performance optimizations and best practices

## License

MIT License - See LICENSE file for details.

## Development History

This plugin was developed through an iterative AI-assisted process. Development history and architectural decisions are archived in `docs/development/` for reference.

**Evolution:**
- **v1.0**: Initial release with 27 agents (Python/TypeScript only)
- **v2.0**: Expanded to 66 agents with 7 languages, mobile, DevOps, infrastructure
- **v2.1**: Expanded to 73 agents with language-specific performance auditing, progress tracking, and parallel development tracks
- **v2.3**: Added PR-based workflow, comprehensive sprint summaries, and git worktree support for parallel tracks
- **v2.4**: Added runtime verification with automated testing and manual testing documentation (75 agents total)

## Support

- **Issues**: https://github.com/michael-harris/claude-code-multi-agent-dev-system/issues
- **Documentation**: See `examples/` directory
- **Installation Help**: See installation section above
- **Feature Requests**: Open an issue with the `enhancement` label

## Frequently Asked Questions

**Q: Do I need to use all 75 agents?**
A: No. The system automatically selects relevant agents based on your project's language and requirements. Most projects use 10-15 agents.

**Q: Can I mix languages in one project?**
A: Yes. The system excels at polyglot projects. For example, Go backend + TypeScript frontend + Python ML services.

**Q: What if my language isn't supported?**
A: The generic Python agents can handle similar languages (like Ruby for scripts), or you can contribute new agents following the existing patterns.

**Q: How does cost optimization work across languages?**
A: All languages use the same T1/T2 system. Java, C#, Go, Ruby, PHP developers benefit from the same 60-70% cost savings as Python/TypeScript.

**Q: Can I use this for existing projects?**
A: Yes. You can use individual agents for specific tasks (add tests, create Dockerfile, generate API endpoints, etc.) without the full workflow.

**Q: What quality standards do the mobile agents follow?**
A: They follow the same quality standards as web development: code review, security audits, testing, and iterative refinement with T1/T2 escalation.

---

**Built with Claude Code** - Demonstrating multi-agent AI development systems.
