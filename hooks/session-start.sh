#!/bin/bash
# DevTeam Session Start Hook
# Loads previous session context and auto-detects project configuration

set -e

# Configuration
MEMORY_DIR=".devteam/memory"
STATE_FILE=".devteam/state.yaml"
CONFIG_FILE=".devteam/config.yaml"

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
    if [ -f "$STATE_FILE" ]; then
        log "Loading project state"

        # Extract key information
        if command -v yq &> /dev/null; then
            CURRENT_SPRINT=$(yq -r '.current_execution.current_sprint // "none"' "$STATE_FILE" 2>/dev/null)
            CURRENT_TASK=$(yq -r '.current_execution.current_task // "none"' "$STATE_FILE" 2>/dev/null)
            PHASE=$(yq -r '.current_execution.phase // "unknown"' "$STATE_FILE" 2>/dev/null)
        else
            # Fallback grep-based extraction
            CURRENT_SPRINT=$(grep "current_sprint:" "$STATE_FILE" 2>/dev/null | head -1 | awk '{print $2}' || echo "unknown")
            CURRENT_TASK=$(grep "current_task:" "$STATE_FILE" 2>/dev/null | head -1 | awk '{print $2}' || echo "unknown")
            PHASE=$(grep "phase:" "$STATE_FILE" 2>/dev/null | head -1 | awk '{print $2}' || echo "unknown")
        fi

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
