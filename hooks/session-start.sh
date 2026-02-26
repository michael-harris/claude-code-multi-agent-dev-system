#!/bin/bash
# DevTeam Session Start Hook
# Loads previous session context and auto-detects project configuration

set -euo pipefail

# Configuration
MEMORY_DIR=".devteam/memory"
CONFIG_FILE=".devteam/config.yaml"

# Source common library for SQLite helpers
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [[ -f "$SCRIPT_DIR/lib/hook-common.sh" ]]; then
    source "$SCRIPT_DIR/lib/hook-common.sh"
elif [[ -f "$SCRIPT_DIR/../lib/hook-common.sh" ]]; then
    source "$SCRIPT_DIR/../lib/hook-common.sh"
else
    echo "[DevTeam Session Start] Warning: hook-common.sh not found" >&2
    exit 0
fi

# Logging function
log() {
    echo "[DevTeam Session Start] $1"
}

# Output to stdout (will be injected into Claude's context)
output() {
    echo "$1"
}

# ============================================
# LOAD PREVIOUS SESSION MEMORY
# ============================================
load_session_memory() {
    if [ -d "$MEMORY_DIR" ]; then
        # Find most recent memory file
        LATEST=$(ls -t "$MEMORY_DIR"/session-*.md 2>/dev/null | head -1)

        if [ -n "$LATEST" ] && [ -f "$LATEST" ]; then
            log "Loading previous session context from $LATEST"
            output ""
            output "## Previous Session Context"
            output ""
            cat "$LATEST"
            output ""
            output "---"
            output ""
        fi
    fi
}

# ============================================
# LOAD CURRENT STATE
# ============================================
load_state_summary() {
    if db_exists 2>/dev/null; then
        log "Loading project state from database"

        # Extract key information from SQLite
        local safe_session_id
        safe_session_id=$(get_current_session 2>/dev/null || echo "")
        safe_session_id="${safe_session_id//\'/\'\'}"
        CURRENT_SPRINT=$(db_query "SELECT sprint_id FROM sessions WHERE id = '$safe_session_id';" 2>/dev/null || echo "none")
        CURRENT_TASK=$(db_query "SELECT current_task_id FROM sessions WHERE id = '$safe_session_id';" 2>/dev/null || echo "none")
        PHASE=$(db_query "SELECT current_phase FROM sessions WHERE id = '$safe_session_id';" 2>/dev/null || echo "unknown")

        CURRENT_SPRINT="${CURRENT_SPRINT:-none}"
        CURRENT_TASK="${CURRENT_TASK:-none}"
        PHASE="${PHASE:-unknown}"

        output "## Current Project State"
        output ""
        output "- **Current Sprint:** $CURRENT_SPRINT"
        output "- **Current Task:** $CURRENT_TASK"
        output "- **Phase:** $PHASE"
        output ""

        # Check for autonomous mode
        if [ -f ".devteam/autonomous-mode" ]; then
            output "- **Mode:** Autonomous (running until complete)"
            output ""
        fi
    fi
}

# ============================================
# AUTO-DETECT PROJECT LANGUAGES
# ============================================
detect_languages() {
    log "Detecting project languages..."

    DETECTED=""

    # Python
    if [ -f "pyproject.toml" ] || [ -f "requirements.txt" ] || [ -f "setup.py" ]; then
        DETECTED="$DETECTED python"
    fi

    # TypeScript/JavaScript
    if [ -f "package.json" ] || [ -f "tsconfig.json" ]; then
        DETECTED="$DETECTED typescript"
    fi

    # Go
    if [ -f "go.mod" ]; then
        DETECTED="$DETECTED go"
    fi

    # Rust
    if [ -f "Cargo.toml" ]; then
        DETECTED="$DETECTED rust"
    fi

    # Java
    if [ -f "pom.xml" ] || [ -f "build.gradle" ]; then
        DETECTED="$DETECTED java"
    fi

    # C#
    if ls *.csproj 1> /dev/null 2>&1 || ls *.sln 1> /dev/null 2>&1; then
        DETECTED="$DETECTED csharp"
    fi

    # Ruby
    if [ -f "Gemfile" ]; then
        DETECTED="$DETECTED ruby"
    fi

    # PHP
    if [ -f "composer.json" ]; then
        DETECTED="$DETECTED php"
    fi

    if [ -n "$DETECTED" ]; then
        output "## Detected Languages"
        output ""
        for lang in $DETECTED; do
            output "- $lang"
        done
        output ""
        output "Consider enabling LSP servers for these languages for better code intelligence."
        output "See \`mcp-configs/lsp-servers.json\` for configuration."
        output ""
    fi
}

# ============================================
# DETECT PACKAGE MANAGERS
# ============================================
detect_package_managers() {
    log "Detecting package managers..."

    # Python
    if [ -f "uv.lock" ]; then
        output "- **Python:** uv (recommended)"
    elif [ -f "poetry.lock" ]; then
        output "- **Python:** poetry"
    elif [ -f "Pipfile.lock" ]; then
        output "- **Python:** pipenv"
    elif [ -f "requirements.txt" ]; then
        output "- **Python:** pip"
    fi

    # Node.js
    if [ -f "pnpm-lock.yaml" ]; then
        output "- **Node.js:** pnpm"
    elif [ -f "yarn.lock" ]; then
        output "- **Node.js:** yarn"
    elif [ -f "bun.lockb" ]; then
        output "- **Node.js:** bun"
    elif [ -f "package-lock.json" ]; then
        output "- **Node.js:** npm"
    fi
}

# ============================================
# MAIN EXECUTION
# ============================================
main() {
    output "# DevTeam Session Initialized"
    output ""

    # Load previous context if available
    load_session_memory

    # Load current state
    load_state_summary

    # Detect project configuration
    detect_languages

    output "## Package Managers"
    output ""
    detect_package_managers
    output ""

    log "Session initialization complete"
}

# Run main function
main
