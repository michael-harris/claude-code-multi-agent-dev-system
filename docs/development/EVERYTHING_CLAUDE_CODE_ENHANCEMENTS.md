# Enhancements from everything-claude-code

> **Note:** This is a historical development document. References to T1/T2 tiers and dynamic model selection have been superseded. The system now uses explicit model assignments (haiku/sonnet/opus) in agent YAML frontmatter and plugin.json, with orchestrators handling escalation via LLM instructions.

Analysis of functionality from [everything-claude-code](https://github.com/affaan-m/everything-claude-code) that could enhance the multi-agent system while maintaining user-friendliness.

---

## Design Principle

**Hidden complexity, surfaced when needed.** Features should:
- Work automatically in the background
- Not require user configuration unless they want customization
- Enhance existing workflows without changing them
- Be discoverable but not intrusive

---

## Priority 1: Critical for Autonomous Mode

### 1.1 Session Memory Persistence

**What it does:** Saves Claude's context and learnings across sessions, enabling continuity when sessions end due to context limits or interruptions.

**Why it's valuable:** Currently, if a session ends mid-sprint, Claude loses all context about what was tried, what worked, and what failed. The state file tracks *completion status* but not *learnings*.

**Implementation:**

```
.multi-agent/
└── memory/
    ├── session-{timestamp}.md    # Per-session learnings
    └── patterns.yaml             # Extracted successful patterns
```

**Session memory format:**
```markdown
# Session Memory - 2025-01-28T10:30:00Z

## Context
- Working on: SPRINT-002
- Current task: TASK-008 (API Authentication)

## What Worked
- Using `uv run pytest -v` with coverage flags
- Database connection pattern from TASK-003

## What Failed
- Initial JWT implementation had key rotation issues
- Fixed by: Adding refresh token endpoint

## Recommendations for Next Session
- Continue from TASK-008, iteration 3
- Review auth middleware before proceeding
```

**Hooks needed:**
```json
{
  "SessionEnd": "Save current context to memory file",
  "SessionStart": "Load most recent memory file into context",
  "PreCompact": "Save state before context compaction"
}
```

**User experience:**
- **Automatic:** Memory saved/loaded without user action
- **Optional:** `/devteam:memory show` to view, `/devteam:memory clear` to reset

---

### 1.2 Strategic Context Compaction

**What it does:** Intelligently manages context window during long autonomous runs, preserving critical information while removing exploration noise.

**Why it's valuable:** Autonomous mode will hit context limits. Without strategic compaction, Claude loses important context randomly.

**Implementation:**

Add to session state (stored in SQLite at `.devteam/devteam.db`):
```bash
source scripts/state.sh
set_state "compaction_strategy" "strategic"
set_state "preserve_always" "Current sprint/task context, Unresolved errors, Quality gate failures"
set_state "safe_to_compact" "Exploration of failed approaches, Verbose tool outputs, Completed task details"
```

**Automatic behavior:**
- Before compaction, save critical state to memory file
- After compaction, reload essential context
- Summarize completed work rather than discarding

**User experience:**
- **Automatic:** Happens transparently during long runs
- **Optional:** `/devteam:compact now` to manually trigger

---

## Priority 2: Enhances Quality & Reliability

### 2.1 Build Error Resolution Agent

**What it does:** Specialized agent for fixing build/compilation errors with minimal code changes.

**Why it's valuable:** Current agents may over-fix when encountering build errors. A focused agent makes minimal changes to get builds green.

**Implementation:**

```markdown
# agents/quality/build-error-resolver.md

**Model:** sonnet (fast, focused)
**Purpose:** Fix build errors with minimal diffs - NO architectural changes

## Workflow

1. Run build command, capture all errors
2. Categorize errors:
   - Type errors → Add annotations
   - Import errors → Fix paths
   - Missing dependencies → Add imports
   - Null/undefined → Add checks
3. Apply smallest possible fix for each
4. Re-run build to verify
5. If new errors, repeat (max 3 cycles)

## CRITICAL CONSTRAINTS

DO:
- Add type annotations
- Fix import paths
- Add null checks
- Update type definitions

DO NOT:
- Refactor working code
- Change architecture
- Rename variables
- Add features
```

**Integration:**
- Called automatically by task-loop when build fails
- Runs before escalating to T2
- Reduces unnecessary T2 escalations

**User experience:**
- **Automatic:** Invoked on build failures
- **Hidden:** User just sees "fixing build errors..." in progress

---

### 2.2 Verification Checkpoints

**What it does:** Git-based savepoints with verification criteria at key workflow milestones.

**Why it's valuable:** Enables rollback if autonomous execution goes off track, and provides verification gates beyond acceptance criteria.

**Implementation:**

Add checkpoint tracking to SQLite (`.devteam/devteam.db`):
```bash
source scripts/state.sh
set_state "checkpoint_pre_sprint_002" '{"name":"pre-sprint-002","commit_sha":"abc123","tests_passing":45,"coverage":"82%","build_status":"green"}'
set_state "checkpoint_post_task_008" '{"name":"post-task-008","commit_sha":"def456","tests_passing":52,"coverage":"85%","build_status":"green"}'
```

**Automatic checkpoints:**
- Before each sprint starts
- After each sprint completes
- Before any destructive operation

**Commands (optional exposure):**
```
/devteam:checkpoint list          # Show checkpoints
/devteam:checkpoint restore NAME  # Rollback to checkpoint
/devteam:checkpoint verify        # Compare current vs last
```

**User experience:**
- **Automatic:** Checkpoints created silently
- **Safety net:** Available for recovery if needed

---

### 2.3 Structured Agent Handoffs

**What it does:** Formalizes the context passed between agents with a standard handoff document.

**Why it's valuable:** Improves agent-to-agent communication, reduces context loss, enables better debugging.

**Implementation:**

Handoff document schema (internal, not user-facing):
```yaml
# Generated automatically between agents
handoff:
  from_agent: "database:developer-python-t2"
  to_agent: "backend:api-developer-python-t1"
  timestamp: "2025-01-28T11:30:00Z"

  context:
    task: "TASK-005"
    iteration: 2

  completed_work:
    - "Created User model with SQLAlchemy"
    - "Added Alembic migration 001_create_users"

  files_modified:
    - "src/models/user.py"
    - "alembic/versions/001_create_users.py"

  key_decisions:
    - "Used UUID for primary key (requirement R-003)"
    - "Added soft delete (deleted_at column)"

  open_questions:
    - "Should password hashing use bcrypt or argon2?"

  recommendations:
    - "API endpoints should use UserSchema for validation"
    - "Include pagination for list endpoints"
```

**Integration:**
- Task loop generates handoff when switching agents
- Receiving agent gets handoff as part of prompt
- Handoffs stored in `.multi-agent/handoffs/` for debugging

**User experience:**
- **Completely hidden:** Internal agent communication
- **Debugging:** Available in logs if something goes wrong

---

## Priority 3: Nice-to-Have Enhancements

### 3.1 Expanded Hooks System

**What it does:** Lifecycle hooks for various events during execution.

**Current hooks needed (for Task Loop functionality - Option 3):**
- `Stop` - Check completion, block premature exit
- `SessionStart` - Load memory, initialize state
- `SessionEnd` - Save memory, persist learnings

**Additional useful hooks:**
```json
{
  "PreToolUse": {
    "Bash(npm|yarn|pnpm)": "Suggest running in background for long operations",
    "Bash(git push)": "Remind to review changes first"
  },
  "PostToolUse": {
    "Edit(*.ts|*.tsx)": "Run type check in background",
    "Edit(*.py)": "Run ruff check in background"
  },
  "PostTask": {
    "*": "Auto-create checkpoint"
  },
  "PostSprint": {
    "*": "Generate sprint summary, create checkpoint"
  }
}
```

**User experience:**
- **Automatic:** Hooks run silently
- **Configurable:** `.multi-agent/hooks.yaml` for customization (advanced users)

---

### 3.2 Continuous Learning / Pattern Extraction

**What it does:** Automatically extracts successful patterns from completed work to improve future executions.

**Why it's valuable:** Over time, the system learns project-specific patterns (e.g., "this project uses argon2 for passwords").

**Implementation:**

```yaml
# .multi-agent/learned-patterns.yaml
patterns:
  - id: "password-hashing"
    confidence: 0.9
    learned_from: ["TASK-003", "TASK-012"]
    pattern: "Use argon2id for password hashing"
    context: "Authentication implementations"

  - id: "api-pagination"
    confidence: 0.85
    learned_from: ["TASK-007", "TASK-015"]
    pattern: "Use cursor-based pagination for list endpoints"
    context: "API endpoint implementations"
```

**Extraction triggers:**
- After task completes successfully
- After quality gates pass
- When similar patterns appear 2+ times

**Usage:**
- Injected into agent prompts when relevant context matches
- Higher confidence patterns weighted more heavily

**User experience:**
- **Automatic:** Learning happens silently
- **Optional:** `/devteam:patterns show` to view learned patterns
- **Optional:** `/devteam:patterns import FILE` to import from another project

---

### 3.3 Package Manager Auto-Detection

**What it does:** Automatically detects and uses the correct package manager.

**Current state:** Multi-agent system specifies `uv` for Python, `npm` for TypeScript, etc.

**Enhancement:**
```yaml
# Auto-detected and stored in state
detected_tools:
  python:
    package_manager: "uv"        # uv | pip | poetry | pdm
    test_runner: "pytest"        # pytest | unittest | nose
    linter: "ruff"               # ruff | flake8 | pylint
  typescript:
    package_manager: "pnpm"      # npm | yarn | pnpm | bun
    test_runner: "vitest"        # jest | vitest | mocha
    linter: "eslint"             # eslint | biome
```

**Detection logic (SessionStart):**
```
If uv.lock exists → uv
Else if poetry.lock exists → poetry
Else if Pipfile.lock exists → pipenv
Else if requirements.txt exists → pip
Else → default to uv (create new project)
```

**User experience:**
- **Automatic:** Detected on first run, stored in state
- **Override:** User can set in state file if detection is wrong

---

## What NOT to Add (Already Covered)

| everything-claude-code | Multi-Agent Equivalent |
|------------------------|------------------------|
| TDD Guide Agent | test-writer agent |
| Code Reviewer Agent | 7 language-specific code reviewers |
| Security Reviewer | security-auditor agent |
| Architect Agent | api-designer + database-designer |
| Planner Agent | task-graph-analyzer + sprint-planner |
| E2E Runner | runtime-verifier agent |
| Doc Updater | documentation-coordinator agent |

---

## Implementation Roadmap

### Phase 1: Autonomous Mode Foundation (with Task Loop Option 3)
1. **Session Memory Persistence** - Required for autonomous continuity
2. **Stop Hook** - Required for Task Loop-style loop
3. **State file extensions** - `autonomous_mode`, `circuit_breaker`, `memory`

### Phase 2: Quality Enhancements
4. **Build Error Resolver Agent** - Reduces T2 escalations
5. **Verification Checkpoints** - Safety net for autonomous runs
6. **Structured Agent Handoffs** - Better agent communication

### Phase 3: Learning & Optimization
7. **Pattern Extraction** - Continuous improvement
8. **Expanded Hooks** - Type checking, linting automation
9. **Package Manager Detection** - Project adaptability

---

## Files to Create/Modify

### New Files
```
agents/quality/build-error-resolver.md
hooks/
├── stop-hook.sh
├── session-start.sh
├── session-end.sh
└── README.md
commands/auto.md
commands/checkpoint.md (optional)
commands/memory.md (optional)
commands/patterns.md (optional)
```

### Modified Files
```
docs/development/state-management-guide.md  # Add new state fields
agents/orchestration/sprint-orchestrator.md  # Add handoff generation
agents/orchestration/task-loop.md    # Add checkpoint creation
plugin.json                                   # Register new agents/commands
```

### New State Fields (stored in SQLite)
```bash
# State is now stored in SQLite at .devteam/devteam.db
# Access via: source scripts/state.sh
# Previous .project-state.yaml has been replaced by SQLite tables.

# Session state key-value pairs stored in session_state table:
set_state "autonomous_mode_enabled" "true"
set_state "max_iterations" "50"
set_state "current_iteration" "12"
set_state "circuit_breaker" '{"consecutive_failures":0,"max_failures":5}'
set_state "memory_last_session" "2025-01-28T10:00:00Z"
set_state "checkpoints" '[{"name":"post-sprint-001","sha":"abc123"}]'
set_state "learned_patterns" '[{"id":"password-hashing","confidence":0.9}]'
set_state "detected_tools" '{"python":{"package_manager":"uv","linter":"ruff"}}'
```

---

## Summary

| Enhancement | User Impact | Implementation Effort | Priority |
|-------------|-------------|----------------------|----------|
| Session Memory | Invisible (automatic) | Medium | P1 |
| Context Compaction | Invisible (automatic) | Medium | P1 |
| Build Error Resolver | Invisible (faster fixes) | Low | P2 |
| Checkpoints | Hidden (safety net) | Low | P2 |
| Structured Handoffs | Hidden (internal) | Low | P2 |
| Hooks System | Invisible (automatic) | Medium | P3 |
| Pattern Learning | Optional visibility | High | P3 |
| Package Detection | Invisible (automatic) | Low | P3 |

All features follow the principle: **works automatically, user doesn't need to know it exists, but power users can access/configure if they want.**
