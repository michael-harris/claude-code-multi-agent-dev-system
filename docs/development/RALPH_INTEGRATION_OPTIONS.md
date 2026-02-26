# Task Loop Integration Options (from ralph-claude-code)

This document identifies the specific functionality from ralph-claude-code that this project lacked, and presents options for adding those capabilities natively.

---

## Functional Gap Analysis

### What ralph-claude-code Does That This Project Didn't

| Capability | ralph-claude-code | This Project | Gap |
|------------|-------|--------------|-----|
| **Continuous execution until done** | Loop re-injects prompt until complete | Executes within single session | **CRITICAL GAP** |
| **Stop interception** | Hook blocks Claude exit, re-prompts | No hook system | **CRITICAL GAP** |
| **Intelligent exit detection** | Dual-gate: completion indicators + EXIT_SIGNAL | State file status only | Moderate gap |
| **Rate limiting** | Tracks calls/hour, handles 5-hour limit | None | Moderate gap |
| **Circuit breaker** | Stops after N consecutive failures | Per-task only (5 iterations) | Moderate gap |
| **Real-time monitoring** | tmux dashboard | Text output only | Nice to have |
| **Session persistence** | Automatic continuation after interruption | Manual re-invocation required | **CRITICAL GAP** |

### The Core Problem

**This project requires the user to stay engaged.** If Claude's session ends, context limits hit, or the user closes their terminal, work stops. The user must manually re-run `/devteam:sprint all` to continue.

**ralph-claude-code lets you walk away.** The stop hook intercepts exit attempts and re-injects the prompt, creating a self-sustaining loop until the project is genuinely complete.

---

## Implementation Options

### Option 1: Claude Code Hooks (Recommended)

**Approach:** Use Claude Code's native hook system to intercept stop events and re-inject prompts.

**What to add:**

```
hooks/
├── stop-hook.sh        # Intercepts exit, checks completion, re-injects
└── post-message.sh     # Optional: tracks progress metrics
```

**`hooks/stop-hook.sh`:**
```bash
#!/bin/bash
# Task Loop-style stop hook for multi-agent system

DB_FILE=".devteam/devteam.db"
CIRCUIT_BREAKER_FILE=".multi-agent/circuit-breaker.json"

# Initialize circuit breaker if needed
if [ ! -f "$CIRCUIT_BREAKER_FILE" ]; then
    mkdir -p .multi-agent
    echo '{"consecutive_failures": 0, "total_iterations": 0}' > "$CIRCUIT_BREAKER_FILE"
fi

# Read circuit breaker state
FAILURES=$(jq -r '.consecutive_failures' "$CIRCUIT_BREAKER_FILE")
ITERATIONS=$(jq -r '.total_iterations' "$CIRCUIT_BREAKER_FILE")
MAX_FAILURES=5
MAX_ITERATIONS=100

# Check circuit breaker limits
if [ "$FAILURES" -ge "$MAX_FAILURES" ]; then
    echo "Circuit breaker OPEN: $FAILURES consecutive failures. Human intervention required."
    exit 0  # Allow exit
fi

if [ "$ITERATIONS" -ge "$MAX_ITERATIONS" ]; then
    echo "Maximum iterations ($MAX_ITERATIONS) reached. Stopping."
    exit 0  # Allow exit
fi

# Check for explicit EXIT_SIGNAL in Claude's output
if echo "$STOP_HOOK_MESSAGE" | grep -q "EXIT_SIGNAL: true"; then
    echo "EXIT_SIGNAL received. Project complete."
    exit 0  # Allow exit
fi

# Check SQLite database for completion
if [ -f "$DB_FILE" ]; then
    PENDING=$(sqlite3 "$DB_FILE" "SELECT COUNT(*) FROM tasks WHERE status = 'pending';" 2>/dev/null || echo "0")
    IN_PROGRESS=$(sqlite3 "$DB_FILE" "SELECT COUNT(*) FROM tasks WHERE status = 'in_progress';" 2>/dev/null || echo "0")

    if [ "$PENDING" -eq 0 ] && [ "$IN_PROGRESS" -eq 0 ]; then
        echo "All work complete. Allowing exit."
        exit 0  # Allow exit
    fi
fi

# Work not complete - block exit and continue
ITERATIONS=$((ITERATIONS + 1))
jq ".total_iterations = $ITERATIONS" "$CIRCUIT_BREAKER_FILE" > tmp.$$ && mv tmp.$$ "$CIRCUIT_BREAKER_FILE"

echo "Work not complete (iteration $ITERATIONS). Continuing..."
exit 2  # Exit code 2 = block exit, re-inject prompt
```

**How to enable:**
```bash
# In project .claude/settings.json or user settings
{
  "hooks": {
    "stop": ["./hooks/stop-hook.sh"]
  }
}
```

**Pros:**
- Native Claude Code integration
- No changes to existing agents/commands
- Simple shell scripts
- Easy to enable/disable

**Cons:**
- Requires user to configure hooks
- Hook behavior may vary across Claude Code versions

**Effort:** 2-4 hours

---

### Option 2: Autonomous Controller Agent

**Approach:** Create a top-level orchestration agent that implements loop logic within the agent system itself.

**What to add:**

```
agents/orchestration/autonomous-controller.md
commands/auto.md
```

**`agents/orchestration/autonomous-controller.md`:**
```markdown
# Autonomous Controller Agent

**Model:** claude-opus-4-5
**Purpose:** Top-level controller that runs until project completion

## Your Role

You are the autonomous execution controller. You continuously execute the
development workflow until ALL work is complete, implementing safety limits
and intelligent exit detection.

## CRITICAL: Continuous Execution Protocol

You MUST continue working in a loop until one of these conditions:
1. All sprints marked "completed" in state file AND EXIT_SIGNAL output
2. Circuit breaker triggered (5+ consecutive failures at same point)
3. Maximum iterations reached (default: 50)
4. Explicit user interrupt

## Execution Loop

```
iteration = 0
consecutive_failures = 0
last_failure_point = null

WHILE true:
    iteration += 1

    # Safety check
    IF iteration > MAX_ITERATIONS:
        OUTPUT "Maximum iterations reached. Stopping."
        OUTPUT "EXIT_SIGNAL: true"
        BREAK

    IF consecutive_failures >= 5:
        OUTPUT "Circuit breaker: 5 failures at {last_failure_point}"
        OUTPUT "EXIT_SIGNAL: true"
        BREAK

    # Load state from SQLite
    state = QUERY ".devteam/devteam.db" "SELECT * FROM v_current_session"

    # Determine next action
    IF no PRD exists:
        CALL prd-generator
    ELSE IF no tasks/sprints exist:
        CALL task-graph-analyzer, sprint-planner
    ELSE IF incomplete sprints exist:
        next_sprint = find_first_incomplete_sprint(state)
        result = CALL sprint-orchestrator(next_sprint)

        IF result.failed:
            IF last_failure_point == next_sprint:
                consecutive_failures += 1
            ELSE:
                consecutive_failures = 1
                last_failure_point = next_sprint
        ELSE:
            consecutive_failures = 0
    ELSE:
        # All complete
        OUTPUT "All sprints complete. Project finished."
        OUTPUT "EXIT_SIGNAL: true"
        BREAK

    # Progress update
    OUTPUT "ITERATION: {iteration}, Sprints: {completed}/{total}, Status: CONTINUING"
```

## EXIT_SIGNAL Protocol

**You MUST output `EXIT_SIGNAL: true` when:**
- All sprints are marked "completed" in state file
- Circuit breaker triggered
- Maximum iterations reached
- Unrecoverable error encountered

**You MUST NOT output EXIT_SIGNAL when:**
- Any sprint is still "pending" or "in_progress"
- Recoverable failures occurred (retry instead)
- Quality gates failed (fix and continue)

## Progress Tracking

After each iteration, output status:
```
═══════════════════════════════════════════
AUTONOMOUS MODE - Iteration {N}
═══════════════════════════════════════════
Sprints: {completed}/{total}
Current: {current_sprint} - {current_task}
Failures: {consecutive_failures}/5
Status: CONTINUING | COMPLETE | CIRCUIT_BREAKER
═══════════════════════════════════════════
```
```

**`commands/auto.md`:**
```markdown
# Autonomous Execution Command

## Usage
/devteam:implement [--max-iterations N]

## Description
Launches autonomous controller that runs until project completion.

## Process

1. Launch autonomous-controller agent
2. Agent loops through: PRD → Planning → Sprint execution
3. Continues until all work complete or safety limit hit
4. Outputs EXIT_SIGNAL when done

## Options
- `--max-iterations N`: Maximum loop iterations (default: 50)
```

**Pros:**
- Pure agent-based (consistent with project architecture)
- No external scripts or hooks needed
- Uses existing state management
- Full integration with quality gates

**Cons:**
- Agent context limits may require careful management
- Need to handle very long sessions

**Effort:** 4-8 hours

---

### Option 3: Enhanced State File + Sprint-All Extension

**Approach:** Extend the state file to track autonomous mode, and enhance `/devteam:sprint all` to read these settings.

**What to add/modify:**

1. **Extend state in SQLite (`.devteam/devteam.db`):**
```bash
# State is managed via SQLite session_state table
source scripts/state.sh

set_state "autonomous_mode_enabled" "true"
set_state "max_iterations" "50"
set_state "current_iteration" "12"
set_state "circuit_breaker" '{"consecutive_failures":0,"max_failures":5,"last_failure_point":null,"state":"closed"}'
set_state "session_started_at" "2025-01-28T10:00:00Z"
set_state "session_last_activity" "2025-01-28T12:30:00Z"
set_state "exit_detection" '{"completion_indicators":2,"exit_signal_required":true}'
```

2. **Modify `commands/sprint-all.md`** to add `--autonomous` flag:
```markdown
## Command Usage

/devteam:sprint all                     # Normal mode
/devteam:sprint all --autonomous        # Autonomous mode
/devteam:sprint all --autonomous --max-iterations 100
```

3. **Add autonomous behavior to sprint-orchestrator:**

When `autonomous_mode_enabled = true` in SQLite session state:
- Continue past normal stopping points
- Check circuit breaker before each sprint
- Output EXIT_SIGNAL only when genuinely complete
- Update iteration count after each action

**Pros:**
- Builds on existing infrastructure
- State-driven (resumable)
- Minimal new code

**Cons:**
- Requires modifying existing agents
- More complex state management

**Effort:** 6-10 hours

---

### Option 4: Hybrid - Hooks + Skills

**Approach:** Combine a lightweight stop hook with a Claude Code skill file that guides autonomous behavior.

**What to add:**

```
hooks/
└── stop-hook.sh           # Minimal hook for exit interception
.claude/
└── skills/
    └── autonomous-mode.md # Behavioral guidance for Claude
```

**`hooks/stop-hook.sh`** (minimal version):
```bash
#!/bin/bash
# Check for explicit completion signal
if echo "$STOP_HOOK_MESSAGE" | grep -q "EXIT_SIGNAL: true"; then
    exit 0  # Allow exit
fi

# Check if autonomous mode marker exists
if [ -f ".multi-agent/autonomous-mode" ]; then
    exit 2  # Block exit, continue
fi

exit 0  # Normal exit
```

**`.claude/skills/autonomous-mode.md`:**
```markdown
# Autonomous Development Mode

When autonomous mode is active (`.multi-agent/autonomous-mode` file exists),
you operate with these behaviors:

## Continuous Execution
- DO NOT stop after completing a task or sprint
- DO NOT ask for permission to continue
- DO NOT wait for user input between operations
- DO check state file and proceed to next incomplete work

## Exit Conditions
Output `EXIT_SIGNAL: true` ONLY when:
- All sprints marked completed in state file
- All quality gates passed
- No pending work remains

## Safety Limits
- Track iterations (stop at 50 if not specified)
- Monitor consecutive failures (stop at 5)
- Always update state file for resumability

## Progress Output
After each significant action:
```
[AUTO] Iteration N | Sprint X/Y | Task: TASK-XXX | Status: CONTINUING
```

## Activation
Autonomous mode is activated by running:
/devteam:implement

This creates `.multi-agent/autonomous-mode` marker file.
```

**`commands/auto.md`:**
```markdown
# Autonomous Mode Command

## Usage
/devteam:implement [--max-iterations N]

## Process
1. Create `.multi-agent/autonomous-mode` marker
2. Run `/devteam:sprint all`
3. Stop hook keeps session alive until EXIT_SIGNAL
4. Remove marker on completion
```

**Pros:**
- Leverages Claude Code's built-in systems
- Skills provide context without code changes
- Hook is minimal and simple
- Easy to toggle on/off

**Cons:**
- Skills influence but don't control behavior
- May need tuning

**Effort:** 3-5 hours

---

## Comparison Summary

| Option | Integration | Effort | Reliability | Maintenance |
|--------|-------------|--------|-------------|-------------|
| **1. Hooks Only** | Native | 2-4 hrs | High | Low |
| **2. Autonomous Agent** | Agent-based | 4-8 hrs | High | Medium |
| **3. Extended State** | State-driven | 6-10 hrs | High | Medium |
| **4. Hooks + Skills** | Hybrid | 3-5 hrs | Medium | Low |

---

## Recommendation

**Start with Option 1 (Hooks Only)** because:

1. **Fastest to implement** - Just shell scripts
2. **Non-invasive** - No changes to existing agents/commands
3. **Native integration** - Uses Claude Code's built-in hook system
4. **Easy to disable** - Just remove the hook configuration
5. **Foundation for more** - Can layer Option 2 or 3 on top later

**Implementation path:**
1. Create `hooks/stop-hook.sh` with completion detection
2. Create `hooks/settings.json` for hook configuration
3. Add documentation for enabling autonomous mode
4. Test with a small project
5. If needed, add Option 2 (autonomous agent) for richer control

---

## Files to Create

### Minimum Viable Implementation (Option 1)

```
hooks/
├── stop-hook.sh              # Main stop interception logic
├── README.md                 # How to enable/configure
└── circuit-breaker.sh        # Circuit breaker logic (optional separate file)

.multi-agent/                  # Runtime state (gitignored)
├── autonomous-mode           # Marker file when active
├── circuit-breaker.json      # Failure tracking
└── session.json              # Session metrics

commands/
└── auto.md                   # New command to start autonomous mode
```

### Full Implementation (Options 1 + 2)

Add to above:
```
agents/orchestration/
└── autonomous-controller.md  # Top-level loop controller

docs/development/
└── AUTONOMOUS_MODE.md        # User documentation
```

---

## Next Steps

1. Choose implementation option
2. Create the hook scripts
3. Add the `/devteam:implement` command
4. Test with a sample project
5. Document usage for end users

Would you like me to implement any of these options?
