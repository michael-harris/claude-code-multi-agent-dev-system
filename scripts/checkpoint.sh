#!/bin/bash
# checkpoint.sh - Save and restore full agent state for resumption
# Based on Anthropic's "Effective Harnesses for Long-Running Agents"

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/common.sh"

PROJECT_ROOT="${PROJECT_ROOT:-$(pwd)}"
DEVTEAM_DIR="${PROJECT_ROOT}/.devteam"
DB_FILE="${DEVTEAM_DIR}/devteam.db"
CHECKPOINT_DIR="${DEVTEAM_DIR}/checkpoints"

# Register temp file cleanup
setup_temp_cleanup

# Ensure checkpoint directory exists
ensure_dirs() {
    mkdir -p "$CHECKPOINT_DIR"
}

# Generate checkpoint ID
generate_checkpoint_id() {
    if ! command -v xxd &>/dev/null; then
        hex=$(od -A n -t x1 -N 4 /dev/urandom | tr -d ' \n')
    else
        hex=$(head -c 4 /dev/urandom | xxd -p)
    fi
    echo "chkpt-$(date +%Y%m%d-%H%M%S)-${hex}"
}

# Create a full checkpoint
create_checkpoint() {
    local description="${1:-Manual checkpoint}"
    # Sanitize user-supplied description
    description=$(sanitize_input "$description" 1024)
    local checkpoint_id
    checkpoint_id=$(generate_checkpoint_id)
    local checkpoint_path="${CHECKPOINT_DIR}/${checkpoint_id}"

    ensure_dirs
    mkdir -p "$checkpoint_path"

    # Verify git repo exists
    ensure_git || {
        log_error "Cannot create checkpoint outside a git repository"
        return 1
    }

    log_info "Creating checkpoint: ${checkpoint_id}"

    # 1. Save git state
    log_info "Saving git state..."
    local git_info="${checkpoint_path}/git-state.json"
    local git_branch
    git_branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo 'unknown')
    local git_commit
    git_commit=$(git rev-parse HEAD 2>/dev/null || echo 'unknown')
    local git_dirty
    if [[ -n "$(git status --porcelain 2>/dev/null)" ]]; then git_dirty="true"; else git_dirty="false"; fi
    local git_stash_count
    git_stash_count=$(git stash list 2>/dev/null | wc -l || echo 0)

    json_object \
        "branch" "$git_branch" \
        "commit" "$git_commit" \
        "dirty" "$git_dirty" \
        "stash_count" "$git_stash_count" \
        "timestamp" "$(date -Iseconds)" > "$git_info"

    # Stash any uncommitted changes
    if [[ -n "$(git status --porcelain 2>/dev/null)" ]]; then
        git stash push -m "checkpoint-${checkpoint_id}" --include-untracked
        echo "stash@{0}" > "${checkpoint_path}/stash-ref"
        log_info "Stashed uncommitted changes"
    fi

    # 2. Save database state
    if [[ -f "$DB_FILE" ]]; then
        log_info "Saving database state..."
        cp "$DB_FILE" "${checkpoint_path}/devteam.db"
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
    local ctx_phase
    ctx_phase=$(cat "${DEVTEAM_DIR}/current-phase" 2>/dev/null || echo 'unknown')
    local ctx_active_task
    ctx_active_task=$(sql_exec "SELECT id FROM tasks WHERE status='in_progress' LIMIT 1;" 2>/dev/null || echo 'none')
    local ctx_active_sprint='none'

    local esc_checkpoint_id esc_description esc_project_root esc_user esc_hostname esc_shell esc_phase esc_task esc_sprint
    esc_checkpoint_id=$(json_escape "$checkpoint_id")
    esc_description=$(json_escape "$description")
    esc_project_root=$(json_escape "$PROJECT_ROOT")
    esc_user=$(json_escape "${USER:-unknown}")
    esc_hostname=$(json_escape "$(hostname)")
    esc_shell=$(json_escape "${SHELL:-unknown}")
    esc_phase=$(json_escape "$ctx_phase")
    esc_task=$(json_escape "$ctx_active_task")
    esc_sprint=$(json_escape "$ctx_active_sprint")

    local esc_timestamp
    esc_timestamp=$(json_escape "$(date -Iseconds)")

    cat > "$context_file" << EOF
{
    "checkpoint_id": "${esc_checkpoint_id}",
    "description": "${esc_description}",
    "created_at": "${esc_timestamp}",
    "working_directory": "${esc_project_root}",
    "environment": {
        "user": "${esc_user}",
        "hostname": "${esc_hostname}",
        "shell": "${esc_shell}"
    },
    "session": {
        "phase": "${esc_phase}",
        "active_task": "${esc_task}",
        "active_sprint": "${esc_sprint}"
    }
}
EOF

    # 6. Save any running process info
    if [[ -f "${DEVTEAM_DIR}/running-processes.json" ]]; then
        cp "${DEVTEAM_DIR}/running-processes.json" "${checkpoint_path}/processes.json"
    fi

    # 7. Create checkpoint manifest
    local manifest="${checkpoint_path}/manifest.json"
    local esc_manifest_ts
    esc_manifest_ts=$(json_escape "$(date -Iseconds)")

    cat > "$manifest" << EOF
{
    "version": "1.0",
    "checkpoint_id": "${esc_checkpoint_id}",
    "description": "${esc_description}",
    "created_at": "${esc_manifest_ts}",
    "files": [
        "git-state.json",
        "devteam.db",
        "features.json",
        "progress.txt",
        "context.json"
    ],
    "can_restore": true
}
EOF

    # 8. Record in database
    if [[ -f "$DB_FILE" ]]; then
        local sql_ckpt_id sql_ckpt_path sql_description sql_git_commit
        sql_ckpt_id=$(sql_escape "$checkpoint_id")
        sql_ckpt_path=$(sql_escape "$checkpoint_path")
        sql_description=$(sql_escape "$description")
        sql_git_commit=$(sql_escape "$(git rev-parse HEAD 2>/dev/null || echo 'unknown')")

        sql_exec "INSERT INTO checkpoints (checkpoint_id, path, description, git_commit, created_at) VALUES ('${sql_ckpt_id}', '${sql_ckpt_path}', '${sql_description}', '${sql_git_commit}', datetime('now'));" > /dev/null
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
                if command -v jq &>/dev/null; then
                    desc=$(jq -r '.description // empty' "$manifest" 2>/dev/null | head -c 23)
                else
                    desc=$(grep -o '"description": "[^"]*"' "$manifest" | cut -d'"' -f4 | head -c 23)
                fi
                local created
                if command -v jq &>/dev/null; then
                    created=$(jq -r '.created_at // empty' "$manifest" 2>/dev/null | cut -dT -f1)
                else
                    created=$(grep -o '"created_at": "[^"]*"' "$manifest" | cut -d'"' -f4 | cut -dT -f1)
                fi
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

    # Verify git repo exists
    ensure_git || {
        log_error "Cannot restore checkpoint outside a git repository"
        return 1
    }

    log_warn "Restoring from checkpoint: ${checkpoint_id}"

    # 1. Create a safety checkpoint first
    log_info "Creating safety checkpoint before restore..."
    if ! create_checkpoint "pre-restore-safety"; then
        log_error "Failed to create safety checkpoint; aborting restore"
        return 1
    fi

    # 2. Restore git state
    if [[ -f "${checkpoint_path}/git-state.json" ]]; then
        log_info "Restoring git state..."
        local target_commit
        if command -v jq &>/dev/null; then
            target_commit=$(jq -r '.commit // empty' "${checkpoint_path}/git-state.json" 2>/dev/null)
        else
            target_commit=$(grep -o '"commit": "[^"]*"' "${checkpoint_path}/git-state.json" | cut -d'"' -f4)
        fi

        if [[ -n "$target_commit" ]] && [[ "$target_commit" != "unknown" ]]; then
            # Validate commit exists before resetting (M6)
            if git cat-file -t "$target_commit" &>/dev/null; then
                git reset --hard "$target_commit"
            else
                log_error "Target commit not found: $target_commit"
                return 1
            fi
        fi

        # Restore stashed changes if any
        if [[ -f "${checkpoint_path}/stash-ref" ]]; then
            log_info "Restoring stashed changes..."
            git stash pop 2>/dev/null || log_warn "Could not pop stash (may not exist)"
        fi
    fi

    # 3. Restore database (check both old and new naming)
    if [[ -f "${checkpoint_path}/devteam.db" ]]; then
        log_info "Restoring database..."
        cp "${checkpoint_path}/devteam.db" "$DB_FILE"
    elif [[ -f "${checkpoint_path}/state.db" ]]; then
        log_info "Restoring database (legacy checkpoint)..."
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
        if command -v jq &>/dev/null; then
            phase=$(jq -r '.session.phase // empty' "${checkpoint_path}/context.json" 2>/dev/null)
        else
            phase=$(grep -o '"phase": "[^"]*"' "${checkpoint_path}/context.json" | cut -d'"' -f4)
        fi
        if [[ -n "$phase" ]] && [[ "$phase" != "unknown" ]]; then
            echo "$phase" > "${DEVTEAM_DIR}/current-phase"
        fi
    fi

    # Record restoration
    if [[ -f "$DB_FILE" ]]; then
        local sql_ckpt_id
        sql_ckpt_id=$(sql_escape "$checkpoint_id")
        sql_exec "INSERT INTO checkpoint_restores (checkpoint_id, restored_at) VALUES ('${sql_ckpt_id}', datetime('now'));" > /dev/null
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
        local sql_ckpt_id
        sql_ckpt_id=$(sql_escape "$checkpoint_id")
        sql_exec "DELETE FROM checkpoints WHERE checkpoint_id='${sql_ckpt_id}';" > /dev/null
    fi
}

# Clean old checkpoints (keep last N)
clean_checkpoints() {
    local keep="${1:-5}"

    ensure_dirs

    local all_checkpoints
    all_checkpoints=$(ls -1t "$CHECKPOINT_DIR" 2>/dev/null | tail -n +"$((keep + 1))")

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
