#!/bin/bash

# Local Installation Script for claude-devteam plugin
# Checks prerequisites, installs hooks, and initializes the database.

set -euo pipefail

PLUGIN_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "Installing DevTeam plugin from: $PLUGIN_DIR"
echo ""

# --- Prerequisites ---

MISSING=()

if ! command -v sqlite3 &>/dev/null; then
    MISSING+=("sqlite3")
fi

if ! command -v git &>/dev/null; then
    MISSING+=("git")
fi

if ! command -v jq &>/dev/null; then
    MISSING+=("jq")
fi

# Check bash version (need 4.0+)
if [ "${BASH_VERSINFO[0]}" -lt 4 ]; then
    echo "ERROR: Bash 4.0+ is required (found ${BASH_VERSION})."
    echo "On macOS, install with: brew install bash"
    exit 1
fi

if [ ${#MISSING[@]} -gt 0 ]; then
    echo "ERROR: Missing required tools: ${MISSING[*]}"
    echo "Please install them and try again."
    exit 1
fi

echo "Prerequisites OK (sqlite3, git, jq, bash ${BASH_VERSINFO[0]})"

# --- Install Hooks ---

echo ""
echo "Installing hooks..."
if [ -x "$PLUGIN_DIR/hooks/install.sh" ]; then
    bash "$PLUGIN_DIR/hooks/install.sh"
else
    chmod +x "$PLUGIN_DIR/hooks/install.sh"
    bash "$PLUGIN_DIR/hooks/install.sh"
fi

# --- Initialize Database ---

echo ""
echo "Initializing database..."
bash "$PLUGIN_DIR/scripts/db-init.sh"

# --- Done ---

echo ""
echo "Installation complete!"
echo ""
echo "Usage:"
echo "  /devteam:plan           - Interactive planning (PRD + tasks + sprints)"
echo "  /devteam:implement      - Autonomous execution until complete"
echo "  /devteam:bug \"desc\"     - Fix a bug with diagnostic workflow"
echo "  /devteam:issue 123      - Fix GitHub issue #123"
echo "  /devteam:status         - Check system health and progress"
echo ""
echo "Documentation: $PLUGIN_DIR/README.md"
