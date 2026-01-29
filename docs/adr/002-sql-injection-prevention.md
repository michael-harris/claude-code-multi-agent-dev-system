# ADR 002: SQL Injection Prevention Strategy

## Status
Accepted

## Date
2026-01-29

## Context

Using SQLite from shell scripts creates SQL injection risks. User input (commands, agent names, etc.) is incorporated into SQL queries. Without proper handling, malicious input could:

- Exfiltrate sensitive data
- Modify execution state
- Delete audit logs
- Corrupt the database

Bash scripts cannot use true prepared statements like application languages can.

## Decision

Implement a multi-layered defense strategy:

### Layer 1: Input Validation

Validate all inputs against whitelists where possible:

```bash
# Valid field names (whitelist)
readonly VALID_SESSION_FIELDS=(
    "status"
    "current_phase"
    "current_model"
    # ... only allowed fields
)

validate_field_name() {
    local field="$1"
    if ! _in_array "$field" "${VALID_SESSION_FIELDS[@]}"; then
        log_error "Invalid field name: $field"
        return 1
    fi
}
```

### Layer 2: Format Validation

Validate formats for structured data:

```bash
# Session IDs must match format
validate_session_id() {
    local session_id="$1"
    if [[ ! "$session_id" =~ ^session-[0-9]{8}-[0-9]{6}-[a-f0-9]+$ ]]; then
        return 1
    fi
}

# Numeric values must be numeric
validate_numeric() {
    local value="$1"
    if [[ ! "$value" =~ ^[0-9]+$ ]]; then
        return 1
    fi
}
```

### Layer 3: SQL Escaping

Escape special characters in string values:

```bash
sql_escape() {
    local value="$1"
    # Double single quotes (SQL standard)
    value="${value//\'/\'\'}"
    # Escape backslashes
    value="${value//\\/\\\\}"
    echo "$value"
}
```

### Layer 4: Query Construction

Use escaped values in queries:

```bash
set_state() {
    local field="$1"
    local value="$2"

    # Validate field (Layer 1)
    validate_field_name "$field" || return 1

    # Escape value (Layer 3)
    local escaped
    escaped=$(sql_escape "$value")

    # Construct safe query
    sql_exec "UPDATE sessions SET $field = '$escaped' WHERE ..."
}
```

## Consequences

### Positive
- Defense in depth prevents single-point failures
- Validation catches issues early with clear errors
- Escaping handles edge cases in string data
- Whitelists prevent unexpected field access

### Negative
- Performance overhead for validation
- More verbose code
- Must maintain whitelists as schema changes

### Trade-offs
- Security over convenience
- Validation over flexibility
- Explicit over implicit

## Alternatives Considered

| Alternative | Why Rejected |
|------------|--------------|
| Python wrapper | Added complexity, dependency |
| Prepared statements | Not available in sqlite3 CLI |
| No escaping | Unacceptable security risk |
| Escape only | Validation catches more issues |

## Implementation Notes

All SQL operations go through:
1. `scripts/lib/common.sh` - Validation and escaping utilities
2. `scripts/state.sh` - State management with validation
3. `scripts/events.sh` - Event logging with validation

## Related Decisions
- ADR 001: SQLite State Management
- ADR 003: Error Handling Strategy
