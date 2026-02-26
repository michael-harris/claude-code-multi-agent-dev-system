#!/bin/bash
# rollback.sh - Automated rollback with regression detection
# Based on Anthropic's "Effective Harnesses for Long-Running Agents"

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/common.sh"

PROJECT_ROOT="${PROJECT_ROOT:-$(pwd)}"
DEVTEAM_DIR="${PROJECT_ROOT}/.devteam"
DB_FILE="${DEVTEAM_DIR}/devteam.db"
ROLLBACK_LOG="${DEVTEAM_DIR}/rollback-log.json"

# Force/yes flag for non-interactive usage
DEVTEAM_FORCE="false"

# Parse global flags (--force, -f, --yes, -y) from arguments
ARGS=()
for arg in "$@"; do
    case "$arg" in
        --force|-f|--yes|-y)
            DEVTEAM_FORCE="true"
            ;;
        *)
            ARGS+=("$arg")
            ;;
    esac
done
set -- "${ARGS[@]+"${ARGS[@]}"}"

# Register temp file cleanup
setup_temp_cleanup

# ensure_git is now provided by scripts/lib/common.sh

# Detect regressions by running tests
detect_regression() {
    local check_type="${1:-all}"

    log_info "Checking for regressions..."

    local regression_detected=false
    local failures=()

    case "$check_type" in
        build)
            if ! run_build_check; then
                regression_detected=true
                failures+=("build")
            fi
            ;;
        test)
            if ! run_test_check; then
                regression_detected=true
                failures+=("tests")
            fi
            ;;
        typecheck)
            if ! run_typecheck; then
                regression_detected=true
                failures+=("typecheck")
            fi
            ;;
        lint)
            if ! run_lint_check; then
                regression_detected=true
                failures+=("lint")
            fi
            ;;
        all)
            if ! run_build_check; then
                regression_detected=true
                failures+=("build")
            fi
            if ! run_test_check; then
                regression_detected=true
                failures+=("tests")
            fi
            if ! run_typecheck; then
                regression_detected=true
                failures+=("typecheck")
            fi
            ;;
    esac

    if [[ "$regression_detected" == "true" ]]; then
        log_error "Regression detected: ${failures[*]}"
        return 1
    fi

    log_info "No regressions detected"
    return 0
}

# Build check
run_build_check() {
    log_info "Running build check..."
    if [[ -f "package.json" ]]; then
        if grep -q '"build"' package.json; then
            npm run build 2>&1 || return 1
        fi
    elif [[ -f "Cargo.toml" ]]; then
        cargo build 2>&1 || return 1
    elif [[ -f "go.mod" ]]; then
        go build ./... 2>&1 || return 1
    fi
    return 0
}

# Test check
run_test_check() {
    log_info "Running test check..."
    if [[ -f "package.json" ]]; then
        if grep -q '"test"' package.json; then
            npm test 2>&1 || return 1
        fi
    elif [[ -f "pytest.ini" ]] || [[ -f "pyproject.toml" ]]; then
        pytest 2>&1 || return 1
    elif [[ -f "Cargo.toml" ]]; then
        cargo test 2>&1 || return 1
    elif [[ -f "go.mod" ]]; then
        go test ./... 2>&1 || return 1
    fi
    return 0
}

# Typecheck
run_typecheck() {
    log_info "Running type check..."
    if [[ -f "tsconfig.json" ]]; then
        npx tsc --noEmit 2>&1 || return 1
    elif [[ -f "pyproject.toml" ]] && grep -q "mypy" pyproject.toml; then
        mypy . 2>&1 || return 1
    fi
    return 0
}

# Lint check
run_lint_check() {
    log_info "Running lint check..."
    if [[ -f "package.json" ]]; then
        if grep -q '"lint"' package.json; then
            npm run lint 2>&1 || return 1
        fi
    elif [[ -f ".eslintrc.json" ]] || [[ -f ".eslintrc.js" ]]; then
        npx eslint . 2>&1 || return 1
    fi
    return 0
}

# Find last known good state
find_last_good_state() {
    local check_type="${1:-build}"
    local max_commits="${2:-10}"

    ensure_git

    log_info "Searching for last known good state (checking last ${max_commits} commits)..."

    local current_branch
    current_branch=$(git rev-parse --abbrev-ref HEAD)
    local original_commit
    original_commit=$(git rev-parse HEAD)

    # Save current HEAD and set trap to restore on error (H8: prevent detached HEAD)
    local _restored=false
    cleanup_rollback() {
        local exit_code=$?
        if [[ $exit_code -ne 0 ]] && [[ "$_restored" != "true" ]]; then
            _restored=true
            log_error "Rollback search failed, restoring to ${original_commit:0:8}"
            git checkout "$current_branch" --quiet 2>/dev/null || git checkout "$original_commit" --quiet 2>/dev/null || true
            if [[ "${stashed:-false}" == "true" ]]; then
                git stash pop --quiet 2>/dev/null || true
            fi
        fi
    }
    trap cleanup_rollback EXIT

    # Stash any uncommitted changes
    local stashed=false
    if [[ -n "$(git status --porcelain)" ]]; then
        git stash push -m "auto-rollback-search" --include-untracked
        stashed=true
    fi

    local good_commit=""
    local commits
    commits=$(git log --oneline -n "$max_commits" --format="%H")

    while IFS= read -r commit; do
        if [[ -n "$commit" ]]; then
            log_info "Testing commit: ${commit:0:8}..."
            git checkout "$commit" --quiet 2>/dev/null

            if detect_regression "$check_type" 2>/dev/null; then
                good_commit="$commit"
                log_info "Found good commit: ${commit:0:8}"
                break
            fi
        fi
    done <<< "$commits"

    # Return to original state
    git checkout "$current_branch" --quiet 2>/dev/null

    # Restore stash if we made one
    if [[ "$stashed" == "true" ]]; then
        git stash pop --quiet 2>/dev/null || true
    fi

    # Mark as restored so trap won't double-restore
    _restored=true
    trap - EXIT

    if [[ -n "$good_commit" ]]; then
        echo "$good_commit"
        return 0
    else
        log_error "No good commit found in last ${max_commits} commits"
        return 1
    fi
}

# Auto-rollback on regression
auto_rollback() {
    local check_type="${1:-build}"
    local dry_run="${2:-false}"

    ensure_git

    log_warn "Starting auto-rollback process..."

    # First, check if there's actually a regression
    if detect_regression "$check_type" 2>/dev/null; then
        log_info "No regression detected, no rollback needed"
        return 0
    fi

    log_error "Regression detected, initiating rollback..."

    # Find last known good state
    local good_commit
    good_commit=$(find_last_good_state "$check_type") || {
        log_error "Could not find a good commit to rollback to"
        return 1
    }

    if [[ "$dry_run" == "true" ]]; then
        log_info "[DRY RUN] Would rollback to: ${good_commit:0:8}"
        git log --oneline HEAD..."$good_commit"
        return 0
    fi

    # Capture current HEAD before rollback for auditing
    local pre_rollback_commit
    pre_rollback_commit=$(git rev-parse HEAD 2>/dev/null || echo 'unknown')

    # Create backup branch
    local backup_branch="backup/pre-rollback-$(date +%Y%m%d-%H%M%S)"
    git branch "$backup_branch"
    log_info "Created backup branch: ${backup_branch}"

    # Perform rollback
    git reset --hard "$good_commit"
    log_info "Rolled back to: ${good_commit:0:8}"

    # Record rollback
    record_rollback "auto" "$good_commit" "$check_type" "$pre_rollback_commit"

    # Verify the rollback fixed the issue
    if detect_regression "$check_type" 2>/dev/null; then
        log_info "Rollback successful - regression fixed"
        return 0
    else
        log_error "Rollback did not fix the regression!"
        return 1
    fi
}

# Manual rollback
manual_rollback() {
    local target="$1"
    local force="${2:-false}"

    ensure_git

    # Resolve target
    local target_commit
    if [[ "$target" == "HEAD~"* ]] || [[ "$target" == "HEAD^"* ]]; then
        target_commit=$(git rev-parse "$target")
    elif git rev-parse "baseline/${target}" > /dev/null 2>&1; then
        target_commit=$(git rev-parse "baseline/${target}")
    else
        target_commit=$(git rev-parse "$target")
    fi

    log_warn "Rolling back to: ${target_commit:0:8}"

    # Show what will be lost
    echo ""
    echo "Commits that will be undone:"
    git log --oneline HEAD..."$target_commit"
    echo ""

    if [[ "$force" != "true" ]]; then
        local confirm
        if [[ "$DEVTEAM_FORCE" == "true" ]] || [[ ! -t 0 ]]; then
            # Auto-confirm in non-interactive or forced mode
            confirm="y"
        else
            read -t 30 -p "Continue with rollback? (y/N): " confirm || confirm="N"
        fi
        if [[ "$confirm" != "y" ]] && [[ "$confirm" != "Y" ]]; then
            log_info "Rollback cancelled"
            return 0
        fi
    fi

    # Capture current HEAD before rollback for auditing
    local pre_rollback_commit
    pre_rollback_commit=$(git rev-parse HEAD 2>/dev/null || echo 'unknown')

    # Create backup
    local backup_branch="backup/manual-rollback-$(date +%Y%m%d-%H%M%S)"
    git branch "$backup_branch"
    log_info "Created backup branch: ${backup_branch}"

    # Perform rollback
    git reset --hard "$target_commit"
    log_info "Rolled back to: ${target_commit:0:8}"

    # Record
    record_rollback "manual" "$target_commit" "user-requested" "$pre_rollback_commit"
}

# Smart rollback - rolls back the minimum number of commits
smart_rollback() {
    local check_type="${1:-build}"

    ensure_git

    log_info "Smart rollback: finding minimal rollback..."

    local current_commit
    current_commit=$(git rev-parse HEAD)

    # Binary search for the breaking commit
    local commits
    commits=$(git log --oneline -n 20 --format="%H" | awk '{a[NR]=$0} END{for(i=NR;i>=1;i--) print a[i]}')  # Oldest first (portable)
    local commits_array=()
    while IFS= read -r line; do
        [[ -n "$line" ]] && commits_array+=("$line")
    done <<< "$commits"

    local low=0
    local high=$((${#commits_array[@]} - 1))
    local breaking_commit=""

    # Save the branch name BEFORE any git checkout operations
    local original_branch
    original_branch=$(git rev-parse --abbrev-ref HEAD)

    # Stash changes
    local stashed=false
    if [[ -n "$(git status --porcelain)" ]]; then
        git stash push -m "smart-rollback-search" --include-untracked
        stashed=true
    fi

    while [[ $low -le $high ]]; do
        local mid=$(((low + high) / 2))
        local test_commit="${commits_array[$mid]}"

        log_info "Testing commit ${mid}/${high}: ${test_commit:0:8}"
        git checkout "$test_commit" --quiet 2>/dev/null

        if detect_regression "$check_type" 2>/dev/null; then
            # This commit is good, problem is later
            low=$((mid + 1))
        else
            # This commit is bad
            breaking_commit="$test_commit"
            high=$((mid - 1))
        fi
    done

    # Return to original state
    if [[ "$original_branch" != "HEAD" ]]; then
        git checkout "$original_branch" --quiet 2>/dev/null || git checkout "$current_commit" --quiet
    else
        git checkout "$current_commit" --quiet
    fi

    if [[ "$stashed" == "true" ]]; then
        git stash pop --quiet 2>/dev/null || true
    fi

    if [[ -n "$breaking_commit" ]]; then
        log_info "Found breaking commit: ${breaking_commit:0:8}"
        git log --oneline -1 "$breaking_commit"
        echo ""
        log_info "Rollback to: ${breaking_commit}~1"

        local confirm
        if [[ "$DEVTEAM_FORCE" == "true" ]] || [[ ! -t 0 ]]; then
            # Auto-confirm in non-interactive or forced mode
            confirm="y"
        else
            read -t 30 -p "Rollback to the commit before? (y/N): " confirm || confirm="N"
        fi
        if [[ "$confirm" == "y" ]] || [[ "$confirm" == "Y" ]]; then
            manual_rollback "${breaking_commit}~1" true
        fi
    else
        log_error "Could not identify breaking commit"
    fi
}

# Record rollback for auditing
record_rollback() {
    local type="$1"
    local target_commit="$2"
    local reason="$3"
    local from_commit="${4:-}"

    mkdir -p "$DEVTEAM_DIR"

    # Use provided from_commit (captured before reset), or fall back to HEAD
    if [[ -z "$from_commit" ]]; then
        from_commit=$(git rev-parse HEAD 2>/dev/null || echo 'unknown')
    fi

    local entry
    entry=$(json_object \
        "timestamp" "$(date -Iseconds)" \
        "type" "$type" \
        "target_commit" "$target_commit" \
        "reason" "$reason" \
        "from_commit" "$from_commit")

    if [[ ! -f "$ROLLBACK_LOG" ]]; then
        echo "[$entry]" > "$ROLLBACK_LOG"
    else
        # Portable sed: use temp file instead of sed -i
        local tmp
        tmp=$(safe_mktemp)
        sed '$ s/]$/,/' "$ROLLBACK_LOG" > "$tmp" && mv "$tmp" "$ROLLBACK_LOG"
        echo "$entry]" >> "$ROLLBACK_LOG"
    fi

    # Record in database
    if [[ -f "$DB_FILE" ]]; then
        local sql_type sql_target sql_reason sql_from_commit
        sql_type=$(sql_escape "$type")
        sql_target=$(sql_escape "$target_commit")
        sql_reason=$(sql_escape "$reason")
        sql_from_commit=$(sql_escape "$from_commit")

        sql_exec "INSERT INTO rollbacks (rollback_type, target_commit, reason, from_commit, rolled_back_at) VALUES ('${sql_type}', '${sql_target}', '${sql_reason}', '${sql_from_commit}', datetime('now'));" > /dev/null
    fi
}

# Show rollback history
history() {
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo " Rollback History"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""

    if [[ -f "$DB_FILE" ]]; then
        sql_exec_table "SELECT rollback_type as type, substr(target_commit, 1, 8) as target, reason, datetime(rolled_back_at, 'localtime') as time FROM rollbacks ORDER BY rolled_back_at DESC LIMIT 20;"
    elif [[ -f "$ROLLBACK_LOG" ]]; then
        cat "$ROLLBACK_LOG" | python3 -m json.tool 2>/dev/null || cat "$ROLLBACK_LOG"
    else
        echo "No rollback history found."
    fi
    echo ""
}

# Undo the last rollback
undo_rollback() {
    ensure_git

    # Find backup branches
    local backups
    backups=$(git branch --list "backup/*" | sort -r | head -5)

    if [[ -z "$backups" ]]; then
        log_error "No backup branches found"
        return 1
    fi

    echo ""
    echo "Available backup branches:"
    echo "$backups"
    echo ""

    local latest_backup
    latest_backup=$(echo "$backups" | head -1 | tr -d ' ')

    local confirm
    if [[ "$DEVTEAM_FORCE" == "true" ]] || [[ ! -t 0 ]]; then
        # Auto-confirm in non-interactive or forced mode
        confirm="y"
    else
        read -t 30 -p "Restore from ${latest_backup}? (y/N): " confirm || confirm="N"
    fi
    if [[ "$confirm" == "y" ]] || [[ "$confirm" == "Y" ]]; then
        git reset --hard "$latest_backup"
        log_info "Restored from ${latest_backup}"
    fi
}

# Main
case "${1:-help}" in
    check)
        detect_regression "${2:-all}"
        ;;
    auto)
        auto_rollback "${2:-build}" "${3:-false}"
        ;;
    manual)
        if [[ -z "${2:-}" ]]; then
            log_error "Usage: $0 manual <commit-or-baseline>"
            exit 1
        fi
        manual_rollback "$2" "${3:-false}"
        ;;
    smart)
        smart_rollback "${2:-build}"
        ;;
    find-good)
        find_last_good_state "${2:-build}" "${3:-10}"
        ;;
    history)
        history
        ;;
    undo)
        undo_rollback
        ;;
    help|*)
        echo "Usage: $0 <command> [args] [--force|--yes]"
        echo ""
        echo "Commands:"
        echo "  check [type]           Check for regressions (build/test/typecheck/lint/all)"
        echo "  auto [type] [dry-run]  Auto-rollback on regression detection"
        echo "  manual <target>        Manual rollback to commit/baseline"
        echo "  smart [type]           Find and rollback to minimal safe point"
        echo "  find-good [type] [n]   Find last known good commit"
        echo "  history                Show rollback history"
        echo "  undo                   Undo the last rollback"
        echo ""
        echo "Global flags:"
        echo "  --force, -f, --yes, -y   Skip confirmation prompts (for automated use)"
        echo ""
        echo "Examples:"
        echo "  $0 check build         # Check if build passes"
        echo "  $0 auto build          # Auto-rollback if build fails"
        echo "  $0 auto build true     # Dry run - show what would happen"
        echo "  $0 manual HEAD~3       # Rollback 3 commits"
        echo "  $0 smart test          # Find minimal rollback for test fix"
        echo "  $0 manual HEAD~1 --force # Rollback without prompting"
        ;;
esac
