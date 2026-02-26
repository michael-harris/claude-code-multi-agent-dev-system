#!/bin/bash
# DevTeam Test Runner
# Runs all tests and reports results
#
# Usage: ./tests/run-tests.sh [test-file]

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0
TESTS_SKIPPED=0

# Test results
declare -a FAILED_TESTS=()

# ============================================================================
# TEST HELPERS
# ============================================================================

log_test() {
    echo -e "${BLUE}[TEST]${NC} $1"
}

log_pass() {
    echo -e "${GREEN}[PASS]${NC} $1"
    ((TESTS_PASSED++))
}

log_fail() {
    echo -e "${RED}[FAIL]${NC} $1"
    ((TESTS_FAILED++))
    FAILED_TESTS+=("$1")
}

log_skip() {
    echo -e "${YELLOW}[SKIP]${NC} $1"
    ((TESTS_SKIPPED++))
}

# Assert functions
assert_equals() {
    local expected="$1"
    local actual="$2"
    local message="${3:-Values should be equal}"

    ((TESTS_RUN++))

    if [ "$expected" = "$actual" ]; then
        log_pass "$message"
        return 0
    else
        log_fail "$message (expected: '$expected', got: '$actual')"
        return 1
    fi
}

assert_not_empty() {
    local value="$1"
    local message="${2:-Value should not be empty}"

    ((TESTS_RUN++))

    if [ -n "$value" ]; then
        log_pass "$message"
        return 0
    else
        log_fail "$message (value was empty)"
        return 1
    fi
}

assert_empty() {
    local value="$1"
    local message="${2:-Value should be empty}"

    ((TESTS_RUN++))

    if [ -z "$value" ]; then
        log_pass "$message"
        return 0
    else
        log_fail "$message (value was: '$value')"
        return 1
    fi
}

assert_contains() {
    local haystack="$1"
    local needle="$2"
    local message="${3:-String should contain substring}"

    ((TESTS_RUN++))

    if [[ "$haystack" == *"$needle"* ]]; then
        log_pass "$message"
        return 0
    else
        log_fail "$message (string did not contain '$needle')"
        return 1
    fi
}

assert_matches() {
    local value="$1"
    local pattern="$2"
    local message="${3:-Value should match pattern}"

    ((TESTS_RUN++))

    if [[ "$value" =~ $pattern ]]; then
        log_pass "$message"
        return 0
    else
        log_fail "$message (value '$value' did not match pattern '$pattern')"
        return 1
    fi
}

assert_file_exists() {
    local file="$1"
    local message="${2:-File should exist}"

    ((TESTS_RUN++))

    if [ -f "$file" ]; then
        log_pass "$message"
        return 0
    else
        log_fail "$message (file not found: $file)"
        return 1
    fi
}

assert_command_succeeds() {
    local cmd="$1"
    local message="${2:-Command should succeed}"

    ((TESTS_RUN++))

    if eval "$cmd" > /dev/null 2>&1; then
        log_pass "$message"
        return 0
    else
        log_fail "$message (command failed: $cmd)"
        return 1
    fi
}

assert_command_fails() {
    local cmd="$1"
    local message="${2:-Command should fail}"

    ((TESTS_RUN++))

    if ! eval "$cmd" > /dev/null 2>&1; then
        log_pass "$message"
        return 0
    else
        log_fail "$message (command succeeded when it should have failed: $cmd)"
        return 1
    fi
}

# ============================================================================
# TEST SETUP/TEARDOWN
# ============================================================================

setup_test_db() {
    export DEVTEAM_DIR="$SCRIPT_DIR/.test-devteam"
    export DB_FILE="$DEVTEAM_DIR/devteam.db"

    # Clean up any existing test database
    rm -rf "$DEVTEAM_DIR"
    mkdir -p "$DEVTEAM_DIR"

    # Initialize fresh database
    bash "$PROJECT_ROOT/scripts/db-init.sh" > /dev/null 2>&1
}

teardown_test_db() {
    rm -rf "$SCRIPT_DIR/.test-devteam"
    unset DEVTEAM_DIR
    unset DB_FILE
}

# ============================================================================
# COMMON LIBRARY TESTS
# ============================================================================

test_common_library() {
    log_test "Testing common library..."

    source "$PROJECT_ROOT/scripts/lib/common.sh"

    # Test sql_escape
    local escaped
    escaped=$(sql_escape "test'value")
    assert_equals "test''value" "$escaped" "sql_escape should escape single quotes"

    escaped=$(sql_escape "test\\value")
    assert_equals "test\\\\value" "$escaped" "sql_escape should escape backslashes"

    # Test validate_numeric
    assert_command_succeeds "validate_numeric 123" "validate_numeric should accept integers"
    assert_command_fails "validate_numeric abc" "validate_numeric should reject non-numbers"
    assert_command_fails "validate_numeric 12.34" "validate_numeric should reject decimals"

    # Test validate_decimal
    assert_command_succeeds "validate_decimal 123" "validate_decimal should accept integers"
    assert_command_succeeds "validate_decimal 12.34" "validate_decimal should accept decimals"
    assert_command_fails "validate_decimal abc" "validate_decimal should reject non-numbers"

    # Test generate_id
    local id
    id=$(generate_id "test")
    assert_matches "$id" "^test-[0-9]{8}-[0-9]{6}-[a-f0-9]+$" "generate_id should match expected format"
}

# ============================================================================
# STATE MANAGEMENT TESTS
# ============================================================================

test_state_management() {
    log_test "Testing state management..."

    setup_test_db
    source "$PROJECT_ROOT/scripts/state.sh"

    # Test session creation
    local session_id
    session_id=$(start_session "test command" "feature")
    assert_not_empty "$session_id" "start_session should return session ID"
    assert_matches "$session_id" "^session-" "Session ID should start with 'session-'"

    # Test get_current_session_id
    local current
    current=$(get_current_session_id)
    assert_equals "$session_id" "$current" "get_current_session_id should return current session"

    # Test is_session_running
    if is_session_running; then
        log_pass "is_session_running returns true when session active"
        ((TESTS_RUN++))
        ((TESTS_PASSED++))
    else
        log_fail "is_session_running should return true"
        ((TESTS_RUN++))
        ((TESTS_FAILED++))
    fi

    # Test set_phase and get_current_phase
    set_phase "executing"
    local phase
    phase=$(get_current_phase)
    assert_equals "executing" "$phase" "Phase should be set correctly"

    # Test iteration increment
    increment_iteration
    local iteration
    iteration=$(get_current_iteration)
    assert_equals "1" "$iteration" "Iteration should be incremented to 1"

    # Test failures tracking
    increment_failures
    local failures
    failures=$(get_consecutive_failures)
    assert_equals "1" "$failures" "Failures should be incremented to 1"

    reset_failures
    failures=$(get_consecutive_failures)
    assert_equals "0" "$failures" "Failures should be reset to 0"

    # Test end session
    end_session "completed" "Test finished"
    if ! is_session_running; then
        log_pass "is_session_running returns false after session ended"
        ((TESTS_RUN++))
        ((TESTS_PASSED++))
    else
        log_fail "Session should not be running after end_session"
        ((TESTS_RUN++))
        ((TESTS_FAILED++))
    fi

    teardown_test_db
}

# ============================================================================
# VALIDATION TESTS
# ============================================================================

test_validation() {
    log_test "Testing input validation..."

    source "$PROJECT_ROOT/scripts/lib/common.sh"

    # Test session ID validation
    assert_command_succeeds "validate_session_id 'session-20260129-120000-abcd1234'" \
        "Valid session ID should pass validation"

    assert_command_fails "validate_session_id 'invalid-session'" \
        "Invalid session ID should fail validation"

    assert_command_fails "validate_session_id \"'; DROP TABLE sessions; --\"" \
        "SQL injection attempt should fail validation"

    # Test field name validation
    assert_command_succeeds "validate_field_name 'status'" \
        "Valid field name should pass validation"

    assert_command_fails "validate_field_name 'invalid_field'" \
        "Invalid field name should fail validation"

    assert_command_fails "validate_field_name \"status; DROP TABLE\"" \
        "SQL injection in field name should fail validation"

    # Test phase validation
    assert_command_succeeds "validate_phase 'executing'" \
        "Valid phase should pass validation"

    assert_command_fails "validate_phase 'invalid_phase'" \
        "Invalid phase should fail validation"

    # Test model validation
    assert_command_succeeds "validate_model 'sonnet'" \
        "Valid model should pass validation"

    assert_command_fails "validate_model 'gpt-4'" \
        "Invalid model should fail validation"
}

# ============================================================================
# SQL INJECTION PREVENTION TESTS
# ============================================================================

test_sql_injection_prevention() {
    log_test "Testing SQL injection prevention..."

    setup_test_db
    source "$PROJECT_ROOT/scripts/state.sh"

    # Start a session for testing
    local session_id
    session_id=$(start_session "test" "test")

    # Try SQL injection via command
    local malicious_command="'; DROP TABLE sessions; --"
    end_session "completed" "test"

    session_id=$(start_session "$malicious_command" "test")

    # Verify database still works
    local count
    count=$(sqlite3 "$DB_FILE" "SELECT COUNT(*) FROM sessions;")
    assert_not_empty "$count" "Database should still be intact after injection attempt"

    # Try injection via set_state (should be blocked by validation)
    # This should fail validation, not execute
    if ! set_state "status; DROP TABLE sessions" "value" 2>/dev/null; then
        log_pass "SQL injection via field name blocked"
        ((TESTS_RUN++))
        ((TESTS_PASSED++))
    else
        log_fail "SQL injection via field name should be blocked"
        ((TESTS_RUN++))
        ((TESTS_FAILED++))
    fi

    # Verify tables still exist
    local tables
    tables=$(sqlite3 "$DB_FILE" "SELECT name FROM sqlite_master WHERE type='table' AND name='sessions';")
    assert_equals "sessions" "$tables" "Sessions table should still exist"

    teardown_test_db
}

# ============================================================================
# EVENT LOGGING TESTS
# ============================================================================

test_event_logging() {
    log_test "Testing event logging..."

    setup_test_db
    source "$PROJECT_ROOT/scripts/events.sh"

    # Start a session
    local session_id
    session_id=$(start_session "test command" "feature")

    # Log various events
    log_phase_changed "executing" "initializing"
    log_agent_started "test-agent" "sonnet" "task-1"
    log_agent_completed "test-agent" "sonnet" "[]" 100 50 5
    log_gate_passed "lint" "{}"

    # Query events
    local event_count
    event_count=$(sqlite3 "$DB_FILE" "SELECT COUNT(*) FROM events WHERE session_id='$session_id';")

    if [ "$event_count" -ge 4 ]; then
        log_pass "Events were logged correctly ($event_count events)"
        ((TESTS_RUN++))
        ((TESTS_PASSED++))
    else
        log_fail "Expected at least 4 events, got $event_count"
        ((TESTS_RUN++))
        ((TESTS_FAILED++))
    fi

    teardown_test_db
}

# ============================================================================
# FILE STRUCTURE TESTS
# ============================================================================

test_file_structure() {
    log_test "Testing project file structure..."

    assert_file_exists "$PROJECT_ROOT/plugin.json" "plugin.json should exist"
    assert_file_exists "$PROJECT_ROOT/scripts/state.sh" "scripts/state.sh should exist"
    assert_file_exists "$PROJECT_ROOT/scripts/events.sh" "scripts/events.sh should exist"
    assert_file_exists "$PROJECT_ROOT/scripts/db-init.sh" "scripts/db-init.sh should exist"
    assert_file_exists "$PROJECT_ROOT/scripts/lib/common.sh" "scripts/lib/common.sh should exist"
    assert_file_exists "$PROJECT_ROOT/scripts/schema.sql" "scripts/schema.sql should exist"

    # Check agent directories
    assert_file_exists "$PROJECT_ROOT/agents/orchestration/task-loop.md" "Task Loop agent should exist"

    # Check commands directory
    local cmd_count
    cmd_count=$(find "$PROJECT_ROOT/commands" -name "*.md" | wc -l)
    if [ "$cmd_count" -ge 10 ]; then
        log_pass "Commands directory has sufficient files ($cmd_count)"
        ((TESTS_RUN++))
        ((TESTS_PASSED++))
    else
        log_fail "Expected at least 10 command files, got $cmd_count"
        ((TESTS_RUN++))
        ((TESTS_FAILED++))
    fi
}

# ============================================================================
# CONFIGURATION TESTS
# ============================================================================

test_configuration() {
    log_test "Testing configuration files..."

    # Check plugin.json is valid JSON
    if command -v jq &> /dev/null; then
        if jq empty "$PROJECT_ROOT/plugin.json" 2>/dev/null; then
            log_pass "plugin.json is valid JSON"
            ((TESTS_RUN++))
            ((TESTS_PASSED++))
        else
            log_fail "plugin.json is not valid JSON"
            ((TESTS_RUN++))
            ((TESTS_FAILED++))
        fi

        # Check required fields in plugin.json
        local name
        name=$(jq -r '.name' "$PROJECT_ROOT/plugin.json")
        assert_not_empty "$name" "plugin.json should have a name field"

        local agent_count
        agent_count=$(jq '.agents | length' "$PROJECT_ROOT/plugin.json")
        if [ "$agent_count" -ge 80 ]; then
            log_pass "plugin.json has sufficient agents ($agent_count)"
            ((TESTS_RUN++))
            ((TESTS_PASSED++))
        else
            log_fail "Expected at least 80 agents, got $agent_count"
            ((TESTS_RUN++))
            ((TESTS_FAILED++))
        fi
    else
        log_skip "jq not installed, skipping JSON validation tests"
    fi
}

# ============================================================================
# MAIN TEST RUNNER
# ============================================================================

print_summary() {
    echo ""
    echo "============================================"
    echo "               TEST SUMMARY                 "
    echo "============================================"
    echo -e "Tests Run:    ${BLUE}$TESTS_RUN${NC}"
    echo -e "Passed:       ${GREEN}$TESTS_PASSED${NC}"
    echo -e "Failed:       ${RED}$TESTS_FAILED${NC}"
    echo -e "Skipped:      ${YELLOW}$TESTS_SKIPPED${NC}"
    echo "============================================"

    if [ ${#FAILED_TESTS[@]} -gt 0 ]; then
        echo ""
        echo -e "${RED}Failed Tests:${NC}"
        for test in "${FAILED_TESTS[@]}"; do
            echo "  - $test"
        done
    fi

    echo ""
    if [ $TESTS_FAILED -eq 0 ]; then
        echo -e "${GREEN}All tests passed!${NC}"
        return 0
    else
        echo -e "${RED}Some tests failed.${NC}"
        return 1
    fi
}

run_all_tests() {
    echo "============================================"
    echo "         DevTeam Test Suite                "
    echo "============================================"
    echo ""

    test_common_library
    echo ""

    test_validation
    echo ""

    test_state_management
    echo ""

    test_sql_injection_prevention
    echo ""

    test_event_logging
    echo ""

    test_file_structure
    echo ""

    test_configuration

    print_summary
}

# Run specific test file or all tests
if [ $# -gt 0 ]; then
    test_file="$1"
    if [ -f "$test_file" ]; then
        source "$test_file"
    else
        echo "Test file not found: $test_file"
        exit 1
    fi
else
    run_all_tests
fi
