#!/bin/bash
# baseline.sh - Create baseline commits at key milestones for easy rollback
# Based on Anthropic's "Effective Harnesses for Long-Running Agents"

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="${PROJECT_ROOT:-$(pwd)}"
DB_FILE="${PROJECT_ROOT}/.devteam/state.db"
DEVTEAM_DIR="${PROJECT_ROOT}/.devteam"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() { echo -e "${GREEN}[baseline]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[baseline]${NC} $1"; }
log_error() { echo -e "${RED}[baseline]${NC} $1"; }

# Ensure we're in a git repo
ensure_git() {
    if ! git rev-parse --git-dir > /dev/null 2>&1; then
        log_error "Not a git repository"
        exit 1
    fi
}

# Create a baseline commit with special tag
create_baseline() {
    local milestone="$1"
    local description="${2:-Baseline checkpoint}"

    ensure_git

    # Check if there are changes to commit
    if [[ -z "$(git status --porcelain)" ]]; then
        log_warn "No changes to commit for baseline"
        return 0
    fi

    # Stage all changes
    git add -A

    # Create the baseline commit
    local timestamp
    timestamp=$(date +%Y%m%d-%H%M%S)
    local commit_msg="[BASELINE] ${milestone}: ${description}

Milestone: ${milestone}
Timestamp: ${timestamp}
Type: baseline-checkpoint

This is an automatic baseline commit for rollback purposes."

    git commit -m "$commit_msg"
    local commit_hash
    commit_hash=$(git rev-parse HEAD)

    # Create a lightweight tag for easy reference
    local tag_name="baseline/${milestone}/${timestamp}"
    git tag "$tag_name" "$commit_hash"

    log_info "Created baseline: ${tag_name}"
    log_info "Commit: ${commit_hash:0:8}"

    # Record in database if available
    if [[ -f "$DB_FILE" ]]; then
        sqlite3 "$DB_FILE" << EOF
INSERT INTO baselines (
    tag_name,
    commit_hash,
    milestone,
    description,
    created_at
) VALUES (
    '${tag_name}',
    '${commit_hash}',
    '${milestone}',
    '${description}',
    datetime('now')
);
EOF
        log_info "Recorded baseline in database"
    fi

    echo "$commit_hash"
}

# List all baselines
list_baselines() {
    ensure_git

    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo " Baseline Commits"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""

    # Get baselines from git tags
    local baselines
    baselines=$(git tag -l "baseline/*" 2>/dev/null || true)

    if [[ -z "$baselines" ]]; then
        echo "No baselines found."
        echo ""
        echo "Create a baseline with:"
        echo "  ./scripts/baseline.sh create <milestone> [description]"
        return 0
    fi

    printf "%-40s %-10s %-20s\n" "TAG" "COMMIT" "DATE"
    echo "─────────────────────────────────────────────────────────────"

    while IFS= read -r tag; do
        if [[ -n "$tag" ]]; then
            local commit
            commit=$(git rev-parse --short "$tag" 2>/dev/null || echo "unknown")
            local date
            date=$(git log -1 --format="%ci" "$tag" 2>/dev/null | cut -d' ' -f1 || echo "unknown")
            printf "%-40s %-10s %-20s\n" "$tag" "$commit" "$date"
        fi
    done <<< "$baselines"

    echo ""
}

# Rollback to a baseline
rollback_to_baseline() {
    local target="$1"

    ensure_git

    # Check if target is a tag or commit
    local commit_hash
    if git rev-parse "baseline/${target}" > /dev/null 2>&1; then
        commit_hash=$(git rev-parse "baseline/${target}")
    elif git rev-parse "$target" > /dev/null 2>&1; then
        commit_hash=$(git rev-parse "$target")
    else
        log_error "Unknown baseline or commit: ${target}"
        list_baselines
        exit 1
    fi

    log_warn "Rolling back to: ${commit_hash:0:8}"

    # Create a backup baseline before rollback
    if [[ -n "$(git status --porcelain)" ]]; then
        log_info "Creating backup baseline before rollback..."
        create_baseline "pre-rollback" "Backup before rollback to ${target}"
    fi

    # Perform the rollback
    git reset --hard "$commit_hash"
    log_info "Rolled back to ${commit_hash:0:8}"

    # Record rollback in database
    if [[ -f "$DB_FILE" ]]; then
        sqlite3 "$DB_FILE" << EOF
INSERT INTO rollbacks (
    target_commit,
    target_tag,
    rolled_back_at,
    reason
) VALUES (
    '${commit_hash}',
    '${target}',
    datetime('now'),
    'manual rollback'
);
EOF
        log_info "Recorded rollback in database"
    fi
}

# Create milestone-specific baselines
create_milestone_baseline() {
    local milestone_type="$1"

    case "$milestone_type" in
        sprint-start)
            local sprint_id="${2:-unknown}"
            create_baseline "sprint-${sprint_id}-start" "Beginning of sprint ${sprint_id}"
            ;;
        sprint-end)
            local sprint_id="${2:-unknown}"
            create_baseline "sprint-${sprint_id}-end" "End of sprint ${sprint_id}"
            ;;
        feature-complete)
            local feature_id="${2:-unknown}"
            create_baseline "feature-${feature_id}" "Feature ${feature_id} complete"
            ;;
        tests-passing)
            create_baseline "tests-passing" "All tests passing"
            ;;
        pre-deploy)
            create_baseline "pre-deploy" "Before deployment"
            ;;
        session-start)
            local session_id="${2:-$(date +%Y%m%d)}"
            create_baseline "session-${session_id}-start" "Session start"
            ;;
        session-end)
            local session_id="${2:-$(date +%Y%m%d)}"
            create_baseline "session-${session_id}-end" "Session end"
            ;;
        *)
            create_baseline "$milestone_type" "${2:-Checkpoint}"
            ;;
    esac
}

# Show diff from baseline
diff_from_baseline() {
    local baseline="$1"

    ensure_git

    local commit_hash
    if git rev-parse "baseline/${baseline}" > /dev/null 2>&1; then
        commit_hash=$(git rev-parse "baseline/${baseline}")
    else
        commit_hash="$baseline"
    fi

    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo " Changes since baseline: ${baseline}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""

    git diff --stat "$commit_hash"..HEAD
    echo ""

    local commits_count
    commits_count=$(git rev-list --count "$commit_hash"..HEAD)
    echo "Total commits since baseline: ${commits_count}"
}

# Clean old baselines (keep last N)
clean_baselines() {
    local keep="${1:-10}"

    ensure_git

    local all_baselines
    all_baselines=$(git tag -l "baseline/*" --sort=-creatordate)
    local count
    count=$(echo "$all_baselines" | wc -l)

    if [[ "$count" -le "$keep" ]]; then
        log_info "Only ${count} baselines exist, keeping all"
        return 0
    fi

    local to_delete
    to_delete=$(echo "$all_baselines" | tail -n +"$((keep + 1))")

    log_warn "Deleting $(echo "$to_delete" | wc -l) old baselines (keeping ${keep} most recent)"

    while IFS= read -r tag; do
        if [[ -n "$tag" ]]; then
            git tag -d "$tag"
            log_info "Deleted: ${tag}"
        fi
    done <<< "$to_delete"
}

# Main
case "${1:-help}" in
    create)
        create_baseline "${2:-checkpoint}" "${3:-Manual baseline}"
        ;;
    milestone)
        create_milestone_baseline "${2:-checkpoint}" "${3:-}"
        ;;
    list)
        list_baselines
        ;;
    rollback)
        if [[ -z "${2:-}" ]]; then
            log_error "Usage: $0 rollback <baseline-tag-or-commit>"
            list_baselines
            exit 1
        fi
        rollback_to_baseline "$2"
        ;;
    diff)
        if [[ -z "${2:-}" ]]; then
            log_error "Usage: $0 diff <baseline>"
            exit 1
        fi
        diff_from_baseline "$2"
        ;;
    clean)
        clean_baselines "${2:-10}"
        ;;
    help|*)
        echo "Usage: $0 <command> [args]"
        echo ""
        echo "Commands:"
        echo "  create <name> [desc]     Create a baseline with custom name"
        echo "  milestone <type> [id]    Create milestone-specific baseline"
        echo "                           Types: sprint-start, sprint-end, feature-complete,"
        echo "                                  tests-passing, pre-deploy, session-start, session-end"
        echo "  list                     List all baselines"
        echo "  rollback <baseline>      Rollback to a baseline"
        echo "  diff <baseline>          Show changes since baseline"
        echo "  clean [keep-count]       Remove old baselines (default: keep 10)"
        echo ""
        echo "Examples:"
        echo "  $0 create pre-refactor \"Before major refactoring\""
        echo "  $0 milestone sprint-start 01"
        echo "  $0 list"
        echo "  $0 rollback baseline/sprint-01-start/20250201-120000"
        ;;
esac
