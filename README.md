# Multi-Agent Dev System - Plugin Development Source

This repository contains the development source and history for the **multi-agent-dev-system** Claude Code plugin.

## The Plugin

**Location:** `../claude-code-multi-agent-dev-system/` or `./plugin/` (symlink)

The plugin is a complete 27-agent automated development system with:
- Planning agents (PRD generation, task breakdown, sprint planning)
- Implementation agents (database, backend, frontend, Python utilities)
- Quality agents (testing, security, documentation)
- T1/T2 cost optimization (Haiku → Sonnet escalation)
- Agent-based orchestration with quality gates

## Quick Start

### Install the Plugin

```bash
# Local installation
/plugin marketplace add file:///home/wburit/claude-code-multi-agent-dev-system
/plugin install multi-agent-dev-system

# Verify
/plugin list
```

### Use the Plugin

```bash
# Full workflow
/prd                    # Generate PRD
/planning               # Create tasks and sprints
/sprint SPRINT-001      # Execute sprint

# Or use individual agents
Task(
  subagent_type="multi-agent-dev-system:database:designer",
  model="opus",
  prompt="Design schema for user authentication"
)
```

## Documentation

**Plugin Documentation:**
- `../claude-code-multi-agent-dev-system/README.md` - Complete plugin docs
- `../claude-code-multi-agent-dev-system/INSTALLATION.md` - Installation guide
- `../claude-code-multi-agent-dev-system/examples/` - Usage examples

**Development History:**
- `docs/development/plugin-conversion.md` - Plugin conversion plan
- `docs/development/agent-review-findings.md` - Agent review & optimization
- `docs/development/PLUGIN_BUILD_COMPLETE.md` - Build completion log

## Repository Structure

```
multi-agent-claude-workflow/          # This repository
├── docs/
│   ├── development/                   # Archived development docs
│   ├── adrs/, api/, features/         # Work directories (empty)
│   ├── planning/, reviews/, sprints/  # Work directories (empty)
├── src/                               # Generated code (when using plugin)
│   ├── backend/
│   └── frontend/
├── tests/                             # Generated tests (when using plugin)
│   ├── backend/
│   └── frontend/
├── .claude-plugin/                    # Plugin installation marker
├── plugin/                            # Symlink to plugin directory
└── README.md                          # This file

../claude-code-multi-agent-dev-system/  # The actual plugin
├── agents/                            # 27 agent definitions
├── commands/                          # 3 workflow commands
├── examples/                          # Usage examples
├── plugin.json                        # Plugin manifest
├── INSTALLATION.md                    # Setup guide
└── README.md                          # Plugin documentation
```

## Using This Repository

This repository serves as:
1. **Plugin development source** - History and context for plugin development
2. **Test environment** - Plugin is installed here for local testing
3. **Work directory** - Example of plugin workspace structure

When you use the plugin in any project, it will generate files in directories like:
- `docs/planning/` - PRDs, tasks, sprints
- `src/` - Generated code
- `tests/` - Generated tests

## Development

The plugin itself is the single source of truth for:
- Agent definitions (27 agents in `agents/`)
- Commands (3 commands in `commands/`)
- Documentation (`README.md`, `INSTALLATION.md`)
- Examples (`examples/`)

This repository archives the development process:
- Planning documents
- Review findings
- Build logs

## Features

### 27 Specialized Agents
- **Planning:** PRD generator, task analyzer, sprint planner
- **Orchestration:** Sprint orchestrator, task orchestrator, requirements validator
- **Database:** Designer + Python/TypeScript developers (T1/T2)
- **Backend:** API designer + Python/TypeScript developers (T1/T2) + reviewers
- **Frontend:** Designer + developers (T1/T2) + reviewer
- **Python:** Generic developers (T1/T2) for utilities/scripts
- **Quality:** Test writer, security auditor, documentation coordinator

### Cost Optimization
- **T1 (Haiku):** Cost-optimized first attempt (handles 70% of work)
- **T2 (Sonnet):** Enhanced quality for complex scenarios (30% of work)
- **Automatic escalation:** T1 → T2 after validation failures
- **Result:** 60-70% cost savings vs all-Sonnet approach

### Quality Gates
- Requirements validator ensures 100% criteria satisfaction
- Security auditor checks OWASP Top 10
- Test coverage ≥ 80% enforced
- Iterative refinement until all standards met

## Architecture

```
User → /prd, /planning, /sprint commands
   ↓
Sprint Orchestrator (Opus) - Manages entire sprint
   ↓
Task Orchestrator (Sonnet) - Coordinates single task
   ↓
Specialized Agents (T1/T2) - Implement with automatic escalation
   ↓
Requirements Validator (Opus) - Quality gate
```

## Tech Stack Support

- **Python:** FastAPI or Django + SQLAlchemy + pytest
- **TypeScript:** Express/NestJS + Prisma/TypeORM + Jest
- **Frontend:** React or Next.js (TypeScript) + Tailwind
- **Database:** PostgreSQL

Stack selection happens during PRD generation based on project requirements.

## License

See LICENSE file.

## Next Steps

1. **Install the plugin** (see Quick Start above)
2. **Read plugin documentation** in `../claude-code-multi-agent-dev-system/README.md`
3. **Try it out** with `/prd` command
4. **Check examples** in `../claude-code-multi-agent-dev-system/examples/`

---

**Note:** This is NOT a template project to clone. The plugin is the installable component. This repository is for development history and local testing only.
