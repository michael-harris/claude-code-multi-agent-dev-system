#!/usr/bin/env node
// Cross-platform event logger for DevTeam hooks
// Logs events to .devteam/devteam.db via sqlite3 CLI.
// Best-effort — silently no-ops if sqlite3 or DB is unavailable.

'use strict';

const { execSync } = require('child_process');
const { existsSync } = require('fs');

var eventType = process.argv[2];
var category = process.argv[3];
var message = process.argv[4];
var data = process.argv[5] || '{}';
var dbFile = '.devteam/devteam.db';

if (!eventType || !existsSync(dbFile)) {
  process.exit(0);
}

// Escape single quotes for SQL
function esc(s) {
  return (s || '').replace(/'/g, "''");
}

var sql = "INSERT INTO events (session_id, event_type, event_category, message, data, timestamp) " +
  "VALUES (" +
  "(SELECT id FROM sessions WHERE status = 'running' ORDER BY started_at DESC LIMIT 1), " +
  "'" + esc(eventType) + "', " +
  "'" + esc(category) + "', " +
  "'" + esc(message) + "', " +
  "'" + esc(data) + "', " +
  "datetime('now'));";

try {
  execSync('sqlite3 "' + dbFile + '"', {
    input: sql,
    stdio: ['pipe', 'ignore', 'ignore'],
    timeout: 5000,
  });
} catch (e) {
  // Best-effort logging — don't block on failure
}
