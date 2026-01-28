# DevTeam Implementation Plan

Comprehensive step-by-step plan to transform the multi-agent system into an enhanced autonomous development platform.

---

## Executive Summary

| Metric | Before | After |
|--------|--------|-------|
| **Agents** | 76 | ~55 (consolidated + enhanced) |
| **Commands** | 10 (`/multi-agent:*`) | 6 (`/devteam:*`) |
| **Model Selection** | Fixed T1/T2 | Dynamic (Haiku/Sonnet/Opus) |
| **Execution Mode** | User-driven | Autonomous with safety limits |
| **Parallelism** | Manual track setup | Automatic (up to 3 concurrent) |
| **Testing** | Runtime verifier | + Chrome E2E automation |
| **Bug Diagnosis** | Single agent | Bug Council (5 Opus ensemble) |
| **Skills** | None | 16 integrated skills |
| **MCPs** | None | GitHub, Memory, LSP servers |

---

## Phase Overview

```
Phase 1: Foundation (Core Infrastructure)
   └─► State file extensions, hooks, MCP setup

Phase 2: Agent Consolidation (Reduce & Enhance)
   └─► Merge agents, add new capabilities, dynamic selection

Phase 3: Command Restructuring (User Interface)
   └─► New /devteam:* commands, issue workflow

Phase 4: Autonomous Mode (Ralph Functionality)
   └─► Stop hooks, session memory, circuit breaker

Phase 5: Parallel Execution (Performance)
   └─► Automatic task parallelization, subagent management

Phase 6: Quality Enhancements (Bug Council, Testing)
   └─► 5-agent diagnosis, Chrome E2E testing

Phase 7: Skills & Polish (Final Integration)
   └─► Skills integration, documentation, testing
```

---

# Phase 1: Foundation

**Duration:** 2-3 days
**Goal:** Establish core infrastructure for all subsequent phases

## Step 1.1: Directory Structure

Create new directory structure:

```bash
mkdir -p hooks
mkdir -p skills/{core,testing,quality,workflow,frontend,meta}
mkdir -p mcp-configs
mkdir -p agents/{architecture,diagnosis,data-ai,support}
mkdir -p .devteam
```

**Files to create:**
```
hooks/
├── stop-hook.sh
├── session-start.sh
├── session-end.sh
├── pre-compact.sh
└── README.md

mcp-configs/
├── required.json
├── recommended.json
├── optional.json
└── lsp-servers.json

.devteam/
├── config.yaml           # Project-level configuration
├── agent-capabilities.yaml  # Agent selection index
└── .gitignore
```

## Step 1.2: Extended State File Schema

Update `docs/development/state-management-guide.md` with new schema:

```yaml
# .devteam/state.yaml (new location, replaces .project-state.yaml)
version: "3.0"
type: project | feature | issue

metadata:
  created_at: timestamp
  updated_at: timestamp
  project_name: string

# ============================================
# AUTONOMOUS MODE (New - Ralph Functionality)
# ============================================
autonomous_mode:
  enabled: boolean
  started_at: timestamp
  max_iterations: 50
  current_iteration: number

  circuit_breaker:
    consecutive_failures: number
    max_failures: 5
    last_failure_point: string | null
    state: closed | open | half-open

  session:
    memory_file: path
    last_checkpoint: timestamp

# ============================================
# DYNAMIC MODEL SELECTION (New)
# ============================================
model_selection:
  strategy: dynamic | fixed

# ============================================
# TASK COMPLEXITY & MODEL TRACKING (New)
# ============================================
tasks:
  TASK-XXX:
    status: pending | in_progress | completed | failed

    # New: Complexity assessment
    complexity:
      score: number (0-14)
      tier: simple | moderate | complex
      factors:
        files_affected: number
        estimated_lines: number
        new_dependencies: number
        task_type: string
        risk_flags: [string]

    # New: Model history (replaces tier_used)
    model_history:
      - iteration: number
        model: haiku | sonnet | opus
        reason: string
        result: pass | fail

    # Existing fields
    iterations: number
    validation_result: string
    acceptance_criteria_met: number
    acceptance_criteria_total: number

# ============================================
# PARALLEL EXECUTION (New)
# ============================================
parallel_execution:
  enabled: boolean
  max_concurrent: 3

  active_slots:
    - slot: number
      task: string
      started_at: timestamp
      status: running | complete

  queue: [task_ids]

# ============================================
# BUG COUNCIL (New)
# ============================================
bug_council:
  activated: boolean
  issue_number: number

  agents:
    root_cause_analyst: {status, proposal, summary}
    code_archaeologist: {status, proposal, summary}
    pattern_matcher: {status, proposal, summary}
    systems_thinker: {status, proposal, summary}
    adversarial_tester: {status, proposal, summary}

  voting:
    results: {proposal: {total, ranks}}
    winner: string
    runner_up: string

# ============================================
# LSP CONFIGURATION (New)
# ============================================
lsp_config:
  auto_detect: boolean
  active_servers:
    - language: string
      server: string
      status: running | stopped

# ============================================
# MEMORY & LEARNING (New)
# ============================================
memory:
  last_session_file: path
  checkpoints:
    - name: string
      timestamp: timestamp
      commit_sha: string

learned_patterns:
  - id: string
    confidence: number
    pattern: string
    context: string

# ============================================
# EXISTING FIELDS (Retained)
# ============================================
sprints:
  SPRINT-XXX:
    status: pending | in_progress | completed | failed
    tasks_completed: number
    tasks_total: number

current_execution:
  command: string
  current_sprint: string
  current_task: string

statistics:
  total_tasks: number
  completed_tasks: number
  # ... etc
```

## Step 1.3: MCP Configuration Files

**Create `mcp-configs/required.json`:**
```json
{
  "mcpServers": {
    "github": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-github"],
      "env": {
        "GITHUB_PERSONAL_ACCESS_TOKEN": "${GITHUB_TOKEN}"
      },
      "purpose": "Issue and PR management for /devteam:issue commands"
    },
    "memory": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-memory"],
      "purpose": "Session persistence for autonomous mode"
    }
  }
}
```

**Create `mcp-configs/lsp-servers.json`:**
```json
{
  "mcpServers": {
    "lsp-typescript": {
      "command": "mcp-language-server",
      "args": ["--workspace", "${PROJECT_ROOT}"],
      "env": {
        "LSP_SERVER": "typescript-language-server",
        "LSP_SERVER_ARGS": "--stdio"
      },
      "detect": ["package.json", "tsconfig.json", "*.ts", "*.tsx"]
    },
    "lsp-python": {
      "command": "mcp-language-server",
      "args": ["--workspace", "${PROJECT_ROOT}"],
      "env": {
        "LSP_SERVER": "pyright",
        "LSP_SERVER_ARGS": ""
      },
      "detect": ["pyproject.toml", "requirements.txt", "*.py"]
    },
    "lsp-go": {
      "command": "mcp-language-server",
      "args": ["--workspace", "${PROJECT_ROOT}"],
      "env": {
        "LSP_SERVER": "gopls",
        "LSP_SERVER_ARGS": ""
      },
      "detect": ["go.mod", "*.go"]
    },
    "lsp-rust": {
      "command": "mcp-language-server",
      "args": ["--workspace", "${PROJECT_ROOT}"],
      "env": {
        "LSP_SERVER": "rust-analyzer",
        "LSP_SERVER_ARGS": ""
      },
      "detect": ["Cargo.toml", "*.rs"]
    }
  }
}
```

## Step 1.4: Base Hook Scripts

**Create `hooks/stop-hook.sh`:**
```bash
#!/bin/bash
# DevTeam Stop Hook - Implements Ralph-style session persistence

STATE_FILE=".devteam/state.yaml"
MEMORY_DIR=".devteam/memory"

# Check if autonomous mode is active
if [ ! -f ".devteam/autonomous-mode" ]; then
    exit 0  # Normal exit, autonomous mode not active
fi

# Check for explicit EXIT_SIGNAL
if echo "$STOP_HOOK_MESSAGE" | grep -q "EXIT_SIGNAL: true"; then
    echo "[DevTeam] EXIT_SIGNAL received. Session complete."
    rm -f ".devteam/autonomous-mode"
    exit 0
fi

# Load circuit breaker state
if [ -f ".devteam/circuit-breaker.json" ]; then
    FAILURES=$(jq -r '.consecutive_failures' .devteam/circuit-breaker.json)
    ITERATIONS=$(jq -r '.total_iterations' .devteam/circuit-breaker.json)
else
    FAILURES=0
    ITERATIONS=0
fi

# Check circuit breaker
if [ "$FAILURES" -ge 5 ]; then
    echo "[DevTeam] Circuit breaker OPEN. Human intervention required."
    exit 0
fi

if [ "$ITERATIONS" -ge 100 ]; then
    echo "[DevTeam] Maximum iterations reached."
    exit 0
fi

# Check completion status from state file
if [ -f "$STATE_FILE" ]; then
    PENDING=$(grep -c "status: pending" "$STATE_FILE" 2>/dev/null || echo "0")
    IN_PROGRESS=$(grep -c "status: in_progress" "$STATE_FILE" 2>/dev/null || echo "0")

    if [ "$PENDING" -eq 0 ] && [ "$IN_PROGRESS" -eq 0 ]; then
        echo "[DevTeam] All work complete."
        exit 0
    fi
fi

# Work not complete - continue
ITERATIONS=$((ITERATIONS + 1))
mkdir -p .devteam
echo "{\"consecutive_failures\": $FAILURES, \"total_iterations\": $ITERATIONS}" > .devteam/circuit-breaker.json

echo "[DevTeam] Work in progress (iteration $ITERATIONS). Continuing..."
exit 2  # Exit code 2 = block exit, re-inject prompt
```

**Create `hooks/session-start.sh`:**
```bash
#!/bin/bash
# Load previous session context

MEMORY_DIR=".devteam/memory"

# Find most recent memory file
if [ -d "$MEMORY_DIR" ]; then
    LATEST=$(ls -t "$MEMORY_DIR"/session-*.md 2>/dev/null | head -1)
    if [ -n "$LATEST" ]; then
        echo "[DevTeam] Loading previous session context from $LATEST"
        cat "$LATEST"
    fi
fi

# Auto-detect project languages for LSP
echo "[DevTeam] Detecting project languages..."
LANGUAGES=""
[ -f "package.json" ] && LANGUAGES="$LANGUAGES typescript"
[ -f "pyproject.toml" ] || [ -f "requirements.txt" ] && LANGUAGES="$LANGUAGES python"
[ -f "go.mod" ] && LANGUAGES="$LANGUAGES go"
[ -f "Cargo.toml" ] && LANGUAGES="$LANGUAGES rust"

if [ -n "$LANGUAGES" ]; then
    echo "[DevTeam] Detected languages:$LANGUAGES"
fi
```

**Create `hooks/session-end.sh`:**
```bash
#!/bin/bash
# Save session context for future resumption

MEMORY_DIR=".devteam/memory"
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
MEMORY_FILE="$MEMORY_DIR/session-$TIMESTAMP.md"

mkdir -p "$MEMORY_DIR"

# Generate session summary (this would be populated by Claude)
cat > "$MEMORY_FILE" << 'EOF'
# Session Memory - ${TIMESTAMP}

## Context
- Working on: ${CURRENT_TASK}
- Sprint: ${CURRENT_SPRINT}

## Progress
${PROGRESS_SUMMARY}

## What Worked
${WHAT_WORKED}

## Issues Encountered
${ISSUES}

## Next Steps
${NEXT_STEPS}
EOF

echo "[DevTeam] Session memory saved to $MEMORY_FILE"
```

## Step 1.5: Configuration Files

**Create `.devteam/config.yaml`:**
```yaml
# DevTeam Project Configuration
version: "1.0"

# Model selection strategy
model_selection:
  strategy: dynamic  # dynamic | fixed

  # Complexity thresholds for starting tier
  complexity_thresholds:
    simple: 4      # Score 0-4 starts at Haiku
    moderate: 8    # Score 5-8 starts at Sonnet
    # Score 9+ starts at Opus

  # Iteration progression
  progression:
    simple: [haiku, haiku, sonnet, sonnet, opus]
    moderate: [sonnet, sonnet, opus, opus, opus]
    complex: [opus, opus, opus, opus, opus]

# Autonomous mode settings
autonomous_mode:
  max_iterations: 50
  circuit_breaker_threshold: 5
  save_memory_on_exit: true

# Parallel execution
parallel_execution:
  enabled: true
  max_concurrent: 3

  # Only parallelize tasks meeting these criteria
  eligibility:
    max_complexity_score: 5
    max_files_affected: 3
    no_shared_files: true

# Bug council
bug_council:
  # Auto-activate for complex bugs
  auto_activate_threshold: 7

  # Skip for simple bugs
  skip_threshold: 4

# LSP configuration
lsp:
  auto_detect: true
  auto_start: true

# GitHub integration
github:
  auto_create_pr: true
  auto_link_issues: true
```

## Step 1.6: Update .gitignore

**Add to `.gitignore`:**
```
# DevTeam runtime files
.devteam/memory/
.devteam/circuit-breaker.json
.devteam/autonomous-mode
.devteam/*.log
```

---

# Phase 2: Agent Consolidation

**Duration:** 3-4 days
**Goal:** Merge T1/T2 pairs, integrate wshobson agents, add new capabilities

## Step 2.1: Create Agent Capability Index

**Create `.devteam/agent-capabilities.yaml`:**
```yaml
# Agent Capability Index for Dynamic Selection
# Used by task-orchestrator to select best agent for each task

agents:
  # ============================================
  # ARCHITECTURE AGENTS
  # ============================================
  backend-architect:
    id: "architecture:backend-architect"
    model: opus
    triggers:
      keywords: [api, rest, graphql, microservice, endpoint, backend]
      task_types: [backend, fullstack, api_design]
      file_patterns: ["*/routes/*", "*/controllers/*", "*/api/*"]
    skills: [rest-api, graphql, microservices, api-security, clean-architecture]
    replaces: [api-designer]

  database-architect:
    id: "architecture:database-architect"
    model: opus
    triggers:
      keywords: [database, schema, migration, model, orm, sql]
      task_types: [database, backend, fullstack]
      file_patterns: ["*/models/*", "*/migrations/*", "*/schema/*"]
    skills: [schema-design, query-optimization, migrations]
    replaces: [database-designer]

  frontend-architect:
    id: "architecture:frontend-architect"
    model: opus
    triggers:
      keywords: [ui, ux, design, component, layout, frontend, react, vue]
      task_types: [frontend, fullstack, ui_design]
      file_patterns: ["*/components/*", "*.tsx", "*.vue"]
    skills: [ui-ux-pro-max, design-systems, accessibility]
    replaces: [frontend-designer]

  cloud-architect:
    id: "architecture:cloud-architect"
    model: opus
    triggers:
      keywords: [aws, azure, gcp, cloud, serverless, lambda]
      task_types: [infrastructure, devops]
    skills: [aws, azure, gcp, serverless]
    new: true

  graphql-architect:
    id: "architecture:graphql-architect"
    model: opus
    triggers:
      keywords: [graphql, apollo, federation, resolver]
      file_patterns: ["*.graphql", "*/graphql/*"]
    skills: [graphql-schema, federation, resolvers]
    new: true

  architect-reviewer:
    id: "architecture:architect-reviewer"
    model: opus
    triggers:
      task_types: [architecture_review]
      keywords: [review architecture, design review]
    skills: [clean-architecture, solid, patterns]
    new: true

  # ============================================
  # DEVELOPMENT AGENTS (Consolidated)
  # ============================================
  python-developer:
    id: "development:python"
    model: dynamic  # Selected based on complexity
    triggers:
      keywords: [python, django, fastapi, flask]
      file_patterns: ["*.py", "pyproject.toml", "requirements.txt"]
    skills: [python-core, django, fastapi, async-python]
    replaces: [python-developer-t1, python-developer-t2, database-developer-python-t1, database-developer-python-t2, api-developer-python-t1, api-developer-python-t2]

  typescript-developer:
    id: "development:typescript"
    model: dynamic
    triggers:
      keywords: [typescript, javascript, node, express, nestjs, react, vue, next]
      file_patterns: ["*.ts", "*.tsx", "*.js", "package.json"]
    skills: [typescript-core, react, vue, node, express]
    replaces: [database-developer-typescript-t1, database-developer-typescript-t2, api-developer-typescript-t1, api-developer-typescript-t2, frontend-developer-t1, frontend-developer-t2]

  java-developer:
    id: "development:java"
    model: dynamic
    triggers:
      keywords: [java, spring, springboot, maven, gradle]
      file_patterns: ["*.java", "pom.xml", "build.gradle"]
    skills: [java-core, spring-boot, jpa]
    replaces: [database-developer-java-t1, database-developer-java-t2, api-developer-java-t1, api-developer-java-t2]

  go-developer:
    id: "development:go"
    model: dynamic
    triggers:
      keywords: [go, golang, gin, echo]
      file_patterns: ["*.go", "go.mod"]
    skills: [go-core, concurrency, gin]
    replaces: [database-developer-go-t1, database-developer-go-t2, api-developer-go-t1, api-developer-go-t2]

  rust-developer:
    id: "development:rust"
    model: dynamic
    triggers:
      keywords: [rust, cargo, tokio, actix]
      file_patterns: ["*.rs", "Cargo.toml"]
    skills: [rust-core, ownership, async-rust]
    new: true

  csharp-developer:
    id: "development:csharp"
    model: dynamic
    triggers:
      keywords: [csharp, dotnet, aspnet, entity framework]
      file_patterns: ["*.cs", "*.csproj"]
    skills: [csharp-core, aspnet, ef-core]
    replaces: [database-developer-csharp-t1, database-developer-csharp-t2, api-developer-csharp-t1, api-developer-csharp-t2]

  ruby-developer:
    id: "development:ruby"
    model: dynamic
    triggers:
      keywords: [ruby, rails, sinatra]
      file_patterns: ["*.rb", "Gemfile"]
    skills: [ruby-core, rails, activerecord]
    replaces: [database-developer-ruby-t1, database-developer-ruby-t2, api-developer-ruby-t1, api-developer-ruby-t2]

  php-developer:
    id: "development:php"
    model: dynamic
    triggers:
      keywords: [php, laravel, symfony]
      file_patterns: ["*.php", "composer.json"]
    skills: [php-core, laravel, eloquent]
    replaces: [database-developer-php-t1, database-developer-php-t2, api-developer-php-t1, api-developer-php-t2]

  mobile-developer:
    id: "development:mobile"
    model: dynamic
    triggers:
      keywords: [ios, android, react native, flutter, swift, kotlin]
      file_patterns: ["*.swift", "*.kt", "*.dart"]
    skills: [ios, android, react-native, flutter]
    replaces: [ios-developer-t1, ios-developer-t2, android-developer-t1, android-developer-t2]

  shell-developer:
    id: "development:shell"
    model: dynamic
    triggers:
      keywords: [bash, shell, powershell, script]
      file_patterns: ["*.sh", "*.ps1", "*.bash"]
    skills: [bash, powershell]
    replaces: [shell-developer-t1, shell-developer-t2, powershell-developer-t1, powershell-developer-t2]

  # ============================================
  # QUALITY AGENTS (Consolidated)
  # ============================================
  code-reviewer:
    id: "quality:code-reviewer"
    model: opus
    triggers:
      task_types: [code_review]
      always_run: true  # Runs for every implementation
    skills: [code-review, security-patterns, performance-patterns]
    replaces: [backend-code-reviewer-python, backend-code-reviewer-typescript, backend-code-reviewer-java, backend-code-reviewer-csharp, backend-code-reviewer-go, backend-code-reviewer-ruby, backend-code-reviewer-php, frontend-code-reviewer]

  security-auditor:
    id: "quality:security-auditor"
    model: opus
    triggers:
      keywords: [security, auth, password, token, encrypt, vulnerability]
      risk_flags: [security_sensitive]
      always_run: true
    skills: [owasp, threat-modeling, security-review]
    enhanced: true  # Enhanced with threat modeling

  tdd-orchestrator:
    id: "quality:tdd-orchestrator"
    model: opus
    triggers:
      task_types: [testing, implementation]
      always_run: true
    skills: [tdd-workflow, test-patterns, coverage]
    replaces: [test-writer]

  performance-engineer:
    id: "quality:performance-engineer"
    model: opus
    triggers:
      keywords: [performance, optimization, slow, latency, memory]
      task_types: [performance_review]
    skills: [profiling, optimization, caching]
    replaces: [performance-auditor-python, performance-auditor-typescript, performance-auditor-java, performance-auditor-csharp, performance-auditor-go, performance-auditor-ruby, performance-auditor-php]

  debugger:
    id: "quality:debugger"
    model: sonnet
    triggers:
      keywords: [bug, error, fix, broken, failing]
      task_types: [bug_fix]
    skills: [debugging, error-analysis, root-cause]
    new: true

  error-detective:
    id: "quality:error-detective"
    model: sonnet
    triggers:
      keywords: [log, trace, stack, exception]
    skills: [log-analysis, pattern-recognition]
    new: true

  accessibility-expert:
    id: "quality:accessibility-expert"
    model: opus
    triggers:
      keywords: [accessibility, wcag, a11y, screen reader]
      task_types: [frontend, ui_design]
    skills: [wcag, aria, inclusive-design]
    new: true

  runtime-verifier:
    id: "quality:runtime-verifier"
    model: sonnet
    triggers:
      task_types: [verification]
      always_run: true
    skills: [playwright-automation, webapp-testing]
    enhanced: true  # Enhanced with Chrome testing

  # ============================================
  # DEVOPS AGENTS
  # ============================================
  deployment-engineer:
    id: "devops:deployment-engineer"
    model: sonnet
    triggers:
      keywords: [deploy, docker, ci, cd, pipeline]
      file_patterns: ["Dockerfile", ".github/workflows/*", "docker-compose.yml"]
    skills: [docker, ci-cd, deployment]
    replaces: [docker-specialist, cicd-specialist]

  kubernetes-architect:
    id: "devops:kubernetes-architect"
    model: opus
    triggers:
      keywords: [kubernetes, k8s, helm, istio]
      file_patterns: ["*.yaml", "*/k8s/*", "*/kubernetes/*"]
    skills: [kubernetes, helm, service-mesh, gitops]
    replaces: [kubernetes-specialist]
    enhanced: true

  terraform-specialist:
    id: "devops:terraform-specialist"
    model: sonnet
    triggers:
      keywords: [terraform, infrastructure, iac]
      file_patterns: ["*.tf", "*.tfvars"]
    skills: [terraform, infrastructure-as-code]

  observability-engineer:
    id: "devops:observability-engineer"
    model: opus
    triggers:
      keywords: [monitoring, logging, tracing, metrics, prometheus, grafana]
    skills: [prometheus, grafana, distributed-tracing]
    new: true

  devops-troubleshooter:
    id: "devops:devops-troubleshooter"
    model: sonnet
    triggers:
      keywords: [production, incident, outage, debug deployment]
    skills: [incident-response, debugging]
    new: true

  # ============================================
  # DOCUMENTATION AGENTS
  # ============================================
  docs-architect:
    id: "documentation:docs-architect"
    model: sonnet
    triggers:
      task_types: [documentation]
      keywords: [docs, documentation, readme]
    skills: [technical-writing, api-documentation]
    replaces: [documentation-coordinator]

  api-documenter:
    id: "documentation:api-documenter"
    model: sonnet
    triggers:
      keywords: [api docs, openapi, swagger]
      file_patterns: ["openapi.yaml", "swagger.json"]
    skills: [openapi, swagger]
    new: true

  mermaid-expert:
    id: "documentation:mermaid-expert"
    model: haiku
    triggers:
      keywords: [diagram, flowchart, sequence, erd]
    skills: [mermaid-diagrams]
    new: true

  # ============================================
  # DATA & AI AGENTS
  # ============================================
  data-engineer:
    id: "data-ai:data-engineer"
    model: sonnet
    triggers:
      keywords: [etl, pipeline, warehouse, streaming, kafka]
    skills: [etl, data-pipelines, streaming]
    new: true

  ai-engineer:
    id: "data-ai:ai-engineer"
    model: opus
    triggers:
      keywords: [llm, rag, embeddings, ai, openai, anthropic]
    skills: [llm-applications, rag, prompt-engineering]
    new: true

  ml-engineer:
    id: "data-ai:ml-engineer"
    model: opus
    triggers:
      keywords: [ml, machine learning, model, training, inference]
    skills: [ml-pipelines, model-serving, mlops]
    new: true

  # ============================================
  # DIAGNOSIS AGENTS (Bug Council)
  # ============================================
  root-cause-analyst:
    id: "diagnosis:root-cause-analyst"
    model: opus
    triggers:
      task_types: [bug_diagnosis]
    skills: [root-cause-tracing]
    council: true

  code-archaeologist:
    id: "diagnosis:code-archaeologist"
    model: opus
    triggers:
      task_types: [bug_diagnosis]
    skills: [git-forensics]
    council: true

  pattern-matcher:
    id: "diagnosis:pattern-matcher"
    model: opus
    triggers:
      task_types: [bug_diagnosis]
    skills: [bug-patterns, anti-patterns]
    council: true

  systems-thinker:
    id: "diagnosis:systems-thinker"
    model: opus
    triggers:
      task_types: [bug_diagnosis]
    skills: [systems-analysis, dependency-mapping]
    council: true

  adversarial-tester:
    id: "diagnosis:adversarial-tester"
    model: opus
    triggers:
      task_types: [bug_diagnosis]
    skills: [edge-case-discovery, chaos-testing]
    council: true

  # ============================================
  # SUPPORT AGENTS
  # ============================================
  incident-responder:
    id: "support:incident-responder"
    model: opus
    triggers:
      keywords: [incident, outage, emergency, production down]
    skills: [incident-management, triage]
    new: true

  legacy-modernizer:
    id: "support:legacy-modernizer"
    model: sonnet
    triggers:
      keywords: [legacy, modernize, migrate, refactor old]
    skills: [refactoring, migration-patterns]
    new: true

  database-optimizer:
    id: "support:database-optimizer"
    model: sonnet
    triggers:
      keywords: [slow query, optimize, index, performance database]
    skills: [query-optimization, indexing]
    new: true
```

## Step 2.2: Create New Agent Files

Create consolidated agent definitions. Example:

**Create `agents/development/python-developer.md`:**
```markdown
# Python Developer

**Model:** dynamic (selected by task-orchestrator based on complexity)
**Purpose:** Full-stack Python development including Django, FastAPI, Flask

## Capabilities

This agent handles all Python development tasks:
- Database models (SQLAlchemy, Django ORM, Tortoise)
- API endpoints (FastAPI, Django REST, Flask)
- Background tasks (Celery, RQ, Dramatiq)
- Testing (pytest, unittest)
- CLI tools (Click, Typer)

## Skills (Loaded Contextually)

- `python-core` - Always loaded
- `django` - When Django project detected
- `fastapi` - When FastAPI project detected
- `async-python` - When async patterns needed
- `sqlalchemy` - When SQLAlchemy detected

## Model Selection

Model is determined dynamically:
- **Haiku**: Simple changes, bug fixes, small features
- **Sonnet**: Standard implementation, multi-file changes
- **Opus**: Complex architecture, security-critical, design decisions

## Consolidates Previous Agents

This agent replaces:
- python-developer-generic-t1
- python-developer-generic-t2
- database-developer-python-t1
- database-developer-python-t2
- api-developer-python-t1
- api-developer-python-t2

## Tool Requirements

- `uv` for package management
- `ruff` for linting
- `pytest` for testing
- `pyright` for type checking (via LSP)
```

**Create all 5 diagnosis agents:**
- `agents/diagnosis/root-cause-analyst.md`
- `agents/diagnosis/code-archaeologist.md`
- `agents/diagnosis/pattern-matcher.md`
- `agents/diagnosis/systems-thinker.md`
- `agents/diagnosis/adversarial-tester.md`

(Content as specified in Bug Council section)

## Step 2.3: Delete Deprecated Agents

Remove T1/T2 pairs that are now consolidated:

```bash
# Database developers (14 files → 0, consolidated into language developers)
rm agents/database/database-developer-*-t1.md
rm agents/database/database-developer-*-t2.md

# Keep database-designer.md but rename
mv agents/database/database-designer.md agents/architecture/database-architect.md

# API developers (14 files → 0, consolidated into language developers)
rm agents/backend/api-developer-*-t1.md
rm agents/backend/api-developer-*-t2.md

# Keep api-designer.md but rename
mv agents/backend/api-designer.md agents/architecture/backend-architect.md

# Code reviewers (7 files → 1 consolidated)
rm agents/backend/backend-code-reviewer-*.md
# Create new agents/quality/code-reviewer.md

# Frontend (4 files → 2)
rm agents/frontend/frontend-developer-t1.md
rm agents/frontend/frontend-developer-t2.md
# Consolidate into development/typescript-developer.md

# Performance auditors (7 files → 1)
rm agents/quality/performance-auditor-*.md
# Create new agents/quality/performance-engineer.md

# Mobile (4 files → 1)
rm agents/mobile/*.md
# Create new agents/development/mobile-developer.md

# Scripting (4 files → 1)
rm agents/scripting/*.md
# Create new agents/development/shell-developer.md
```

## Step 2.4: Update plugin.json

Update `plugin.json` with new agent structure:

```json
{
  "name": "devteam",
  "version": "3.0.0",
  "description": "Autonomous development team with 55 specialized agents, dynamic model selection, parallel execution, and Bug Council diagnosis",

  "agents": [
    {
      "id": "architecture:backend-architect",
      "name": "Backend Architect",
      "description": "RESTful API design, microservices, system architecture",
      "file": "agents/architecture/backend-architect.md",
      "model": "opus",
      "category": "architecture"
    },
    {
      "id": "development:python",
      "name": "Python Developer",
      "description": "Full-stack Python with Django, FastAPI, Flask",
      "file": "agents/development/python-developer.md",
      "model": "dynamic",
      "category": "development"
    }
    // ... all other agents
  ],

  "commands": [
    {
      "name": "/plan",
      "description": "Interactive planning: PRD + tasks + sprints",
      "file": "commands/plan.md"
    },
    {
      "name": "/sprint",
      "description": "Execute a single sprint",
      "file": "commands/sprint.md"
    },
    {
      "name": "/auto",
      "description": "Full autonomous development",
      "file": "commands/auto.md"
    },
    {
      "name": "/issue-new",
      "description": "Create a new GitHub issue",
      "file": "commands/issue-new.md"
    },
    {
      "name": "/issue",
      "description": "Fetch and fix a GitHub issue",
      "file": "commands/issue.md"
    },
    {
      "name": "/status",
      "description": "Show current progress",
      "file": "commands/status.md"
    }
  ],

  "hooks": {
    "stop": ["./hooks/stop-hook.sh"],
    "sessionStart": ["./hooks/session-start.sh"],
    "sessionEnd": ["./hooks/session-end.sh"]
  }
}
```

---

# Phase 3: Command Restructuring

**Duration:** 2 days
**Goal:** Create new `/devteam:*` commands

## Step 3.1: Create `/devteam:plan` Command

**Create `commands/plan.md`:**
```markdown
# Plan Command

## Usage
/devteam:plan

## Description
Interactive planning that combines PRD generation and sprint planning into a single workflow.

## Process

### Step 1: Project Discovery (Interactive)

Ask the user:
1. "What are you building?" (product description)
2. "What's the primary technology stack?" (auto-detect if possible)
3. "What are the must-have features?" (core requirements)
4. "Any specific constraints?" (timeline, integrations, etc.)

### Step 2: PRD Generation

Based on answers, generate:
- `docs/planning/PROJECT_PRD.yaml`

Include:
- Project metadata
- Technology stack
- Feature requirements (must-have, should-have, nice-to-have)
- Non-functional requirements
- Acceptance criteria for each feature

### Step 3: Task Breakdown

Call task-graph-analyzer to:
- Break PRD into discrete tasks
- Identify dependencies
- **NEW: Flag parallel-eligible tasks**
- Calculate complexity scores
- Create task files in `docs/planning/tasks/`

### Step 4: Sprint Organization

Call sprint-planner to:
- Group tasks into sprints
- Respect dependencies
- Balance sprint workload
- Create sprint files in `docs/sprints/`

### Step 5: Output Summary

Display:
```
Planning Complete!

📋 PRD: docs/planning/PROJECT_PRD.yaml
📝 Tasks: 15 tasks created
   - 8 can run in parallel
   - 7 require sequential execution
🏃 Sprints: 3 sprints planned
   - Sprint 1: Foundation (5 tasks)
   - Sprint 2: Core Features (6 tasks)
   - Sprint 3: Polish & Deploy (4 tasks)

Run /devteam:auto to build autonomously
 or /devteam:sprint SPRINT-001 to start manually
```
```

## Step 3.2: Create `/devteam:auto` Command

**Create `commands/auto.md`:**
```markdown
# Auto Command

## Usage
/devteam:auto "Project description"
/devteam:auto --resume
/devteam:auto --max-iterations 100

## Description
Full autonomous development from idea to deployed application.

## Process

### Initialization

1. Create `.devteam/autonomous-mode` marker file
2. Initialize state file if not exists
3. Load session memory if resuming
4. Configure LSP for detected languages
5. Set up circuit breaker

### Phase 1: Planning (if needed)

If no PRD exists:
1. Generate PRD from description (non-interactive)
2. Create task breakdown
3. Plan sprints
4. Identify parallel-eligible tasks

### Phase 2: Sprint Execution

For each sprint:
1. Execute tasks (with parallelism where eligible)
2. Run quality gates
3. Create checkpoint after sprint completion

### Phase 3: Testing

1. Run unit/integration tests
2. Launch application
3. Run Chrome E2E tests (via Playwright)
4. Fix any failures

### Phase 4: Completion

When all sprints complete:
1. Generate final documentation
2. Create deployment artifacts
3. Output EXIT_SIGNAL: true
4. Remove autonomous-mode marker

### Safety Features

- **Circuit Breaker**: Stops after 5 consecutive failures
- **Max Iterations**: Default 50, configurable
- **Memory Persistence**: Saves context on session end
- **Checkpoints**: Git commits after each sprint
```

## Step 3.3: Create `/devteam:issue-new` Command

**Create `commands/issue-new.md`:**
```markdown
# Issue New Command

## Usage
/devteam:issue-new "Issue description"

## Description
Creates a new GitHub issue with AI-enhanced details.

## Process

1. **Parse Description**
   - Extract title
   - Detect issue type (bug, feature, enhancement)
   - Identify affected components

2. **Enhance Issue**
   - Add appropriate labels
   - Suggest priority/severity
   - Add template sections:
     - Steps to reproduce (for bugs)
     - Acceptance criteria (for features)
     - Technical notes

3. **Create Issue**
   ```bash
   gh issue create \
     --title "..." \
     --body "..." \
     --label "..."
   ```

4. **Output**
   ```
   Created issue #127: Login button not working on mobile Safari
   https://github.com/user/repo/issues/127

   Labels: bug, mobile, authentication
   Priority: medium

   Run /devteam:issue 127 to fix it automatically.
   ```
```

## Step 3.4: Create `/devteam:issue` Command

**Create `commands/issue.md`:**
```markdown
# Issue Command

## Usage
/devteam:issue <number>
/devteam:issue <number> --council        # Force Bug Council
/devteam:issue <number> --no-council     # Skip Bug Council
/devteam:issue <number> --plan-only      # Analyze only, don't implement

## Description
Fetches a GitHub issue and runs automated workflow to fix it.

## Process

### Step 1: Fetch Issue

```bash
gh issue view <number> --json title,body,labels,comments
```

Parse:
- Issue description
- Reproduction steps
- Expected vs actual behavior
- Related comments

### Step 2: Assess Complexity

Calculate complexity score to determine:
- Simple bug (< 4): Direct to debugger agent
- Complex bug (>= 7): Activate Bug Council
- Medium (4-6): Standard diagnosis

### Step 3A: Bug Council (if complex)

Spawn 5 Opus subagents in parallel:
1. Root Cause Analyst
2. Code Archaeologist
3. Pattern Matcher
4. Systems Thinker
5. Adversarial Tester

Each provides diagnosis + proposed fix.

Conduct ranked-choice voting:
- Each agent ranks all 5 proposals
- Lowest total score wins
- Pass winning proposal to implementation

### Step 3B: Simple Bug (if simple)

Direct to debugger agent for quick fix.

### Step 4: Implementation

1. Create fix branch: `fix/issue-<number>-<slug>`
2. Implement winning solution
3. Run tests
4. Verify fix addresses issue

### Step 5: Create PR

```bash
gh pr create \
  --title "Fix: <issue title> (#<number>)" \
  --body "..." \
  --label "bug-fix"
```

Include in PR body:
- Issue link
- Bug Council summary (if used)
- Changes made
- Test results

### Step 6: Update Issue

Add comment linking to PR:
```bash
gh issue comment <number> --body "Fix submitted in PR #<pr_number>"
```
```

## Step 3.5: Rename/Update Existing Commands

```bash
# Rename command files
mv commands/prd.md commands/_deprecated_prd.md
mv commands/planning.md commands/_deprecated_planning.md
mv commands/sprint-all.md commands/_deprecated_sprint-all.md
mv commands/feature.md commands/_deprecated_feature.md

# Keep and update
# commands/sprint.md - keep for single sprint execution
```

---

# Phase 4: Autonomous Mode

**Duration:** 2-3 days
**Goal:** Implement Ralph-style autonomous execution

## Step 4.1: Update Task Orchestrator

**Modify `agents/orchestration/task-orchestrator.md`:**

Add complexity assessment:
```markdown
## NEW: Complexity Assessment (Before Iteration Loop)

Before starting iterations, assess task complexity:

1. Read task definition
2. Calculate complexity score:
   - files_affected: 1 file=0, 2-3=1, 4-7=2, 8+=3
   - estimated_lines: <50=0, 50-150=1, 150-400=2, 400+=3
   - new_dependencies: 0=0, 1-2=1, 3+=2
   - task_type: bug_fix=0, enhancement=1, new_feature=2, architectural=3
   - risk_flags: security+2, external_integration+1, db_migration+1

3. Determine starting tier:
   - Score 0-4: simple (start Haiku)
   - Score 5-8: moderate (start Sonnet)
   - Score 9+: complex (start Opus)

4. Record in state file
```

Add dynamic model selection:
```markdown
## NEW: Dynamic Model Selection

Replace fixed T1/T2 with:

```python
def get_model(complexity_tier, iteration):
    progression = {
        "simple": ["haiku", "haiku", "sonnet", "sonnet", "opus"],
        "moderate": ["sonnet", "sonnet", "opus", "opus", "opus"],
        "complex": ["opus", "opus", "opus", "opus", "opus"]
    }
    return progression[complexity_tier][iteration - 1]
```

When calling developer agents, pass model parameter:
```
Task(
    agent="development:python",
    model=get_model(task.complexity_tier, current_iteration),
    prompt="..."
)
```
```

## Step 4.2: Update Sprint Orchestrator

**Modify `agents/orchestration/sprint-orchestrator.md`:**

Add parallel execution:
```markdown
## NEW: Parallel Task Execution

When executing sprint tasks:

1. Build dependency graph
2. Identify tasks that can run in parallel:
   - All dependencies completed
   - Complexity score <= 5
   - No overlapping files with other parallel tasks

3. Execute in waves:
   ```
   Wave 1: [TASK-001] (sequential - foundation)
   Wave 2: [TASK-002, TASK-003, TASK-004] (parallel - max 3)
   Wave 3: [TASK-005] (sequential - depends on wave 2)
   ```

4. For parallel tasks:
   ```
   Task(
       agent="development:python",
       model="sonnet",
       prompt="...",
       run_in_background=True  # Run as background subagent
   )
   ```

5. Monitor parallel tasks:
   - Check completion status
   - When slot frees, start next eligible task
   - Collect results when all complete
```

Add checkpoint creation:
```markdown
## NEW: Checkpoints

After each sprint completion:

1. Create git commit with sprint summary
2. Record checkpoint in state file:
   ```yaml
   checkpoints:
     - name: "post-sprint-001"
       timestamp: "..."
       commit_sha: "abc123"
       verification:
         tests_passing: 45
         coverage: 82%
   ```
```

## Step 4.3: Implement Session Memory

**Create `agents/orchestration/memory-manager.md`:**
```markdown
# Memory Manager

**Model:** haiku (fast, simple task)
**Purpose:** Manage session memory for autonomous continuity

## Save Memory (on session end)

Generate memory file with:
- Current task/sprint context
- What approaches worked
- What failed and why
- Recommended next steps
- Any blockers identified

Save to: `.devteam/memory/session-{timestamp}.md`

## Load Memory (on session start)

1. Find most recent memory file
2. Inject into context
3. Resume from recorded state
```

---

# Phase 5: Parallel Execution

**Duration:** 2 days
**Goal:** Implement automatic task parallelization

## Step 5.1: Parallel Eligibility Detection

**Add to task-graph-analyzer:**
```markdown
## NEW: Parallel Eligibility Analysis

For each task, calculate:

1. **Dependencies satisfied**: All dependencies complete
2. **Complexity eligible**: Score <= 5
3. **File isolation**: No overlap with concurrent tasks
4. **Type eligible**: Not database migration, not security-critical

Mark in task file:
```yaml
parallel_eligible: true
parallel_group: 2  # Can run with other group 2 tasks
estimated_duration: short  # short | medium | long
```
```

## Step 5.2: Parallel Execution Manager

**Add to sprint-orchestrator:**
```markdown
## Parallel Execution Protocol

```
MAX_CONCURRENT = 3
active_tasks = []
task_queue = get_eligible_tasks()

while task_queue or active_tasks:
    # Fill available slots
    while len(active_tasks) < MAX_CONCURRENT and task_queue:
        task = task_queue.pop(0)
        if dependencies_met(task) and no_file_conflicts(task, active_tasks):
            launch_task_async(task)
            active_tasks.append(task)

    # Check for completions
    for task in active_tasks:
        if task.complete:
            active_tasks.remove(task)
            update_state(task)

    # Brief wait before next check
    wait(1 second)
```
```

---

# Phase 6: Quality Enhancements

**Duration:** 3-4 days
**Goal:** Bug Council and Chrome testing

## Step 6.1: Bug Council Implementation

**Create `agents/orchestration/bug-council.md`:**
```markdown
# Bug Council Orchestrator

**Model:** opus
**Purpose:** Coordinate 5-agent ensemble diagnosis for complex bugs

## Process

### 1. Launch Diagnosis Agents (Parallel)

```
Task(agent="diagnosis:root-cause-analyst", run_in_background=True)
Task(agent="diagnosis:code-archaeologist", run_in_background=True)
Task(agent="diagnosis:pattern-matcher", run_in_background=True)
Task(agent="diagnosis:systems-thinker", run_in_background=True)
Task(agent="diagnosis:adversarial-tester", run_in_background=True)
```

### 2. Collect Proposals

Wait for all 5 agents to complete.
Collect:
- Diagnosis summary
- Proposed fix
- Confidence score
- Affected files

### 3. Conduct Voting

Each agent evaluates all 5 proposals on:
- Correctness (weight: 3)
- Completeness (weight: 2)
- Safety (weight: 3)
- Scope (weight: 2)
- Maintainability (weight: 1)

Rank 1-5 (1 = best).

### 4. Calculate Winner

```python
scores = {proposal: sum(ranks) for proposal, ranks in votes.items()}
winner = min(scores, key=scores.get)
runner_up = sorted(scores, key=scores.get)[1]
```

### 5. Output Decision

```yaml
bug_council_decision:
  winner: "C"
  winner_summary: "Fix null check + 3 similar locations"
  runner_up: "D"
  runner_up_summary: "Update AuthContext contract"
  vote_breakdown:
    C: [2, 3, 1, 3, 2]  # Total: 11
    D: [1, 1, 3, 1, 4]  # Total: 10 (close)
  recommendation: "Implement C, create tech debt ticket for D"
```
```

## Step 6.2: Chrome E2E Testing

**Update `agents/quality/runtime-verifier.md`:**
```markdown
## NEW: Chrome E2E Testing

### When to Run
- After all sprints complete
- After fixing user-facing bugs
- When acceptance criteria include UI behavior

### Process

1. **Start Application**
   ```bash
   # Detect and run appropriate command
   docker-compose up -d  # or
   npm run dev           # or
   python manage.py runserver
   ```

2. **Wait for Ready**
   - Poll health endpoint
   - Check for startup errors

3. **Launch Playwright Tests**
   ```javascript
   // Generated test scenarios from acceptance criteria
   test('User can register', async ({ page }) => {
       await page.goto('http://localhost:3000');
       await page.click('text=Sign Up');
       await page.fill('[name=email]', 'test@example.com');
       await page.fill('[name=password]', 'securepass123');
       await page.click('button[type=submit]');
       await expect(page.locator('.success')).toBeVisible();
   });
   ```

4. **Handle Failures**
   - Screenshot on failure
   - Log DOM state
   - Report to implementing agent for fix
   - Re-run after fix

5. **Generate Report**
   ```markdown
   # E2E Test Report

   - Scenarios: 12
   - Passed: 11
   - Failed: 1 (fixed and re-passed)
   - Duration: 45s
   - Screenshots: ./test-results/
   ```
```

---

# Phase 7: Skills & Polish

**Duration:** 2-3 days
**Goal:** Integrate skills, finalize documentation

## Step 7.1: Create Skills Files

**Create `skills/core/software-architecture.md`:**
```markdown
---
name: Software Architecture
description: Clean Architecture, SOLID principles, design patterns
---

# Software Architecture Skill

## Principles

### SOLID
- **S**ingle Responsibility
- **O**pen/Closed
- **L**iskov Substitution
- **I**nterface Segregation
- **D**ependency Inversion

### Clean Architecture
- Entities (innermost)
- Use Cases
- Interface Adapters
- Frameworks & Drivers (outermost)

## When Applied
- Architecture design tasks
- Code review for structure
- Refactoring decisions
```

**Create all skills from approved list:**
- `skills/core/test-driven-development.md`
- `skills/core/root-cause-tracing.md`
- `skills/testing/playwright-automation.md`
- `skills/testing/webapp-testing.md`
- `skills/quality/kaizen.md`
- `skills/workflow/changelog-generator.md`
- `skills/frontend/ui-ux-pro-max.md`
- ... (all 16 skills)

## Step 7.2: Documentation Updates

**Update `README.md`:**
```markdown
# DevTeam - Autonomous Development System

## Quick Start

```bash
# Full autonomous development
/devteam:auto "Build a task management app with user authentication"

# Interactive planning
/devteam:plan

# Fix a GitHub issue
/devteam:issue 127
```

## Features

- 🤖 **55 Specialized Agents** - Architecture, development, quality, DevOps
- 🧠 **Dynamic Model Selection** - Haiku/Sonnet/Opus based on task complexity
- 🔄 **Autonomous Execution** - Runs until complete with safety limits
- ⚡ **Parallel Tasks** - Up to 3 concurrent for eligible tasks
- 🔍 **Bug Council** - 5-agent ensemble diagnosis for complex bugs
- 🌐 **Chrome E2E Testing** - Automated UI testing via Playwright
- 🔌 **LSP Integration** - Semantic code understanding
```

**Create `docs/USER_GUIDE.md`:**
- Command reference
- Configuration options
- Troubleshooting

**Create `docs/ARCHITECTURE.md`:**
- System design
- Agent relationships
- State management

## Step 7.3: Testing & Validation

1. **Unit Tests**
   - Test complexity calculation
   - Test model selection logic
   - Test parallel eligibility

2. **Integration Tests**
   - Test full `/devteam:auto` flow
   - Test `/devteam:issue` with Bug Council
   - Test parallel execution

3. **Manual Testing**
   - Build sample project end-to-end
   - Test issue workflow
   - Verify Chrome testing works

---

# Implementation Timeline

```
Week 1:
├── Day 1-2: Phase 1 (Foundation)
├── Day 3-4: Phase 2 (Agent Consolidation - Part 1)
└── Day 5: Phase 2 (Agent Consolidation - Part 2)

Week 2:
├── Day 1-2: Phase 3 (Commands)
├── Day 3-4: Phase 4 (Autonomous Mode)
└── Day 5: Phase 5 (Parallel Execution)

Week 3:
├── Day 1-2: Phase 6 (Bug Council)
├── Day 3: Phase 6 (Chrome Testing)
├── Day 4: Phase 7 (Skills)
└── Day 5: Phase 7 (Documentation & Testing)
```

---

# Migration Checklist

## Before Starting
- [ ] Backup current project state
- [ ] Create feature branch
- [ ] Document current agent inventory

## Phase 1 Complete
- [ ] Directory structure created
- [ ] State schema documented
- [ ] MCP configs created
- [ ] Hook scripts created
- [ ] Config files created

## Phase 2 Complete
- [ ] Agent capability index created
- [ ] New agents created
- [ ] Deprecated agents removed
- [ ] plugin.json updated

## Phase 3 Complete
- [ ] /devteam:plan command created
- [ ] /devteam:auto command created
- [ ] /devteam:issue-new command created
- [ ] /devteam:issue command updated
- [ ] Old commands deprecated

## Phase 4 Complete
- [ ] Task orchestrator updated with complexity assessment
- [ ] Dynamic model selection implemented
- [ ] Sprint orchestrator updated with checkpoints
- [ ] Session memory implemented
- [ ] Stop hook tested

## Phase 5 Complete
- [ ] Parallel eligibility detection working
- [ ] Parallel execution manager working
- [ ] State tracking for parallel tasks working

## Phase 6 Complete
- [ ] Bug Council orchestrator created
- [ ] 5 diagnosis agents created
- [ ] Voting system implemented
- [ ] Chrome E2E testing working

## Phase 7 Complete
- [ ] All skills created
- [ ] README updated
- [ ] User guide created
- [ ] Architecture docs created
- [ ] All tests passing

---

# Risk Mitigation

| Risk | Mitigation |
|------|------------|
| Breaking existing workflows | Keep deprecated commands available for transition period |
| LSP server issues | Make LSP optional, graceful fallback |
| Parallel execution conflicts | Conservative eligibility criteria, file locking |
| Bug Council taking too long | Timeout after 5 minutes, fall back to single agent |
| Context window limits with MCPs | Only load needed MCPs, monitor usage |

---

# Success Metrics

| Metric | Target |
|--------|--------|
| Agent count | ~55 (down from 76) |
| Commands | 6 (down from 10) |
| Bug fix accuracy (with Council) | >90% first-time fix |
| Parallel speedup | 2-3x for eligible tasks |
| E2E test coverage | 80%+ of acceptance criteria |
| Autonomous completion rate | >85% without intervention |
