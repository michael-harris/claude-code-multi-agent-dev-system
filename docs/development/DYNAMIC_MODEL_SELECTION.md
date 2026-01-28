# Dynamic Model Selection System

Replace fixed T1/T2 agent tiers with intelligent, dynamic model selection based on task complexity and iteration position.

---

## Overview

**Current System:**
- 44 developer agents (22 T1 + 22 T2 pairs)
- Fixed escalation: iterations 1-2 use T1, iterations 3-5 use T2
- No consideration of task complexity

**Proposed System:**
- 22 developer agents (single version each)
- Dynamic model selection based on:
  1. Task complexity assessment
  2. Iteration position in loop
- Smarter resource allocation

---

## Model Tiers

| Tier | Model | Use Case | Cost |
|------|-------|----------|------|
| **Tier 0** | Haiku | Simple fixes, single-file changes | Lowest |
| **Tier 1** | Sonnet | Standard implementation, multi-file | Medium |
| **Tier 2** | Opus | Complex architecture, security-critical | Highest |

---

## Complexity Assessment

### Assessment Criteria

Performed automatically by task-orchestrator before first iteration.

```yaml
complexity_factors:
  # File scope (0-3 points)
  files_affected:
    1: 0          # Single file
    2-3: 1        # Few files
    4-7: 2        # Multiple files
    8+: 3         # Many files

  # Code volume (0-3 points)
  estimated_lines:
    0-50: 0       # Minor change
    51-150: 1     # Moderate change
    151-400: 2    # Significant change
    400+: 3       # Large change

  # Dependency complexity (0-2 points)
  new_dependencies:
    0: 0          # No new dependencies
    1-2: 1        # Few dependencies
    3+: 2         # Many dependencies

  # Task nature (0-3 points)
  task_type:
    bug_fix: 0              # Fix existing behavior
    enhancement: 1          # Add to existing feature
    new_feature: 2          # New capability
    architectural: 3        # System-level change

  # Risk factors (0-3 points)
  risk_indicators:
    security_sensitive: +2   # Auth, encryption, permissions
    external_integration: +1 # Third-party APIs
    database_migration: +1   # Schema changes
    breaking_change: +1      # API contract changes

# Total: 0-14 points
complexity_thresholds:
  simple: 0-4       # Start at Haiku
  moderate: 5-8     # Start at Sonnet
  complex: 9+       # Start at Opus
```

### Assessment Sources

The orchestrator determines complexity from:

1. **Task definition file** (`docs/planning/tasks/TASK-XXX.yaml`):
   ```yaml
   estimated_files: 3
   estimated_lines: 120
   dependencies: ["redis", "celery"]
   risk_flags: ["external_integration"]
   ```

2. **Acceptance criteria count and nature**:
   - More criteria = more complex
   - Criteria mentioning "security", "performance", "scale" = higher risk

3. **Task type** from workflow field:
   - `bug_fix` → simpler
   - `fullstack` → more complex

4. **Dependency analysis**:
   - Tasks depending on many others = more integration complexity

---

## Iteration Escalation Pattern

### Model Progression by Starting Tier

```
Starting Tier    Iter 1    Iter 2    Iter 3    Iter 4    Iter 5
─────────────────────────────────────────────────────────────────
Haiku (simple)   Haiku     Haiku     Sonnet    Sonnet    Opus
Sonnet (moderate) Sonnet    Sonnet    Opus      Opus      Opus
Opus (complex)   Opus      Opus      Opus      Opus      Opus
```

### Pseudocode

```python
def get_model_for_iteration(complexity_tier: str, iteration: int) -> str:
    """
    Determine model based on starting complexity and current iteration.

    Args:
        complexity_tier: "simple" | "moderate" | "complex"
        iteration: 1-5

    Returns:
        "haiku" | "sonnet" | "opus"
    """
    progression = {
        "simple": {
            1: "haiku",
            2: "haiku",
            3: "sonnet",
            4: "sonnet",
            5: "opus"
        },
        "moderate": {
            1: "sonnet",
            2: "sonnet",
            3: "opus",
            4: "opus",
            5: "opus"
        },
        "complex": {
            1: "opus",
            2: "opus",
            3: "opus",
            4: "opus",
            5: "opus"
        }
    }

    return progression[complexity_tier][iteration]
```

---

## Dynamic Adjustments

Beyond the base progression, adjust model selection dynamically:

### Downgrade Triggers (use simpler model)
- Validation failure is a simple type error → Haiku can fix
- Only test coverage is missing → Haiku can add tests
- Linting/formatting issues only → Haiku

### Upgrade Triggers (use more powerful model)
- Validation failure mentions "architecture" or "design"
- Multiple interconnected failures
- Same failure persists across 2 iterations
- Security-related validation failures

### Implementation

```yaml
# In state file, track per-iteration
model_selection:
  task: TASK-005
  assessed_complexity: moderate
  complexity_score: 7

  iterations:
    - iteration: 1
      base_model: sonnet
      adjusted_model: sonnet  # No adjustment
      reason: "Initial attempt"

    - iteration: 2
      base_model: sonnet
      adjusted_model: haiku   # Downgraded
      reason: "Failure was simple type error"

    - iteration: 3
      base_model: opus
      adjusted_model: opus    # No adjustment
      reason: "Escalation after 2 failures"
```

---

## Agent Consolidation

### Before (T1/T2 Pairs)

```
agents/database/
├── database-developer-python-t1.md   # Haiku
├── database-developer-python-t2.md   # Sonnet
├── database-developer-typescript-t1.md
├── database-developer-typescript-t2.md
... (14 files for 7 languages)
```

### After (Single Agent + Dynamic Model)

```
agents/database/
├── database-developer-python.md      # Model: dynamic
├── database-developer-typescript.md
├── database-developer-java.md
├── database-developer-csharp.md
├── database-developer-go.md
├── database-developer-ruby.md
├── database-developer-php.md
... (7 files for 7 languages)
```

### Agent Definition Change

**Before:**
```markdown
# Database Developer Python T1

**Model:** claude-haiku-3
**Tier:** T1
**Purpose:** Implements SQLAlchemy models (cost-optimized)
```

**After:**
```markdown
# Database Developer Python

**Model:** dynamic
**Purpose:** Implements SQLAlchemy models and Alembic migrations

## Model Selection

Model is determined dynamically by task-orchestrator based on:
- Task complexity assessment
- Current iteration in execution loop
- Validation failure analysis

This agent may run as Haiku, Sonnet, or Opus depending on context.
```

### Agents to Consolidate

| Category | Current | After | Reduction |
|----------|---------|-------|-----------|
| Database | 14 (7×2) | 7 | -7 |
| Backend API | 14 (7×2) | 7 | -7 |
| Frontend | 2 | 1 | -1 |
| Python Generic | 2 | 1 | -1 |
| Scripting | 4 (2×2) | 2 | -2 |
| Infrastructure | 2 | 1 | -1 |
| Mobile | 4 (2×2) | 2 | -2 |
| **Total** | **42** | **21** | **-21** |

---

## Task Orchestrator Changes

### New Complexity Assessment Step

Add before iteration loop:

```markdown
## Execution Process

1. **Check task status in state file** (existing)

2. **NEW: Assess Task Complexity**

   a. Read task definition from `docs/planning/tasks/TASK-XXX.yaml`

   b. Calculate complexity score:
      - Count files affected
      - Estimate lines of code
      - Check for risk indicators
      - Analyze acceptance criteria

   c. Determine starting tier:
      - Score 0-4: "simple" (start Haiku)
      - Score 5-8: "moderate" (start Sonnet)
      - Score 9+: "complex" (start Opus)

   d. Record in state file:
      ```yaml
      tasks:
        TASK-XXX:
          complexity_score: 7
          complexity_tier: moderate
          model_progression: [sonnet, sonnet, opus, opus, opus]
      ```

3. **Mark task as in_progress** (existing)

4. **Iterative Execution Loop:**

   FOR iteration 1 to 5:

   a. **NEW: Select model for this iteration**
      - Get base model from progression
      - Check for dynamic adjustments
      - Record selected model in state

   b. Execute workflow with selected model:
      - Call developer agent with `model` parameter
      - Example: `Task(agent="database:developer-python", model="sonnet")`

   c. Submit to requirements-validator (existing)

   d. **NEW: Analyze failure for model adjustment**
      - If simple failure type → note for potential downgrade
      - If complex failure type → note for potential upgrade

   e. Handle validation result (existing)
```

### Model Parameter Passing

When calling developer agents:

```javascript
// Current (T1 vs T2 selection)
if (iteration <= 2) {
    Task(agent="database:developer-python-t1", ...)
} else {
    Task(agent="database:developer-python-t2", ...)
}

// New (dynamic model)
const model = getModelForIteration(task.complexity_tier, iteration);
Task(
    agent="database:developer-python",
    model=model,  // "haiku" | "sonnet" | "opus"
    ...
)
```

---

## State File Changes

### New Fields

```yaml
tasks:
  TASK-XXX:
    status: in_progress

    # NEW: Complexity assessment
    complexity:
      score: 7
      tier: moderate           # simple | moderate | complex
      factors:
        files_affected: 3
        estimated_lines: 120
        new_dependencies: 1
        task_type: new_feature
        risk_flags: []

    # NEW: Model selection tracking
    model_history:
      - iteration: 1
        selected: sonnet
        reason: "Base progression (moderate complexity)"
      - iteration: 2
        selected: haiku
        reason: "Downgraded - failure was simple type error"
      - iteration: 3
        selected: opus
        reason: "Escalation after 2 attempts"

    # Existing fields
    iterations: 3
    validation_result: PASS
```

---

## Task Definition Enhancement

### Optional Complexity Hints

Task definitions can include hints to improve assessment accuracy:

```yaml
# docs/planning/tasks/TASK-XXX.yaml
id: TASK-005
name: User Authentication API
type: backend

# NEW: Optional complexity hints
complexity_hints:
  estimated_files: 4
  estimated_lines: 200
  risk_flags:
    - security_sensitive
    - external_integration

  # Override automatic assessment (optional)
  # force_tier: complex

acceptance_criteria:
  - User can register with email/password
  - Passwords are hashed with bcrypt
  - JWT tokens issued on login
  - Token refresh endpoint exists
  - Rate limiting on auth endpoints
```

---

## Benefits

### Cost Optimization

| Scenario | Current (T1→T2) | Dynamic | Savings |
|----------|-----------------|---------|---------|
| Simple task, passes iter 1 | Haiku | Haiku | Same |
| Simple task, passes iter 3 | Haiku→Sonnet | Haiku→Sonnet | Same |
| Complex task, passes iter 1 | Haiku | Opus | More quality |
| Moderate task, simple fix iter 2 | Haiku | Haiku (downgrade) | Cheaper |

### Quality Improvement

- Complex tasks get Opus from the start (no wasted Haiku attempts)
- Simple failures don't waste expensive Opus iterations
- Model matches task requirements

### Simplification

- 21 fewer agent files to maintain
- Single source of truth for each developer type
- Clearer mental model for users

---

## Migration Path

### Phase 1: Add Complexity Assessment
- Add complexity calculation to task-orchestrator
- Log assessments but don't change model selection yet
- Validate assessment accuracy

### Phase 2: Dynamic Selection (Parallel)
- Run both systems in parallel
- Compare outcomes
- Tune thresholds

### Phase 3: Consolidate Agents
- Merge T1/T2 agent pairs
- Update agent definitions to `model: dynamic`
- Update plugin.json

### Phase 4: Remove T1/T2
- Delete duplicate agent files
- Update documentation
- Full rollout

---

## Integration with Ralph Loop (Option 3)

The dynamic model selection integrates naturally with autonomous mode:

```yaml
autonomous_mode:
  enabled: true
  max_iterations: 50

  # Each task within the autonomous loop uses dynamic selection
  current_task:
    id: TASK-008
    complexity_tier: moderate
    current_iteration: 3
    current_model: opus

  # Global circuit breaker (separate from per-task iterations)
  circuit_breaker:
    consecutive_failures: 1
    max_failures: 5
```

The 5-iteration limit applies per-task, while the autonomous loop continues across tasks until all complete.

---

## Summary

| Aspect | Current | Proposed |
|--------|---------|----------|
| Developer agents | 42 (21 pairs) | 21 (single) |
| Model selection | Fixed (iter 1-2: T1, 3-5: T2) | Dynamic (complexity + iteration) |
| Simple task handling | Starts at Haiku regardless | Starts at Haiku |
| Complex task handling | Wastes 2 Haiku iterations | Starts at Opus |
| Failure recovery | Fixed escalation | Smart up/downgrade |
| State tracking | Tier used | Full model history |
