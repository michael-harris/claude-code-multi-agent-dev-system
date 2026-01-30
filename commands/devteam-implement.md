# DevTeam Implement Command

**Command:** `/devteam:implement [task] [options]`

Execute implementation work - plans, sprints, tasks, or ad-hoc work.

## Usage

```bash
# Execute selected/current plan
/devteam:implement

# Execute specific sprint
/devteam:implement --sprint 1
/devteam:implement --sprint SPRINT-001

# Execute all sprints
/devteam:implement --all

# Execute specific task
/devteam:implement --task TASK-001

# Ad-hoc task (will trigger interview if ambiguous)
/devteam:implement "Add pagination to user list"

# Cost-optimized execution
/devteam:implement --eco
/devteam:implement --sprint 1 --eco

# Skip interview for ad-hoc tasks
/devteam:implement "Fix typo in header" --skip-interview

# Specify task type for better agent selection
/devteam:implement "Audit auth flow" --type security
/devteam:implement "Restructure utils" --type refactor
```

## Options

| Option | Description |
|--------|-------------|
| `--sprint <id>` | Execute specific sprint |
| `--all` | Execute all sprints sequentially |
| `--task <id>` | Execute specific task |
| `--eco` | Cost-optimized execution (slower escalation, summarized context) |
| `--skip-interview` | Skip ambiguity check for ad-hoc tasks |
| `--type <type>` | Specify task type: feature, bug, security, refactor, docs |
| `--model <model>` | Force starting model: haiku, sonnet, opus |
| `--max-iterations <n>` | Override max iterations (default: 10) |
| `--show-worktrees` | Debug: Show worktree operations (normally hidden) |

## Your Process

### Phase 0: Initialize Session

```bash
# Source state management
source scripts/state.sh
source scripts/events.sh

# Start session
SESSION_ID=$(start_session "/devteam:implement $*" "implement")
log_session_started "/devteam:implement $*" "implement"

# Determine execution mode
if [[ "$*" == *"--eco"* ]]; then
    set_state "execution_mode" "eco"
fi
```

Create/update session in database:

```sql
INSERT INTO sessions (
    id, command, command_type, execution_mode, status, current_phase
) VALUES (
    'session-xxx', '/devteam:implement --sprint 1', 'implement', 'normal', 'running', 'initializing'
);
```

### Phase 1: Determine Execution Target

**Priority order:**
1. `--task TASK-001` → Execute single task
2. `--sprint 1` → Execute specific sprint
3. `--all` → Execute all sprints
4. `"ad-hoc task"` → Create and execute ad-hoc task
5. (no args) → Execute current/selected plan

```javascript
function determineTarget(args) {
    if (args.task) return { type: 'task', id: args.task }
    if (args.sprint) return { type: 'sprint', id: args.sprint }
    if (args.all) return { type: 'all_sprints' }
    if (args._.length > 0) return { type: 'adhoc', description: args._.join(' ') }
    return { type: 'plan', id: getSelectedPlan() }
}
```

### Phase 2: Interview (for ad-hoc tasks)

**Skip if:**
- `--skip-interview` flag present
- Task is from a plan (already has context)
- Description is clearly unambiguous

**Trigger interview if:**
- Ad-hoc task with vague description
- Missing critical information

```javascript
// Check for ambiguity
const ambiguityIndicators = [
    description.split(' ').length < 5,           // Too short
    /fix|broken|doesn't work|issue/i.test(description) && !description.includes('when'),
    /add|create|implement/i.test(description) && !description.includes('to'),
    !description.includes(' ')                    // Single word
]

if (ambiguityIndicators.some(x => x) && !args.noInterview) {
    await runInterview('adhoc_task', description)
}
```

**Interview questions for ad-hoc tasks:**

```yaml
adhoc_task:
  triggers:
    - pattern: "fix|broken|bug"
      redirect: bug_interview
    - pattern: "add|create|implement"
      questions:
        - key: scope
          question: "What component/area should this be added to?"
        - key: requirements
          question: "What are the specific requirements?"
        - key: acceptance
          question: "How will we know when this is complete?"
```

### Phase 3: Agent Selection

Based on task type and content, select appropriate agents.

```yaml
# Agent selection weights
selection_weights:
  keywords: 40%
  file_types: 30%
  task_type: 20%
  language: 10%

# Task type overrides
task_type_agents:
  security:
    primary: security_auditor
    support: [penetration_tester, compliance_engineer]
  refactor:
    primary: refactoring_agent
    support: [code_reviewer]
  bug:
    primary: root_cause_analyst
    support: [bug_council_on_failure]
```

### Phase 4: Model Selection

**Normal Mode:**
```yaml
complexity_based:
  1-4: haiku
  5-8: sonnet
  9-14: opus
```

**Eco Mode:**
```yaml
eco_mode:
  default: haiku
  exceptions:
    - security: sonnet
    - architecture: sonnet
    - complexity_10_plus: sonnet
```

### Phase 5: Execute with Ralph Loop

```
┌─────────────────────────────────────────────────────────────┐
│                      RALPH QUALITY LOOP                      │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│   ┌─────────────┐                                           │
│   │   Execute   │◄─────────────────────────────────┐        │
│   │   Agent(s)  │                                  │        │
│   └──────┬──────┘                                  │        │
│          │                                         │        │
│          ▼                                         │        │
│   ┌─────────────┐      ┌──────────────┐           │        │
│   │   Quality   │─FAIL─▶│  Create Fix  │───────────┘        │
│   │    Gates    │      │    Tasks     │                     │
│   └──────┬──────┘      └──────────────┘                     │
│          │                     │                            │
│         PASS              ESCALATE?                         │
│          │                     │                            │
│          ▼                     ▼                            │
│   ┌─────────────┐      ┌──────────────┐                     │
│   │  Complete   │      │   Upgrade    │                     │
│   │  + Report   │      │    Model     │                     │
│   └─────────────┘      └──────────────┘                     │
│                                                              │
│   Max Iterations: 10 (normal) / 10 (eco, slower escalation) │
└─────────────────────────────────────────────────────────────┘
```

**Escalation thresholds:**

| Mode | haiku→sonnet | sonnet→opus | opus→council |
|------|--------------|-------------|--------------|
| Normal | 2 failures | 2 failures | 3 failures |
| Eco | 4 failures | 4 failures | 4 failures |

### Phase 6: Quality Gates

Run all applicable quality gates:

```javascript
const gates = [
    { name: 'tests', command: 'npm test', required: true },
    { name: 'typecheck', command: 'npm run typecheck', required: true },
    { name: 'lint', command: 'npm run lint', required: true },
    { name: 'security', command: 'npm audit', required: false },
    { name: 'coverage', command: 'npm run coverage', threshold: 80 }
]

for (const gate of gates) {
    const result = await runGate(gate)
    log_gate_passed(gate.name) // or log_gate_failed()

    if (!result.passed && gate.required) {
        createFixTask(gate, result.errors)
    }
}
```

### Phase 7: Completion

**On success:**
```javascript
log_session_ended('completed', 'All quality gates passed')
end_session('completed', 'Success')

// Output completion message
console.log(`
╔══════════════════════════════════════════╗
║  ✅ IMPLEMENTATION COMPLETE              ║
╚══════════════════════════════════════════╝

Task: ${taskDescription}

Files Changed:
${filesChanged.map(f => `  • ${f}`).join('\n')}

Quality Gates:
  ✅ Tests: ${testCount} passing
  ✅ Types: No errors
  ✅ Lint: Clean
  ✅ Coverage: ${coverage}%

Iterations: ${iterations}
Model Usage: ${modelBreakdown}
Cost: $${totalCost}

EXIT_SIGNAL: true
`)
```

**On max iterations:**
```javascript
log_session_ended('failed', 'Max iterations reached')
end_session('failed', 'Max iterations reached')

console.log(`
╔══════════════════════════════════════════╗
║  ⚠️  MAX ITERATIONS REACHED              ║
╚══════════════════════════════════════════╝

The task could not be completed within ${maxIterations} iterations.

Remaining Issues:
${remainingIssues.map(i => `  • ${i}`).join('\n')}

Recommendation: Review the issues above and either:
1. Run /devteam:implement again with more context
2. Break the task into smaller pieces
3. Manually address the blocking issues

EXIT_SIGNAL: true
`)
```

## Automatic Worktree Management

**Worktrees are fully automatic.** Users never need to interact with worktrees directly - the system creates, uses, merges, and cleans them up transparently.

### When Worktrees Are Created

Worktrees are automatically created when:
- A plan has multiple parallel tracks (detected from state file)
- The plan was designed with `parallel_tracks.mode: "worktrees"` in state

```javascript
// Auto-detect and create worktrees at execution start
async function initializeExecution(plan) {
    const parallelTracks = plan.parallel_tracks?.track_info

    if (parallelTracks && Object.keys(parallelTracks).length > 1) {
        // Multiple tracks - use worktrees for isolation
        for (const [trackId, trackInfo] of Object.entries(parallelTracks)) {
            const worktreePath = `.multi-agent/track-${trackId}`
            const branchName = `dev-track-${trackId}`

            if (!existsSync(worktreePath)) {
                // Create worktree silently
                await exec(`git worktree add ${worktreePath} -b ${branchName}`)
                log_event('worktree_created', { track: trackId, path: worktreePath })
            }
        }
    }
}
```

### Worktree Isolation During Execution

Each track's sprints execute in their isolated worktree:

```javascript
async function executeTrackSprint(trackId, sprintId) {
    const worktreePath = `.multi-agent/track-${trackId}`

    // Change to worktree directory for all operations
    process.chdir(worktreePath)

    try {
        await executeSprint(sprintId)

        // Auto-commit progress
        await exec('git add -A')
        await exec(`git commit -m "Complete ${sprintId} in track ${trackId}"`)

        // Auto-push for backup (silent failure ok)
        await exec(`git push -u origin dev-track-${trackId}`)
    } finally {
        // Return to main repo
        process.chdir(mainRepoPath)
    }
}
```

### Automatic Merge on Completion

When all tracks are complete, auto-merge occurs:

```javascript
async function checkAndAutoMerge() {
    const state = loadState()
    const tracks = state.parallel_tracks?.track_info

    if (!tracks) return  // Single track, no merge needed

    // Check if all tracks complete
    const allComplete = Object.values(tracks).every(t => t.status === 'completed')

    if (allComplete) {
        console.log('All tracks complete - auto-merging...')

        // Merge each track sequentially
        for (const trackId of Object.keys(tracks).sort()) {
            const branchName = `dev-track-${trackId}`

            // Merge with descriptive commit
            await exec(`git merge ${branchName} -m "Merge track ${trackId}: ${tracks[trackId].name}"`)

            log_event('track_merged', { track: trackId })
        }

        // Auto-cleanup worktrees
        await cleanupWorktrees()

        log_event('all_tracks_merged', { count: Object.keys(tracks).length })
    }
}
```

### Automatic Cleanup

After successful merge, worktrees are removed automatically:

```javascript
async function cleanupWorktrees() {
    const worktreeDir = '.multi-agent'

    // Get all worktrees
    const worktrees = await exec('git worktree list --porcelain')

    for (const worktree of parseWorktrees(worktrees)) {
        if (worktree.path.includes('.multi-agent')) {
            // Remove worktree (keeps branch for history)
            await exec(`git worktree remove ${worktree.path}`)
            log_event('worktree_removed', { path: worktree.path })
        }
    }

    // Remove .multi-agent directory if empty
    if (existsSync(worktreeDir) && readdirSync(worktreeDir).length === 0) {
        rmdirSync(worktreeDir)
    }
}
```

### Debug Flag

For advanced users who want to see worktree operations:

```bash
/devteam:implement --sprint 1 --show-worktrees
```

This displays:
```
═══════════════════════════════════════════════════
 Worktree Operations (debug mode)
═══════════════════════════════════════════════════

Track 01: .multi-agent/track-01 (dev-track-01)
  ✅ Worktree exists
  📍 Current commit: abc123

Track 02: .multi-agent/track-02 (dev-track-02)
  ✅ Worktree exists
  📍 Current commit: def456

Executing in: .multi-agent/track-01
```

### Important Notes

- **Users never need to run worktree commands** - everything is automatic
- Worktrees are created in `.multi-agent/` (gitignored)
- Branches are kept after merge for history (use `--delete-branches` in debug commands to remove)
- If something goes wrong, use `/devteam:worktree status` for diagnostics

## Sprint Execution

When executing a sprint (`--sprint` or `--all`):

```javascript
async function executeSprint(sprintId) {
    const sprint = await loadSprint(sprintId)
    set_active_sprint(sprintId)

    for (const task of sprint.tasks) {
        log_task_started(task.id, task.description)

        try {
            await executeTask(task)
            log_task_completed(task.id)
        } catch (error) {
            log_task_failed(task.id, error.message)
            // Continue to next task or abort based on task priority
            if (task.blocking) throw error
        }
    }

    // Sprint complete
    updateSprintStatus(sprintId, 'completed')
}
```

## User Communication

**Starting:**
```
═══════════════════════════════════════════════════
 DevTeam Implementation
═══════════════════════════════════════════════════

Target: Sprint SPRINT-001 (3 tasks)
Mode: Normal
Model: sonnet (complexity: 6)

Starting execution...
```

**Progress:**
```
═══════════════════════════════════════════════════
Task 1/3: Implement user authentication
═══════════════════════════════════════════════════

Agent: api_developer_typescript
Model: sonnet
Iteration: 1

Progress:
  ✅ Created auth middleware
  ✅ Added JWT validation
  ⏳ Writing tests...

Quality Gates:
  ⏳ Pending...
```

**Escalation:**
```
⚠️  Model Escalation
────────────────────
Reason: 2 consecutive test failures
Action: sonnet → opus

Retrying with enhanced reasoning...
```

## Cost Tracking

Track costs in real-time:

```javascript
// After each agent call
const cost = calculateCost(model, tokensInput, tokensOutput)
add_tokens(tokensInput, tokensOutput, cost)
log_agent_completed(agent, model, filesChanged, tokensInput, tokensOutput, cost)

// Cost calculation (cents)
function calculateCost(model, input, output) {
    const rates = {
        haiku: { input: 0.025, output: 0.125 },   // per 1K tokens
        sonnet: { input: 0.3, output: 1.5 },
        opus: { input: 1.5, output: 7.5 }
    }
    const rate = rates[model]
    return Math.ceil((input * rate.input + output * rate.output) / 10)
}
```

## Error Handling

```javascript
try {
    await executeImplementation()
} catch (error) {
    if (error.type === 'circuit_breaker') {
        log_error('Circuit breaker tripped', { failures: consecutiveFailures })
        // Wait and retry or abort
    } else if (error.type === 'rate_limit') {
        log_warning('Rate limit approaching', { usage: currentUsage })
        // Throttle execution
    } else {
        log_error(error.message, { stack: error.stack })
        end_session('failed', error.message)
    }
}
```

## See Also

- `/devteam:plan` - Create plans before implementing
- `/devteam:bug` - Fix bugs with diagnostic workflow
- `/devteam:status` - Check implementation progress
- `/devteam:list` - List available plans and sprints
