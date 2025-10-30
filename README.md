# Multi-Agent Full-Stack Development System

**Version:** 2.1 (Pragmatic Approach)
**Status:** Production Ready
**Architecture:** 27 Specialized Agents (T1/T2 Tiers) + Claude Code Orchestration

---

## What Is This?

A pragmatic multi-agent development system that takes you from idea to working code through Claude Code's orchestration:

**Phase 1: Planning** (Human-guided, 15-20 minutes)
- Interactive PRD generation with tech stack selection
- Claude-orchestrated task decomposition with dependency analysis
- Claude-orchestrated sprint organization with realistic timelines

**Phase 2: Execution** (Claude-orchestrated)
- You run slash commands (`/sprint SPRINT-001`)
- Claude manually orchestrates all specialized agents
- T1 developers (Haiku) implement first (cost-optimized)
- If validation fails twice, T2 developers (Sonnet) take over (enhanced quality)
- Claude tracks iterations and manages T1→T2 switching
- Requirements validation enforces quality gates
- Iterative loops until all criteria met

## Quick Start

```bash
# 1. System is already set up with agent definitions and commands

# 2. Create your plan
/prd                    # Interactive PRD generation
/planning               # Task and sprint planning

# 3. Execute with Claude orchestrating
/sprint SPRINT-001      # Claude coordinates all agents

# 4. Deploy your MVP
```

**Time from idea to MVP:** Days instead of weeks
**How it works:** Slash commands prompt Claude to orchestrate specialized agents

---

## System Architecture

### 27 Specialized Agents (T1/T2 Quality Tiers)

**Planning (3):**
- PRD Generator - Interactive requirements gathering
- Task Analyzer - Dependency-aware task breakdown
- Sprint Planner - Optimal sprint organization

**Orchestration (3):**
- Sprint Orchestrator - Manages entire sprint execution
- Task Orchestrator - Coordinates single task workflow
- Requirements Validator - Quality gate enforcement

**Database (6):**
- Designer - Schema design
- Developer Python T1/T2 - SQLAlchemy/Alembic (Haiku/Sonnet)
- Developer TypeScript T1/T2 - Prisma/TypeORM (Haiku/Sonnet)

**Backend API (9):**
- Designer - RESTful API specifications
- Developer Python T1/T2 - FastAPI/Django (Haiku/Sonnet)
- Developer TypeScript T1/T2 - Express/NestJS (Haiku/Sonnet)
- Code Reviewer Python - Python review
- Code Reviewer TypeScript - TypeScript review

**Frontend (4):**
- Designer - Component architecture
- Developer T1/T2 - React/Next.js (Haiku/Sonnet)
- Code Reviewer - Frontend review

**Generic Python (2):**
- Developer T1/T2 - Utilities, scripts, CLI tools (Haiku/Sonnet)

**Quality & Docs (3):**
- Test Writer - Comprehensive test generation
- Security Auditor - Security analysis
- Documentation Coordinator - Complete documentation

### 3 Slash Commands (Pragmatic Orchestration)

1. **/prd** - Interactive PRD generation (Claude conducts interview)
2. **/planning** - Task decomposition + sprint organization (Claude coordinates agents)
3. **/sprint SPRINT-ID** - Full sprint execution (Claude orchestrates all agents)

### 4 Tech Stack Templates

- **Python/FastAPI + React** - ML/Data Science projects
- **Python/Django + React** - Enterprise applications
- **TypeScript/Express + Next.js** - Full JavaScript teams
- **TypeScript/NestJS + Next.js** - Large-scale microservices

Stack selection happens during PRD generation based on integration requirements.

---

## How It Works

### Phase 1: Planning

```bash
/prd
```

Claude conducts interactive Q&A to create comprehensive PRD:
1. Asks about integrations and recommends tech stack
2. Gathers problem, solution, users, requirements
3. Defines success metrics and constraints
4. Generates structured PRD with all details

```bash
/planning
```

Claude orchestrates task decomposition and sprint planning:
1. Launches task-graph-analyzer agent to read PRD
2. Agent breaks PRD into discrete, implementable tasks
3. Agent analyzes dependencies between tasks
4. Agent generates task files with acceptance criteria and task types
5. Claude then launches sprint-planner agent
6. Agent groups tasks by dependencies and priorities
7. Agent creates sprint files with goals and timelines

**Result:** Complete development roadmap, no code yet.
**Process:** Claude manually coordinates planning agents using the Task tool.

### Phase 2: Execution

```bash
/sprint SPRINT-001
```

Claude manually orchestrates the entire sprint:
1. Claude reads sprint plan from `docs/sprints/SPRINT-001.yaml`
2. For each task in dependency order:
   - Claude reads task definition
   - Claude determines workflow type (fullstack/backend/frontend/python-generic)
   - Claude launches specialized agents in sequence using the Task tool:
     * T1 developers (Haiku) implement first (cost-optimized)
     * Database designer → database-developer-{lang}-t1
     * API designer → api-developer-{lang}-t1
     * Frontend designer → frontend-developer-t1
     * Test writer, code reviewers, security auditor
   - Claude launches requirements-validator agent
   - If FAIL: Claude increments iteration counter, notes gaps
     * Iterations 1-2: Claude re-runs specific agents using T1
     * Iterations 3+: Claude switches to T2 agents (Sonnet)
   - If PASS: Claude marks task complete, moves to next
3. Sprint complete when Claude has orchestrated all tasks to completion

**Result:** Working, tested, documented features.
**Process:** Claude manually coordinates agents using the Task tool, tracking state in responses.

---

## Quality Gates

Every task goes through requirements validation before completion:

**Validator checks:**
- ✅ All acceptance criteria met
- ✅ Test coverage ≥80%
- ✅ All required tests exist and pass
- ✅ Security review clean
- ✅ Documentation complete
- ✅ No blocking technical debt

**If validation fails:**
- Validator returns specific gaps to address
- Claude routes to only agents needed for fixes
- Claude repeats until validation passes
- Claude uses T1 (Haiku) for iterations 1-2
- Claude switches to T2 (Sonnet) for iteration 3+
- Maximum 10 iterations before human intervention

**This ensures:**
- No incomplete features
- No untested code
- No security vulnerabilities
- No missing documentation
- Production-ready quality
- Cost-optimized development

---

## Documentation

### Core Documents

**[docs/usage/SETUP.md](docs/usage/SETUP.md)** - Complete setup guide
- Directory structure already created
- Configuration files in `.claude/`
- All 27 agent definitions in `.claude/agents/`
- Slash commands in `.claude/commands/`

**[docs/usage/USAGE.md](docs/usage/USAGE.md)** - How to use the system
- Complete workflow walkthrough
- Slash command reference
- How Claude orchestrates agents
- Monitoring progress
- Handling failures
- Best practices

**[docs/usage/WORKFLOWS.md](docs/usage/WORKFLOWS.md)** - Orchestration patterns
- How Claude coordinates agents
- Task execution patterns (fullstack/backend/frontend/python-generic)
- T1/T2 switching logic
- Validation loop handling
- Agent handoff protocols

**[docs/usage/AGENTS.md](docs/usage/AGENTS.md)** - Agent details
- All 27 agent specifications
- T1/T2 tier descriptions
- Implementation examples
- Output formats
- How to invoke via Task tool

### Quick Reference

**Available slash commands:**
```bash
/prd                  # Interactive PRD generation (Claude asks questions)
/planning             # Task decomposition + sprint planning (Claude orchestrates)
/sprint SPRINT-001    # Sprint execution (Claude orchestrates all agents)
```

**Note:** These are slash commands that prompt Claude to orchestrate agents manually.
Claude uses the Task tool to launch agents and tracks state in responses.

---

## Features

### Intelligent Tech Stack Selection

PRD generator asks about integrations first:
- ML/Data Science → Python recommended
- Full JavaScript team → TypeScript recommended
- Analyzes requirements before suggesting stack
- Provides reasoning for recommendations
- All agents adapt to chosen stack

### Dependency-Aware Planning

Task analyzer builds dependency graph:
- Identifies blocking relationships
- Enables parallel execution where possible
- Prevents circular dependencies
- Creates critical path analysis
- Optimizes sprint organization

### Iterative Quality Loops

Requirements validator enforces standards:
- Checks all acceptance criteria
- Returns specific gaps when validation fails
- Task orchestrator routes to needed agents only
- Repeats until quality gates pass
- Prevents shipping incomplete work

### Cost Optimization with T1/T2 Tiers

Model usage optimized by iteration and complexity:
- T1 (Haiku): First 2 iterations - cost-optimized
- T2 (Sonnet): Iteration 3+ - enhanced quality for complex fixes
- Automatic switching based on validation failures
- 70% of tasks complete with T1 only
- Opus: Architecture and design decisions

### Execution Tracking (Manual by Claude)

Claude tracks progress in responses:
- Sprint progress reported after each task
- Task-level status updates
- Iteration counts maintained manually
- T1/T2 tier switching decisions
- Validation results communicated
- Files created by agents saved to disk

---

## What Gets Built

### For Each Task

**Code:**
- Database models with migrations
- API endpoints with authentication
- Frontend components with state management
- Python utilities and scripts where applicable
- Integration between layers

**Tests:**
- Unit tests for all business logic
- Integration tests for APIs
- Component tests for frontend
- End-to-end tests for critical flows
- Coverage ≥80%

**Security:**
- Input validation
- Authentication and authorization
- SQL injection prevention
- XSS/CSRF protection
- Security audit report

**Documentation:**
- API endpoint documentation with examples
- Component usage documentation
- Setup and deployment instructions
- Architecture decision records

### For Each Sprint

**Deliverables:**
- All planned features working
- All tests passing
- All security reviews clean
- All documentation complete

**Reports:**
- Sprint execution summary
- Task performance metrics
- Iteration statistics
- T1/T2 tier usage analysis
- Quality metrics
- Lessons learned
- Next sprint readiness

---

## Success Metrics

**Planning Phase:**
- PRD completeness: 100%
- Task clarity: All acceptance criteria defined, task types identified
- Dependency accuracy: No circular dependencies
- Sprint balance: Even workload distribution

**Execution Phase:**
- Task completion rate: 100%
- Average iterations per task: 1-3
- T1 completion rate: ~70% of tasks
- T2 escalation rate: ~30% of tasks
- Validation pass rate: 100% (by definition)
- Test coverage: ≥80%
- Security issues: 0 critical/high
- Documentation completeness: 100%

**Project Overall:**
- MVP delivery time: Days not weeks
- Code quality: Production-ready
- Technical debt: Minimal and tracked
- Developer satisfaction: High automation
- Cost efficiency: Optimized T1/T2 usage

---

## Example Project

**Input:** "Build a task management app"

**After Planning (20 minutes):**
- PRD with Python/FastAPI + React stack
- 18 tasks across 3 sprints
- Sprint 1: Auth + Database (5 tasks, 2 weeks)
- Sprint 2: Core Features (8 tasks, 2 weeks)  
- Sprint 3: Polish (5 tasks, 1 week)

**After Execution (Automated):**
- Working authentication system
- Task CRUD with categories and priorities
- User dashboard with filtering
- Complete API documentation
- 87% test coverage
- Clean security audit
- Deployment ready

**T1/T2 Statistics:**
- 13 tasks completed with T1 only (72%)
- 5 tasks required T2 escalation (28%)
- Average iterations: 2.3 per task
- Cost savings: 60% vs all-Sonnet approach

**Total Time:** 5 weeks (mostly automated)  
**Your Time:** ~25 hours (planning + reviews)  
**System Time:** ~120 hours (automated development)

---

## When to Use This

**Perfect for:**
- MVP development
- Prototypes that need production quality
- New features in existing projects
- Technical refactoring with tests
- Projects with clear requirements
- Solo developers who want team productivity
- Teams who want consistency and quality

**Not ideal for:**
- Exploratory coding (requirements unclear)
- Highly experimental features
- Projects requiring extensive human creativity
- Real-time collaboration (Pair programming)
- Projects with frequently changing requirements

---

## Getting Started

### Prerequisites

- Claude Code access
- Git repository (empty or existing)
- 15-20 minutes for planning
- Clear idea of what you're building

### Using This Template

**Step 1:** Clone or download this repository
```bash
git clone <this-repo-url>
cd cs-archiver
```

**Step 2:** Verify structure exists
- `.claude/agents/` - 27 agent definitions
- `.claude/commands/` - 3 slash commands
- `.claude/settings.json` - Configuration
- `docs/` - Documentation structure

**Step 3:** Start planning
```bash
/prd
```

**Step 4:** Execute
```bash
/planning
/sprint SPRINT-001
```

**Note:** The system is already set up. Slash commands prompt Claude to orchestrate.

### First Project Tips

**Start small:**
- 3-5 features for MVP
- 1-2 sprints initially
- Clear, simple requirements
- Learn the system before scaling

**Be specific:**
- Clear acceptance criteria
- Defined success metrics
- Explicit integrations
- Known constraints

**Trust the process:**
- Let iterations happen
- Don't intervene too early
- Review validation reports
- Observe T1/T2 patterns
- Learn from tier usage

**Iterate on planning:**
- Refine PRD based on results
- Adjust task sizing over time
- Improve requirement clarity
- Build institutional knowledge

---

## Support

### Documentation

- **[docs/usage/USAGE.md](docs/usage/USAGE.md)** - Complete usage guide with examples
- **[docs/usage/WORKFLOWS.md](docs/usage/WORKFLOWS.md)** - Orchestration patterns
- **[docs/usage/AGENTS.md](docs/usage/AGENTS.md)** - Agent implementation details

### Artifacts Created

Claude and agents create:
```
docs/planning/PROJECT_PRD.yaml           # Your PRD
docs/planning/tasks/TASK-*.yaml          # Task definitions
docs/sprints/SPRINT-*.yaml               # Sprint plans
src/                                      # Generated code
tests/                                    # Generated tests
docs/api/                                 # API documentation
docs/reviews/                             # Review reports
```

### Common Issues

See [docs/usage/USAGE.md](docs/usage/USAGE.md) for:
- How Claude orchestrates agents
- Troubleshooting guide
- Common issues and solutions
- Best practices

---

## Version History

**Version 2.1 - Pragmatic Approach** (Current)
- 27 specialized agents with T1/T2 tiers
- T1 (Haiku): First 2 iterations (cost-optimized)
- T2 (Sonnet): Iteration 3+ (enhanced quality)
- Slash commands prompt Claude to orchestrate
- Claude manually coordinates agents using Task tool
- Claude tracks iterations and manages T1→T2 switching
- No YAML execution - pure prompt-based orchestration
- 70% cost reduction vs all-Sonnet approach
- Generic Python development support
- 3 slash commands: /prd, /planning, /sprint

---

## Architecture Highlights

### Two-Phase Design

**Planning generates documents, execution reads them:**
- Planning phase: Claude-guided, generates all task/sprint files
- Execution phase: Claude-orchestrated, reads documents
- Clean separation of concerns
- Reproducible and auditable

### Manual Orchestration by Claude

**Slash Commands → Claude → Agents (T1/T2):**
- User runs slash commands (/prd, /planning, /sprint)
- Claude reads agent definitions and follows instructions
- Claude launches specialized agents using Task tool
- Claude tracks iteration counts manually
- Claude decides when to switch T1→T2
- Agents perform focused work (T1 or T2)
- Requirements validator enforces quality

### Quality-First Approach

**No task completes without validation:**
- Every acceptance criterion checked
- Iterative loops fix gaps
- Automatic T1→T2 escalation for complex scenarios
- No shortcuts allowed
- Production-ready by design

### Cost Optimization

**T1/T2 tier system:**
- T1 (Haiku) handles 70% of work cost-effectively
- T2 (Sonnet) provides enhanced quality for complex 30%
- Automatic switching based on validation failures
- Significant cost savings vs uniform tier approach

### Stack Flexibility

**Backend choice based on requirements:**
- Python for ML/data science
- TypeScript for full JS teams
- All agents adapt automatically
- Template-based project structure

---

## License & Usage

This system is designed for development automation. Use it to build:
- Commercial products
- Open source projects
- Internal tools
- Client work
- Personal projects

No attribution required, no usage restrictions.

---

## Next Steps

1. **Clone this template repository**
2. **Read [docs/usage/USAGE.md](docs/usage/USAGE.md)** - Learn how Claude orchestrates
3. **Read [docs/usage/SETUP.md](docs/usage/SETUP.md)** - Understand the structure
4. **Start planning** - Run `/prd`
5. **Continue planning** - Run `/planning`
6. **Execute your first sprint** - Run `/sprint SPRINT-001`
7. **Monitor Claude's orchestration** - Watch as agents are invoked
8. **Review tier usage** - Learn which tasks needed T2
9. **Iterate and improve** - Learn from each sprint

**Welcome to pragmatic multi-agent development with Claude Code orchestration.**

Build faster. Build better. Build with confidence. Build affordably.
