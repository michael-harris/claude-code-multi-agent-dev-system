-- DevTeam SQLite Schema
-- Single source of truth for all runtime state
-- Version: 1.0.0

-- ============================================================================
-- SESSIONS - Execution sessions (one per command invocation)
-- ============================================================================

CREATE TABLE IF NOT EXISTS sessions (
    id TEXT PRIMARY KEY,
    started_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    ended_at TIMESTAMP,

    -- Command info
    command TEXT NOT NULL,              -- "/devteam:implement --sprint 1"
    command_type TEXT NOT NULL,         -- plan, implement, bug, issue

    -- Status
    status TEXT DEFAULT 'running',      -- running, completed, failed, aborted
    exit_reason TEXT,                   -- Success, user_abort, max_iterations, error

    -- Current execution state
    current_phase TEXT,                 -- interview, research, planning, executing, quality_gates
    current_task_id TEXT,
    current_agent TEXT,
    current_model TEXT,                 -- haiku, sonnet, opus
    current_iteration INTEGER DEFAULT 0,
    max_iterations INTEGER DEFAULT 10,

    -- Circuit breaker
    consecutive_failures INTEGER DEFAULT 0,
    max_consecutive_failures INTEGER DEFAULT 5,
    circuit_breaker_state TEXT DEFAULT 'closed', -- closed, open, half-open

    -- Plan/Sprint context
    plan_id TEXT,
    sprint_id TEXT,

    -- Execution mode
    execution_mode TEXT DEFAULT 'normal', -- normal, eco

    -- Cost tracking
    total_tokens_input INTEGER DEFAULT 0,
    total_tokens_output INTEGER DEFAULT 0,
    total_cost_cents INTEGER DEFAULT 0,

    -- Bug Council
    bug_council_activated BOOLEAN DEFAULT FALSE,
    bug_council_reason TEXT
);

-- ============================================================================
-- SESSION_STATE - Key-value store for complex/nested state
-- ============================================================================

CREATE TABLE IF NOT EXISTS session_state (
    session_id TEXT NOT NULL REFERENCES sessions(id) ON DELETE CASCADE,
    key TEXT NOT NULL,
    value JSON NOT NULL,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (session_id, key)
);

-- ============================================================================
-- EVENTS - Full event history for debugging and analytics
-- ============================================================================

CREATE TABLE IF NOT EXISTS events (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    session_id TEXT NOT NULL REFERENCES sessions(id) ON DELETE CASCADE,
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    -- Event classification
    event_type TEXT NOT NULL,           -- See event types below
    event_category TEXT,                -- agent, gate, escalation, interview, etc.

    -- Context
    agent TEXT,
    model TEXT,
    iteration INTEGER,
    phase TEXT,

    -- Payload
    data JSON,
    message TEXT,

    -- Cost tracking per event
    tokens_input INTEGER,
    tokens_output INTEGER,
    cost_cents INTEGER
);

-- Event types:
-- session_started, session_ended
-- phase_changed
-- agent_started, agent_completed, agent_failed
-- model_escalated, model_deescalated
-- gate_passed, gate_failed
-- bug_council_activated, bug_council_completed
-- interview_started, interview_question, interview_completed
-- research_started, research_finding, research_completed
-- task_started, task_completed, task_failed
-- error_occurred, warning_issued
-- abandonment_detected, abandonment_prevented

-- ============================================================================
-- AGENT_RUNS - Detailed agent execution tracking
-- ============================================================================

CREATE TABLE IF NOT EXISTS agent_runs (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    session_id TEXT NOT NULL REFERENCES sessions(id) ON DELETE CASCADE,

    -- Agent info
    agent TEXT NOT NULL,
    agent_type TEXT,                    -- orchestration, backend, frontend, etc.
    model TEXT NOT NULL,

    -- Timing
    started_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    ended_at TIMESTAMP,
    duration_seconds INTEGER,

    -- Result
    status TEXT,                        -- running, success, failed, escalated
    error_message TEXT,
    error_type TEXT,                    -- test_failure, type_error, lint_error, etc.

    -- Context
    task_id TEXT,
    iteration INTEGER,
    attempt INTEGER DEFAULT 1,          -- Retry attempt number

    -- Cost
    tokens_input INTEGER,
    tokens_output INTEGER,
    cost_cents INTEGER,

    -- Output summary
    files_changed JSON,                 -- ["src/foo.ts", "src/bar.ts"]
    output_summary TEXT
);

-- ============================================================================
-- QUALITY_GATES - Gate execution results
-- ============================================================================

CREATE TABLE IF NOT EXISTS gate_results (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    session_id TEXT NOT NULL REFERENCES sessions(id) ON DELETE CASCADE,

    -- Gate info
    gate TEXT NOT NULL,                 -- tests, lint, typecheck, security, coverage
    iteration INTEGER NOT NULL,

    -- Result
    passed BOOLEAN NOT NULL,

    -- Details
    details JSON,                       -- Gate-specific details
    error_count INTEGER,
    warning_count INTEGER,

    -- For coverage gate
    coverage_percent REAL,

    -- Timing
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    duration_seconds INTEGER
);

-- ============================================================================
-- INTERVIEWS - Interview questions and responses
-- ============================================================================

CREATE TABLE IF NOT EXISTS interviews (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    session_id TEXT NOT NULL REFERENCES sessions(id) ON DELETE CASCADE,

    -- Interview context
    interview_type TEXT NOT NULL,       -- feature, bug, issue, task
    started_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    completed_at TIMESTAMP,

    -- Status
    status TEXT DEFAULT 'in_progress',  -- in_progress, completed, skipped
    questions_asked INTEGER DEFAULT 0,
    questions_answered INTEGER DEFAULT 0
);

CREATE TABLE IF NOT EXISTS interview_questions (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    interview_id INTEGER NOT NULL REFERENCES interviews(id) ON DELETE CASCADE,

    -- Question
    question_key TEXT NOT NULL,         -- expected_behavior, repro_steps, etc.
    question_text TEXT NOT NULL,
    question_type TEXT DEFAULT 'text',  -- text, choice, confirm

    -- Response
    response TEXT,
    responded_at TIMESTAMP,

    -- Ordering
    sequence INTEGER NOT NULL,
    required BOOLEAN DEFAULT TRUE
);

-- ============================================================================
-- RESEARCH - Research phase findings
-- ============================================================================

CREATE TABLE IF NOT EXISTS research_sessions (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    session_id TEXT NOT NULL REFERENCES sessions(id) ON DELETE CASCADE,

    -- Timing
    started_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    completed_at TIMESTAMP,

    -- Summary
    status TEXT DEFAULT 'in_progress',
    findings_count INTEGER DEFAULT 0,
    recommendations_count INTEGER DEFAULT 0,
    blockers_found INTEGER DEFAULT 0
);

CREATE TABLE IF NOT EXISTS research_findings (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    research_session_id INTEGER NOT NULL REFERENCES research_sessions(id) ON DELETE CASCADE,

    -- Finding
    finding_type TEXT NOT NULL,         -- pattern, technology, blocker, recommendation
    title TEXT NOT NULL,
    description TEXT,

    -- Evidence
    source TEXT,                        -- codebase, documentation, web
    file_path TEXT,
    evidence JSON,

    -- Importance
    priority TEXT DEFAULT 'medium',     -- high, medium, low

    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================================
-- BUGS - Local bug tracking (for /devteam:bug)
-- ============================================================================

CREATE TABLE IF NOT EXISTS bugs (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    session_id TEXT REFERENCES sessions(id) ON DELETE SET NULL,

    -- Bug info
    description TEXT NOT NULL,
    severity TEXT,                      -- critical, high, medium, low
    complexity TEXT,                    -- simple, moderate, complex

    -- Diagnosis
    root_cause TEXT,
    diagnosis_method TEXT,              -- direct, bug_council

    -- Resolution
    fix_summary TEXT,
    files_changed JSON,
    prevention_measures TEXT,

    -- Status
    status TEXT DEFAULT 'open',         -- open, in_progress, resolved, wont_fix

    -- Tracking
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    resolved_at TIMESTAMP,

    -- Bug Council
    council_activated BOOLEAN DEFAULT FALSE,
    council_votes JSON
);

-- ============================================================================
-- PLANS - Plan tracking (links to plan YAML files)
-- ============================================================================

CREATE TABLE IF NOT EXISTS plans (
    id TEXT PRIMARY KEY,                -- plan-001, plan-002

    -- Plan info
    name TEXT NOT NULL,
    description TEXT,
    plan_type TEXT,                     -- feature, project, maintenance

    -- File reference
    prd_path TEXT,
    tasks_path TEXT,
    sprints_path TEXT,

    -- Status
    status TEXT DEFAULT 'draft',        -- draft, ready, in_progress, completed, archived

    -- Progress
    total_sprints INTEGER DEFAULT 0,
    completed_sprints INTEGER DEFAULT 0,
    total_tasks INTEGER DEFAULT 0,
    completed_tasks INTEGER DEFAULT 0,

    -- Tracking
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    started_at TIMESTAMP,
    completed_at TIMESTAMP,

    -- Research link
    research_session_id INTEGER REFERENCES research_sessions(id)
);

-- ============================================================================
-- ESCALATIONS - Model escalation history
-- ============================================================================

CREATE TABLE IF NOT EXISTS escalations (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    session_id TEXT NOT NULL REFERENCES sessions(id) ON DELETE CASCADE,

    -- Escalation details
    from_model TEXT NOT NULL,
    to_model TEXT NOT NULL,
    agent TEXT,

    -- Reason
    reason TEXT NOT NULL,               -- consecutive_failures, complexity_increase, etc.
    failure_count INTEGER,

    -- Context
    iteration INTEGER,
    task_id TEXT,

    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================================
-- INDEXES
-- ============================================================================

-- Sessions
CREATE INDEX IF NOT EXISTS idx_sessions_status ON sessions(status);
CREATE INDEX IF NOT EXISTS idx_sessions_command_type ON sessions(command_type);
CREATE INDEX IF NOT EXISTS idx_sessions_started_at ON sessions(started_at);

-- Events
CREATE INDEX IF NOT EXISTS idx_events_session ON events(session_id);
CREATE INDEX IF NOT EXISTS idx_events_type ON events(event_type);
CREATE INDEX IF NOT EXISTS idx_events_timestamp ON events(timestamp);
CREATE INDEX IF NOT EXISTS idx_events_category ON events(event_category);

-- Agent runs
CREATE INDEX IF NOT EXISTS idx_agent_runs_session ON agent_runs(session_id);
CREATE INDEX IF NOT EXISTS idx_agent_runs_agent ON agent_runs(agent);
CREATE INDEX IF NOT EXISTS idx_agent_runs_status ON agent_runs(status);

-- Gate results
CREATE INDEX IF NOT EXISTS idx_gate_results_session ON gate_results(session_id);
CREATE INDEX IF NOT EXISTS idx_gate_results_gate ON gate_results(gate);

-- Plans
CREATE INDEX IF NOT EXISTS idx_plans_status ON plans(status);

-- ============================================================================
-- VIEWS
-- ============================================================================

-- Current running session
CREATE VIEW IF NOT EXISTS v_current_session AS
SELECT * FROM sessions WHERE status = 'running' ORDER BY started_at DESC LIMIT 1;

-- Session summary with costs
CREATE VIEW IF NOT EXISTS v_session_summary AS
SELECT
    s.id,
    s.command,
    s.status,
    s.started_at,
    s.ended_at,
    s.current_phase,
    s.current_agent,
    s.current_model,
    s.current_iteration,
    s.execution_mode,
    s.total_tokens_input + s.total_tokens_output as total_tokens,
    ROUND(s.total_cost_cents / 100.0, 2) as total_cost_dollars,
    (SELECT COUNT(*) FROM agent_runs ar WHERE ar.session_id = s.id) as agent_runs,
    (SELECT COUNT(*) FROM escalations e WHERE e.session_id = s.id) as escalations,
    s.bug_council_activated
FROM sessions s;

-- Model usage breakdown
CREATE VIEW IF NOT EXISTS v_model_usage AS
SELECT
    session_id,
    model,
    COUNT(*) as runs,
    SUM(CASE WHEN status = 'success' THEN 1 ELSE 0 END) as successes,
    SUM(CASE WHEN status = 'failed' THEN 1 ELSE 0 END) as failures,
    ROUND(AVG(CASE WHEN status = 'success' THEN 1.0 ELSE 0.0 END) * 100, 1) as success_rate,
    SUM(tokens_input) as tokens_input,
    SUM(tokens_output) as tokens_output,
    SUM(cost_cents) as cost_cents
FROM agent_runs
GROUP BY session_id, model;

-- Agent performance
CREATE VIEW IF NOT EXISTS v_agent_performance AS
SELECT
    agent,
    COUNT(*) as total_runs,
    SUM(CASE WHEN status = 'success' THEN 1 ELSE 0 END) as successes,
    ROUND(AVG(CASE WHEN status = 'success' THEN 1.0 ELSE 0.0 END) * 100, 1) as success_rate,
    AVG(duration_seconds) as avg_duration_seconds,
    SUM(cost_cents) as total_cost_cents
FROM agent_runs
GROUP BY agent;

-- Quality gate pass rates
CREATE VIEW IF NOT EXISTS v_gate_pass_rates AS
SELECT
    gate,
    COUNT(*) as total_runs,
    SUM(CASE WHEN passed THEN 1 ELSE 0 END) as passes,
    ROUND(AVG(CASE WHEN passed THEN 1.0 ELSE 0.0 END) * 100, 1) as pass_rate
FROM gate_results
GROUP BY gate;
