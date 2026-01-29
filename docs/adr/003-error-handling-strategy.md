# ADR 003: Error Handling Strategy

## Status
Accepted

## Date
2026-01-29

## Context

Shell scripts traditionally fail silently or continue after errors. This creates problems:

- Errors go unnoticed until cascading failures
- Debugging is difficult without error context
- State corruption from partial operations
- User confusion when commands don't work

DevTeam shell scripts need reliable error handling for:
- Database operations
- File operations
- External command execution
- Validation failures

## Decision

Implement comprehensive error handling across all shell scripts.

### 1. Strict Mode

All scripts start with strict mode:

```bash
#!/bin/bash
set -euo pipefail
```

| Flag | Meaning | Benefit |
|------|---------|---------|
| `-e` | Exit on error | Stops execution at first failure |
| `-u` | Error on undefined | Catches typos and missing vars |
| `-o pipefail` | Pipeline errors | Catches failures in piped commands |

### 2. Structured Logging

Use consistent logging functions:

```bash
log_debug() { log "debug" "$1" "${2:-}"; }
log_info()  { log "info" "$1" "${2:-}"; }
log_warn()  { log "warn" "$1" "${2:-}"; }
log_error() { log "error" "$1" "${2:-}"; }
```

Output format:
```
[2026-01-29 12:00:00] [devteam] [error] [context] Message here
```

### 3. Error Trap

Set up trap to catch errors:

```bash
on_error() {
    local line_no="$1"
    local error_code="$2"
    log_error "Error on line $line_no (exit code: $error_code)"
}

setup_error_trap() {
    trap 'on_error ${LINENO} $?' ERR
}
```

### 4. Function Return Codes

All functions return meaningful codes:

```bash
my_function() {
    if [ -z "$1" ]; then
        log_error "Parameter required"
        return 1  # Explicit failure
    fi

    if ! some_operation; then
        log_error "Operation failed"
        return 1
    fi

    return 0  # Explicit success
}
```

### 5. SQL Error Handling

Wrap SQL operations:

```bash
sql_exec() {
    local query="$1"

    local result
    if ! result=$(sqlite3 "$DB_FILE" "$query" 2>&1); then
        log_error "SQL execution failed: $result"
        return 1
    fi

    echo "$result"
}
```

## Consequences

### Positive
- Errors are caught immediately
- Clear error messages with context
- Easier debugging via log levels
- Prevents silent corruption

### Negative
- Scripts may exit unexpectedly
- More verbose code
- Must handle expected failures explicitly

### Patterns for Expected Failures

```bash
# When failure is acceptable
result=$(some_command) || result=""

# When you want to continue despite error
if ! some_command; then
    log_warn "Command failed, continuing..."
fi

# For optional operations
some_command || true
```

## Log Levels

| Level | When to Use |
|-------|-------------|
| `debug` | Internal details, disabled by default |
| `info` | Normal operation milestones |
| `warn` | Recoverable issues |
| `error` | Failures requiring attention |

Control via environment:
```bash
export DEVTEAM_LOG_LEVEL=debug
```

## Related Decisions
- ADR 001: SQLite State Management
- ADR 002: SQL Injection Prevention
