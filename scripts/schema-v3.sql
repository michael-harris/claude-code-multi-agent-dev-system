-- Schema v3 Migration (no-op)
-- All indexes and views in this migration were already defined in schema.sql
-- with IF NOT EXISTS clauses. This migration is retained for version tracking
-- continuity but applies no changes.
--
-- Original description: Indexes and views for tasks, task_attempts, task_files tables
-- Tables are defined in schema.sql; this file adds supplementary indexes and views
-- Migrates from v2 - run after schema-v2.sql
-- Version: 3.0.0

-- ============================================================================
-- INDEXES FOR TASK TABLES
-- ============================================================================

CREATE INDEX IF NOT EXISTS idx_tasks_status ON tasks(status);
CREATE INDEX IF NOT EXISTS idx_tasks_plan ON tasks(plan_id);
CREATE INDEX IF NOT EXISTS idx_tasks_sprint ON tasks(sprint_id);
CREATE INDEX IF NOT EXISTS idx_tasks_priority ON tasks(priority);
CREATE INDEX IF NOT EXISTS idx_task_attempts_task ON task_attempts(task_id);
CREATE INDEX IF NOT EXISTS idx_task_attempts_session ON task_attempts(session_id);
CREATE INDEX IF NOT EXISTS idx_task_files_task ON task_files(task_id);
CREATE INDEX IF NOT EXISTS idx_tasks_session ON tasks(session_id);

-- ============================================================================
-- VIEWS FOR TASKS
-- ============================================================================

-- Current in-progress task
CREATE VIEW IF NOT EXISTS v_current_task AS
SELECT * FROM tasks WHERE status = 'in_progress' ORDER BY started_at DESC LIMIT 1;

-- Task progress by sprint
CREATE VIEW IF NOT EXISTS v_sprint_progress AS
SELECT
    sprint_id,
    COUNT(*) as total_tasks,
    SUM(CASE WHEN status = 'completed' THEN 1 ELSE 0 END) as completed,
    SUM(CASE WHEN status = 'in_progress' THEN 1 ELSE 0 END) as in_progress,
    SUM(CASE WHEN status = 'failed' THEN 1 ELSE 0 END) as failed,
    SUM(CASE WHEN status = 'pending' THEN 1 ELSE 0 END) as pending,
    ROUND(AVG(CASE WHEN status = 'completed' THEN 1.0 ELSE 0.0 END) * 100, 1) as completion_rate
FROM tasks
WHERE sprint_id IS NOT NULL
GROUP BY sprint_id;

-- Task attempt summary
CREATE VIEW IF NOT EXISTS v_task_attempts_summary AS
SELECT
    task_id,
    COUNT(*) as total_attempts,
    SUM(CASE WHEN status = 'success' THEN 1 ELSE 0 END) as successes,
    SUM(CASE WHEN status = 'failed' THEN 1 ELSE 0 END) as failures,
    MAX(attempt_number) as last_attempt,
    SUM(tokens_input + tokens_output) as total_tokens,
    SUM(cost_cents) as total_cost_cents
FROM task_attempts
GROUP BY task_id;

-- Note: Schema version is managed by db-init.sh
