#!/bin/bash
# DevTeam Hooks Test Suite
# Tests all hook functionality
#
# Usage: ./test-hooks.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HOOKS_DIR="$(dirname "$SCRIPT_DIR")"
PROJECT_ROOT="$(dirname "$HOOKS_DIR")"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Test counters
TESTS_PASSED=0
TESTS_FAILED=0
TESTS_SKIPPED=0

# Test helper functions
run_test() {
    local name="$1"
    local expected_exit="$2"
    shift 2

    echo -n "  Testing: $name... "

    local result
    local exit_code
    result=$("$@" 2>&1) || exit_code=$?
    exit_code=${exit_code:-0}

    if [[ "$exit_code" -eq "$expected_exit" ]]; then
        echo -e "${GREEN}PASS${NC}"
        TESTS_PASSED=$((TESTS_PASSED + 1))
        return 0
    else
        echo -e "${RED}FAIL${NC} (expected exit $expected_exit, got $exit_code)"
        echo "    Output: ${result:0:100}..."
        TESTS_FAILED=$((TESTS_FAILED + 1))
        return 1
    fi
}

assert_contains() {
    local output="$1"
    local expected="$2"
    local name="$3"

    echo -n "  Assert: $name... "

    if echo "$output" | grep -q "$expected"; then
        echo -e "${GREEN}PASS${NC}"
        TESTS_PASSED=$((TESTS_PASSED + 1))
        return 0
    else
        echo -e "${RED}FAIL${NC} (expected to contain: $expected)"
        TESTS_FAILED=$((TESTS_FAILED + 1))
        return 1
    fi
}

skip_test() {
    local name="$1"
    local reason="$2"
    echo -e "  Testing: $name... ${YELLOW}SKIP${NC} ($reason)"
    TESTS_SKIPPED=$((TESTS_SKIPPED + 1))
}

# ============================================================================
# SETUP
# ============================================================================

echo ""
echo "================================================================"
echo "         DevTeam Hooks Test Suite"
echo "================================================================"
echo ""

# Create temporary test environment
TEST_DIR=$(mktemp -d)
trap "rm -rf $TEST_DIR" EXIT

# Set up minimal .devteam directory
mkdir -p "$TEST_DIR/.devteam"
export DEVTEAM_DIR="$TEST_DIR/.devteam"
export DEVTEAM_ROOT="$TEST_DIR"

echo "Test directory: $TEST_DIR"
echo ""

# ============================================================================
# TEST: Hook Library Loads
# ============================================================================

echo "Testing: Hook Library"
echo ""

echo -n "  Testing: hook-common.sh loads... "
if source "$HOOKS_DIR/lib/hook-common.sh" 2>/dev/null; then
    echo -e "${GREEN}PASS${NC}"
    TESTS_PASSED=$((TESTS_PASSED + 1))
else
    echo -e "${RED}FAIL${NC}"
    TESTS_FAILED=$((TESTS_FAILED + 1))
fi

echo -n "  Testing: init_hook function exists... "
if type init_hook &>/dev/null; then
    echo -e "${GREEN}PASS${NC}"
    TESTS_PASSED=$((TESTS_PASSED + 1))
else
    echo -e "${RED}FAIL${NC}"
    TESTS_FAILED=$((TESTS_FAILED + 1))
fi

echo -n "  Testing: inject_system_message function exists... "
if type inject_system_message &>/dev/null; then
    echo -e "${GREEN}PASS${NC}"
    TESTS_PASSED=$((TESTS_PASSED + 1))
else
    echo -e "${RED}FAIL${NC}"
    TESTS_FAILED=$((TESTS_FAILED + 1))
fi

echo ""

# ============================================================================
# TEST: Persistence Hook
# ============================================================================

echo "Testing: Persistence Hook"
echo ""

# Test: Detects "I give up"
export CLAUDE_OUTPUT="I give up on this task"
run_test "detects 'I give up'" 2 "$HOOKS_DIR/persistence-hook.sh"

# Test: Detects "I'm stuck"
export CLAUDE_OUTPUT="I'm stuck and cannot proceed"
run_test "detects 'I'm stuck'" 2 "$HOOKS_DIR/persistence-hook.sh"

# Test: Allows EXIT_SIGNAL
export CLAUDE_OUTPUT="Task complete. EXIT_SIGNAL: true"
run_test "allows EXIT_SIGNAL" 0 "$HOOKS_DIR/persistence-hook.sh"

# Test: Allows empty message
export CLAUDE_OUTPUT=""
run_test "allows empty message" 0 "$HOOKS_DIR/persistence-hook.sh"

# Test: Detects passive abandonment
export CLAUDE_OUTPUT="Let me know if you need anything else"
run_test "detects passive abandonment" 2 "$HOOKS_DIR/persistence-hook.sh"

# Test: Allows normal completion
export CLAUDE_OUTPUT="All tests passing. Implementation complete."
run_test "allows normal completion" 0 "$HOOKS_DIR/persistence-hook.sh"

echo ""

# ============================================================================
# TEST: Stop Hook
# ============================================================================

echo "Testing: Stop Hook"
echo ""

# Clean up autonomous mode marker
rm -f "$TEST_DIR/.devteam/autonomous-mode"

# Test: Allows exit when not in autonomous mode
export STOP_HOOK_MESSAGE=""
run_test "allows exit when not autonomous" 0 "$HOOKS_DIR/stop-hook.sh"

# Enable autonomous mode
touch "$TEST_DIR/.devteam/autonomous-mode"

# Test: Allows EXIT_SIGNAL in autonomous mode
export STOP_HOOK_MESSAGE="EXIT_SIGNAL: true"
run_test "allows EXIT_SIGNAL in autonomous" 0 "$HOOKS_DIR/stop-hook.sh"

# Re-enable for next test (EXIT_SIGNAL removes it)
touch "$TEST_DIR/.devteam/autonomous-mode"

# Test: Blocks exit without signal
export STOP_HOOK_MESSAGE="I'm done for now"
run_test "blocks exit without signal" 2 "$HOOKS_DIR/stop-hook.sh"

# Clean up
rm -f "$TEST_DIR/.devteam/autonomous-mode"

echo ""

# ============================================================================
# TEST: Pre-Tool-Use Hook
# ============================================================================

echo "Testing: Pre-Tool-Use Hook"
echo ""

# Test: Allows normal tool use
export CLAUDE_TOOL_NAME="Read"
export CLAUDE_TOOL_INPUT='{"file_path": "/some/file.txt"}'
run_test "allows Read tool" 0 "$HOOKS_DIR/pre-tool-use-hook.sh"

# Test: Allows empty tool name
export CLAUDE_TOOL_NAME=""
export CLAUDE_TOOL_INPUT=""
run_test "allows empty tool name" 0 "$HOOKS_DIR/pre-tool-use-hook.sh"

# Test: Blocks dangerous rm -rf /
export CLAUDE_TOOL_NAME="Bash"
export CLAUDE_TOOL_INPUT='{"command": "rm -rf /"}'
run_test "blocks rm -rf /" 2 "$HOOKS_DIR/pre-tool-use-hook.sh"

# Test: Blocks dangerous force push
export CLAUDE_TOOL_NAME="Bash"
export CLAUDE_TOOL_INPUT='{"command": "git push --force main"}'
run_test "blocks force push to main" 2 "$HOOKS_DIR/pre-tool-use-hook.sh"

# Test: Allows safe bash command
export CLAUDE_TOOL_NAME="Bash"
export CLAUDE_TOOL_INPUT='{"command": "ls -la"}'
run_test "allows safe bash command" 0 "$HOOKS_DIR/pre-tool-use-hook.sh"

echo ""

# ============================================================================
# TEST: Post-Tool-Use Hook
# ============================================================================

echo "Testing: Post-Tool-Use Hook"
echo ""

# Test: Handles empty result
export CLAUDE_TOOL_NAME="Bash"
export CLAUDE_TOOL_RESULT=""
run_test "handles empty result" 0 "$HOOKS_DIR/post-tool-use-hook.sh"

# Test: Detects test failure
export CLAUDE_TOOL_NAME="Bash"
export CLAUDE_TOOL_RESULT="FAILED: 3 tests failed"
run_test "detects test failure" 0 "$HOOKS_DIR/post-tool-use-hook.sh"

# Reset failure counter for next test
echo "0" > "$TEST_DIR/.devteam/consecutive-failures.txt"

# Test: Detects success
export CLAUDE_TOOL_NAME="Bash"
export CLAUDE_TOOL_RESULT="All tests passing. 10 tests passed."
run_test "detects success" 0 "$HOOKS_DIR/post-tool-use-hook.sh"

echo ""

# ============================================================================
# TEST: Scope Check Hook
# ============================================================================

echo "Testing: Scope Check Hook"
echo ""

# Initialize a git repo in test dir
cd "$TEST_DIR"
git init -q
git config user.email "test@test.com"
git config user.name "Test"

# Test: Skips when no task context
rm -f "$TEST_DIR/.devteam/current-task.txt"
run_test "skips when no task context" 0 "$HOOKS_DIR/scope-check.sh"

echo ""

# ============================================================================
# TEST: System Message Injection
# ============================================================================

echo "Testing: System Message Injection"
echo ""

# Source library again to get function
source "$HOOKS_DIR/lib/hook-common.sh" 2>/dev/null || true

result=$(inject_system_message "test-tag" "Test message content")
assert_contains "$result" "<system-test-tag>" "injects opening tag"
assert_contains "$result" "Test message content" "includes message"
assert_contains "$result" "</system-test-tag>" "injects closing tag"

echo ""

# ============================================================================
# TEST: Session Start Hook
# ============================================================================

echo "Testing: Session Start Hook"
echo ""

# Test: Runs successfully with no prior session memory
cd "$TEST_DIR"
run_test "runs with no prior memory" 0 "$HOOKS_DIR/session-start.sh"

# Test: Output contains initialization header
result=$("$HOOKS_DIR/session-start.sh" 2>&1) || true
assert_contains "$result" "DevTeam Session Initialized" "outputs initialization header"

# Test: Detects Python language when pyproject.toml exists
touch "$TEST_DIR/pyproject.toml"
result=$("$HOOKS_DIR/session-start.sh" 2>&1) || true
assert_contains "$result" "python" "detects Python from pyproject.toml"
rm -f "$TEST_DIR/pyproject.toml"

# Test: Detects TypeScript language when package.json exists
echo '{}' > "$TEST_DIR/package.json"
result=$("$HOOKS_DIR/session-start.sh" 2>&1) || true
assert_contains "$result" "typescript" "detects TypeScript from package.json"
rm -f "$TEST_DIR/package.json"

# Test: Loads previous session memory when present
mkdir -p "$TEST_DIR/.devteam/memory"
echo "Previous session context here" > "$TEST_DIR/.devteam/memory/session-20260101-120000.md"
result=$("$HOOKS_DIR/session-start.sh" 2>&1) || true
assert_contains "$result" "Previous Session Context" "loads previous session memory"
rm -rf "$TEST_DIR/.devteam/memory"

echo ""

# ============================================================================
# TEST: Session End Hook
# ============================================================================

echo "Testing: Session End Hook"
echo ""

# Test: Runs successfully
cd "$TEST_DIR"
mkdir -p "$TEST_DIR/.devteam"
run_test "runs successfully" 0 "$HOOKS_DIR/session-end.sh"

# Test: Creates memory file
if ls "$TEST_DIR/.devteam/memory"/session-*.md 1>/dev/null 2>&1; then
    echo -e "  Assert: creates memory file... ${GREEN}PASS${NC}"
    TESTS_PASSED=$((TESTS_PASSED + 1))
else
    echo -e "  Assert: creates memory file... ${RED}FAIL${NC}"
    TESTS_FAILED=$((TESTS_FAILED + 1))
fi

# Test: Memory file contains expected content
LATEST_MEMORY=$(ls -t "$TEST_DIR/.devteam/memory"/session-*.md 2>/dev/null | head -1)
if [[ -n "$LATEST_MEMORY" ]]; then
    memory_content=$(cat "$LATEST_MEMORY")
    assert_contains "$memory_content" "Session Memory" "memory file contains header"
    assert_contains "$memory_content" "Resumption Instructions" "memory file contains resumption instructions"
fi

# Clean up memory files for next test
rm -rf "$TEST_DIR/.devteam/memory"

echo ""

# ============================================================================
# TEST: Pre-Compact Hook
# ============================================================================

echo "Testing: Pre-Compact Hook"
echo ""

# Test: Runs successfully
cd "$TEST_DIR"
mkdir -p "$TEST_DIR/.devteam"
run_test "runs successfully" 0 "$HOOKS_DIR/pre-compact.sh"

# Test: Creates pre-compact file
if ls "$TEST_DIR/.devteam/memory"/pre-compact-*.md 1>/dev/null 2>&1; then
    echo -e "  Assert: creates pre-compact file... ${GREEN}PASS${NC}"
    TESTS_PASSED=$((TESTS_PASSED + 1))
else
    echo -e "  Assert: creates pre-compact file... ${RED}FAIL${NC}"
    TESTS_FAILED=$((TESTS_FAILED + 1))
fi

# Test: Output contains post-compaction context
result=$("$HOOKS_DIR/pre-compact.sh" 2>&1) || true
assert_contains "$result" "Post-Compaction Context" "outputs post-compaction context"

# Test: Pre-compact file contains recovery instructions
LATEST_COMPACT=$(ls -t "$TEST_DIR/.devteam/memory"/pre-compact-*.md 2>/dev/null | head -1)
if [[ -n "$LATEST_COMPACT" ]]; then
    compact_content=$(cat "$LATEST_COMPACT")
    assert_contains "$compact_content" "Pre-Compaction State Snapshot" "compact file contains snapshot header"
    assert_contains "$compact_content" "Recovery Instructions" "compact file contains recovery instructions"
fi

# Test: Includes autonomous mode status when active
touch "$TEST_DIR/.devteam/autonomous-mode"
"$HOOKS_DIR/pre-compact.sh" >/dev/null 2>&1 || true
LATEST_COMPACT=$(ls -t "$TEST_DIR/.devteam/memory"/pre-compact-*.md 2>/dev/null | head -1)
if [[ -n "$LATEST_COMPACT" ]]; then
    compact_content=$(cat "$LATEST_COMPACT")
    assert_contains "$compact_content" "Autonomous Mode" "compact file includes autonomous mode status"
fi
rm -f "$TEST_DIR/.devteam/autonomous-mode"

# Clean up
rm -rf "$TEST_DIR/.devteam/memory"

echo ""

# ============================================================================
# TEST: File Structure
# ============================================================================

echo "Testing: File Structure"
echo ""

check_file() {
    local file="$1"
    local name="$2"
    echo -n "  Checking: $name... "
    if [[ -f "$file" ]]; then
        echo -e "${GREEN}EXISTS${NC}"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo -e "${RED}MISSING${NC}"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
}

check_file "$HOOKS_DIR/lib/hook-common.sh" "lib/hook-common.sh"
check_file "$HOOKS_DIR/lib/hook-common.ps1" "lib/hook-common.ps1"
check_file "$HOOKS_DIR/pre-tool-use-hook.sh" "pre-tool-use-hook.sh"
check_file "$HOOKS_DIR/pre-tool-use-hook.ps1" "pre-tool-use-hook.ps1"
check_file "$HOOKS_DIR/post-tool-use-hook.sh" "post-tool-use-hook.sh"
check_file "$HOOKS_DIR/post-tool-use-hook.ps1" "post-tool-use-hook.ps1"
check_file "$HOOKS_DIR/persistence-hook.sh" "persistence-hook.sh"
check_file "$HOOKS_DIR/persistence-hook.ps1" "persistence-hook.ps1"
check_file "$HOOKS_DIR/stop-hook.sh" "stop-hook.sh"
check_file "$HOOKS_DIR/stop-hook.ps1" "stop-hook.ps1"
check_file "$HOOKS_DIR/scope-check.sh" "scope-check.sh"
check_file "$HOOKS_DIR/scope-check.ps1" "scope-check.ps1"
check_file "$HOOKS_DIR/session-start.sh" "session-start.sh"
check_file "$HOOKS_DIR/session-start.ps1" "session-start.ps1"
check_file "$HOOKS_DIR/session-end.sh" "session-end.sh"
check_file "$HOOKS_DIR/session-end.ps1" "session-end.ps1"
check_file "$HOOKS_DIR/pre-compact.sh" "pre-compact.sh"
check_file "$HOOKS_DIR/pre-compact.ps1" "pre-compact.ps1"
check_file "$HOOKS_DIR/install.sh" "install.sh"
check_file "$HOOKS_DIR/install.ps1" "install.ps1"

echo ""

# ============================================================================
# SUMMARY
# ============================================================================

TOTAL=$((TESTS_PASSED + TESTS_FAILED + TESTS_SKIPPED))

echo "================================================================"
echo "                    Test Results"
echo "================================================================"
echo ""
echo -e "  ${GREEN}Passed:${NC}  $TESTS_PASSED"
echo -e "  ${RED}Failed:${NC}  $TESTS_FAILED"
echo -e "  ${YELLOW}Skipped:${NC} $TESTS_SKIPPED"
echo "  --------"
echo "  Total:   $TOTAL"
echo ""

if [[ $TESTS_FAILED -eq 0 ]]; then
    echo -e "${GREEN}All tests passed!${NC}"
    exit 0
else
    echo -e "${RED}Some tests failed.${NC}"
    exit 1
fi
