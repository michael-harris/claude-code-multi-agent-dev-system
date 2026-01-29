# DevTeam Reset Command

**Command:** `/devteam:reset [options]`

Reset state, clear stuck sessions, and recover from errors.

## Usage

```bash
# Abort current session and reset state
/devteam:reset

# Abort with specific reason
/devteam:reset --reason "Changing approach"

# Clear all session history (keep plans)
/devteam:reset --clear-history

# Full reset (clear everything except config)
/devteam:reset --full

# Reset specific session
/devteam:reset --session session-20260129-103045-abc123

# Dry run (show what would be reset)
/devteam:reset --dry-run
```

## Options

| Option | Description |
|--------|-------------|
| `--reason <text>` | Reason for reset (logged) |
| `--clear-history` | Clear all session history |
| `--full` | Full reset (sessions, history, temp files) |
| `--session <id>` | Reset specific session |
| `--dry-run` | Show what would be reset without doing it |
| `--force` | Skip confirmation prompts |

## Your Process

### Basic Reset (Abort Current Session)

```bash
source scripts/state.sh
source scripts/events.sh

# Check for running session
if is_session_running; then
    SESSION_ID=$(get_current_session_id)

    # Log the abort
    log_event "session_aborted" "system" "User initiated reset" \
        "{\"reason\": \"$REASON\"}"

    # End session
    end_session "aborted" "${REASON:-User reset}"

    echo "Session $SESSION_ID aborted."
else
    echo "No active session to reset."
fi

# Reset circuit breaker state
sqlite3 "$DB_FILE" "
    UPDATE sessions
    SET circuit_breaker_state = 'closed',
        consecutive_failures = 0
    WHERE status = 'running';
"
```

### Clear History

```bash
if [[ "$CLEAR_HISTORY" == "true" ]]; then
    # Confirm
    if [[ "$FORCE" != "true" ]]; then
        read -p "Clear all session history? This cannot be undone. [y/N] " confirm
        if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
            echo "Cancelled."
            exit 0
        fi
    fi

    # Clear history tables
    sqlite3 "$DB_FILE" "
        DELETE FROM events;
        DELETE FROM agent_runs;
        DELETE FROM gate_results;
        DELETE FROM escalations;
        DELETE FROM interviews;
        DELETE FROM interview_questions;
        DELETE FROM research_sessions;
        DELETE FROM research_findings;
        DELETE FROM sessions WHERE status != 'running';
    "

    echo "Session history cleared."
fi
```

### Full Reset

```bash
if [[ "$FULL_RESET" == "true" ]]; then
    # Confirm
    if [[ "$FORCE" != "true" ]]; then
        read -p "Full reset? This will clear all sessions and history. Plans will be preserved. [y/N] " confirm
        if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
            echo "Cancelled."
            exit 0
        fi
    fi

    # Backup database first
    BACKUP_FILE="${DB_FILE}.backup-$(date +%Y%m%d-%H%M%S)"
    cp "$DB_FILE" "$BACKUP_FILE"
    echo "Backup created: $BACKUP_FILE"

    # Clear all session-related data
    sqlite3 "$DB_FILE" "
        DELETE FROM events;
        DELETE FROM agent_runs;
        DELETE FROM gate_results;
        DELETE FROM escalations;
        DELETE FROM interviews;
        DELETE FROM interview_questions;
        DELETE FROM research_sessions;
        DELETE FROM research_findings;
        DELETE FROM bugs;
        DELETE FROM session_state;
        DELETE FROM sessions;
    "

    # Clean up temp files
    rm -f .devteam/autonomous-mode
    rm -f .devteam/current-task.txt
    rm -f .devteam/escalation-trigger

    echo "Full reset complete. Database backup: $BACKUP_FILE"
fi
```

## Output

### Normal Reset

```
═══════════════════════════════════════════════════════════════════
 DevTeam Reset
═══════════════════════════════════════════════════════════════════

Current Session: session-20260129-103045-a1b2c3
Status: running (iteration 5)
Command: /devteam:implement --sprint 1

Resetting...

  ✅ Session aborted
  ✅ Circuit breaker reset
  ✅ Temp files cleared

Reset complete. Ready for new session.
```

### Dry Run

```
═══════════════════════════════════════════════════════════════════
 DevTeam Reset (Dry Run)
═══════════════════════════════════════════════════════════════════

The following actions would be taken:

  [SESSION] Abort session-20260129-103045-a1b2c3
    - Status: running → aborted
    - Iterations completed: 5
    - Cost incurred: $2.34

  [STATE] Reset circuit breaker
    - Current failures: 3 → 0
    - State: half-open → closed

  [FILES] Remove temp files
    - .devteam/autonomous-mode
    - .devteam/current-task.txt

No changes made. Remove --dry-run to execute.
```

### Clear History

```
═══════════════════════════════════════════════════════════════════
 DevTeam Reset (Clear History)
═══════════════════════════════════════════════════════════════════

WARNING: This will permanently delete:

  Sessions:     47 records
  Events:       2,341 records
  Agent Runs:   892 records
  Gate Results: 1,203 records
  Escalations:  124 records

Plans and configuration will be preserved.

Clear all session history? This cannot be undone. [y/N] y

  ✅ Sessions cleared
  ✅ Events cleared
  ✅ Agent runs cleared
  ✅ Gate results cleared
  ✅ Escalations cleared

History cleared. Lifetime statistics reset.
```

## Recovery Scenarios

### Stuck Session

If a session appears stuck:

```bash
# Check what's happening
/devteam:status

# If truly stuck, reset
/devteam:reset --reason "Session stuck on iteration 8"
```

### Circuit Breaker Tripped

```bash
# Check status
/devteam:status
# Shows: Circuit Breaker: OPEN (5 consecutive failures)

# Reset to retry
/devteam:reset

# Then retry with different approach
/devteam:implement --sprint 1 --model sonnet
```

### Database Corruption

```bash
# If database is corrupted
/devteam:reset --full

# Or reinitialize
rm .devteam/devteam.db
bash scripts/db-init.sh
```

## Implementation Notes

### Preserves

- `.devteam/config.yaml` - Project configuration
- `.devteam/ralph-config.yaml` - Ralph configuration
- `.devteam/agent-capabilities.yaml` - Agent registry
- `.devteam/plans/` - Plan files
- `docs/planning/` - PRDs and planning docs

### Clears

- Running session state
- Circuit breaker
- Temp files (autonomous-mode, current-task.txt)
- Session history (with --clear-history)
- Events, agent runs, gate results (with --clear-history or --full)

## See Also

- `/devteam:status` - Check current state before reset
- `/devteam:implement` - Start new implementation after reset
