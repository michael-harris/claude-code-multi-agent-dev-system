#!/bin/bash
# checkpoint.sh - Save and restore full agent state for resumption
# Based on Anthropic's "Effective Harnesses for Long-Running Agents"

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="${PROJECT_ROOT:-$(pwd)}"
DEVTEAM_DIR="${PROJECT_ROOT}/.devteam"
CHECKPOINT_DIR="${DEVTEAM_DIR}/checkpoints"
DB_FILE="${DEVTEAM_DIR}/state.db"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() { echo -e "${GREEN}[checkpoint]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[checkpoint]${NC} $1"; }
log_error() { echo -e "${RED}[checkpoint]${NC} $1"; }

# Ensure checkpoint directory exists
ensure_dirs() {
    mkdir -p "$CHECKPOINT_DIR"
}

# Generate checkpoint ID
generate_checkpoint_id() {
    echo "chkpt-$(date +%Y%m%d-%H%M%S)-$(head -c 4 /dev/urandom | xxd -p)"
}

# Create a full checkpoint
create_checkpoint() {
    local description="${1:-Manual checkpoint}"
    local checkpoint_id
    checkpoint_id=$(generate_checkpoint_id)
    local checkpoint_path="${CHECKPOINT_DIR}/${checkpoint_id}"

    ensure_dirs
    mkdir -p "$checkpoint_path"

    log_info "Creating checkpoint: ${checkpoint_id}"

    # 1. Save git state
    log_info "Saving git state..."
    local git_info="${checkpoint_path}/git-state.json"
    cat > "$git_info" << EOF
{
    "branch": "$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo 'unknown')",
    "commit": "$(git rev-parse HEAD 2>/dev/null || echo 'unknown')",
    "dirty": $(if [[ -n "$(git status --porcelain 2>/dev/null)" ]]; then echo "true"; else echo "false"; fi),
    "stash_count": $(git stash list 2>/dev/null | wc -l || echo 0),
    "timestamp": "$(date -Iseconds)"
}
EOF

    # Stash any uncommitted changes
    if [[ -n "$(git status --porcelain 2>/dev/null)" ]]; then
        git stash push -m "checkpoint-${checkpoint_id}" --include-untracked
        echo "stash@{0}" > "${checkpoint_path}/stash-ref"
        log_info "Stashed uncommitted changes"
    fi

    # 2. Save database state
    if [[ -f "$DB_FILE" ]]; then
        log_info "Saving database state..."
        cp "$DB_FILE" "${checkpoint_path}/state.db"
    fi

    # 3. Save features.json if exists
    if [[ -f "${DEVTEAM_DIR}/features.json" ]]; then
        log_info "Saving features.json..."
        cp "${DEVTEAM_DIR}/features.json" "${checkpoint_path}/features.json"
    fi

    # 4. Save progress.txt if exists
    if [[ -f "${DEVTEAM_DIR}/progress.txt" ]]; then
        log_info "Saving progress.txt..."
        cp "${DEVTEAM_DIR}/progress.txt" "${checkpoint_path}/progress.txt"
    fi

    # 5. Save current session context
    log_info "Saving session context..."
    local context_file="${checkpoint_path}/context.json"
    cat > "$context_file" << EOF
{
    "checkpoint_id": "${checkpoint_id}",
    "description": "${description}",
    "created_at": "$(date -Iseconds)",
    "working_directory": "${PROJECT_ROOT}",
    "environment": {
        "user": "${USER:-unknown}",
        "hostname": "$(hostname)",
        "shell": "${SHELL:-unknown}"
    },
    "session": {
        "phase": "$(cat "${DEVTEAM_DIR}/current-phase" 2>/dev/null || echo 'unknown')",
        "active_task": "$(sqlite3 "$DB_FILE" "SELECT task_id FROM tasks WHERE status='in_progress' LIMIT 1;" 2>/dev/null || echo 'none')",
        "active_sprint": "$(sqlite3 "$DB_FILE" "SELECT sprint_id FROM sprints WHERE status='in_progress' LIMIT 1;" 2>/dev/null || echo 'none')"
    }
}
EOF

    # 6. Save any running process info
    if [[ -f "${DEVTEAM_DIR}/running-processes.json" ]]; then
        cp "${DEVTEAM_DIR}/running-processes.json" "${checkpoint_path}/processes.json"
    fi

    # 7. Create checkpoint manifest
    local manifest="${checkpoint_path}/manifest.json"
    cat > "$manifest" << EOF
{
    "version": "1.0",
    "checkpoint_id": "${checkpoint_id}",
    "description": "${description}",
    "created_at": "$(date -Iseconds)",
    "files": [
        "git-state.json",
        "state.db",
        "features.json",
        "progress.txt",
        "context.json"
    ],
    "can_restore": true
}
EOF

    # 8. Record in database
    if [[ -f "$DB_FILE" ]]; then
        sqlite3 "$DB_FILE" << EOF
INSERT INTO checkpoints (
    checkpoint_id,
    path,
    description,
    git_commit,
    created_at
) VALUES (
    '${checkpoint_id}',
    '${checkpoint_path}',
    '${description}',
    '$(git rev-parse HEAD 2>/dev/null || echo 'unknown')',
    datetime('now')
);
EOF
    fi

    log_info "Checkpoint created: ${checkpoint_id}"
    log_info "Path: ${checkpoint_path}"

    echo "$checkpoint_id"
}

# List all checkpoints
list_checkpoints() {
    ensure_dirs

    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo " Available Checkpoints"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""

    if [[ ! -d "$CHECKPOINT_DIR" ]] || [[ -z "$(ls -A "$CHECKPOINT_DIR" 2>/dev/null)" ]]; then
        echo "No checkpoints found."
        echo ""
        echo "Create a checkpoint with:"
        echo "  ./scripts/checkpoint.sh save [description]"
        return 0
    fi

    printf "%-35s %-25s %-20s\n" "CHECKPOINT ID" "DESCRIPTION" "CREATED"
    echo "─────────────────────────────────────────────────────────────────────────────"

    for checkpoint_dir in "$CHECKPOINT_DIR"/chkpt-*; do
        if [[ -d "$checkpoint_dir" ]]; then
            local manifest="${checkpoint_dir}/manifest.json"
            if [[ -f "$manifest" ]]; then
                local id
                id=$(basename "$checkpoint_dir")
                local desc
                desc=$(grep -o '"description": "[^"]*"' "$manifest" | cut -d'"' -f4 | head -c 23)
                local created
                created=$(grep -o '"created_at": "[^"]*"' "$manifest" | cut -d'"' -f4 | cut -dT -f1)
                printf "%-35s %-25s %-20s\n" "$id" "$desc" "$created"
            fi
        fi
    done

    echo ""
}

# Restore from checkpoint
restore_checkpoint() {
    local checkpoint_id="$1"
    local checkpoint_path="${CHECKPOINT_DIR}/${checkpoint_id}"

    if [[ ! -d "$checkpoint_path" ]]; then
        log_error "Checkpoint not found: ${checkpoint_id}"
        list_checkpoints
        exit 1
    fi

    log_warn "Restoring from checkpoint: ${checkpoint_id}"

    # 1. Create a safety checkpoint first
    log_info "Creating safety checkpoint before restore..."
    create_checkpoint "pre-restore-safety"

    # 2. Restore git state
    if [[ -f "${checkpoint_path}/git-state.json" ]]; then
        log_info "Restoring git state..."
        local target_commit
        target_commit=$(grep -o '"commit": "[^"]*"' "${checkpoint_path}/git-state.json" | cut -d'"' -f4)

        if [[ -n "$target_commit" ]] && [[ "$target_commit" != "unknown" ]]; then
            git reset --hard "$target_commit"
        fi

        # Restore stashed changes if any
        if [[ -f "${checkpoint_path}/stash-ref" ]]; then
            log_info "Restoring stashed changes..."
            git stash pop 2>/dev/null || log_warn "Could not pop stash (may not exist)"
        fi
    fi

    # 3. Restore database
    if [[ -f "${checkpoint_path}/state.db" ]]; then
        log_info "Restoring database..."
        cp "${checkpoint_path}/state.db" "$DB_FILE"
    fi

    # 4. Restore features.json
    if [[ -f "${checkpoint_path}/features.json" ]]; then
        log_info "Restoring features.json..."
        cp "${checkpoint_path}/features.json" "${DEVTEAM_DIR}/features.json"
    fi

    # 5. Restore progress.txt
    if [[ -f "${checkpoint_path}/progress.txt" ]]; then
        log_info "Restoring progress.txt..."
        cp "${checkpoint_path}/progress.txt" "${DEVTEAM_DIR}/progress.txt"
    fi

    # 6. Restore session context
    if [[ -f "${checkpoint_path}/context.json" ]]; then
        local phase
        phase=$(grep -o '"phase": "[^"]*"' "${checkpoint_path}/context.json" | cut -d'"' -f4)
        if [[ -n "$phase" ]] && [[ "$phase" != "unknown" ]]; then
            echo "$phase" > "${DEVTEAM_DIR}/current-phase"
        fi
    fi

    # Record restoration
    if [[ -f "$DB_FILE" ]]; then
        sqlite3 "$DB_FILE" << EOF
INSERT INTO checkpoint_restores (
    checkpoint_id,
    restored_at
) VALUES (
    '${checkpoint_id}',
    datetime('now')
);
EOF
    fi

    log_info "Checkpoint restored: ${checkpoint_id}"
    log_info "Session state has been recovered"
}

# Delete a checkpoint
delete_checkpoint() {
    local checkpoint_id="$1"
    local checkpoint_path="${CHECKPOINT_DIR}/${checkpoint_id}"

    if [[ ! -d "$checkpoint_path" ]]; then
        log_error "Checkpoint not found: ${checkpoint_id}"
        exit 1
    fi

    rm -rf "$checkpoint_path"
    log_info "Deleted checkpoint: ${checkpoint_id}"

    # Update database
    if [[ -f "$DB_FILE" ]]; then
        sqlite3 "$DB_FILE" "DELETE FROM checkpoints WHERE checkpoint_id='${checkpoint_id}';"
    fi
}

# Clean old checkpoints (keep last N)
clean_checkpoints() {
    local keep="${1:-5}"

    ensure_dirs

    local all_checkpoints
    all_checkpoints=$(ls -1t "$CHECKPOINT_DIR" 2>/dev/null | head -n -"$keep")

    if [[ -z "$all_checkpoints" ]]; then
        log_info "No old checkpoints to clean"
        return 0
    fi

    local count
    count=$(echo "$all_checkpoints" | wc -l)
    log_warn "Deleting ${count} old checkpoints (keeping ${keep} most recent)"

    while IFS= read -r checkpoint; do
        if [[ -n "$checkpoint" ]]; then
            delete_checkpoint "$checkpoint"
        fi
    done <<< "$all_checkpoints"
}

# Show checkpoint details
show_checkpoint() {
    local checkpoint_id="$1"
    local checkpoint_path="${CHECKPOINT_DIR}/${checkpoint_id}"

    if [[ ! -d "$checkpoint_path" ]]; then
        log_error "Checkpoint not found: ${checkpoint_id}"
        exit 1
    fi

    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo " Checkpoint Details: ${checkpoint_id}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""

    if [[ -f "${checkpoint_path}/manifest.json" ]]; then
        cat "${checkpoint_path}/manifest.json" | python3 -m json.tool 2>/dev/null || cat "${checkpoint_path}/manifest.json"
    fi

    echo ""
    echo "Git State:"
    if [[ -f "${checkpoint_path}/git-state.json" ]]; then
        cat "${checkpoint_path}/git-state.json" | python3 -m json.tool 2>/dev/null || cat "${checkpoint_path}/git-state.json"
    fi

    echo ""
    echo "Session Context:"
    if [[ -f "${checkpoint_path}/context.json" ]]; then
        cat "${checkpoint_path}/context.json" | python3 -m json.tool 2>/dev/null || cat "${checkpoint_path}/context.json"
    fi
}

# Auto-checkpoint on timer (for long sessions)
auto_checkpoint() {
    local interval="${1:-30}"  # minutes
    local description="${2:-Auto-checkpoint}"

    log_info "Starting auto-checkpoint every ${interval} minutes"
    log_info "Press Ctrl+C to stop"

    while true; do
        sleep "$((interval * 60))"
        create_checkpoint "${description} (auto)"
    done
}

# Main
case "${1:-help}" in
    save|create)
        create_checkpoint "${2:-Manual checkpoint}"
        ;;
    list)
        list_checkpoints
        ;;
    restore)
        if [[ -z "${2:-}" ]]; then
            log_error "Usage: $0 restore <checkpoint-id>"
            list_checkpoints
            exit 1
        fi
        restore_checkpoint "$2"
        ;;
    show)
        if [[ -z "${2:-}" ]]; then
            log_error "Usage: $0 show <checkpoint-id>"
            exit 1
        fi
        show_checkpoint "$2"
        ;;
    delete)
        if [[ -z "${2:-}" ]]; then
            log_error "Usage: $0 delete <checkpoint-id>"
            exit 1
        fi
        delete_checkpoint "$2"
        ;;
    clean)
        clean_checkpoints "${2:-5}"
        ;;
    auto)
        auto_checkpoint "${2:-30}" "${3:-Auto-checkpoint}"
        ;;
    help|*)
        echo "Usage: $0 <command> [args]"
        echo ""
        echo "Commands:"
        echo "  save [description]       Create a new checkpoint"
        echo "  list                     List all checkpoints"
        echo "  restore <checkpoint-id>  Restore from a checkpoint"
        echo "  show <checkpoint-id>     Show checkpoint details"
        echo "  delete <checkpoint-id>   Delete a checkpoint"
        echo "  clean [keep-count]       Remove old checkpoints (default: keep 5)"
        echo "  auto [minutes] [desc]    Auto-checkpoint at interval"
        echo ""
        echo "Examples:"
        echo "  $0 save \"Before major refactoring\""
        echo "  $0 list"
        echo "  $0 restore chkpt-20250201-120000-abc123"
        echo "  $0 auto 30 \"Session checkpoint\""
        ;;
esac
