# SQLite Database Schema

DevTeam v3.0 uses SQLite for state management, event logging, and metrics tracking. This document describes the database schema.

## Database Location

```
.devteam/devteam.db
```

## Schema Overview

```
┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐
│    sessions     │────▶│     events      │     │   agent_runs    │
└─────────────────┘     └─────────────────┘     └─────────────────┘
        │                       │                       │
        │                       │                       │
        ▼                       ▼                       ▼
┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐
│  session_state  │     │  gate_results   │     │   escalations   │
└─────────────────┘     └─────────────────┘     └─────────────────┘

┌─────────────────┐     ┌─────────────────┐
│   interviews    │     │     bugs        │
└─────────────────┘     └─────────────────┘
        │
        ▼
┌─────────────────────┐
│ interview_questions │
└─────────────────────┘

┌─────────────────────┐     ┌─────────────────────┐
│  research_sessions  │────▶│  research_findings  │
└─────────────────────┘     └─────────────────────┘
```

## Tables

### sessions

Tracks execution sessions (each command invocation).

```sql
CREATE TABLE sessions (
    id TEXT PRIMARY KEY,                    -- e.g., 'sess_abc123'
    command TEXT NOT NULL,                  -- e.g., '/devteam:implement --sprint 1'
    command_type TEXT NOT NULL,             -- plan, implement, bug, issue
    execution_mode TEXT DEFAULT 'normal',   -- normal, eco
    status TEXT DEFAULT 'running',          -- running, completed, failed, aborted
    current_phase TEXT,                     -- initializing, interviewing, researching, executing
    started_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    ended_at DATETIME,
    error_message TEXT,
    total_tokens_in INTEGER DEFAULT 0,
    total_tokens_out INTEGER DEFAULT 0,
    total_cost_cents INTEGER DEFAULT 0
);
```

### session_state

Key-value state storage for sessions.

```sql
CREATE TABLE session_state (
    session_id TEXT NOT NULL,
    key TEXT NOT NULL,
    value TEXT,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (session_id, key),
    FOREIGN KEY (session_id) REFERENCES sessions(id)
);
```

### events

Full event log for debugging and analytics.

```sql
CREATE TABLE events (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    session_id TEXT,
    agent_run_id INTEGER,
    timestamp DATETIME DEFAULT CURRENT_TIMESTAMP,
    event_type TEXT NOT NULL,               -- session_started, agent_started, gate_passed, etc.
    event_data TEXT,                        -- JSON blob with event details
    FOREIGN KEY (session_id) REFERENCES sessions(id),
    FOREIGN KEY (agent_run_id) REFERENCES agent_runs(id)
);
```

**Event Types:**
- `session_started`, `session_ended`
- `phase_changed`
- `agent_started`, `agent_completed`, `agent_failed`
- `task_started`, `task_completed`, `task_failed`
- `gate_passed`, `gate_failed`
- `model_escalated`
- `bug_council_activated`
- `worktree_created`, `worktree_removed`, `track_merged`

### agent_runs

Tracks individual agent executions.

```sql
CREATE TABLE agent_runs (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    session_id TEXT NOT NULL,
    agent_id TEXT NOT NULL,                 -- e.g., 'api-developer-typescript-t1'
    task_id TEXT,                           -- e.g., 'TASK-001'
    model TEXT NOT NULL,                    -- haiku, sonnet, opus
    started_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    ended_at DATETIME,
    status TEXT DEFAULT 'running',          -- running, completed, failed
    tokens_in INTEGER,
    tokens_out INTEGER,
    cost_cents INTEGER,
    files_modified TEXT,                    -- JSON array
    error_message TEXT,
    FOREIGN KEY (session_id) REFERENCES sessions(id)
);
```

### gate_results

Quality gate execution results.

```sql
CREATE TABLE gate_results (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    session_id TEXT NOT NULL,
    agent_run_id INTEGER,
    gate_name TEXT NOT NULL,                -- tests, lint, typecheck, security
    passed BOOLEAN NOT NULL,
    duration_ms INTEGER,
    output TEXT,                            -- Captured output
    error_count INTEGER,
    executed_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (session_id) REFERENCES sessions(id),
    FOREIGN KEY (agent_run_id) REFERENCES agent_runs(id)
);
```

### interviews

Interview session records.

```sql
CREATE TABLE interviews (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    session_id TEXT NOT NULL,
    interview_type TEXT NOT NULL,           -- bug_report, feature_request, adhoc_task
    started_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    completed_at DATETIME,
    questions_asked INTEGER DEFAULT 0,
    redirected_to TEXT,                     -- If redirected to different workflow
    FOREIGN KEY (session_id) REFERENCES sessions(id)
);
```

### interview_questions

Individual Q&A from interviews.

```sql
CREATE TABLE interview_questions (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    interview_id INTEGER NOT NULL,
    question_key TEXT NOT NULL,
    question_text TEXT NOT NULL,
    answer TEXT,
    skipped BOOLEAN DEFAULT FALSE,
    asked_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (interview_id) REFERENCES interviews(id)
);
```

### research_sessions

Research phase tracking.

```sql
CREATE TABLE research_sessions (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    session_id TEXT NOT NULL,
    feature_description TEXT,
    started_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    completed_at DATETIME,
    patterns_found INTEGER DEFAULT 0,
    blockers_found INTEGER DEFAULT 0,
    FOREIGN KEY (session_id) REFERENCES sessions(id)
);
```

### research_findings

Individual findings from research.

```sql
CREATE TABLE research_findings (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    research_session_id INTEGER NOT NULL,
    finding_type TEXT NOT NULL,             -- pattern, blocker, recommendation, technology
    title TEXT NOT NULL,
    description TEXT,
    severity TEXT,                          -- For blockers: high, medium, low
    confidence TEXT,                        -- high, medium, low
    location TEXT,                          -- File/code location if applicable
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (research_session_id) REFERENCES research_sessions(id)
);
```

### bugs

Local bug tracking (not GitHub).

```sql
CREATE TABLE bugs (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    session_id TEXT,
    description TEXT NOT NULL,
    severity TEXT DEFAULT 'medium',         -- critical, high, medium, low
    status TEXT DEFAULT 'open',             -- open, investigating, fixing, resolved
    root_cause TEXT,
    resolution TEXT,
    files_affected TEXT,                    -- JSON array
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    resolved_at DATETIME,
    FOREIGN KEY (session_id) REFERENCES sessions(id)
);
```

### escalations

Model escalation history.

```sql
CREATE TABLE escalations (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    session_id TEXT NOT NULL,
    agent_run_id INTEGER,
    from_model TEXT NOT NULL,               -- haiku, sonnet
    to_model TEXT NOT NULL,                 -- sonnet, opus
    reason TEXT NOT NULL,                   -- e.g., 'gate_failures: 2'
    failure_count INTEGER,
    escalated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (session_id) REFERENCES sessions(id),
    FOREIGN KEY (agent_run_id) REFERENCES agent_runs(id)
);
```

## Views

### v_current_session

Get the most recent active session.

```sql
CREATE VIEW v_current_session AS
SELECT * FROM sessions
WHERE status = 'running'
ORDER BY started_at DESC
LIMIT 1;
```

### v_session_summary

Summary of completed sessions.

```sql
CREATE VIEW v_session_summary AS
SELECT
    s.id,
    s.command,
    s.status,
    s.started_at,
    s.ended_at,
    ROUND((julianday(s.ended_at) - julianday(s.started_at)) * 86400) as duration_seconds,
    s.total_tokens_in,
    s.total_tokens_out,
    s.total_cost_cents,
    COUNT(DISTINCT ar.id) as agent_count,
    SUM(CASE WHEN gr.passed THEN 1 ELSE 0 END) as gates_passed,
    SUM(CASE WHEN NOT gr.passed THEN 1 ELSE 0 END) as gates_failed
FROM sessions s
LEFT JOIN agent_runs ar ON s.id = ar.session_id
LEFT JOIN gate_results gr ON s.id = gr.session_id
GROUP BY s.id;
```

### v_model_usage

Model usage statistics.

```sql
CREATE VIEW v_model_usage AS
SELECT
    model,
    COUNT(*) as run_count,
    SUM(tokens_in) as total_tokens_in,
    SUM(tokens_out) as total_tokens_out,
    SUM(cost_cents) as total_cost_cents,
    AVG(ROUND((julianday(ended_at) - julianday(started_at)) * 86400)) as avg_duration_seconds
FROM agent_runs
WHERE status = 'completed'
GROUP BY model;
```

### v_agent_performance

Agent performance metrics.

```sql
CREATE VIEW v_agent_performance AS
SELECT
    agent_id,
    COUNT(*) as total_runs,
    SUM(CASE WHEN status = 'completed' THEN 1 ELSE 0 END) as successful_runs,
    ROUND(100.0 * SUM(CASE WHEN status = 'completed' THEN 1 ELSE 0 END) / COUNT(*), 1) as success_rate,
    AVG(tokens_in + tokens_out) as avg_tokens,
    AVG(cost_cents) as avg_cost_cents
FROM agent_runs
GROUP BY agent_id;
```

### v_gate_pass_rates

Quality gate pass rates.

```sql
CREATE VIEW v_gate_pass_rates AS
SELECT
    gate_name,
    COUNT(*) as total_runs,
    SUM(CASE WHEN passed THEN 1 ELSE 0 END) as passed_count,
    ROUND(100.0 * SUM(CASE WHEN passed THEN 1 ELSE 0 END) / COUNT(*), 1) as pass_rate,
    AVG(duration_ms) as avg_duration_ms
FROM gate_results
GROUP BY gate_name;
```

## Example Queries

### Get current session status
```sql
SELECT * FROM v_current_session;
```

### Get cost breakdown by model
```sql
SELECT
    model,
    total_cost_cents / 100.0 as cost_dollars,
    run_count
FROM v_model_usage
ORDER BY total_cost_cents DESC;
```

### Find failed gates in last session
```sql
SELECT gr.*
FROM gate_results gr
JOIN sessions s ON gr.session_id = s.id
WHERE s.id = (SELECT id FROM sessions ORDER BY started_at DESC LIMIT 1)
AND NOT gr.passed;
```

### Get escalation history
```sql
SELECT
    e.from_model,
    e.to_model,
    e.reason,
    e.escalated_at,
    s.command
FROM escalations e
JOIN sessions s ON e.session_id = s.id
ORDER BY e.escalated_at DESC
LIMIT 10;
```

### Calculate session costs for today
```sql
SELECT
    SUM(total_cost_cents) / 100.0 as total_cost_dollars,
    COUNT(*) as session_count
FROM sessions
WHERE date(started_at) = date('now');
```

## Helper Scripts

### Bash (`scripts/state.sh`)
```bash
source scripts/state.sh

# Start session
SESSION_ID=$(start_session "/devteam:implement" "implement")

# Get/set state
set_state "current_phase" "executing"
phase=$(get_state "current_phase")

# Track tokens
add_tokens 1000 500 15  # in, out, cost_cents

# End session
end_session "completed" "All tasks done"
```

### PowerShell (`scripts/state.ps1`)
```powershell
. scripts/state.ps1

$sessionId = Start-DevTeamSession "/devteam:implement" "implement"
Set-DevTeamState "current_phase" "executing"
$phase = Get-DevTeamState "current_phase"
Add-DevTeamTokens 1000 500 15
End-DevTeamSession "completed" "All tasks done"
```

## Maintenance

### Backup
```bash
cp .devteam/devteam.db .devteam/devteam.db.backup
```

### Reset
```bash
rm .devteam/devteam.db
bash scripts/db-init.sh
```

### Query from command line
```bash
sqlite3 .devteam/devteam.db "SELECT * FROM v_session_summary LIMIT 5"
```

### Vacuum (reclaim space)
```bash
sqlite3 .devteam/devteam.db "VACUUM"
```
