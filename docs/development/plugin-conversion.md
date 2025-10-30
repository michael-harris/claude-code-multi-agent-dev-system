# Converting Custom Agents to Claude Code Plugin

## Current State ✅ UPDATED AFTER REVIEW

You have **28 custom agent definitions** in `.claude/agents/` organized as markdown files:
- `planning/` - **prd-generator** (NEW!), task-graph-analyzer, sprint-planner
- `orchestration/` - sprint-orchestrator (⚠️ see notes), task-orchestrator, requirements-validator
- `database/` - database-designer, database-developer-{python,typescript}-{t1,t2} (FIXED)
- `backend/` - api-designer, api-developer-{python,typescript}-{t1,t2} (FIXED), backend-code-reviewer-{python,typescript}
- `frontend/` - frontend-designer, frontend-developer-{t1,t2} (FIXED), frontend-code-reviewer
- `python/` - python-developer-generic-{t1,t2} (FIXED)
- `quality/` - test-writer, security-auditor, documentation-coordinator

**Status:** ✅ All bash template syntax removed from 12 files - agents are now ready for plugin conversion
**Note:** requirements-validator is in orchestration/ (correct - it's an orchestration quality gate)

⚠️ **Architectural Decision Needed:** sprint-orchestrator agent exists but is not currently launched by `/sprint` command. See "Sprint Orchestrator Decision" section below.

## Goal

Create a Claude Code plugin named **`multi-agent-dev-system`** that registers all **28 agents** as subagent types, allowing:
- Usage: `Task(subagent_type="multi-agent-dev-system:database:designer", model="opus", ...)`
- Proper model assignment (Opus for designers, Haiku for T1, Sonnet for T2/quality)
- Hierarchical namespacing that matches your architecture
- Commands: `/prd`, `/planning`, `/sprint` for complete workflows

## Plugin Structure Analysis

Based on the installed plugin `claude-code-templates` which provides agents like:
- `python-development:fastapi-pro`
- `unit-testing:test-automator`
- `code-review-ai:architect-review`

A Claude Code plugin needs:
1. **Plugin manifest** - Metadata and configuration
2. **Agent definitions** - Each agent as a subagent type
3. **Namespace structure** - Organized by domain/category

## Required Plugin Structure

```
claude-code-multi-agent-dev-system/
├── plugin.json                          # Plugin manifest
├── README.md                            # Plugin documentation
├── agents/
│   ├── planning/
│   │   ├── task-graph-analyzer.md      # Agent definition with model spec
│   │   └── sprint-planner.md
│   ├── orchestration/
│   │   ├── sprint-orchestrator.md
│   │   └── task-orchestrator.md
│   ├── database/
│   │   ├── database-designer.md
│   │   ├── database-developer-python-t1.md
│   │   ├── database-developer-python-t2.md
│   │   ├── database-developer-typescript-t1.md
│   │   └── database-developer-typescript-t2.md
│   ├── backend/
│   │   ├── api-designer.md
│   │   ├── api-developer-python-t1.md
│   │   ├── api-developer-python-t2.md
│   │   ├── api-developer-typescript-t1.md
│   │   ├── api-developer-typescript-t2.md
│   │   ├── backend-code-reviewer-python.md
│   │   └── backend-code-reviewer-typescript.md
│   ├── frontend/
│   │   ├── frontend-designer.md
│   │   ├── frontend-developer-t1.md
│   │   ├── frontend-developer-t2.md
│   │   └── frontend-code-reviewer.md
│   ├── python/
│   │   ├── python-developer-generic-t1.md
│   │   └── python-developer-generic-t2.md
│   └── quality/
│       ├── test-writer.md
│       ├── security-auditor.md
│       ├── documentation-coordinator.md
│       └── requirements-validator.md
└── examples/
    ├── sprint-workflow-example.md
    └── task-workflow-example.md
```

## plugin.json Format

```json
{
  "name": "multi-agent-dev-system",
  "version": "1.0.0",
  "description": "27-agent automated development system with hierarchical orchestration and T1/T2 quality tiers for full-stack development",
  "author": "Your Name",
  "repository": "https://github.com/yourusername/claude-code-multi-agent-dev-system",
  "agents": [
    {
      "id": "planning:task-graph-analyzer",
      "name": "Task Graph Analyzer",
      "description": "Analyzes PRD and creates task breakdown with dependency graph",
      "file": "agents/planning/task-graph-analyzer.md",
      "model": "opus",
      "category": "planning"
    },
    {
      "id": "planning:sprint-planner",
      "name": "Sprint Planner",
      "description": "Organizes tasks into sprints based on dependencies and capacity",
      "file": "agents/planning/sprint-planner.md",
      "model": "opus",
      "category": "planning"
    },
    {
      "id": "orchestration:sprint-orchestrator",
      "name": "Sprint Orchestrator",
      "description": "Manages entire sprint execution and coordinates task orchestrator",
      "file": "agents/orchestration/sprint-orchestrator.md",
      "model": "sonnet",
      "category": "orchestration"
    },
    {
      "id": "orchestration:task-orchestrator",
      "name": "Task Orchestrator",
      "description": "Coordinates specialized agents for single task with T1/T2 escalation",
      "file": "agents/orchestration/task-orchestrator.md",
      "model": "sonnet",
      "category": "orchestration"
    },
    {
      "id": "database:designer",
      "name": "Database Designer",
      "description": "Designs normalized database schemas (language-agnostic)",
      "file": "agents/database/database-designer.md",
      "model": "opus",
      "category": "database"
    },
    {
      "id": "database:developer-python-t1",
      "name": "Database Developer Python T1",
      "description": "Implements SQLAlchemy models and Alembic migrations (cost-optimized)",
      "file": "agents/database/database-developer-python-t1.md",
      "model": "haiku",
      "category": "database",
      "tier": "t1"
    },
    {
      "id": "database:developer-python-t2",
      "name": "Database Developer Python T2",
      "description": "Implements SQLAlchemy models and Alembic migrations (enhanced quality)",
      "file": "agents/database/database-developer-python-t2.md",
      "model": "sonnet",
      "category": "database",
      "tier": "t2"
    },
    {
      "id": "database:developer-typescript-t1",
      "name": "Database Developer TypeScript T1",
      "description": "Implements Prisma/TypeORM models and migrations (cost-optimized)",
      "file": "agents/database/database-developer-typescript-t1.md",
      "model": "haiku",
      "category": "database",
      "tier": "t1"
    },
    {
      "id": "database:developer-typescript-t2",
      "name": "Database Developer TypeScript T2",
      "description": "Implements Prisma/TypeORM models and migrations (enhanced quality)",
      "file": "agents/database/database-developer-typescript-t2.md",
      "model": "sonnet",
      "category": "database",
      "tier": "t2"
    },
    {
      "id": "backend:api-designer",
      "name": "API Designer",
      "description": "Designs RESTful API specifications with OpenAPI",
      "file": "agents/backend/api-designer.md",
      "model": "opus",
      "category": "backend"
    },
    {
      "id": "backend:api-developer-python-t1",
      "name": "API Developer Python T1",
      "description": "Implements FastAPI/Django endpoints (cost-optimized)",
      "file": "agents/backend/api-developer-python-t1.md",
      "model": "haiku",
      "category": "backend",
      "tier": "t1"
    },
    {
      "id": "backend:api-developer-python-t2",
      "name": "API Developer Python T2",
      "description": "Implements FastAPI/Django endpoints (enhanced quality)",
      "file": "agents/backend/api-developer-python-t2.md",
      "model": "sonnet",
      "category": "backend",
      "tier": "t2"
    },
    {
      "id": "backend:api-developer-typescript-t1",
      "name": "API Developer TypeScript T1",
      "description": "Implements Express/NestJS endpoints (cost-optimized)",
      "file": "agents/backend/api-developer-typescript-t1.md",
      "model": "haiku",
      "category": "backend",
      "tier": "t1"
    },
    {
      "id": "backend:api-developer-typescript-t2",
      "name": "API Developer TypeScript T2",
      "description": "Implements Express/NestJS endpoints (enhanced quality)",
      "file": "agents/backend/api-developer-typescript-t2.md",
      "model": "sonnet",
      "category": "backend",
      "tier": "t2"
    },
    {
      "id": "backend:code-reviewer-python",
      "name": "Backend Code Reviewer Python",
      "description": "Reviews Python backend code for quality and security",
      "file": "agents/backend/backend-code-reviewer-python.md",
      "model": "sonnet",
      "category": "backend"
    },
    {
      "id": "backend:code-reviewer-typescript",
      "name": "Backend Code Reviewer TypeScript",
      "description": "Reviews TypeScript backend code for quality and security",
      "file": "agents/backend/backend-code-reviewer-typescript.md",
      "model": "sonnet",
      "category": "backend"
    },
    {
      "id": "frontend:designer",
      "name": "Frontend Designer",
      "description": "Designs UI/UX with component specifications",
      "file": "agents/frontend/frontend-designer.md",
      "model": "opus",
      "category": "frontend"
    },
    {
      "id": "frontend:developer-t1",
      "name": "Frontend Developer T1",
      "description": "Implements React/Vue components (cost-optimized)",
      "file": "agents/frontend/frontend-developer-t1.md",
      "model": "haiku",
      "category": "frontend",
      "tier": "t1"
    },
    {
      "id": "frontend:developer-t2",
      "name": "Frontend Developer T2",
      "description": "Implements React/Vue components (enhanced quality)",
      "file": "agents/frontend/frontend-developer-t2.md",
      "model": "sonnet",
      "category": "frontend",
      "tier": "t2"
    },
    {
      "id": "frontend:code-reviewer",
      "name": "Frontend Code Reviewer",
      "description": "Reviews frontend code for quality, accessibility, and performance",
      "file": "agents/frontend/frontend-code-reviewer.md",
      "model": "sonnet",
      "category": "frontend"
    },
    {
      "id": "python:developer-generic-t1",
      "name": "Python Developer Generic T1",
      "description": "Implements Python utilities, scripts, CLI tools (cost-optimized)",
      "file": "agents/python/python-developer-generic-t1.md",
      "model": "haiku",
      "category": "python",
      "tier": "t1"
    },
    {
      "id": "python:developer-generic-t2",
      "name": "Python Developer Generic T2",
      "description": "Implements Python utilities, scripts, CLI tools (enhanced quality)",
      "file": "agents/python/python-developer-generic-t2.md",
      "model": "sonnet",
      "category": "python",
      "tier": "t2"
    },
    {
      "id": "quality:test-writer",
      "name": "Test Writer",
      "description": "Creates comprehensive test suites (unit, integration, e2e)",
      "file": "agents/quality/test-writer.md",
      "model": "sonnet",
      "category": "quality"
    },
    {
      "id": "quality:security-auditor",
      "name": "Security Auditor",
      "description": "Performs security audits and vulnerability scanning",
      "file": "agents/quality/security-auditor.md",
      "model": "sonnet",
      "category": "quality"
    },
    {
      "id": "quality:documentation-coordinator",
      "name": "Documentation Coordinator",
      "description": "Creates and maintains technical documentation",
      "file": "agents/quality/documentation-coordinator.md",
      "model": "sonnet",
      "category": "quality"
    },
    {
      "id": "quality:requirements-validator",
      "name": "Requirements Validator",
      "description": "Validates implementation against acceptance criteria",
      "file": "agents/quality/requirements-validator.md",
      "model": "sonnet",
      "category": "quality"
    }
  ],
  "commands": [
    {
      "name": "/prd",
      "description": "Generate comprehensive PRD from project idea",
      "file": "commands/prd.md"
    },
    {
      "name": "/planning",
      "description": "Break down PRD into tasks and sprints",
      "file": "commands/planning.md"
    },
    {
      "name": "/sprint",
      "description": "Execute a sprint with full agent orchestration",
      "file": "commands/sprint.md"
    }
  ]
}
```

## Agent File Format Requirements

Each agent markdown file should follow this structure:

```markdown
# [Agent Name]

**Model:** [opus/sonnet/haiku]
**Tier:** [t1/t2] (if applicable)
**Purpose:** [Brief description]

## Your Role

[Role description]

## Responsibilities

1. [Responsibility 1]
2. [Responsibility 2]
...

## Input

- [What the agent receives]

## Output

- [What the agent produces]

## Quality Checks

- ✅ [Check 1]
- ✅ [Check 2]
...

## Technical Guidelines

[Specific technical requirements, frameworks, patterns, etc.]
```

## Conversion Steps

### Step 1: Create Plugin Repository

```bash
mkdir claude-code-multi-agent-dev-system
cd claude-code-multi-agent-dev-system
git init
```

### Step 2: Copy Agent Files

Copy all files from `.claude/agents/` to `agents/` in the new repository, preserving directory structure.

### Step 3: Create plugin.json

Use the template above, ensuring:
- Agent IDs follow `category:name` format
- File paths are correct relative to plugin root
- Models are properly assigned (opus/sonnet/haiku)
- T1/T2 tiers are marked

### Step 4: Create README.md

```markdown
# Multi-Agent Development System Plugin

27-agent automated development system with hierarchical orchestration and T1/T2 quality tiers.

## Features

- **Planning Agents**: Break down requirements into tasks and sprints
- **Orchestration Agents**: Coordinate multi-agent workflows
- **Database Agents**: Design and implement database schemas
- **Backend Agents**: Design and implement APIs
- **Frontend Agents**: Design and implement UI components
- **Python Agents**: Generic Python development (CLI, scripts, utilities)
- **Quality Agents**: Testing, security, documentation, validation

## Architecture

**Planning → Orchestration → Implementation (T1/T2) → Quality**

- **T1 (Haiku)**: Cost-optimized for straightforward implementation
- **T2 (Sonnet)**: Enhanced quality for complex scenarios
- **Design (Opus)**: High-quality architectural and design decisions

## Installation

\`\`\`bash
/plugin marketplace add https://github.com/yourusername/claude-code-multi-agent-dev-system
/plugin install multi-agent-dev-system
\`\`\`

## Usage

### Full Workflow

1. Generate PRD: `/prd "Build a task management app"`
2. Create plan: `/planning`
3. Execute sprint: `/sprint SPRINT-001`

### Individual Agents

\`\`\`
Task(
  subagent_type="multi-agent-dev-system:database:designer",
  prompt="Design database schema for user authentication"
)
\`\`\`

## Agents

[List all 27 agents with brief descriptions]
```

### Step 5: Copy Commands

Copy `.claude/commands/*.md` to `commands/` in the plugin repository.

### Step 6: Test Locally

```bash
# In the project that needs the agents:
/plugin marketplace add file:///path/to/claude-code-multi-agent-dev-system
/plugin install multi-agent-dev-system
```

### Step 7: Publish (Optional)

If you want others to use it:
1. Push to GitHub
2. Add proper repository URL in plugin.json
3. Share the marketplace add command

## Sprint Orchestrator Decision ⚠️

**Issue:** The `sprint-orchestrator` agent is defined but NOT currently launched by the `/sprint` command. The `/sprint` command performs manual orchestration instead.

**Options:**

### Option A: Launch as Agent (Recommended for Plugin)
- Update `/sprint` command to launch sprint-orchestrator agent
- Provides true agent-based architecture
- Consistent with other orchestration patterns
- Enables sprint-orchestrator to be used standalone

### Option B: Document as Reference Only
- Keep sprint-orchestrator.md in plugin as "reference architecture"
- `/sprint` command continues manual orchestration
- Mark agent as "not directly launchable"

### Option C: Remove from Plugin
- Remove sprint-orchestrator.md entirely
- Only include task-orchestrator
- `/sprint` remains pure command

**Recommendation:** **Option A** - Convert to true agent-based orchestration for consistency and plugin reusability.

---

## Testing Checklist

- [ ] All 28 agents appear in Task tool subagent_type dropdown
- [ ] Agent IDs follow `multi-agent-dev-system:category:name` format
- [ ] Model switching works (haiku for T1, sonnet for T2, opus for designers)
- [ ] Commands work: `/prd`, `/planning`, `/sprint`
- [ ] Agent instructions are properly loaded and followed
- [ ] T1→T2 escalation logic works
- [ ] prd-generator properly interviews and selects tech stack
- [ ] Sprint orchestrator decision implemented (A, B, or C)

## Usage After Plugin Installation

```javascript
// Database task
Task(
  subagent_type="multi-agent-dev-system:database:designer",
  model="opus",  // Can override, but plugin specifies opus by default
  prompt="Design schema for..."
)

Task(
  subagent_type="multi-agent-dev-system:database:developer-python-t1",
  model="haiku",  // T1 uses haiku
  prompt="Implement the schema..."
)

// If T1 fails, escalate to T2
Task(
  subagent_type="multi-agent-dev-system:database:developer-python-t2",
  model="sonnet",  // T2 uses sonnet
  prompt="Fix the implementation issues..."
)
```

## Key Benefits of Plugin Approach

1. ✅ **Proper model switching** - Each agent gets the right model automatically
2. ✅ **Reusable across projects** - Install once, use everywhere
3. ✅ **Version controlled** - Track changes to agent instructions
4. ✅ **Shareable** - Others can use your multi-agent system
5. ✅ **IDE integration** - Agents appear in Claude Code autocomplete
6. ✅ **Proper namespacing** - `multi-agent-dev-system:category:agent` prevents conflicts

## Next Steps

1. Create the plugin repository with this structure
2. Test locally with file:// installation
3. Push to GitHub
4. Install in cs-archiver project
5. Re-run `/sprint SPRINT-001` with proper agent invocation

---

## Instructions for Claude

When you receive this document in a new repository, follow these steps:

1. **Read current agent files** from the source project (if provided)
2. **Create plugin structure** as specified above
3. **Generate plugin.json** with all 27 agents properly registered
4. **Copy/adapt agent markdown files** to plugin format
5. **Create README.md** with installation and usage instructions
6. **Create example files** showing workflows
7. **Test plugin.json** for valid JSON syntax
8. **Provide installation command** for the user

The goal is a fully functional Claude Code plugin that registers all 27 agents as proper subagent types with correct model assignments.
