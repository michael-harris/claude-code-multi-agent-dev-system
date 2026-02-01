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
-- SCHEMA VERSION UPDATE
-- ============================================================================

INSERT OR REPLACE INTO schema_version (version) VALUES (2);
