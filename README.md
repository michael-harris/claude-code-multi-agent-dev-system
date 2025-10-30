# Multi-Agent Development System

A comprehensive Claude Code plugin providing 27 specialized AI agents with hierarchical orchestration, T1/T2 cost optimization, and full-stack development coverage.

## Features

### 27 Specialized Agents

**Planning Agents (3)**
- **PRD Generator** - Interactive PRD creation with technology stack selection
- **Task Graph Analyzer** - Breaks PRD into tasks with dependency analysis
- **Sprint Planner** - Organizes tasks into executable sprints

**Orchestration Agents (3)**
- **Sprint Orchestrator** - Manages entire sprint execution (Opus)
- **Task Orchestrator** - Coordinates single task with T1/T2 escalation (Sonnet)
- **Requirements Validator** - Quality gate ensuring 100% criteria satisfaction (Opus)

**Database Agents (5)**
- **Database Designer** - Schema design and normalization (Opus)
- **Database Developer Python T1/T2** - SQLAlchemy + Alembic (Haiku/Sonnet)
- **Database Developer TypeScript T1/T2** - Prisma/TypeORM (Haiku/Sonnet)

**Backend Agents (7)**
- **API Designer** - RESTful API specifications with OpenAPI (Opus)
- **API Developer Python T1/T2** - FastAPI/Django endpoints (Haiku/Sonnet)
- **API Developer TypeScript T1/T2** - Express/NestJS endpoints (Haiku/Sonnet)
- **Backend Code Reviewer** - Python and TypeScript variants (Sonnet)

**Frontend Agents (4)**
- **Frontend Designer** - UI/UX component specifications (Opus)
- **Frontend Developer T1/T2** - React/Vue implementation (Haiku/Sonnet)
- **Frontend Code Reviewer** - Accessibility and performance (Sonnet)

**Python Agents (2)**
- **Python Developer Generic T1/T2** - CLI tools, scripts, utilities (Haiku/Sonnet)

**Quality Agents (3)**
- **Test Writer** - Unit, integration, and e2e tests (Sonnet)
- **Security Auditor** - OWASP Top 10 compliance (Opus)
- **Documentation Coordinator** - Technical documentation (Sonnet)

### Cost Optimization (T1/T2 System)

**T1 Tier (Haiku)** - Cost-optimized first attempt
- Handles 70-80% of implementation work
- $0.001 per 1K tokens
- Automatic escalation on failure

**T2 Tier (Sonnet)** - Enhanced quality
- Handles complex scenarios after T1 validation fails
- 15-20% of work requiring deeper analysis
- $0.003 per 1K tokens

**Design Tier (Opus)** - High-value decisions
- Schema design, API contracts, component architecture
- Critical quality gates and security audits
- 10% of work requiring architectural thinking
- $0.015 per 1K tokens

**Result: 60-70% cost savings vs all-Opus approach while maintaining quality**

### Quality Gates

- **100% Criteria Satisfaction** - Requirements validator enforces acceptance criteria
- **Security First** - OWASP Top 10 audits on all implementations
- **80%+ Test Coverage** - Enforced by test writer agent
- **Code Review** - Language-specific reviewers for every implementation
- **Iterative Refinement** - Max 5 iterations with T1→T2 escalation

### Technology Stack Support

**Backend Options:**
- **Python**: FastAPI or Django + SQLAlchemy + pytest
- **TypeScript**: Express/NestJS + Prisma/TypeORM + Jest

**Frontend:**
- React or Next.js (TypeScript) + Tailwind CSS

**Database:**
- PostgreSQL (primary)

**Stack Selection:**
- Determined during PRD generation based on project requirements
- Python recommended for ML/data science/heavy processing
- TypeScript recommended for full-stack JS teams

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
/prd
# Interactive interview to create comprehensive PRD
# Output: docs/planning/PROJECT_PRD.yaml

# 2. Create tasks and sprints
/planning
# Breaks PRD into tasks with dependencies
# Organizes tasks into sprints
# Output: docs/planning/tasks/TASK-*.yaml
#         docs/sprints/SPRINT-*.yaml

# 3. Execute sprint
/sprint SPRINT-001
# Automated execution with quality loops
# T1 attempts first, escalates to T2 if needed
# Requirements validator ensures 100% criteria met
```

### Individual Agent Usage

```javascript
// Design database schema
Task(
  subagent_type="multi-agent-dev-system:database:designer",
  model="opus",
  prompt="Design schema for user authentication with roles and permissions"
)

// Implement schema (T1 attempt)
Task(
  subagent_type="multi-agent-dev-system:database:developer-python-t1",
  model="haiku",
  prompt="Implement the schema design from docs/api/database-schema.yaml using SQLAlchemy"
)

// If T1 fails validation, escalate to T2
Task(
  subagent_type="multi-agent-dev-system:database:developer-python-t2",
  model="sonnet",
  prompt="Fix the implementation issues identified by the validator"
)

// Design API
Task(
  subagent_type="multi-agent-dev-system:backend:api-designer",
  model="opus",
  prompt="Design REST API for user management"
)

// Security audit
Task(
  subagent_type="multi-agent-dev-system:quality:security-auditor",
  model="opus",
  prompt="Audit the authentication implementation for OWASP Top 10 vulnerabilities"
)
```

## Architecture

### Hierarchical Orchestration

```
User → /prd, /planning, /sprint commands
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

Every task passes through:
1. **Code Reviewers** - Language-specific quality checks
2. **Security Auditor** - OWASP Top 10 compliance
3. **Test Writer** - 80%+ coverage requirement
4. **Requirements Validator** - Binary pass/fail on acceptance criteria

**No task completes without 100% criteria satisfaction**

## Model Distribution

| Model | Count | Use Cases | Cost/1K Tokens |
|-------|-------|-----------|----------------|
| **Opus** | 6 | Design decisions, quality gates, security | $0.015 |
| **Sonnet** | 15 | T2 developers, reviewers, orchestration | $0.003 |
| **Haiku** | 6 | T1 developers (first attempt) | $0.001 |

**Cost Optimization Logic:**
1. T1 (Haiku) attempts implementation first (70-80% success rate)
2. T2 (Sonnet) handles complex cases after T1 failure (15-20% of work)
3. Opus only for critical design decisions and quality gates (10% of work)

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

## Agent Reference

### Planning
- `planning:prd-generator` (Sonnet)
- `planning:task-graph-analyzer` (Sonnet)
- `planning:sprint-planner` (Sonnet)

### Orchestration
- `orchestration:sprint-orchestrator` (Opus)
- `orchestration:task-orchestrator` (Sonnet)
- `orchestration:requirements-validator` (Opus)

### Database
- `database:designer` (Opus)
- `database:developer-python-t1` (Haiku)
- `database:developer-python-t2` (Sonnet)
- `database:developer-typescript-t1` (Haiku)
- `database:developer-typescript-t2` (Sonnet)

### Backend
- `backend:api-designer` (Opus)
- `backend:api-developer-python-t1` (Haiku)
- `backend:api-developer-python-t2` (Sonnet)
- `backend:api-developer-typescript-t1` (Haiku)
- `backend:api-developer-typescript-t2` (Sonnet)
- `backend:code-reviewer-python` (Sonnet)
- `backend:code-reviewer-typescript` (Sonnet)

### Frontend
- `frontend:designer` (Opus)
- `frontend:developer-t1` (Haiku)
- `frontend:developer-t2` (Sonnet)
- `frontend:code-reviewer` (Sonnet)

### Python
- `python:developer-generic-t1` (Haiku)
- `python:developer-generic-t2` (Sonnet)

### Quality
- `quality:test-writer` (Sonnet)
- `quality:security-auditor` (Opus)
- `quality:documentation-coordinator` (Sonnet)

## Repository Structure

```
claude-code-multi-agent-dev-system/
├── plugin.json              # Plugin manifest (27 agents, 3 commands)
├── README.md                # This file
├── LICENSE                  # MIT License
├── install-local.sh         # Local installation script
├── agents/                  # 27 agent definitions
│   ├── planning/           # PRD, task analysis, sprint planning (3)
│   ├── orchestration/      # Sprint/task orchestration, validation (3)
│   ├── database/           # Schema design + implementation (5)
│   ├── backend/            # API design + implementation + review (7)
│   ├── frontend/           # UI design + implementation + review (4)
│   ├── python/             # Generic Python development (2)
│   └── quality/            # Testing, security, documentation (3)
├── commands/               # 3 workflow commands
│   ├── prd.md             # Generate PRD
│   ├── planning.md        # Create tasks and sprints
│   └── sprint.md          # Execute sprint
├── examples/              # Usage examples
│   ├── complete-workflow-example.md
│   └── individual-agent-usage.md
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
- **Manual Development**: 40-60 hours × $150/hour = $6,000-9,000
- **AI-Assisted Build**: ~2 hours × $0.50/hour = $1
- **Savings**: 99.98%

### Using the Plugin (Per Project)
- **Small project (1 sprint)**: ~$0.70
- **Medium project (3 sprints)**: ~$6-8
- **Large project (10 sprints)**: ~$25-30

**Compared to:**
- Human developers: 99%+ savings
- All-Opus AI: 60-70% savings

## Contributing

Contributions are welcome! Please feel free to submit issues or pull requests.

## License

MIT License - See LICENSE file for details.

## Development History

This plugin was developed through an iterative AI-assisted process. Development history and architectural decisions are archived in `docs/development/` for reference.

## Support

- **Issues**: https://github.com/michael-harris/claude-code-multi-agent-dev-system/issues
- **Documentation**: See `examples/` directory
- **Installation Help**: See installation section above

---

**Built with Claude Code** - Demonstrating the power of multi-agent AI development systems.
