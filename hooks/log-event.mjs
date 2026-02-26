#!/usr/bin/env node
// Cross-platform event logger for DevTeam hooks
// Logs events to .devteam/devteam.db via sqlite3 CLI.
// Best-effort — silently no-ops if sqlite3 or DB is unavailable.

import { execSync } from 'node:child_process';
import { existsSync } from 'node:fs';

const [, , eventType, category, message, data = '{}'] = process.argv;
const dbFile = '.devteam/devteam.db';

if (!eventType || !existsSync(dbFile)) {
  process.exit(0);
}

// Escape single quotes for SQL
const esc = (s) => (s || '').replace(/'/g, "''");

const sql = `INSERT INTO events (session_id, event_type, event_category, message, data, timestamp)
VALUES (
  (SELECT id FROM sessions WHERE status = 'running' ORDER BY started_at DESC LIMIT 1),
  '${esc(eventType)}',
  '${esc(category)}',
  '${esc(message)}',
  '${esc(data)}',
  datetime('now')
);`;

try {
  execSync(`sqlite3 "${dbFile}"`, {
    input: sql,
    stdio: ['pipe', 'ignore', 'ignore'],
    timeout: 5000,
  });
} catch {
  // Best-effort logging — don't block on failure
}
