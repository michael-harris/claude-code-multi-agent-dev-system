-- DevTeam SQLite Schema v4
-- Fixes: Missing ON DELETE SET NULL on plans.research_session_id
-- Migrates from v3
-- Transaction management handled by db-init.sh run_migrations()

-- Recreate plans table with proper foreign key constraint
CREATE TABLE IF NOT EXISTS plans_new (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    description TEXT,
    plan_type TEXT,
    prd_path TEXT,
    tasks_path TEXT,
    sprints_path TEXT,
    status TEXT DEFAULT 'draft',
    total_sprints INTEGER DEFAULT 0,
    completed_sprints INTEGER DEFAULT 0,
    total_tasks INTEGER DEFAULT 0,
    completed_tasks INTEGER DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    started_at TIMESTAMP,
    completed_at TIMESTAMP,
    research_session_id INTEGER REFERENCES research_sessions(id) ON DELETE SET NULL
);

-- Migrate existing data
INSERT INTO plans_new SELECT * FROM plans;

-- Swap tables
DROP TABLE IF EXISTS plans;
ALTER TABLE plans_new RENAME TO plans;

-- Recreate index
CREATE INDEX IF NOT EXISTS idx_plans_status ON plans(status);
