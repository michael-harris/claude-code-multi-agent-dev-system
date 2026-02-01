-- DevTeam SQLite Schema v2
-- Adds: Acceptance Criteria, Context Management, Progress Tracking
-- Migrates from v1 - run after schema.sql
-- Version: 2.0.0

-- ============================================================================
-- ACCEPTANCE CRITERIA - JSON-backed feature tracking with passes boolean
-- ============================================================================

CREATE TABLE IF NOT EXISTS acceptance_criteria (
    id INTEGER PRIMARY KEY AUTOINCREMENT,

    -- Parent reference (task or sprint)
    task_id TEXT,
    sprint_id TEXT,
    plan_id TEXT,

    -- Criterion details
    criterion_id TEXT NOT NULL UNIQUE,   -- AC-001, AC-002, etc.
    description TEXT NOT NULL,
    category TEXT,                        -- functional, visual, performance, security

    -- The key field from Anthropic's article
    passes BOOLEAN NOT NULL DEFAULT FALSE,

    -- Verification tracking
    verified_at TIMESTAMP,
    verified_by TEXT,                     -- Agent that verified
    verification_method TEXT,             -- automated_test, manual, visual
    verification_evidence TEXT,           -- Test name, screenshot path, etc.

    -- Failure tracking
    last_failure_reason TEXT,
    failure_count INTEGER DEFAULT 0,

    -- Ordering
    priority TEXT DEFAULT 'medium',       -- critical, high, medium, low
    sequence INTEGER DEFAULT 0,

    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================================
-- FEATURES - Granular feature breakdown (200+ feature enumeration)
-- ============================================================================

CREATE TABLE IF NOT EXISTS features (
    id INTEGER PRIMARY KEY AUTOINCREMENT,

    -- Parent reference
    plan_id TEXT,
    sprint_id TEXT,

    -- Feature details
    feature_id TEXT NOT NULL UNIQUE,      -- FEAT-001, FEAT-002
    name TEXT NOT NULL,
    description TEXT,
    category TEXT,                        -- auth, ui, api, data, etc.

    -- Granular steps (JSON array of step objects)
    steps JSON,                           -- [{"step": "click button", "passes": false}, ...]

    -- Pass status
    passes BOOLEAN NOT NULL DEFAULT FALSE,
    all_steps_pass BOOLEAN DEFAULT FALSE,

    -- Progress
    steps_total INTEGER DEFAULT 0,
    steps_passed INTEGER DEFAULT 0,

    -- Verification
    verified_at TIMESTAMP,
    verified_by TEXT,

    -- Priority and ordering
    priority TEXT DEFAULT 'medium',
    sequence INTEGER DEFAULT 0,

    -- Timestamps
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================================
-- CONTEXT_SNAPSHOTS - Context window management
-- ============================================================================

CREATE TABLE IF NOT EXISTS context_snapshots (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    session_id TEXT NOT NULL REFERENCES sessions(id) ON DELETE CASCADE,

    -- Snapshot info
    snapshot_type TEXT NOT NULL,          -- auto, checkpoint, overflow_prevention

    -- Token tracking
    tokens_before INTEGER,
    tokens_after INTEGER,
    tokens_saved INTEGER,

    -- What was preserved vs summarized
    preserved_items JSON,                 -- Critical items kept in full
    summarized_items JSON,                -- Items that were summarized

    -- The actual summary
    summary_text TEXT,

    -- Trigger reason
    trigger_reason TEXT,                  -- approaching_limit, iteration_complete, phase_change

    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================================
-- CONTEXT_BUDGETS - Real-time context/token budget tracking
-- ============================================================================

CREATE TABLE IF NOT EXISTS context_budgets (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    session_id TEXT NOT NULL REFERENCES sessions(id) ON DELETE CASCADE,

    -- Model context limits
    model TEXT NOT NULL,
    context_limit INTEGER NOT NULL,       -- Max tokens for this model

    -- Current usage
    current_usage INTEGER DEFAULT 0,
    usage_percent REAL DEFAULT 0.0,

    -- Thresholds
    warn_threshold INTEGER,               -- Token count to warn at
    summarize_threshold INTEGER,          -- Token count to auto-summarize

    -- Status
    status TEXT DEFAULT 'ok',             -- ok, warning, critical
    last_action TEXT,                     -- none, warned, summarized

    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================================
-- PROGRESS_SUMMARIES - Human-readable progress tracking
-- ============================================================================

CREATE TABLE IF NOT EXISTS progress_summaries (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    session_id TEXT NOT NULL REFERENCES sessions(id) ON DELETE CASCADE,

    -- Summary content
    summary_text TEXT NOT NULL,           -- Human-readable markdown

    -- What it covers
    from_iteration INTEGER,
    to_iteration INTEGER,

    -- Metrics at time of summary
    tasks_completed INTEGER DEFAULT 0,
    tasks_remaining INTEGER DEFAULT 0,
    tests_passing INTEGER DEFAULT 0,
    tests_failing INTEGER DEFAULT 0,
    features_passing INTEGER DEFAULT 0,
    features_total INTEGER DEFAULT 0,

    -- Git info
    last_commit_sha TEXT,
    files_changed JSON,

    -- Timestamps
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================================
-- SESSION_PHASES - Two-phase architecture tracking
-- ============================================================================

CREATE TABLE IF NOT EXISTS session_phases (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    session_id TEXT NOT NULL REFERENCES sessions(id) ON DELETE CASCADE,

    -- Phase info
    phase_type TEXT NOT NULL,             -- initializer, coding, resume
    is_first_run BOOLEAN DEFAULT FALSE,

    -- What was set up in initializer phase
    init_script_created BOOLEAN DEFAULT FALSE,
    features_enumerated BOOLEAN DEFAULT FALSE,
    progress_file_created BOOLEAN DEFAULT FALSE,
    baseline_commit_sha TEXT,

    -- Coding phase tracking
    features_attempted INTEGER DEFAULT 0,
    features_completed INTEGER DEFAULT 0,

    -- Resume detection
    resumed_from_session TEXT,            -- Previous session ID if resuming
    resume_point TEXT,                    -- Where to continue from

    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================================
-- INDEXES FOR NEW TABLES
-- ============================================================================

CREATE INDEX IF NOT EXISTS idx_acceptance_criteria_task ON acceptance_criteria(task_id);
CREATE INDEX IF NOT EXISTS idx_acceptance_criteria_passes ON acceptance_criteria(passes);
CREATE INDEX IF NOT EXISTS idx_features_plan ON features(plan_id);
CREATE INDEX IF NOT EXISTS idx_features_passes ON features(passes);
CREATE INDEX IF NOT EXISTS idx_context_snapshots_session ON context_snapshots(session_id);
CREATE INDEX IF NOT EXISTS idx_progress_summaries_session ON progress_summaries(session_id);
CREATE INDEX IF NOT EXISTS idx_session_phases_session ON session_phases(session_id);

-- ============================================================================
-- VIEWS FOR NEW TABLES
-- ============================================================================

-- Acceptance criteria pass rate
CREATE VIEW IF NOT EXISTS v_acceptance_criteria_status AS
SELECT
    task_id,
    COUNT(*) as total_criteria,
    SUM(CASE WHEN passes THEN 1 ELSE 0 END) as passing,
    SUM(CASE WHEN NOT passes THEN 1 ELSE 0 END) as failing,
    ROUND(AVG(CASE WHEN passes THEN 1.0 ELSE 0.0 END) * 100, 1) as pass_rate
FROM acceptance_criteria
GROUP BY task_id;

-- Feature pass status
CREATE VIEW IF NOT EXISTS v_feature_status AS
SELECT
    plan_id,
    COUNT(*) as total_features,
    SUM(CASE WHEN passes THEN 1 ELSE 0 END) as passing,
    SUM(CASE WHEN NOT passes THEN 1 ELSE 0 END) as failing,
    SUM(steps_total) as total_steps,
    SUM(steps_passed) as steps_passed,
    ROUND(AVG(CASE WHEN passes THEN 1.0 ELSE 0.0 END) * 100, 1) as feature_pass_rate
FROM features
GROUP BY plan_id;

-- Context budget status
CREATE VIEW IF NOT EXISTS v_context_status AS
SELECT
    cb.session_id,
    cb.model,
    cb.context_limit,
    cb.current_usage,
    cb.usage_percent,
    cb.status,
    (SELECT COUNT(*) FROM context_snapshots cs WHERE cs.session_id = cb.session_id) as snapshots_created
FROM context_budgets cb;

-- ============================================================================
-- BASELINES - Checkpoint commits for rollback
-- ============================================================================

CREATE TABLE IF NOT EXISTS baselines (
    id INTEGER PRIMARY KEY AUTOINCREMENT,

    -- Baseline identification
    tag_name TEXT NOT NULL UNIQUE,            -- baseline/sprint-01/20250201-120000
    commit_hash TEXT NOT NULL,
    milestone TEXT NOT NULL,                  -- sprint-start, feature-complete, etc.

    -- Description
    description TEXT,

    -- Metadata
    branch TEXT,
    files_changed INTEGER DEFAULT 0,

    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================================
-- CHECKPOINTS - Full state snapshots for resume
-- ============================================================================

CREATE TABLE IF NOT EXISTS checkpoints (
    id INTEGER PRIMARY KEY AUTOINCREMENT,

    -- Checkpoint identification
    checkpoint_id TEXT NOT NULL UNIQUE,       -- chkpt-20250201-120000-abc123
    path TEXT NOT NULL,                       -- .devteam/checkpoints/chkpt-xxx

    -- Context
    description TEXT,
    git_commit TEXT,
    session_id TEXT,
    task_id TEXT,
    sprint_id TEXT,

    -- Status
    can_restore BOOLEAN DEFAULT TRUE,

    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================================
-- CHECKPOINT_RESTORES - Track when checkpoints are restored
-- ============================================================================

CREATE TABLE IF NOT EXISTS checkpoint_restores (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    checkpoint_id TEXT NOT NULL,
    restored_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================================
-- ROLLBACKS - Track all rollback operations
-- ============================================================================

CREATE TABLE IF NOT EXISTS rollbacks (
    id INTEGER PRIMARY KEY AUTOINCREMENT,

    -- Rollback details
    rollback_type TEXT NOT NULL,              -- auto, manual, smart
    target_commit TEXT NOT NULL,
    target_tag TEXT,

    -- Context
    reason TEXT,
    from_commit TEXT,

    -- What triggered it
    trigger_type TEXT,                        -- regression, user_request, error
    check_type TEXT,                          -- build, test, typecheck, lint

    -- Backup info
    backup_branch TEXT,

    rolled_back_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================================
-- TOKEN_USAGE - Cost and token tracking
-- ============================================================================

CREATE TABLE IF NOT EXISTS token_usage (
    id INTEGER PRIMARY KEY AUTOINCREMENT,

    -- Session and task context
    session_id TEXT,
    task_id TEXT,
    sprint_id TEXT,

    -- Model info
    model TEXT NOT NULL,

    -- Token counts
    input_tokens INTEGER NOT NULL DEFAULT 0,
    output_tokens INTEGER NOT NULL DEFAULT 0,

    -- Cost (USD)
    cost_usd REAL NOT NULL DEFAULT 0,

    -- Operation context
    operation TEXT,                           -- code-gen, test, review, etc.
    agent_name TEXT,                          -- Which agent made the call

    recorded_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================================
-- ERROR_LOG - Track errors for recovery analysis
-- ============================================================================

CREATE TABLE IF NOT EXISTS error_log (
    id INTEGER PRIMARY KEY AUTOINCREMENT,

    -- Error context
    session_id TEXT,
    task_id TEXT,
    operation TEXT,

    -- Error details
    error_type TEXT NOT NULL,                 -- transient, permanent, recoverable
    error_message TEXT NOT NULL,
    error_pattern TEXT,                       -- Matched pattern from error-recovery.yaml

    -- Recovery attempt
    recovery_action TEXT,
    recovery_success BOOLEAN,
    retry_count INTEGER DEFAULT 0,

    -- Circuit breaker
    circuit_opened BOOLEAN DEFAULT FALSE,

    logged_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================================
-- DEAD_LETTER - Failed operations for later retry
-- ============================================================================

CREATE TABLE IF NOT EXISTS dead_letter (
    id INTEGER PRIMARY KEY AUTOINCREMENT,

    -- Operation details
    operation_type TEXT NOT NULL,
    operation_params JSON,

    -- Error info
    error_message TEXT,
    stack_trace TEXT,
    attempt_count INTEGER DEFAULT 1,

    -- Context
    session_id TEXT,
    task_id TEXT,

    -- Status
    status TEXT DEFAULT 'pending',            -- pending, retried, failed, expired
    retry_after TIMESTAMP,
    expires_at TIMESTAMP,

    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================================
-- ADDITIONAL INDEXES
-- ============================================================================

CREATE INDEX IF NOT EXISTS idx_baselines_milestone ON baselines(milestone);
CREATE INDEX IF NOT EXISTS idx_checkpoints_session ON checkpoints(session_id);
CREATE INDEX IF NOT EXISTS idx_rollbacks_type ON rollbacks(rollback_type);
CREATE INDEX IF NOT EXISTS idx_token_usage_session ON token_usage(session_id);
CREATE INDEX IF NOT EXISTS idx_token_usage_recorded ON token_usage(recorded_at);
CREATE INDEX IF NOT EXISTS idx_error_log_session ON error_log(session_id);
CREATE INDEX IF NOT EXISTS idx_error_log_type ON error_log(error_type);
CREATE INDEX IF NOT EXISTS idx_dead_letter_status ON dead_letter(status);

-- ============================================================================
-- ADDITIONAL VIEWS
-- ============================================================================

-- Token usage by session
CREATE VIEW IF NOT EXISTS v_session_cost AS
SELECT
    session_id,
    COUNT(*) as api_calls,
    SUM(input_tokens) as total_input_tokens,
    SUM(output_tokens) as total_output_tokens,
    SUM(input_tokens + output_tokens) as total_tokens,
    ROUND(SUM(cost_usd), 4) as total_cost_usd,
    MIN(recorded_at) as first_call,
    MAX(recorded_at) as last_call
FROM token_usage
GROUP BY session_id;

-- Token usage by day
CREATE VIEW IF NOT EXISTS v_daily_cost AS
SELECT
    date(recorded_at) as date,
    COUNT(*) as api_calls,
    SUM(input_tokens + output_tokens) as total_tokens,
    ROUND(SUM(cost_usd), 4) as total_cost_usd
FROM token_usage
GROUP BY date(recorded_at);

-- Error summary
CREATE VIEW IF NOT EXISTS v_error_summary AS
SELECT
    error_type,
    COUNT(*) as occurrences,
    SUM(CASE WHEN recovery_success THEN 1 ELSE 0 END) as recovered,
    SUM(CASE WHEN circuit_opened THEN 1 ELSE 0 END) as circuits_opened
FROM error_log
GROUP BY error_type;

-- ============================================================================
-- SCHEMA VERSION UPDATE
-- ============================================================================

INSERT OR REPLACE INTO schema_version (version) VALUES (2);
