#!/bin/bash
# DevTeam Progress Indicator Library
# Provides visual progress feedback for long-running operations
#
# Usage:
#   source scripts/lib/progress.sh
#   progress_start "Analyzing codebase" 100
#   progress_update 25 "Scanning files..."
#   progress_complete "Analysis complete"

set -euo pipefail

# ============================================================================
# CONFIGURATION
# ============================================================================

# Progress bar settings
PROGRESS_WIDTH=40
PROGRESS_CHAR="="
PROGRESS_EMPTY_CHAR=" "
PROGRESS_START_CHAR="["
PROGRESS_END_CHAR="]"

# Colors
readonly PROG_GREEN='\033[0;32m'
readonly PROG_YELLOW='\033[1;33m'
readonly PROG_BLUE='\033[0;34m'
readonly PROG_NC='\033[0m'

# State
_PROGRESS_TOTAL=100
_PROGRESS_CURRENT=0
_PROGRESS_LABEL=""
_PROGRESS_START_TIME=""
_PROGRESS_ENABLED=true

# Check if output is a terminal
if [ ! -t 1 ]; then
    _PROGRESS_ENABLED=false
fi

# ============================================================================
# PROGRESS BAR FUNCTIONS
# ============================================================================

# Start a new progress operation
# Args: label, [total]
progress_start() {
    local label="$1"
    local total="${2:-100}"

    _PROGRESS_LABEL="$label"
    _PROGRESS_TOTAL="$total"
    _PROGRESS_CURRENT=0
    _PROGRESS_START_TIME=$(date +%s)

    if [ "$_PROGRESS_ENABLED" = true ]; then
        echo -en "\n${PROG_BLUE}$label${PROG_NC}\n"
        _render_progress_bar 0
    else
        echo "Starting: $label"
    fi
}

# Update progress
# Args: current, [status_message]
progress_update() {
    local current="$1"
    local message="${2:-}"

    _PROGRESS_CURRENT="$current"

    if [ "$_PROGRESS_ENABLED" = true ]; then
        _render_progress_bar "$current" "$message"
    elif [ -n "$message" ]; then
        echo "  Progress: $current/$_PROGRESS_TOTAL - $message"
    fi
}

# Increment progress by amount
# Args: [amount], [status_message]
progress_increment() {
    local amount="${1:-1}"
    local message="${2:-}"

    _PROGRESS_CURRENT=$((_PROGRESS_CURRENT + amount))
    progress_update "$_PROGRESS_CURRENT" "$message"
}

# Complete the progress
# Args: [completion_message]
progress_complete() {
    local message="${1:-Complete}"

    _PROGRESS_CURRENT="$_PROGRESS_TOTAL"

    if [ "$_PROGRESS_ENABLED" = true ]; then
        _render_progress_bar "$_PROGRESS_TOTAL" ""
        echo -e "\n${PROG_GREEN}$message${PROG_NC}"

        # Show elapsed time
        local elapsed=$(($(date +%s) - _PROGRESS_START_TIME))
        echo -e "${PROG_BLUE}Elapsed: ${elapsed}s${PROG_NC}\n"
    else
        echo "Completed: $message"
    fi
}

# Fail the progress
# Args: [error_message]
progress_fail() {
    local message="${1:-Failed}"

    if [ "$_PROGRESS_ENABLED" = true ]; then
        echo -e "\n${PROG_YELLOW}$message${PROG_NC}\n"
    else
        echo "Failed: $message"
    fi
}

# Internal: Render the progress bar
_render_progress_bar() {
    local current="$1"
    local message="${2:-}"

    local percent=$((current * 100 / _PROGRESS_TOTAL))
    local filled=$((current * PROGRESS_WIDTH / _PROGRESS_TOTAL))
    local empty=$((PROGRESS_WIDTH - filled))

    # Build the bar
    local bar="${PROGRESS_START_CHAR}"
    for ((i=0; i<filled; i++)); do
        bar+="${PROGRESS_CHAR}"
    done
    for ((i=0; i<empty; i++)); do
        bar+="${PROGRESS_EMPTY_CHAR}"
    done
    bar+="${PROGRESS_END_CHAR}"

    # Format percentage
    local pct_str
    printf -v pct_str "%3d%%" "$percent"

    # Build status line
    local status_line="$bar $pct_str"
    if [ -n "$message" ]; then
        status_line+=" - $message"
    fi

    # Print with carriage return for same-line update
    echo -en "\r${status_line}"

    # Truncate if too long
    local term_width
    term_width=$(tput cols 2>/dev/null || echo 80)
    if [ ${#status_line} -gt "$term_width" ]; then
        echo -en "\r${status_line:0:$((term_width-3))}..."
    fi
}

# ============================================================================
# SPINNER FUNCTIONS
# ============================================================================

# Spinner characters
_SPINNER_CHARS='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏'
_SPINNER_PID=""

# Start a spinner for indeterminate progress
# Args: label
spinner_start() {
    local label="$1"

    if [ "$_PROGRESS_ENABLED" = false ]; then
        echo "Processing: $label"
        return
    fi

    # Start spinner in background
    (
        local i=0
        while true; do
            local char="${_SPINNER_CHARS:i:1}"
            echo -en "\r${PROG_BLUE}${char}${PROG_NC} $label"
            sleep 0.1
            i=$(( (i + 1) % ${#_SPINNER_CHARS} ))
        done
    ) &

    _SPINNER_PID=$!
    disown $_SPINNER_PID 2>/dev/null || true
}

# Stop the spinner
# Args: [completion_message]
spinner_stop() {
    local message="${1:-Done}"

    if [ -n "$_SPINNER_PID" ]; then
        kill "$_SPINNER_PID" 2>/dev/null || true
        _SPINNER_PID=""
    fi

    if [ "$_PROGRESS_ENABLED" = true ]; then
        echo -e "\r${PROG_GREEN}✓${PROG_NC} $message"
    else
        echo "Completed: $message"
    fi
}

# ============================================================================
# TASK LIST FUNCTIONS
# ============================================================================

# Display a task list with checkboxes
# Args: task_status (pending|running|done|failed) task_name
task_item() {
    local status="$1"
    local name="$2"

    local icon
    case "$status" in
        pending) icon="○" ;;
        running) icon="${PROG_YELLOW}◉${PROG_NC}" ;;
        done)    icon="${PROG_GREEN}●${PROG_NC}" ;;
        failed)  icon="${PROG_YELLOW}✗${PROG_NC}" ;;
        *)       icon="○" ;;
    esac

    echo -e "  $icon $name"
}

# Display a step counter
# Args: current total label
step_counter() {
    local current="$1"
    local total="$2"
    local label="$3"

    echo -e "${PROG_BLUE}[$current/$total]${PROG_NC} $label"
}

# ============================================================================
# SESSION PROGRESS
# ============================================================================

# Show session progress summary
# Reads from database and displays current state
show_session_progress() {
    local session_id="${1:-}"

    # Source state functions if not already loaded
    if ! declare -f get_current_session_id > /dev/null 2>&1; then
        local script_dir
        script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
        source "${script_dir}/state.sh"
    fi

    if [ -z "$session_id" ]; then
        session_id=$(get_current_session_id) || true
    fi

    if [ -z "$session_id" ]; then
        echo "No active session"
        return
    fi

    # Get session data
    local phase iteration model failures
    phase=$(get_current_phase) || phase="unknown"
    iteration=$(get_current_iteration) || iteration=0
    model=$(get_current_model) || model="unknown"
    failures=$(get_consecutive_failures) || failures=0

    echo ""
    echo -e "${PROG_BLUE}═══════════════════════════════════════${PROG_NC}"
    echo -e "${PROG_BLUE}         Session Progress              ${PROG_NC}"
    echo -e "${PROG_BLUE}═══════════════════════════════════════${PROG_NC}"
    echo ""

    # Phase indicator
    local phases=("initializing" "interview" "research" "planning" "executing" "quality_check" "completed")
    local phase_idx=0
    for i in "${!phases[@]}"; do
        if [ "${phases[$i]}" = "$phase" ]; then
            phase_idx=$i
            break
        fi
    done

    echo "  Phases:"
    for i in "${!phases[@]}"; do
        local status="pending"
        if [ "$i" -lt "$phase_idx" ]; then
            status="done"
        elif [ "$i" -eq "$phase_idx" ]; then
            status="running"
        fi
        task_item "$status" "${phases[$i]}"
    done

    echo ""
    echo "  Stats:"
    echo "    Iteration: $iteration"
    echo "    Model:     $model"
    echo "    Failures:  $failures"
    echo ""
}

# ============================================================================
# EXPORT
# ============================================================================

# Make functions available to sourcing scripts
export -f progress_start progress_update progress_increment progress_complete progress_fail
export -f spinner_start spinner_stop
export -f task_item step_counter show_session_progress
