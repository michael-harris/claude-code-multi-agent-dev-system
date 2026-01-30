# DevTeam: Multi-Agent Autonomous Development System

An enterprise-grade Claude Code plugin providing **126 specialized AI agents** with:
- **Interview-driven planning** - Clarify requirements before work begins
- **Codebase research** - Investigate patterns and blockers before implementation
- **SQLite state management** - Reliable session tracking and cost analytics
- **Model escalation** - Automatic haiku → sonnet → opus progression
- **Bug Council** - 5-agent diagnostic team for complex issues
- **Eco mode** - 30-50% cost reduction for routine tasks
- **Quality gates** - Tests, types, lint, security, coverage enforcement

---

## Key Features

### Autonomous Development with Ralph

**Ralph** (Recursive Agent Loop for Polished Handling) is the quality enforcement system that ensures every task is completed to specification:

```
┌─────────────────────────────────────────────────────────────┐
│                      RALPH QUALITY LOOP                      │
│                                                              │
│   Execute → Quality Gates → Pass? → Complete                 │
│      ↑           │                                           │
│      │          Fail                                         │
│      │           ↓                                           │
│      └─── Fix Tasks ← Model Escalation (if needed)          │
│                                                              │
│   Loop until: ALL QUALITY GATES PASS                        │
└─────────────────────────────────────────────────────────────┘
```

**Features:**
- Automatic model escalation (haiku → sonnet → opus) after failures
- Stuck loop detection with Bug Council activation
- Quality gates: tests, types, lint, security, coverage
- Anti-abandonment system prevents agents from giving up
- Maximum 10 iterations with human notification

### Intelligent Agent Selection

The `/devteam:implement` command automatically selects the best agents for your task:

```bash
/devteam:implement "Add user authentication with JWT tokens"
```

**Selection Algorithm:**
| Factor | Weight | Example |
|--------|--------|---------|
| Keywords | 40% | "authentication" → security_auditor |
| File Types | 30% | `*.py` → api_developer_python |
| Task Type | 20% | "bug" → Bug Council |
| Language | 10% | FastAPI → Python agents |

### Bug Council: Multi-Perspective Debugging

For complex bugs, the Bug Council convenes 5 specialized analysts:

```
┌─────────────────────────────────────────────────────────────┐
│                       BUG COUNCIL                            │
├─────────────────────────────────────────────────────────────┤
│  Root Cause Analyst    │ Error analysis, stack traces       │
│  Code Archaeologist    │ Git history, regression detection  │
│  Pattern Matcher       │ Similar bugs, anti-patterns        │
│  Systems Thinker       │ Dependencies, integration issues   │
│  Adversarial Tester    │ Edge cases, security vectors       │
└─────────────────────────────────────────────────────────────┘
                              ↓
                    Synthesized Solution
```

**Activation Triggers:**
- Critical/high severity bugs
- 2+ failed fix attempts
- Complexity score ≥ 10
- Explicit `bug_council: true` flag

### Scope Enforcement

Agents are strictly confined to their assigned scope:

```yaml
scope:
  allowed_files:
    - "src/auth/*.py"
  forbidden_directories:
    - "src/billing/"
  max_files_changed: 5
```

**6 Enforcement Layers:**
1. Task scope definition in YAML
2. Agent prompt constraints
3. Scope validator agent with VETO power
4. Pre-commit hook blocking
5. Runtime file access control
6. Out-of-scope observations logging

### Anti-Abandonment System

Agents cannot give up. The persistence system ensures completion:

```
Abandonment Attempt → Detected → Re-engagement Prompt
         ↓
    Still stuck?
         ↓
    Model Escalation (haiku → sonnet → opus)
         ↓
    Still stuck?
         ↓
    Bug Council Activation
         ↓
    Still stuck?
         ↓
    Human Notification (but keep trying)
```

---

## 76+ Specialized Agents

### Enterprise Roles (NEW)

| Category | Agents | Capabilities |
|----------|--------|--------------|
| **SRE** | Site Reliability Engineer | SLOs, incident response, chaos engineering |
| **SRE** | Platform Engineer | Internal developer platforms, golden paths |
| **SRE** | Observability Engineer | Metrics, logging, tracing, alerting |
| **Security** | Penetration Tester | OWASP testing, API security, vuln assessment |
| **Security** | Compliance Engineer | SOC2, HIPAA, GDPR, PCI-DSS |
| **Product** | Product Manager | PRDs, roadmaps, user research |
| **Quality** | Accessibility Specialist | WCAG 2.1, screen readers, inclusive design |
| **DevRel** | Developer Advocate | Technical content, community, DX |

### Orchestration Agents

| Agent | Purpose |
|-------|---------|
| **Ralph Orchestrator** | Quality loop management, model escalation |
| **Task Orchestrator** | Task decomposition, agent coordination |
| **Bug Council Orchestrator** | Multi-perspective bug analysis |
| **Scope Validator** | Enforce scope boundaries |
| **Sprint Orchestrator** | Sprint execution management |

### Bug Council Agents

| Agent | Specialty |
|-------|-----------|
| **Root Cause Analyst** | Error analysis, hypothesis generation |
| **Code Archaeologist** | Git history, regression detection |
| **Pattern Matcher** | Similar bugs, anti-pattern identification |
| **Systems Thinker** | Dependencies, architectural issues |
| **Adversarial Tester** | Edge cases, security vulnerabilities |

### Implementation Agents

**Backend (by language):**
- Python (FastAPI, Django, Flask)
- TypeScript (Express, NestJS, Fastify)
- Go (Gin, Echo, Fiber)
- Java (Spring Boot, Micronaut)
- Rust (Actix, Axum)
- C# (ASP.NET Core)
- Ruby (Rails, Sinatra)
- PHP (Laravel, Symfony)

**Frontend:**
- React, Vue, Svelte, Angular specialists
- Accessibility specialist
- Performance auditor

**Database:**
- Schema designers
- Query optimization specialists
- Migration specialists

**DevOps:**
- CI/CD Specialist (GitHub Actions, Jenkins, GitLab CI)
- Docker Specialist
- Kubernetes Specialist
- Terraform Specialist

### Quality Agents

| Agent | Focus |
|-------|-------|
| **Test Writer** | Unit, integration, e2e tests |
| **Security Auditor** | OWASP Top 10, vulnerability scanning |
| **Performance Auditor** | Profiling, optimization, load testing |
| **Accessibility Specialist** | WCAG compliance, inclusive design |
| **E2E Tester** | Playwright, Cypress, browser testing |

---

## Quick Start

### Planning + Implementation (Recommended)

```bash
# Plan a new feature (interview → research → PRD → tasks → sprints)
/devteam:plan --feature "Add user authentication with OAuth"

# Execute the plan
/devteam:implement

# Or execute specific sprint
/devteam:implement --sprint 1
```

The system will:
1. **Interview** - Clarify requirements with targeted questions
2. **Research** - Analyze codebase, identify patterns and blockers
3. **Plan** - Generate PRD, tasks, and sprints
4. **Execute** - Run with Ralph quality loop and model escalation
5. **Verify** - Pass all quality gates before completion

### Bug Fixing

```bash
# Fix a local bug (interview → diagnose → fix → verify)
/devteam:bug "Login fails for guest users"

# Fix a GitHub issue
/devteam:issue 123

# Force Bug Council for complex issues
/devteam:bug "Memory leak in image processor" --council
```

### Cost-Optimized Mode

```bash
# Use eco mode for 30-50% cost savings
/devteam:implement --eco
/devteam:bug "Minor CSS issue" --eco
```

### Monitoring

```bash
# Check status, costs, progress
/devteam:status

# List plans and tasks
/devteam:list

# Reset stuck sessions
/devteam:reset
```

---

## Configuration

### Ralph Configuration (`.devteam/ralph-config.yaml`)

```yaml
loop_settings:
  max_iterations: 10

model_escalation:
  enabled: true
  consecutive_failures:
    haiku_to_sonnet: 2
    sonnet_to_opus: 2
    opus_max_failures: 3  # Then Bug Council

quality_gates:
  required:
    tests_passing: true
    type_check: true
    lint: true
  security:
    on_finding: create_fix_task
```

### Scope Definition (per task)

```yaml
# In task definition
scope:
  allowed_files:
    - "src/auth/*.py"
  allowed_patterns:
    - "tests/auth/**/*.py"
  forbidden_directories:
    - "src/billing/"
    - "src/admin/"
  max_files_changed: 10
```

### Agent Selection (`.devteam/agent-capabilities.yaml`)

```yaml
categories:
  security:
    agents:
      - id: penetration_tester
        triggers:
          keywords: [pentest, security testing, vulnerability]
          task_types: [security_testing]
```

---

## Hooks System

The system uses Claude Code hooks for autonomous execution. **All hooks support both Linux/macOS (Bash) and Windows (PowerShell).**

| Hook | Linux/macOS | Windows | Purpose |
|------|-------------|---------|---------|
| Stop Hook | `stop-hook.sh` | `stop-hook.ps1` | Blocks exit without `EXIT_SIGNAL: true` |
| Persistence Hook | `persistence-hook.sh` | `persistence-hook.ps1` | Detects and prevents abandonment |
| Scope Check | `scope-check.sh` | `scope-check.ps1` | Validates commits stay in scope |
| Pre-Compact | `pre-compact.sh` | (coming soon) | Preserves state before context compaction |

See [hooks/README.md](hooks/README.md) for detailed cross-platform installation instructions.

### Installation (Linux/macOS)

Add to `~/.claude/settings.json`:

```json
{
  "hooks": {
    "Stop": [{
      "matcher": "",
      "hooks": [{
        "type": "command",
        "command": "/path/to/hooks/stop-hook.sh"
      }]
    }],
    "PostToolUse": [{
      "matcher": "",
      "hooks": [{
        "type": "command",
        "command": "/path/to/hooks/persistence-hook.sh"
      }]
    }]
  }
}
```

---

## Model Tiers & Cost Optimization

### Automatic Model Selection

| Complexity | Model | Cost | Use Case |
|------------|-------|------|----------|
| 1-4 | Haiku | $0.001/1K | Simple fixes, docs |
| 5-8 | Sonnet | $0.003/1K | Standard features |
| 9-14 | Opus | $0.015/1K | Complex architecture |

### Escalation Flow

```
Task starts at complexity-appropriate tier
           │
           ▼
       Attempt #1
           │
       FAIL? ──────────────────┐
           │                   │
           ▼                   ▼
       Attempt #2          Same tier
           │              + more context
       FAIL? ──────────────────┐
           │                   │
           ▼                   ▼
       Attempt #3          Same tier
           │              + alt approach
       FAIL? ──────────────────┐
           │                   │
           ▼                   ▼
       ESCALATE           Upgrade tier
           │              (haiku→sonnet→opus)
           ▼
    Continue with higher tier
```

---

## Architecture

### Complete Flow

```
User Request
     │
     ▼
┌─────────────────┐
│  /devteam:implement  │ ← Automatic agent selection
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ Task Orchestrator│ ← Decomposes task, assigns scope
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│     RALPH       │ ← Quality loop wrapper
│  ┌───────────┐  │
│  │  Execute  │  │ ← Selected agents work
│  │  Agents   │  │
│  └─────┬─────┘  │
│        │        │
│        ▼        │
│  ┌───────────┐  │
│  │  Quality  │  │ ← Tests, lint, security
│  │   Gates   │  │
│  └─────┬─────┘  │
│        │        │
│    PASS│ FAIL   │
│        │   │    │
│        │   ▼    │
│        │ ┌────┐ │
│        │ │Fix │ │ ← Create fix tasks
│        │ └──┬─┘ │
│        │    │   │
│        │    ▼   │
│        │ Escalate? → Model upgrade if needed
│        │    │   │
│        └────┴───┘
│             │
└─────────────┘
         │
         ▼
   EXIT_SIGNAL: true
```

### Directory Structure

```
.devteam/
├── config.yaml              # Main project configuration
├── ralph-config.yaml        # Ralph quality loop config
├── agent-capabilities.yaml  # Agent registry with triggers
├── agent-selection.md       # Selection algorithm docs
├── persistence-config.yaml  # Anti-abandonment rules
├── scope-enforcement.md     # Scope system docs
├── model-selection.md       # Dynamic model assignment
├── parallel-execution.md    # Concurrent task handling
├── plan-management.md       # Plan lifecycle tracking
├── state.yaml               # Execution state (runtime)
├── circuit-breaker.json     # Failure tracking (runtime)
└── plans/                   # Multi-plan storage (runtime)

agents/
├── orchestration/           # 9 orchestration agents
│   ├── ralph-orchestrator.md
│   ├── task-orchestrator.md
│   ├── sprint-orchestrator.md
│   ├── bug-council-orchestrator.md
│   ├── scope-validator.md
│   └── workflow-compliance.md
├── planning/                # PRD & sprint planning
├── diagnosis/               # Bug Council agents (5)
├── backend/                 # Backend API developers
├── frontend/                # Frontend developers
├── database/                # Database specialists
├── python/                  # Python utilities
├── quality/                 # Testing & QA
├── devops/                  # CI/CD, Docker, K8s
├── sre/                     # Site Reliability Engineering
├── security/                # Security & Compliance
├── mobile/                  # iOS & Android
├── scripting/               # Shell & PowerShell
├── ux/                      # Design system agents
├── accessibility/           # A11y specialists
└── templates/
    └── base-agent.md

commands/                    # 18 slash commands
├── devteam-auto.md
├── devteam-plan.md
├── devteam-sprint.md
├── devteam-list.md
├── devteam-select.md
├── devteam-issue.md
├── devteam-issue-new.md
└── ...

hooks/                       # Cross-platform hooks
├── stop-hook.sh / .ps1      # Exit control
├── persistence-hook.sh / .ps1
├── scope-check.sh / .ps1
└── README.md

skills/                      # Specialized capabilities
├── core/
├── testing/
├── quality/
├── workflow/
└── frontend/

mcp-configs/                 # MCP server configurations
├── required.json
├── recommended.json
└── lsp-servers.json
```

---

## Commands Reference

### Core Commands

| Command | Description |
|---------|-------------|
| `/devteam:plan` | Interactive planning with interview, research, and sprint generation |
| `/devteam:implement` | Execute plans, sprints, tasks, or ad-hoc work |
| `/devteam:bug "<desc>"` | Fix bugs with diagnostic workflow and Bug Council |
| `/devteam:issue <#>` | Fix GitHub issues with interview if needed |
| `/devteam:status` | Display system health, progress, and costs |
| `/devteam:reset` | Reset stuck sessions and recover from errors |

### Planning Options

```bash
/devteam:plan                      # Interactive planning
/devteam:plan --feature "desc"     # Plan specific feature
/devteam:plan --from spec.md       # Plan from spec file
/devteam:plan --skip-research      # Skip research phase
```

### Implementation Options

```bash
/devteam:implement                 # Execute current plan
/devteam:implement --sprint 1      # Execute specific sprint
/devteam:implement --all           # Execute all sprints
/devteam:implement --task TASK-001 # Execute specific task
/devteam:implement "ad-hoc task"   # One-off task with interview
/devteam:implement --eco           # Cost-optimized mode
```

### Bug Fixing Options

```bash
/devteam:bug "description"         # Fix with interview
/devteam:bug "desc" --council      # Force Bug Council
/devteam:bug "desc" --severity critical
/devteam:bug "desc" --eco          # Cost-optimized
```

### Management Commands

| Command | Description |
|---------|-------------|
| `/devteam:list` | List plans, sprints, and tasks |
| `/devteam:select <plan>` | Select active plan |
| `/devteam:issue-new "<desc>"` | Create new GitHub issue |

### Worktree Commands

| Command | Description |
|---------|-------------|
| `/devteam:worktree-status` | Show worktree status |
| `/devteam:worktree-list` | List all worktrees |
| `/devteam:worktree-cleanup` | Clean up worktrees |
| `/devteam:merge-tracks` | Merge parallel tracks |

See [commands/README.md](commands/README.md) for detailed documentation.

---

## Quality Standards

Every task must pass:

| Gate | Requirement |
|------|-------------|
| **Tests** | 100% of tests passing |
| **Types** | No type errors (mypy, tsc) |
| **Lint** | No lint errors |
| **Security** | No high/critical findings |
| **Coverage** | ≥80% code coverage |
| **Scope** | All changes within scope |

**No task completes without all gates passing.**

---

## Examples

### Example 1: Add Feature

```bash
/devteam:implement "Add user profile page with avatar upload"
```

System automatically:
1. Detects React frontend + FastAPI backend
2. Selects: frontend_developer, api_developer_python, test_writer
3. Creates scoped subtasks for each
4. Executes with Ralph loop
5. Security audit on file upload
6. Completes when all tests pass

### Example 2: Fix Bug

```bash
/devteam:implement "Fix: Users can't login after password reset"
```

System automatically:
1. Detects bug-type task
2. Assigns root_cause_analyst first
3. If initial fix fails, activates Bug Council
4. 5 perspectives analyze the issue
5. Synthesized solution implemented
6. Regression tests added

### Example 3: Security Audit

```bash
/devteam:security "Audit authentication system"
```

System automatically:
1. Selects: security_auditor, penetration_tester, compliance_engineer
2. Runs OWASP Top 10 checks
3. Creates fix tasks for findings
4. Verifies fixes
5. Generates compliance report

---

## Installation

### From GitHub

```bash
/plugin marketplace add https://github.com/michael-harris/claude-devteam
/plugin install claude-devteam
```

### Local Development

```bash
git clone https://github.com/michael-harris/claude-devteam.git
cd claude-devteam
./install-local.sh
```

### Configure Hooks

```bash
# Make hooks executable
chmod +x hooks/*.sh

# Add to Claude Code settings (see Hooks section)
```

---

## FAQ

**Q: What stops agents from giving up?**

A: The persistence system detects "give up" language and blocks it, forcing continued effort with escalating re-engagement prompts, model upgrades, and Bug Council activation.

**Q: How does model escalation work?**

A: After 2 consecutive failures at a tier, the model upgrades (haiku→sonnet→opus). After 3 opus failures, Bug Council activates.

**Q: Can agents modify files outside their scope?**

A: No. The scope validator has VETO power and blocks all out-of-scope changes. Agents log observations for out-of-scope issues instead.

**Q: What triggers the Bug Council?**

A: Critical bugs, 2+ failed attempts, complexity ≥10, or explicit flag.

**Q: How do I customize agent selection?**

A: Edit `.devteam/agent-capabilities.yaml` to add triggers, keywords, and file patterns.

---

## Contributing

Contributions welcome! Areas of interest:
- Additional language support
- New enterprise agent roles
- Improved selection algorithms
- Integration with more tools

---

## Credits & Acknowledgments

This project draws inspiration from and builds upon several pioneering projects in the AI-assisted development space.

### Direct Inspirations (Claude Code Ecosystem)

These projects directly influenced our design and implementation:

| Project | What We Learned | Link |
|---------|-----------------|------|
| **ralph-claude-code** | The Ralph autonomous loop concept, EXIT_SIGNAL pattern, circuit breaker for stagnation detection, dual-condition exit gates, `.ralph/` directory structure pattern | [github.com/frankbria/ralph-claude-code](https://github.com/frankbria/ralph-claude-code) |
| **everything-claude-code** | Specialized agent delegation pattern, cross-platform hook architecture, subagent orchestration strategies, skill/agent separation | [github.com/affaan-m/everything-claude-code](https://github.com/affaan-m/everything-claude-code) |
| **awesome-claude-skills** | Skill organization patterns, YAML frontmatter structure, category-based skill taxonomy | [github.com/ComposioHQ/awesome-claude-skills](https://github.com/ComposioHQ/awesome-claude-skills) |
| **wshobson/agents** | Tiered model assignment (Opus/Sonnet/Haiku), plugin architecture patterns, token efficiency strategies, 72-plugin modular design | [github.com/wshobson/agents](https://github.com/wshobson/agents) |
| **ui-ux-pro-max-skill** | Design system generation patterns, industry-specific rule sets, Master+Overrides architecture concept | [github.com/nextlevelbuilder/ui-ux-pro-max-skill](https://github.com/nextlevelbuilder/ui-ux-pro-max-skill) |

### What We Built Upon (Our Additions)

While inspired by these projects, we developed original implementations:

| Feature | Inspiration Source | Our Original Addition |
|---------|-------------------|----------------------|
| **Ralph Quality Loop** | ralph-claude-code's autonomous loop | Added model escalation (haiku→sonnet→opus), Bug Council activation, quality gates integration |
| **Model Escalation** | wshobson/agents tier concept | Automatic escalation after consecutive failures, complexity-based initial selection, de-escalation after success |
| **Bug Council** | Original concept | 5-agent multi-perspective debugging system with synthesized solutions |
| **Scope Enforcement** | Original concept | 6-layer enforcement with VETO power, out-of-scope observations logging |
| **Anti-Abandonment** | Original concept | Persistence hooks detecting "give up" patterns, escalating re-engagement prompts |
| **Agent Selection** | everything-claude-code delegation | Weighted scoring algorithm (keywords 40%, files 30%, task type 20%, language 10%) |
| **Enterprise Agents** | wshobson/agents categories | SRE, Platform Engineer, Compliance Engineer, Penetration Tester, and 8 other enterprise roles |

### Broader Ecosystem Inspirations

| Project | Inspiration | Link |
|---------|-------------|------|
| **Aider** | Iterative code refinement and "linting loops" | [github.com/paul-gauthier/aider](https://github.com/paul-gauthier/aider) |
| **AutoGPT** | Multi-agent orchestration patterns | [github.com/Significant-Gravitas/AutoGPT](https://github.com/Significant-Gravitas/AutoGPT) |
| **MetaGPT** | Role-based agents, "committee of experts" | [github.com/geekan/MetaGPT](https://github.com/geekan/MetaGPT) |
| **GPT-Engineer** | PRD-to-code workflows | [github.com/gpt-engineer-org/gpt-engineer](https://github.com/gpt-engineer-org/gpt-engineer) |
| **Sweep AI** | Automated bug fixing patterns | [github.com/sweepai/sweep](https://github.com/sweepai/sweep) |
| **OpenHands** | Agent-computer interfaces | [github.com/All-Hands-AI/OpenHands](https://github.com/All-Hands-AI/OpenHands) |
| **SWE-agent** | Software engineering agent design | [github.com/princeton-nlp/SWE-agent](https://github.com/princeton-nlp/SWE-agent) |

### Standards & Frameworks Referenced

- **OWASP Top 10** - Security testing methodology
- **WCAG 2.1** - Accessibility compliance standards
- **SOC2/HIPAA/GDPR/PCI-DSS** - Compliance frameworks
- **Google SRE** - Site Reliability Engineering practices
- **The Twelve-Factor App** - Modern application design principles

### Originality Statement

All code in this repository was written from scratch. While we adopted concepts and patterns from the above projects (particularly the Ralph loop concept from frankbria/ralph-claude-code), our implementations are original:

- Our hooks use different file structures (`.devteam/` vs `.ralph/`)
- Our Ralph config uses YAML with model escalation (original uses INI without escalation)
- Our agent definitions follow a different structure
- Bug Council, scope enforcement, and anti-abandonment are entirely original systems

We believe in standing on the shoulders of giants while contributing our own innovations back to the community.

---

## License

MIT License - See LICENSE file.

---

**Built with Claude Code** - Enterprise-grade autonomous development.
