# DevTeam v3.0.0 Enhancements

**Release Date:** January 2026
**Previous Version:** 2.5.0

This major release introduces interview-driven planning, codebase research, SQLite state management, eco mode, and a streamlined command structure.

---

## Breaking Changes

### Command Restructure

| Old Command | New Command | Notes |
|-------------|-------------|-------|
| `/devteam:auto` | `/devteam:implement` | Renamed for clarity |
| `/devteam:sprint` | `/devteam:implement --sprint` | Consolidated into implement |
| `/devteam:feature` | `/devteam:plan --feature` | Absorbed into plan |
| `/devteam:prd` | `/devteam:plan` | Absorbed into plan |
| `/devteam:planning` | `/devteam:plan` | Absorbed into plan |

### State Management

- **YAML state files replaced with SQLite**
- Migration: Old `.devteam/state.yaml` files are no longer used
- New: `.devteam/devteam.db` contains all session state
- Run `bash scripts/db-init.sh` to initialize

---

## New Features

### 1. Interview System

All commands now support intelligent interview phases that clarify ambiguous requests before work begins.

```bash
# Bug reports get clarifying questions
/devteam:bug "Login doesn't work"
# → "What is the expected behavior?"
# → "What error message do you see?"
# → "What steps reproduce this?"
```

**Features:**
- Automatic ambiguity detection
- Context-aware question skipping
- Redirect to appropriate workflow (bug vs feature)
- `--no-interview` flag to skip

**Configuration:** `templates/interview-questions.yaml`

### 2. Research Phase in Planning

Planning now includes codebase research before generating PRDs.

```bash
/devteam:plan --feature "Add dark mode"
# → Phase 1: Interview
# → Phase 2: Research (NEW)
#   - Analyze existing codebase
#   - Identify patterns to follow
#   - Find potential blockers
#   - Generate recommendations
# → Phase 3: Follow-up questions from research
# → Phase 4: Generate PRD with research insights
```

**Research Agent Capabilities:**
- Codebase pattern discovery
- Technology compatibility checking
- Blocker identification
- Implementation recommendations

**Skip with:** `/devteam:plan --skip-research`

### 3. SQLite State Management

All session state now persists in SQLite for reliability and queryability.

```bash
# Initialize database
bash scripts/db-init.sh

# Query session history
sqlite3 .devteam/devteam.db "SELECT * FROM v_session_summary"

# Get cost breakdown
sqlite3 .devteam/devteam.db "SELECT * FROM v_model_usage"
```

**Tables:**
- `sessions` - Execution sessions
- `events` - Full event history
- `agent_runs` - Agent performance tracking
- `gate_results` - Quality gate results
- `escalations` - Model escalation history
- `interviews` - Interview responses
- `research_findings` - Research results
- `bugs` - Local bug tracking

**Helper Scripts:**
- `scripts/state.sh` - Bash state functions
- `scripts/events.sh` - Event logging functions
- `scripts/state.ps1` - PowerShell equivalents

### 4. Eco Mode

Cost-optimized execution mode with 30-50% savings.

```bash
/devteam:implement --eco
/devteam:bug "Minor issue" --eco
```

**Eco Mode Behavior:**
| Setting | Normal | Eco |
|---------|--------|-----|
| Initial model | Complexity-based | Haiku (mostly) |
| Escalation threshold | 2 failures | 4 failures |
| Context strategy | Full | Summarized |
| Gate execution | Parallel | Sequential |

**Exceptions (still get appropriate model):**
- Security tasks
- Architecture tasks
- Complexity ≥ 10

**Configuration:** `.devteam/ralph-config.yaml` → `execution_modes`

### 5. New Commands

#### `/devteam:status`

Display system health, progress, and cost analytics.

```bash
/devteam:status              # Current session
/devteam:status --history    # Recent sessions
/devteam:status --costs      # Cost breakdown
/devteam:status --agents     # Agent performance
```

#### `/devteam:reset`

Reset stuck sessions and recover from errors.

```bash
/devteam:reset                # Abort current session
/devteam:reset --clear-history  # Clear all history
/devteam:reset --full         # Full reset
```

#### `/devteam:bug`

Fix local bugs (not in GitHub) with structured diagnostic workflow.

```bash
/devteam:bug "description"     # With interview
/devteam:bug "desc" --council  # Force Bug Council
/devteam:bug "desc" --severity critical
```

### 6. New Agents

| Agent | Category | Purpose |
|-------|----------|---------|
| Research Agent | research | Codebase investigation before planning |
| Refactoring Agent | quality | Dedicated code restructuring |
| Ralph Orchestrator | orchestration | Quality loop management |
| Autonomous Controller | orchestration | Stop hooks and persistence |
| Bug Council Orchestrator | orchestration | Bug Council coordination |
| Scope Validator | orchestration | 6-layer scope enforcement |
| Root Cause Analyst | diagnosis | Bug Council - error analysis |
| Code Archaeologist | diagnosis | Bug Council - git history |
| Pattern Matcher | diagnosis | Bug Council - similar bugs |
| Systems Thinker | diagnosis | Bug Council - dependencies |
| Adversarial Tester | diagnosis | Bug Council - edge cases |

**Total Agents:** 89 (up from 76)

---

## Improvements

### Unified Command Structure

Before (confusing):
```bash
/devteam:auto "task"      # What does "auto" mean?
/devteam:sprint 1         # Separate from auto?
/devteam:feature "feat"   # Different from plan?
```

After (clear):
```bash
/devteam:plan             # Plan work
/devteam:implement        # Execute work
/devteam:bug              # Fix bugs
/devteam:issue            # Fix GitHub issues
```

### Better Progress Visibility

- Real-time status display
- Token/cost tracking per session
- Model usage breakdown
- Escalation history
- Quality gate results

### Automatic Worktree Management

Git worktrees for parallel track isolation are now **fully automatic**:

- **Auto-create**: Worktrees are created when executing multi-track plans
- **Auto-merge**: When all tracks complete, merges happen automatically
- **Auto-cleanup**: Worktrees are removed after successful merge
- **Hidden from users**: Users never need to interact with worktrees directly

For debugging, use `--show-worktrees` flag or debug commands:
```bash
/devteam:implement --sprint 1 --show-worktrees  # See worktree operations
/devteam:worktree-status                        # Debug: View worktree state
```

### Cross-Platform Support

All scripts now support both Linux/macOS (Bash) and Windows (PowerShell):
- `scripts/db-init.sh` / `scripts/db-init.ps1`
- `scripts/state.sh` / `scripts/state.ps1`
- All hooks have `.ps1` equivalents

---

## Migration Guide

### 1. Update Commands in Workflows

```bash
# Old
/devteam:auto "Add feature"
/devteam:sprint 1

# New
/devteam:implement "Add feature"
/devteam:implement --sprint 1
```

### 2. Initialize SQLite Database

```bash
cd your-project
bash scripts/db-init.sh
```

### 3. Update Hooks (if using custom)

Hooks now use SQLite. Update any custom hooks that read from `state.yaml`:

```bash
# Old
state=$(cat .devteam/state.yaml)

# New
source scripts/state.sh
current_agent=$(get_current_agent)
```

### 4. Review Configuration

New configuration sections in `.devteam/ralph-config.yaml`:
- `execution_modes` - Normal vs eco mode settings
- `execution_modes.eco.summarization` - Context compression settings

---

## Configuration Reference

### New Files

| File | Purpose |
|------|---------|
| `scripts/schema.sql` | SQLite database schema |
| `scripts/db-init.sh` | Database initialization |
| `scripts/state.sh` | State management functions |
| `scripts/events.sh` | Event logging functions |
| `templates/interview-questions.yaml` | Interview question templates |
| `agents/research/research-agent.md` | Research agent definition |
| `agents/quality/refactoring-agent.md` | Refactoring agent definition |
| `commands/devteam-implement.md` | New implement command |
| `commands/devteam-bug.md` | New bug command |
| `commands/devteam-status.md` | New status command |
| `commands/devteam-reset.md` | New reset command |

### Removed Files

| File | Reason |
|------|--------|
| `commands/devteam-auto.md` | Replaced by devteam-implement.md |
| `commands/devteam-sprint.md` | Consolidated into implement |
| `commands/feature.md` | Consolidated into plan |
| `commands/prd.md` | Consolidated into plan |
| `commands/planning.md` | Consolidated into plan |

---

## Upgrade Checklist

- [ ] Back up existing `.devteam/` directory
- [ ] Pull latest version
- [ ] Run `bash scripts/db-init.sh`
- [ ] Update any custom scripts using old commands
- [ ] Update any CI/CD pipelines using old commands
- [ ] Test with `/devteam:status` to verify installation
- [ ] Review eco mode settings for cost optimization

---

## Full Changelog

### Added
- Interview system for all commands
- Research phase in planning
- SQLite state management
- Eco mode for cost optimization
- `/devteam:implement` command
- `/devteam:bug` command
- `/devteam:status` command
- `/devteam:reset` command
- Research Agent
- Refactoring Agent
- 5 Bug Council diagnosis agents in plugin.json
- 4 orchestration agents in plugin.json
- Cross-platform PowerShell support
- Cost tracking and analytics
- Session history and queryable events
- **Automatic worktree management** - Worktrees are created, merged, and cleaned up automatically
- `--show-worktrees` debug flag for viewing worktree operations

### Changed
- `/devteam:auto` → `/devteam:implement`
- `/devteam:sprint` → `/devteam:implement --sprint`
- State management from YAML to SQLite
- Plugin version 2.5.0 → 3.0.0
- Agent count 76 → 89
- Worktree commands moved to debug category (auto-managed by default)

### Removed
- `/devteam:auto` command (use `/devteam:implement`)
- `/devteam:sprint` command (use `/devteam:implement --sprint`)
- `/devteam:feature` command (use `/devteam:plan --feature`)
- `/devteam:prd` command (use `/devteam:plan`)
- `/devteam:planning` command (use `/devteam:plan`)
- YAML-based state files

### Fixed
- Agent count inconsistency across documentation
- Missing Bug Council agents in plugin.json
- Missing orchestration agents in plugin.json
- Namespace inconsistencies (`/devteam:` → `/devteam:`)

---

## What's Next (Roadmap)

- [ ] Hot-reload skills (Claude Code 2.1 feature)
- [ ] Agent lifecycle hooks in frontmatter
- [ ] Session teleportation support
- [ ] Distributed multi-instance execution
- [ ] Web dashboard for monitoring
- [ ] Cost prediction before execution
