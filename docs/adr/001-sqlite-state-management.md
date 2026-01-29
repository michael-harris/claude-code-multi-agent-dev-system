# ADR 001: SQLite for State Management

## Status
Accepted

## Date
2026-01-29

## Context

DevTeam needs persistent state management to track:
- Active sessions and their status
- Execution history and events
- Cost tracking and token usage
- Quality gate results
- Escalation records

Initial implementation used YAML files, which had issues:
- Concurrent access caused data corruption
- No query capability for historical analysis
- No transaction support
- File-based locking was unreliable

## Decision

Use SQLite as the state management backend.

### Rationale

1. **ACID Compliance**: Transactions prevent data corruption
2. **Single File**: Easy to backup, move, and manage
3. **No Server**: Works without external dependencies
4. **Query Support**: SQL enables complex historical queries
5. **Cross-Platform**: Works on Linux, macOS, Windows
6. **Bash Integration**: `sqlite3` CLI is widely available

### Schema Design

```sql
-- Core session tracking
CREATE TABLE sessions (
    id TEXT PRIMARY KEY,
    command TEXT,
    status TEXT,
    current_phase TEXT,
    current_model TEXT,
    -- ... additional fields
);

-- Event log for audit trail
CREATE TABLE events (
    id INTEGER PRIMARY KEY,
    session_id TEXT,
    event_type TEXT,
    message TEXT,
    timestamp DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- Additional tables for specific concerns
```

## Consequences

### Positive
- Reliable state persistence
- Query historical data easily
- Transaction support prevents corruption
- Familiar SQL interface for maintenance

### Negative
- Requires sqlite3 installation
- Binary file not human-readable
- Shell scripts need careful SQL escaping

### Mitigations
- Document sqlite3 installation in setup guide
- Provide database inspection tools
- Create sql_escape() function for safe queries

## Alternatives Considered

| Alternative | Why Rejected |
|------------|--------------|
| YAML files | No transactions, corruption issues |
| JSON files | Same issues as YAML |
| PostgreSQL | Requires server, over-engineered |
| Redis | Requires server, not persistent by default |

## Related Decisions
- ADR 002: SQL Injection Prevention
- ADR 003: Error Handling Strategy
