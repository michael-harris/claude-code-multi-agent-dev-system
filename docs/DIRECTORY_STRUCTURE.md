# Directory Structure Reference

This document describes the directory structure of the DevTeam plugin and the files it creates in your project.

## Plugin Structure

```
claude-devteam/
├── plugin.json                 # Plugin manifest
├── README.md                   # Main documentation
├── ENHANCEMENTS_V3.0.md        # Version 3.0 changelog
│
├── commands/                   # Slash command definitions
│   ├── devteam-plan.md         # /devteam:plan
│   ├── devteam-implement.md    # /devteam:implement
│   ├── devteam-bug.md          # /devteam:bug
│   ├── devteam-issue.md        # /devteam:issue
│   ├── devteam-status.md       # /devteam:status
│   ├── devteam-reset.md        # /devteam:reset
│   ├── devteam-config.md       # /devteam:config
│   ├── devteam-logs.md         # /devteam:logs
│   ├── devteam-help.md         # /devteam:help
│   ├── devteam-list.md         # /devteam:list
│   ├── devteam-select.md       # /devteam:select
│   ├── devteam-issue-new.md    # /devteam:issue-new
│   ├── merge-tracks.md         # [Debug] /devteam:merge-tracks
│   ├── worktree-status.md      # [Debug] /devteam:worktree-status
│   ├── worktree-list.md        # [Debug] /devteam:worktree-list
│   └── worktree-cleanup.md     # [Debug] /devteam:worktree-cleanup
│
├── agents/                     # Agent definitions (89 agents)
│   ├── planning/               # Planning agents (3)
│   │   ├── prd-generator.md
│   │   ├── task-graph-analyzer.md
│   │   └── sprint-planner.md
│   ├── orchestration/          # Orchestration agents (9)
│   │   ├── ralph-orchestrator.md
│   │   ├── sprint-orchestrator.md
│   │   ├── task-orchestrator.md
│   │   ├── autonomous-controller.md
│   │   ├── bug-council-orchestrator.md
│   │   ├── scope-validator.md
│   │   ├── track-merger.md
│   │   ├── requirements-validator.md
│   │   └── workflow-compliance.md
│   ├── research/               # Research agents (1)
│   │   └── research-agent.md
│   ├── diagnosis/              # Bug Council diagnosis (5)
│   │   ├── root-cause-analyst.md
│   │   ├── code-archaeologist.md
│   │   ├── pattern-matcher.md
│   │   ├── systems-thinker.md
│   │   └── adversarial-tester.md
│   ├── database/               # Database agents (13)
│   │   ├── database-designer.md
│   │   └── database-developer-{lang}-{tier}.md
│   ├── backend/                # Backend agents (21)
│   │   ├── api-designer.md
│   │   ├── api-developer-{lang}-{tier}.md
│   │   └── backend-code-reviewer-{lang}.md
│   ├── frontend/               # Frontend agents (4)
│   │   ├── frontend-designer.md
│   │   ├── frontend-developer-{tier}.md
│   │   └── frontend-code-reviewer.md
│   ├── quality/                # Quality agents (10)
│   │   ├── test-writer.md
│   │   ├── security-auditor.md
│   │   ├── refactoring-agent.md
│   │   ├── documentation-coordinator.md
│   │   ├── runtime-verifier.md
│   │   └── performance-auditor-{lang}.md
│   ├── devops/                 # DevOps agents (4)
│   │   ├── docker-specialist.md
│   │   ├── kubernetes-specialist.md
│   │   ├── cicd-specialist.md
│   │   └── terraform-specialist.md
│   ├── mobile/                 # Mobile agents (4)
│   │   ├── ios-developer-{tier}.md
│   │   └── android-developer-{tier}.md
│   ├── scripting/              # Scripting agents (4)
│   │   ├── powershell-developer-{tier}.md
│   │   └── shell-developer-{tier}.md
│   ├── infrastructure/         # Infrastructure agents (2)
│   │   └── configuration-manager-{tier}.md
│   └── python/                 # Python generic agents (2)
│       └── python-developer-generic-{tier}.md
│
├── skills/                     # Reusable skills (18)
│   ├── README.md
│   ├── core/                   # Core skills (3)
│   │   ├── code-reviewer.md
│   │   ├── debugger.md
│   │   └── refactorer.md
│   ├── testing/                # Testing skills (3)
│   │   ├── test-generator.md
│   │   ├── integration-tester.md
│   │   └── e2e-tester.md
│   ├── quality/                # Quality skills (3)
│   │   ├── performance-optimizer.md
│   │   ├── security-scanner.md
│   │   └── accessibility-checker.md
│   ├── workflow/               # Workflow skills (3)
│   │   ├── ci-cd-engineer.md
│   │   ├── git-specialist.md
│   │   └── deployment-manager.md
│   ├── frontend/               # Frontend skills (3)
│   │   ├── ui-ux-pro-max.md
│   │   ├── responsive-design.md
│   │   └── accessibility-expert.md
│   └── meta/                   # Meta skills (3)
│       ├── prompt-engineer.md
│       ├── context-manager.md
│       └── learning-optimizer.md
│
├── hooks/                      # Lifecycle hooks
│   ├── stop-hook.sh            # Stop/completion hook
│   ├── stop-hook.ps1           # Windows version
│   ├── persistence-hook.sh     # State persistence
│   ├── persistence-hook.ps1
│   ├── scope-check.sh          # Scope validation
│   ├── scope-check.ps1
│   ├── session-start.sh        # Session initialization
│   ├── session-start.ps1
│   ├── session-end.sh          # Session cleanup
│   ├── session-end.ps1
│   ├── pre-compact.sh          # Pre-context-compaction
│   └── pre-compact.ps1
│
├── templates/                  # Templates
│   └── interview-questions.yaml  # Interview question templates
│
├── scripts/                    # Utility scripts
│   ├── schema.sql              # SQLite database schema
│   ├── db-init.sh              # Database initialization (Linux/macOS)
│   ├── db-init.ps1             # Database initialization (Windows)
│   ├── state.sh                # State management functions (Bash)
│   ├── state.ps1               # State management functions (PowerShell)
│   └── events.sh               # Event logging functions
│
├── examples/                   # Usage examples
│   ├── complete-workflow-example.md
│   └── parallel-tracks-example.md
│
└── docs/                       # Documentation
    ├── GETTING_STARTED.md      # New user guide
    ├── DIRECTORY_STRUCTURE.md  # This file
    ├── SQLITE_SCHEMA.md        # Database schema docs
    ├── TROUBLESHOOTING.md      # Problem solving guide
    └── development/            # Development docs
        └── *.md
```

## Project Files Created

When you use DevTeam, it creates files in your project:

```
your-project/
├── .devteam/                   # DevTeam data directory
│   ├── devteam.db              # SQLite database
│   │   ├── sessions            # Execution sessions
│   │   ├── events              # Event history
│   │   ├── agent_runs          # Agent performance
│   │   ├── gate_results        # Quality gate results
│   │   ├── interviews          # Interview responses
│   │   ├── research_findings   # Research results
│   │   ├── bugs                # Bug tracking
│   │   └── escalations         # Model escalations
│   └── ralph-config.yaml       # Configuration file
│
├── docs/
│   ├── planning/               # Planning artifacts
│   │   ├── PROJECT_PRD.yaml    # Product Requirements Document
│   │   └── tasks/              # Task definitions
│   │       ├── TASK-001.yaml
│   │       ├── TASK-002.yaml
│   │       └── ...
│   └── sprints/                # Sprint definitions
│       ├── SPRINT-001.yaml
│       ├── SPRINT-002.yaml
│       └── ...
│
└── .multi-agent/               # Worktrees (temporary, auto-managed)
    ├── track-01/               # Track 1 worktree
    ├── track-02/               # Track 2 worktree
    └── ...
```

## File Descriptions

### `.devteam/devteam.db`
SQLite database containing all runtime state. See [SQLITE_SCHEMA.md](SQLITE_SCHEMA.md) for details.

### `.devteam/ralph-config.yaml`
Configuration file for DevTeam behavior:

```yaml
version: "3.0"

execution:
  mode: normal          # normal | eco
  max_iterations: 10
  parallel_gates: true

models:
  default_tier: auto
  escalation_threshold: 2
  eco_threshold: 4

gates:
  tests:
    enabled: true
    command: auto
  lint:
    enabled: true
  typecheck:
    enabled: true
  security:
    enabled: false
```

### `docs/planning/PROJECT_PRD.yaml`
Product Requirements Document generated during planning:

```yaml
version: "1.0"
project_name: "My Project"
created: "2026-01-29"

technology_stack:
  primary_language: typescript
  backend_framework: express
  frontend_framework: react
  database: postgresql

problem_statement: |
  Description of the problem being solved

features:
  must_have:
    - id: F001
      name: "Feature name"
      acceptance_criteria:
        - "Criterion 1"
```

### `docs/planning/tasks/TASK-XXX.yaml`
Individual task definitions:

```yaml
id: TASK-001
title: "Implement user authentication"
description: |
  Create login and registration endpoints

feature_ref: F001
task_type: backend
complexity:
  score: 6
  tier: moderate

dependencies: []
acceptance_criteria:
  - "Users can register"
  - "Users can login"
```

### `docs/sprints/SPRINT-XXX.yaml`
Sprint definitions grouping tasks:

```yaml
id: SPRINT-001
name: "Foundation"
goal: "Set up core infrastructure"

tasks:
  - TASK-001
  - TASK-002

estimated_complexity: 12

quality_gates:
  - All tests pass
  - No type errors
```

## Temporary Files

### `.multi-agent/`
Contains git worktrees for parallel track execution. This directory is:
- Created automatically when executing multi-track plans
- Managed entirely by DevTeam (users don't interact with it)
- Cleaned up automatically after merge
- Safe to delete if empty

## Gitignore Recommendations

Add to your `.gitignore`:

```gitignore
# DevTeam
.devteam/devteam.db
.devteam/devteam.db-journal
.devteam/devteam.db-wal
.multi-agent/

# Keep config in version control
!.devteam/ralph-config.yaml
```

## Cleaning Up

To remove all DevTeam files:

```bash
# Remove state (keeps config)
rm .devteam/devteam.db*

# Full removal
rm -rf .devteam/
rm -rf .multi-agent/
rm -rf docs/planning/
rm -rf docs/sprints/
```

To reinitialize:

```bash
bash scripts/db-init.sh
```
