# Context and Scope Management Assessment

## Executive Summary

After thorough analysis of the codebase, I've identified the current state of context and scope management across 128 agents and their orchestration systems. While there are foundational mechanisms in place, several gaps exist that could lead to:
- **Excessive token usage** during implementation phases
- **Scope creep** during task execution
- **Inconsistent context handling** between planning and implementation phases

---

## Current State Analysis

### 1. Context Management - What Exists

| Component | Location | Purpose | Status |
|-----------|----------|---------|--------|
| **Pre-compact hook** | `hooks/pre-compact.sh` | Preserves critical state before context compaction | Implemented |
| **State file** | `.devteam/state.yaml` | Persistent execution state with model history | Implemented |
| **Eco mode summarization** | `ralph-config.yaml:435-449` | Token-optimized context passing | Documented, not enforced |
| **Model escalation context** | `ralph-config.yaml:277-307` | Adds error context on retry | Implemented |
| **Learned patterns** | `state-schema.yaml:342-361` | Cross-session pattern storage | Schema defined |

### 2. Scope Management - What Exists

| Component | Location | Purpose | Status |
|-----------|----------|---------|--------|
| **Scope Validator Agent** | `agents/orchestration/scope-validator.md` | VETO authority over out-of-scope changes | Implemented |
| **Base Agent Scope Rules** | `agents/templates/base-agent.md:119-143` | Scope compliance directives | Template defined |
| **Out-of-scope Observations** | Referenced in base-agent.md | Log issues found outside scope | Documented, logging only |
| **Task Scope Schema** | Shown in scope-validator examples | allowed_files, forbidden_directories | Example only, no schema |

### 3. Planning vs Implementation Phase Handling

| Phase | Current Context Strategy | Current Scope Strategy |
|-------|-------------------------|------------------------|
| **Research** | Full codebase access | Read-only, no restrictions |
| **Planning** | Full task/dependency visibility | No write restrictions (reads only) |
| **Implementation** | Full context + failure history | Scope-constrained (validated post-hoc) |
| **Quality Gates** | Changed files + test output | Read-only of affected files |

---

## Critical Gaps Identified

### Gap 1: No Task-Level Context Specification
**Issue:** Tasks don't define what context they need, leading to over-provision.

**Current state:** Agent receives all available information regardless of relevance.
```yaml
# Current task structure (implicit)
task:
  id: TASK-042
  description: "Fix session timeout bug"
  acceptance_criteria: [...]
  # NO context specification
```

**Impact:** Token waste on irrelevant context; implementation agents reading files they don't need.

---

### Gap 2: Scope Validation Happens Post-Hoc
**Issue:** The Scope Validator runs AFTER changes are made, not proactively.

**Current flow:**
```
Agent makes changes → Scope Validator checks → VETO if violated → Revert required
```

**Impact:** Wasted tokens on generating code that gets reverted; agents don't have scope awareness during generation.

---

### Gap 3: No Read Restrictions for Implementation Agents
**Issue:** Agents can read ANY file for "context," even when not relevant.

**Evidence from `base-agent.md:122-123`:**
```yaml
### Allowed Actions
- Read any file for context  # ← No restrictions
```

**Impact:** Agents may read large files unnecessarily, consuming context window tokens.

---

### Gap 4: Eco Mode Summarization Not Active
**Issue:** The eco mode context summarization in `ralph-config.yaml` is well-documented but has no enforcement mechanism.

**Current config (lines 435-449):**
```yaml
summarization:
  enabled: true
  between_agents: true
  max_context_tokens: 8000
  preserve:
    - error_messages
    - file_paths
    - test_results
```

**Missing:** No code/hook that actually performs this summarization before passing context.

---

### Gap 5: Planning Phase Lacks Explicit "Unrestricted" Marker
**Issue:** Research and planning agents should have explicit full-context access, but this isn't formally documented.

**Impact:** Inconsistent behavior; possibility of accidentally restricting planning context.

---

### Gap 6: No Context Token Tracking
**Issue:** No metrics on context tokens used per agent call.

**Evidence:** `state-schema.yaml` tracks model usage (haiku/sonnet/opus counts) but not token consumption.

**Impact:** Can't measure optimization effectiveness.

---

### Gap 7: Task Definitions Lack Scope Fields
**Issue:** There's no standardized task schema that includes scope constraints.

**Current:** Scope is only shown as an example in `scope-validator.md`, not in any task generation or schema document.

---

## Implementation Plan

### Phase 1: Define Context and Scope Schema (Foundation)

**Objective:** Create standardized schemas for task context and scope that all agents respect.

#### 1.1 Create Task Context Specification Schema
**Location:** `.devteam/task-schema.yaml` (new file)

```yaml
task_context_schema:
  version: "1.0"

  context:
    # Required context for this task
    required_files:
      type: array
      description: "Files agent MUST read to complete task"
      example: ["src/auth/session.ts", "src/types/auth.d.ts"]

    required_context:
      type: object
      properties:
        error_details: { type: boolean }
        test_output: { type: boolean }
        related_files: { type: boolean }
        architecture_docs: { type: boolean }

    # Context that would help but isn't required
    optional_files:
      type: array
      description: "Files that may provide useful context"

    # Maximum context target (eco mode)
    max_tokens:
      type: integer
      description: "Target context window size"
      default: 32000
      eco_mode: 8000

  scope:
    # Files allowed to modify
    allowed_files:
      type: array
      description: "Exact file paths that can be modified"

    allowed_patterns:
      type: array
      description: "Glob patterns for allowed modifications"

    forbidden_files:
      type: array
      description: "Files explicitly forbidden from modification"

    forbidden_directories:
      type: array
      description: "Directories completely off-limits"

    max_files_changed:
      type: integer
      description: "Maximum files this task should modify"
```

#### 1.2 Add Phase Context Markers
**Location:** Update `.devteam/config.yaml`

```yaml
phase_context:
  research:
    context_restrictions: none
    scope_restrictions: read_only
    max_tokens: unlimited
    purpose: "Full codebase exploration for discovery"

  planning:
    context_restrictions: none
    scope_restrictions: none
    max_tokens: unlimited
    purpose: "Complete visibility for accurate planning"

  implementation:
    context_restrictions: task_defined
    scope_restrictions: task_defined
    max_tokens: complexity_based
    purpose: "Focused execution within defined boundaries"

  validation:
    context_restrictions: changed_files_only
    scope_restrictions: read_only
    max_tokens: 16000
    purpose: "Verify changes meet requirements"
```

---

### Phase 2: Implement Proactive Context Filtering

**Objective:** Filter context BEFORE it reaches implementation agents.

#### 2.1 Create Context Manager Skill
**Location:** `agents/skills/context-manager.md` (new file)

**Purpose:** Pre-processes and filters context based on task requirements.

**Key behaviors:**
- Reads task context specification
- Filters available context to required + optional files only
- Summarizes large files when in eco mode
- Tracks token usage for reporting

**Integration point:** Called by Task Loop before invoking implementation agents.

#### 2.2 Update Task Loop to Use Context Manager
**Location:** Update `agents/orchestration/task-loop.md`

**Add before Step 1 (Implementation):**
```yaml
step_0_context_preparation:
  agent: "skills:context-manager"
  input:
    - task_definition (with context spec)
    - execution_mode (normal/eco)
    - iteration_number

  output:
    - filtered_context
    - token_count
    - context_summary (for state tracking)

  rules:
    - If iteration > 1: Include failure context
    - If eco_mode: Summarize optional context
    - If planning_phase: Skip filtering (full context)
```

---

### Phase 3: Implement Proactive Scope Enforcement

**Objective:** Make agents scope-aware DURING generation, not just after.

#### 3.1 Create Scope Injection Template
**Location:** Update `agents/templates/base-agent.md`

Add new section:
```markdown
## TASK-SPECIFIC SCOPE (Injected at Runtime)

When assigned a task, your scope constraints are:

SCOPE_INJECTION:
  can_modify:
    files: {{allowed_files}}
    patterns: {{allowed_patterns}}

  cannot_modify:
    files: {{forbidden_files}}
    directories: {{forbidden_directories}}

  max_files: {{max_files_changed}}

  on_out_of_scope_need:
    action: log_observation
    location: .devteam/out-of-scope-observations.md
    do_not: modify the file yourself

**CRITICAL:** Before modifying ANY file, verify it against your scope.
If not in scope, DO NOT modify. Log an observation instead.
```

#### 3.2 Create Pre-Modification Scope Check Hook
**Location:** `hooks/pre-edit.sh` (new file)

**Purpose:** Hook that fires before Edit/Write tools, validates against task scope.

**Behavior:**
1. Read current task's scope from state file
2. Compare target file against scope rules
3. If out-of-scope: Block modification, return error with guidance
4. If in-scope: Allow modification

**Configuration in hooks.yaml:**
```yaml
hooks:
  pre_edit:
    script: "hooks/pre-edit.sh"
    applies_to: [Edit, Write]
    exit_codes:
      0: allow
      1: block_out_of_scope
      2: log_warning_but_allow
```

#### 3.3 Update Task Definition Generator
**Location:** Update planning agents (PRD generator, task breakdown)

Ensure every generated task includes scope:
```yaml
task:
  id: TASK-042
  # ... existing fields ...

  scope:
    allowed_files:
      - "src/auth/session.ts"
      - "src/auth/middleware.ts"
    allowed_patterns:
      - "tests/auth/**/*.test.ts"
    forbidden_files:
      - "src/auth/oauth.ts"  # Different feature
    forbidden_directories:
      - "src/api/"  # Not auth-related
      - "src/database/"  # Schema changes separate task
    max_files_changed: 5
```

---

### Phase 4: Implement Context Token Tracking

**Objective:** Measure and optimize context usage.

#### 4.1 Extend State Schema for Token Tracking
**Location:** Update `.devteam/state-schema.yaml`

Add to task tracking:
```yaml
tasks:
  TASK-XXX:
    # ... existing fields ...

    context_metrics:
      type: object
      properties:
        total_context_tokens:
          type: integer
          description: "Total tokens used across all iterations"
        context_per_iteration:
          type: array
          items:
            type: object
            properties:
              iteration: { type: integer }
              input_tokens: { type: integer }
              filtered_files: { type: integer }
              full_files: { type: integer }

        optimization_savings:
          type: object
          properties:
            tokens_saved: { type: integer }
            files_filtered: { type: integer }
```

#### 4.2 Add Context Metrics to Sprint Summary
**Location:** Update `agents/orchestration/sprint-orchestrator.md`

Add to sprint summary report:
```markdown
## Context Optimization Metrics

| Task | Context Tokens | Saved vs Full | Files Filtered |
|------|----------------|---------------|----------------|
| TASK-001 | 8,234 | 67% | 12/18 |
| TASK-004 | 12,456 | 54% | 8/15 |
| TASK-008 | 5,890 | 78% | 15/22 |

**Sprint Totals:**
- Total context tokens used: 142,567
- Estimated savings: 58% (vs unfiltered)
- Average files filtered per task: 11.7
```

---

### Phase 5: Enhanced Planning Phase Context

**Objective:** Explicitly document unrestricted context for planning.

#### 5.1 Update Research Agent
**Location:** Update `agents/research/research-agent.md`

Add explicit context section:
```markdown
## Context Access

**This agent operates in UNRESTRICTED context mode.**

### Why Unrestricted
Research requires full codebase visibility to:
- Discover patterns across all modules
- Identify hidden dependencies
- Find similar implementations
- Assess technical debt that may affect planning

### Context Rules
context_mode: unrestricted
read_access: all_files
write_access: none (research artifacts only)
token_limit: none
scope_restrictions: none

**No context filtering is applied to this agent.**
```

#### 5.2 Update Sprint Planner
**Location:** Update `agents/planning/sprint-planner.md`

Add similar section:
```markdown
## Context Access

**This agent operates in UNRESTRICTED context mode during planning.**

### Planning Context Rules
context_mode: unrestricted
purpose: "Accurate dependency analysis requires full visibility"
read_access:
  - all task definitions
  - all dependency information
  - project structure
  - state file
write_access:
  - sprint files only
  - state file
scope_restrictions: none

**Context filtering is NOT applied during planning phases.**
```

---

### Phase 6: Integration and Validation

#### 6.1 Create Context/Scope Validation Test Suite
**Location:** `tests/context-scope/` (new directory)

Test cases:
1. Task with context spec - verify only specified files loaded
2. Eco mode - verify summarization applied
3. Pre-edit hook - verify out-of-scope modifications blocked
4. Planning phase - verify full context available
5. Token tracking - verify metrics recorded correctly

#### 6.2 Update Agent Capability Index
**Location:** Update `.devteam/agent-capabilities.yaml`

Add context/scope awareness markers:
```yaml
agents:
  - id: api_developer_python
    # ... existing fields ...
    context_mode: task_defined
    scope_enforced: true

  - id: research_agent
    context_mode: unrestricted
    scope_enforced: false

  - id: sprint_planner
    context_mode: unrestricted
    scope_enforced: false
```

---

## Implementation Priority

| Phase | Priority | Effort | Impact |
|-------|----------|--------|--------|
| **Phase 1:** Schema Definition | HIGH | Low | Foundation for all other phases |
| **Phase 3:** Proactive Scope Enforcement | HIGH | Medium | Prevents scope creep, saves revert cycles |
| **Phase 2:** Context Filtering | MEDIUM | Medium | Token optimization |
| **Phase 5:** Planning Phase Context | MEDIUM | Low | Documentation/clarity |
| **Phase 4:** Token Tracking | LOW | Medium | Metrics for optimization validation |
| **Phase 6:** Validation | LOW | Medium | Ensures system works correctly |

---

## Expected Outcomes

After implementation:

1. **Token Usage Reduction:** 40-60% reduction in context tokens for implementation tasks
2. **Scope Compliance:** Zero out-of-scope modifications (blocked proactively vs. reverted)
3. **Clear Phase Boundaries:** Explicit documentation of unrestricted planning vs. restricted implementation
4. **Measurable Optimization:** Token metrics in sprint summaries for continuous improvement
5. **Consistent Task Format:** Every task includes context and scope specifications

---

## Files to Create/Modify

### New Files
1. `.devteam/task-schema.yaml` - Task context and scope schema
2. `agents/skills/context-manager.md` - Context filtering skill
3. `hooks/pre-edit.sh` - Pre-modification scope check hook
4. `tests/context-scope/` - Validation test suite

### Modified Files
1. `.devteam/config.yaml` - Add phase context markers
2. `.devteam/state-schema.yaml` - Add context metrics tracking
3. `agents/orchestration/task-loop.md` - Add context preparation step
4. `agents/templates/base-agent.md` - Add scope injection template
5. `agents/research/research-agent.md` - Add explicit unrestricted context
6. `agents/planning/sprint-planner.md` - Add explicit unrestricted context
7. `agents/orchestration/sprint-orchestrator.md` - Add context metrics to summary
8. `.devteam/agent-capabilities.yaml` - Add context/scope markers
