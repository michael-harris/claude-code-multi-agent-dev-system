# Ralph Integration Options Analysis

This document analyzes options for integrating [ralph-claude-code](https://github.com/frankbria/ralph-claude-code) autonomous loop functionality into the claude-code-multi-agent-dev-system.

## Executive Summary

Ralph provides **autonomous iterative development loops** with intelligent exit detection, while this project provides **76 specialized agents** with orchestrated workflows. The integration goal is to combine Ralph's "keep working until done" autonomy with this project's structured multi-agent development pipeline.

---

## Architecture Comparison

### This Project (claude-code-multi-agent-dev-system)

| Aspect | Implementation |
|--------|----------------|
| **Execution Model** | Agent-based orchestration via Task tool |
| **Loop Control** | Internal agent logic with max 5 iterations per task |
| **State Tracking** | YAML state files (`.project-state.yaml`) |
| **Exit Condition** | All tasks completed + quality gates passed |
| **Resumability** | State file enables resume from any point |
| **Safety** | Workflow compliance validation, max iterations |
| **Commands** | `/multi-agent:prd`, `/planning`, `/sprint`, `/feature` |

### Ralph (ralph-claude-code)

| Aspect | Implementation |
|--------|----------------|
| **Execution Model** | Bash loop with Stop hook interception |
| **Loop Control** | External shell loop with re-prompt injection |
| **State Tracking** | `.ralph/status.json`, session persistence |
| **Exit Condition** | Dual-gate: completion indicators + EXIT_SIGNAL |
| **Resumability** | Session continuity with `--continue` flag |
| **Safety** | Circuit breaker, rate limiting (100 calls/hr), 5-hour limit handling |
| **Commands** | `ralph`, `/ralph-loop`, `/cancel-ralph` |

---

## Integration Options

### Option 1: External Ralph Wrapper (Minimal Integration)

**Approach:** Use Ralph as an external orchestrator that wraps multi-agent commands.

```
Ralph Loop
  └─► /multi-agent:sprint all
        └─► sprint-orchestrator
              └─► task-orchestrator
                    └─► specialized agents
```

**Implementation:**
1. Install Ralph globally (`ralph-setup`)
2. Create `.ralph/PROMPT.md` that calls multi-agent commands
3. Ralph's loop handles retry on failures

**Example `.ralph/PROMPT.md`:**
```markdown
Execute the multi-agent development workflow for this project.

1. Check if docs/planning/PROJECT_PRD.yaml exists
   - If not: Run /multi-agent:prd to create it

2. Check if docs/sprints/ contains sprint files
   - If not: Run /multi-agent:planning

3. Execute all sprints: /multi-agent:sprint all

4. Verify completion by checking:
   - All sprints marked "completed" in .project-state.yaml
   - All tests pass
   - All quality gates satisfied

When ALL sprints are complete and verified:
<promise>PROJECT_COMPLETE</promise>
EXIT_SIGNAL: true
```

**Pros:**
- No code changes to multi-agent system
- Uses Ralph's proven safety mechanisms (circuit breaker, rate limiting)
- Ralph's monitoring dashboard available
- Quick to implement

**Cons:**
- Two separate state tracking systems
- Potential confusion between Ralph and multi-agent state
- Less tight integration
- Extra shell process overhead

**Effort:** Low (1-2 hours)

---

### Option 2: Stop Hook Integration (Hook-Based)

**Approach:** Implement Ralph's Stop hook pattern directly in the multi-agent plugin.

**Implementation:**

1. **Create hooks directory in plugin:**
```
claude-code-multi-agent-dev-system/
├── hooks/
│   ├── stop-hook.sh          # Ralph-style stop interceptor
│   └── post-tool-hook.sh     # Progress tracking hook
```

2. **Create Stop Hook (`hooks/stop-hook.sh`):**
```bash
#!/bin/bash
# Intercept Claude's stop attempts and check if work is complete

STATE_FILE="docs/planning/.project-state.yaml"

# Check completion status
if [ -f "$STATE_FILE" ]; then
    # Parse state file for completion
    COMPLETED=$(grep -c 'status: completed' "$STATE_FILE" || echo "0")
    TOTAL=$(grep -c 'status:' "$STATE_FILE" || echo "0")

    # Check for explicit EXIT_SIGNAL in Claude's output
    if echo "$CLAUDE_OUTPUT" | grep -q "EXIT_SIGNAL: true"; then
        # Allow exit
        exit 0
    fi

    # Check if all work is done
    if [ "$COMPLETED" -eq "$TOTAL" ] && [ "$TOTAL" -gt 0 ]; then
        exit 0  # Allow exit - work complete
    fi
fi

# Block exit and re-inject prompt
echo "Work not complete. Continuing..."
exit 2  # Exit code 2 = block and continue
```

3. **Add new command `/multi-agent:auto`:**
```markdown
# Autonomous Development Command

Starts autonomous development loop using Ralph-style hooks.

## Usage
/multi-agent:auto [--max-iterations N] [--completion-promise TEXT]

This command:
1. Activates stop hook interception
2. Runs /multi-agent:feature or /multi-agent:sprint all
3. Loops until EXIT_SIGNAL or max iterations reached
```

**Pros:**
- Uses Claude Code's native hook system
- State tracked in existing state files
- Single integrated system
- No external processes

**Cons:**
- Requires understanding Claude Code's hook mechanism
- More implementation effort
- Need to handle hook installation

**Effort:** Medium (4-8 hours)

---

### Option 3: Autonomous Orchestrator Agent (Agent-Based)

**Approach:** Create a new top-level agent that implements Ralph's loop logic internally.

**Implementation:**

1. **Create `agents/orchestration/autonomous-orchestrator.md`:**

```markdown
# Autonomous Orchestrator Agent

**Model:** claude-opus-4-5
**Purpose:** Top-level autonomous controller with Ralph-style loop logic

## Your Role

You are the autonomous development controller. You continuously execute development
tasks until the project is complete, implementing Ralph's iterative approach within
the agent system.

## CRITICAL: Loop Until Complete

**You MUST continue working until one of these conditions:**
1. All sprints completed with all quality gates passed
2. You output `EXIT_SIGNAL: true` (only when genuinely complete)
3. Circuit breaker triggered (5+ consecutive failures)
4. Maximum iterations reached (configurable, default 50)

## Autonomous Execution Protocol

```
LOOP:
  1. Read state file (.project-state.yaml)
  2. Identify next incomplete work unit:
     - If no PRD → Generate PRD
     - If no tasks → Run planning
     - If incomplete sprints → Execute next sprint
  3. Execute work using appropriate orchestrator
  4. Validate completion:
     - Check state file for completion markers
     - Verify quality gates passed
     - Run test verification
  5. If complete → Output EXIT_SIGNAL: true
  6. If not complete → GOTO 1
  7. If stuck (3+ attempts at same work) → Escalate or adjust strategy
```

## Exit Signal Protocol

**When to output EXIT_SIGNAL: true:**
- ALL sprints marked completed in state file
- ALL acceptance criteria verified (100%)
- ALL tests passing (0 failures)
- ALL quality gates passed

**When to continue (no EXIT_SIGNAL):**
- Any sprint still pending or in_progress
- Any failing tests
- Any unmet acceptance criteria
- Any validation failures

## Failure Recovery

If a task/sprint fails:
1. Log failure reason
2. Increment failure counter
3. If failure_count < 3: Retry with adjusted approach
4. If failure_count >= 3: Try alternative strategy
5. If failure_count >= 5: Output problem report and EXIT_SIGNAL

## Inputs

- Optional: PRD or project description
- Optional: Maximum iterations (default: 50)
- State file path

## Outputs

- Complete project with all sprints done
- Or: Detailed status report with blockers
```

2. **Add command `/multi-agent:auto`:**

```markdown
# Autonomous Development Command

## Usage
/multi-agent:auto [--max-iterations 50] [--from-scratch | --resume]

## Process

Launch the autonomous-orchestrator agent which will:
1. Assess current project state
2. Identify next required action
3. Execute PRD → Planning → Sprint workflow
4. Loop until completion or max iterations
5. Output EXIT_SIGNAL when done
```

**Pros:**
- Pure agent-based solution (consistent with project architecture)
- No external dependencies
- Uses existing state management
- Full integration with quality gates

**Cons:**
- Agent context limits may require careful state management
- More complex agent logic
- Need to handle very long-running sessions

**Effort:** Medium-High (8-16 hours)

---

### Option 4: Skills + Hooks Hybrid

**Approach:** Use Claude Code's skills mechanism combined with lightweight hooks.

**Implementation:**

1. **Create skill file `.claude/skills/ralph-autonomy.md`:**

```markdown
# Ralph Autonomy Skill

When working on this project, you have autonomous development capabilities.

## Autonomous Mode Activation

When the user invokes `/multi-agent:auto` or says "work autonomously":

1. **Read Project State**
   - Check docs/planning/.project-state.yaml
   - Understand current progress

2. **Iterative Execution**
   - DO NOT stop to ask for permission
   - DO NOT wait for confirmation between steps
   - CONTINUE working until genuinely complete

3. **Completion Detection**
   When you have verified:
   - All sprints: status=completed
   - All tests: passing (check TESTING_SUMMARY.md)
   - All quality gates: passed

   Then output:
   ```
   EXIT_SIGNAL: true
   COMPLETION_REASON: All sprints completed, tests passing, quality gates satisfied
   ```

4. **Progress Indicators**
   After each significant action, output:
   ```
   RALPH_STATUS: {
     "iteration": N,
     "sprints_complete": X/Y,
     "current_action": "description",
     "blockers": [],
     "EXIT_SIGNAL": false
   }
   ```

## Safety Limits

- Max iterations per session: 50
- Max consecutive failures: 5 (then pause and report)
- Always update state file after actions
```

2. **Create minimal stop hook (`hooks/stop-hook.sh`):**

```bash
#!/bin/bash
# Check if autonomous mode is active and work is complete

if [ -f ".ralph-mode" ]; then
    # Check for EXIT_SIGNAL in output
    if ! echo "$STOP_HOOK_MESSAGE" | grep -q "EXIT_SIGNAL: true"; then
        echo "Autonomous mode active - continuing work"
        exit 2
    fi
fi
exit 0
```

3. **Add activation command:**

```markdown
# /multi-agent:auto command

Activates autonomous mode:
1. Create .ralph-mode marker file
2. Load ralph-autonomy skill
3. Begin iterative execution
4. Remove .ralph-mode on completion
```

**Pros:**
- Leverages Claude Code's native skills system
- Minimal hook complexity
- Skills provide context without code changes
- Flexible and extensible

**Cons:**
- Skills may not fully control Claude's behavior
- Hook still needed for stop interception
- May need experimentation to tune

**Effort:** Medium (6-12 hours)

---

### Option 5: Full Project Merge (Comprehensive)

**Approach:** Merge Ralph's infrastructure into this project as a first-class feature.

**Implementation:**

1. **Project Structure After Merge:**
```
claude-code-multi-agent-dev-system/
├── agents/                    # Existing 76 agents
├── commands/
│   ├── (existing commands)
│   └── auto.md               # New autonomous command
├── hooks/
│   ├── stop-hook.sh          # Ralph stop hook
│   ├── post-tool-hook.sh     # Progress tracking
│   └── rate-limiter.sh       # API rate limiting
├── lib/
│   ├── circuit_breaker.sh    # From Ralph
│   ├── response_analyzer.sh  # From Ralph
│   └── state_manager.sh      # Unified state management
├── monitoring/
│   ├── dashboard.sh          # Ralph's tmux dashboard
│   └── progress-tracker.sh   # Real-time progress
├── templates/
│   └── autonomous-prompt.md  # Default autonomous prompt
└── plugin.json               # Updated with new capabilities
```

2. **Unified State Management:**

Extend `.project-state.yaml`:
```yaml
version: "2.0"
type: project

# Existing fields...
sprints: ...
tasks: ...

# New Ralph integration fields
autonomous_mode:
  enabled: true
  iteration: 15
  max_iterations: 50
  started_at: "2025-01-28T10:00:00Z"
  rate_limit:
    calls_this_hour: 45
    limit: 100
    reset_at: "2025-01-28T11:00:00Z"
  circuit_breaker:
    failures: 0
    threshold: 5
    state: closed  # closed | open | half-open
  exit_detection:
    completion_indicators: 2
    exit_signal_received: false
    last_status: "Executing SPRINT-003"
```

3. **New Commands:**

| Command | Description |
|---------|-------------|
| `/multi-agent:auto` | Start autonomous development |
| `/multi-agent:auto status` | Show autonomous mode status |
| `/multi-agent:auto pause` | Pause autonomous execution |
| `/multi-agent:auto resume` | Resume from pause |
| `/multi-agent:monitor` | Open tmux monitoring dashboard |

4. **Monitoring Dashboard:**

Adapt Ralph's monitoring to show multi-agent progress:
```
┌─────────────────────────────────────────────────────────────┐
│ Multi-Agent Autonomous Development Monitor                   │
├─────────────────────────────────────────────────────────────┤
│ Project: My Awesome App                                      │
│ Status: RUNNING                                              │
│ Iteration: 15/50                                             │
├─────────────────────────────────────────────────────────────┤
│ Progress:                                                    │
│ ├─ PRD:      ✅ Complete                                    │
│ ├─ Planning: ✅ Complete (3 sprints, 15 tasks)              │
│ ├─ Sprint 1: ✅ Complete (5/5 tasks)                        │
│ ├─ Sprint 2: ⏳ In Progress (3/5 tasks)                     │
│ │   └─ Current: TASK-009 - API Authentication (T2, iter 2)  │
│ └─ Sprint 3: ⏸ Pending (0/5 tasks)                         │
├─────────────────────────────────────────────────────────────┤
│ Rate: 45/100 calls/hr │ Circuit: CLOSED │ Failures: 0/5    │
├─────────────────────────────────────────────────────────────┤
│ [P]ause  [R]esume  [S]top  [L]ogs  [Q]uit                   │
└─────────────────────────────────────────────────────────────┘
```

**Pros:**
- Most complete integration
- Unified state management
- Professional monitoring
- All Ralph safety features (rate limiting, circuit breaker)
- Single cohesive tool

**Cons:**
- Highest implementation effort
- More maintenance burden
- Need to keep features synchronized

**Effort:** High (24-40 hours)

---

## Comparison Matrix

| Aspect | Option 1 | Option 2 | Option 3 | Option 4 | Option 5 |
|--------|----------|----------|----------|----------|----------|
| **Integration Depth** | Low | Medium | High | Medium | Very High |
| **Implementation Effort** | 1-2 hrs | 4-8 hrs | 8-16 hrs | 6-12 hrs | 24-40 hrs |
| **State Management** | Separate | Shared | Shared | Shared | Unified |
| **Safety Features** | Ralph's | Custom | Agent-based | Hybrid | Full |
| **Monitoring** | Ralph's | None | None | Basic | Full |
| **Maintenance** | Low | Low | Medium | Low | High |
| **User Experience** | Two tools | Seamless | Seamless | Seamless | Best |

---

## Recommendation

### For Quick Start: **Option 1 (External Ralph Wrapper)**

If you want to start using autonomous loops immediately with minimal effort, use Ralph as an external wrapper. Create a `.ralph/PROMPT.md` that invokes multi-agent commands.

### For Best Integration: **Option 3 (Autonomous Orchestrator Agent)**

This aligns best with the project's existing architecture. It keeps everything agent-based, uses existing state files, and doesn't introduce external dependencies.

### For Production Use: **Option 5 (Full Merge)**

If you're committed to long-term use and want the best experience, invest in the full merge. This provides unified state management, professional monitoring, and all safety features.

### Recommended Path

1. **Phase 1:** Start with Option 1 to validate the workflow (1-2 hours)
2. **Phase 2:** Implement Option 3 for proper integration (1-2 days)
3. **Phase 3:** If heavily used, evolve to Option 5 (1-2 weeks)

---

## Implementation Notes

### Claude Code Hooks System

Hooks are shell scripts that run at specific points:
- **Stop Hook:** Runs when Claude tries to exit - can block exit (exit code 2)
- **Post-Tool Hook:** Runs after each tool execution
- **Pre-Tool Hook:** Runs before tool execution

To use hooks, create `.claude/hooks/` directory and register in settings.

### Skills System

Skills are markdown files in `.claude/skills/` that Claude reads for context. They influence behavior but don't programmatically control execution.

### Rate Limiting Considerations

Claude API has a 5-hour usage limit. Ralph handles this with:
- Tracking calls per hour
- Prompting user to wait when limit approached
- Graceful session save for continuation

### Circuit Breaker Pattern

Ralph's circuit breaker prevents infinite loops:
- Tracks consecutive failures
- Opens after threshold (default: 5)
- Prevents further API calls when open
- Can be reset manually or after cooldown

---

## Next Steps

1. Choose an integration option based on your needs
2. Review the implementation details for your chosen option
3. Test with a small project first
4. Iterate based on results

For questions or assistance with implementation, refer to:
- [Ralph-claude-code repository](https://github.com/frankbria/ralph-claude-code)
- [Ralph Wiggum technique origin](https://ghuntley.com/ralph/)
- Multi-agent system documentation in this repository
