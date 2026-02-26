#!/bin/bash
# DevTeam Hooks Installer
# Installs hooks into Claude Code configuration and git
#
# Usage: ./install.sh [--auto]
#   --auto: Skip interactive prompts, auto-install everything

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Options
AUTO_MODE=false
[[ "${1:-}" == "--auto" ]] && AUTO_MODE=true

echo ""
echo -e "${BLUE}================================================================${NC}"
echo -e "${BLUE}             DevTeam Hooks Installer${NC}"
echo -e "${BLUE}================================================================${NC}"
echo ""

# ============================================================================
# DETECT CLAUDE CODE CONFIG
# ============================================================================

detect_claude_config() {
    local config_dir=""
    local config_file=""

    # Check common locations
    if [[ -d "$HOME/.claude" ]]; then
        config_dir="$HOME/.claude"
    elif [[ -d "$HOME/Library/Application Support/Claude" ]]; then
        config_dir="$HOME/Library/Application Support/Claude"
    elif [[ -n "${APPDATA:-}" ]] && [[ -d "$APPDATA/Claude" ]]; then
        config_dir="$APPDATA/Claude"
    elif [[ -n "${XDG_CONFIG_HOME:-}" ]] && [[ -d "$XDG_CONFIG_HOME/claude" ]]; then
        config_dir="$XDG_CONFIG_HOME/claude"
    fi

    if [[ -n "$config_dir" ]]; then
        config_file="$config_dir/settings.json"
        echo "$config_file"
    fi
}

CLAUDE_CONFIG_FILE=$(detect_claude_config)

if [[ -z "$CLAUDE_CONFIG_FILE" ]]; then
    echo -e "${YELLOW}! Could not auto-detect Claude Code configuration directory.${NC}"
    echo ""
    echo "  Please manually add hooks to your Claude Code settings."
    echo "  See hooks/README.md for configuration details."
    echo ""
else
    echo -e "${GREEN}ok${NC} Found Claude Code config: $CLAUDE_CONFIG_FILE"
fi
echo ""

# ============================================================================
# MAKE HOOKS EXECUTABLE
# ============================================================================

echo "Making hooks executable..."

chmod +x "$SCRIPT_DIR"/*.sh 2>/dev/null || true
chmod +x "$SCRIPT_DIR"/lib/*.sh 2>/dev/null || true

echo -e "${GREEN}ok${NC} Hooks are executable"
echo ""

# ============================================================================
# INSTALL GIT HOOKS
# ============================================================================

if [[ -d "$PROJECT_ROOT/.git" ]]; then
    echo "Installing git hooks..."

    GIT_HOOKS_DIR="$PROJECT_ROOT/.git/hooks"
    mkdir -p "$GIT_HOOKS_DIR"

    # Pre-commit hook for scope checking
    cat > "$GIT_HOOKS_DIR/pre-commit" << EOF
#!/bin/bash
# DevTeam scope check hook
exec "$SCRIPT_DIR/scope-check.sh"
EOF
    chmod +x "$GIT_HOOKS_DIR/pre-commit"

    echo -e "${GREEN}ok${NC} Git pre-commit hook installed"
else
    echo -e "${YELLOW}!${NC} Not a git repository - skipping git hooks"
fi
echo ""

# ============================================================================
# GENERATE CLAUDE CODE CONFIG
# ============================================================================

echo "Generating Claude Code hook configuration..."
echo ""

# Determine script extension based on platform
if [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "cygwin" ]] || [[ -n "${WINDIR:-}" ]]; then
    HOOK_EXT=".ps1"
    SHELL_CMD="powershell -ExecutionPolicy Bypass -File"
else
    HOOK_EXT=".sh"
    SHELL_CMD=""
fi

HOOKS_CONFIG=$(cat << EOF
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": ".*",
        "hooks": ["$SHELL_CMD$SCRIPT_DIR/pre-tool-use-hook$HOOK_EXT"]
      }
    ],
    "PostToolUse": [
      {
        "matcher": ".*",
        "hooks": ["$SHELL_CMD$SCRIPT_DIR/post-tool-use-hook$HOOK_EXT"]
      }
    ],
    "Stop": [
      {
        "matcher": ".*",
        "hooks": ["$SHELL_CMD$SCRIPT_DIR/stop-hook$HOOK_EXT"]
      }
    ],
    "PostMessage": [
      {
        "matcher": ".*",
        "hooks": ["$SHELL_CMD$SCRIPT_DIR/persistence-hook$HOOK_EXT"]
      }
    ],
    "SessionStart": [
      {
        "matcher": ".*",
        "hooks": ["$SHELL_CMD$SCRIPT_DIR/session-start$HOOK_EXT"]
      }
    ],
    "SessionEnd": [
      {
        "matcher": ".*",
        "hooks": ["$SHELL_CMD$SCRIPT_DIR/session-end$HOOK_EXT"]
      }
    ],
    "PreCompact": [
      {
        "matcher": ".*",
        "hooks": ["$SHELL_CMD$SCRIPT_DIR/pre-compact$HOOK_EXT"]
      }
    ]
  }
}
EOF
)

echo "Add the following to your Claude Code settings:"
echo ""
echo -e "${BLUE}----------------------------------------------------------------${NC}"
echo "$HOOKS_CONFIG"
echo -e "${BLUE}----------------------------------------------------------------${NC}"
echo ""

# ============================================================================
# AUTO-INSTALL TO SETTINGS
# ============================================================================

install_to_settings() {
    local config_file="$1"

    if [[ ! -f "$config_file" ]]; then
        # Create new config
        mkdir -p "$(dirname "$config_file")"
        echo "$HOOKS_CONFIG" > "$config_file"
        echo -e "${GREEN}ok${NC} Config file created: $config_file"
        return 0
    fi

    # Backup existing config
    cp "$config_file" "${config_file}.backup"
    echo -e "${GREEN}ok${NC} Backed up existing config to ${config_file}.backup"

    # Merge hooks into existing config
    if command -v jq &> /dev/null; then
        # Use jq for proper JSON merge
        local temp_file="${config_file}.tmp"
        jq -s '.[0] * .[1]' "$config_file" <(echo "$HOOKS_CONFIG") > "$temp_file" \
            || { mv "${config_file}.backup" "$config_file"; echo "jq merge failed"; return 1; }
        mv "$temp_file" "$config_file"
        echo -e "${GREEN}ok${NC} Hooks merged into config"
    else
        echo -e "${YELLOW}!${NC} jq not installed. Please manually merge the configuration."
        echo ""
        echo "Install jq for automatic merging: https://stedolan.github.io/jq/download/"
        return 1
    fi

    return 0
}

if [[ -n "$CLAUDE_CONFIG_FILE" ]]; then
    if [[ "$AUTO_MODE" == true ]]; then
        install_to_settings "$CLAUDE_CONFIG_FILE"
    else
        echo -n "Would you like to automatically add these hooks to your config? [y/N] "
        read -r response
        echo ""

        if [[ "$response" =~ ^[Yy]$ ]]; then
            install_to_settings "$CLAUDE_CONFIG_FILE"
        else
            echo "Skipped automatic installation."
            echo "Please manually add the configuration above to: $CLAUDE_CONFIG_FILE"
        fi
    fi
fi

echo ""

# ============================================================================
# CREATE .devteam DIRECTORY
# ============================================================================

echo "Creating .devteam directory..."

DEVTEAM_DIR="$PROJECT_ROOT/.devteam"
mkdir -p "$DEVTEAM_DIR"

# Initialize database if script exists
if [[ -x "$PROJECT_ROOT/scripts/db-init.sh" ]]; then
    echo "Initializing database..."
    "$PROJECT_ROOT/scripts/db-init.sh" 2>/dev/null || true
    echo -e "${GREEN}ok${NC} Database initialized"
fi

# Create hooks-installed marker so db-init.sh can detect it
touch "$DEVTEAM_DIR/.hooks-installed"

echo -e "${GREEN}ok${NC} .devteam directory ready"
echo ""

# ============================================================================
# VERIFICATION
# ============================================================================

echo "Verifying installation..."
echo ""

verify_file() {
    local file="$1"
    local name="$2"

    if [[ -f "$file" ]] && [[ -x "$file" ]]; then
        echo -e "  ${GREEN}ok${NC} $name"
        return 0
    else
        echo -e "  ${RED}X${NC} $name (missing or not executable)"
        return 1
    fi
}

ERRORS=0

verify_file "$SCRIPT_DIR/lib/hook-common.sh" "hook-common.sh (shared library)" || ERRORS=$((ERRORS + 1))
verify_file "$SCRIPT_DIR/pre-tool-use-hook.sh" "pre-tool-use-hook.sh" || ERRORS=$((ERRORS + 1))
verify_file "$SCRIPT_DIR/post-tool-use-hook.sh" "post-tool-use-hook.sh" || ERRORS=$((ERRORS + 1))
verify_file "$SCRIPT_DIR/stop-hook.sh" "stop-hook.sh" || ERRORS=$((ERRORS + 1))
verify_file "$SCRIPT_DIR/persistence-hook.sh" "persistence-hook.sh" || ERRORS=$((ERRORS + 1))
verify_file "$SCRIPT_DIR/scope-check.sh" "scope-check.sh" || ERRORS=$((ERRORS + 1))
verify_file "$SCRIPT_DIR/session-start.sh" "session-start.sh" || ERRORS=$((ERRORS + 1))
verify_file "$SCRIPT_DIR/session-end.sh" "session-end.sh" || ERRORS=$((ERRORS + 1))
verify_file "$SCRIPT_DIR/pre-compact.sh" "pre-compact.sh" || ERRORS=$((ERRORS + 1))

echo ""

# ============================================================================
# SUMMARY
# ============================================================================

echo -e "${BLUE}================================================================${NC}"
if [[ $ERRORS -eq 0 ]]; then
    echo -e "${GREEN}             Installation Complete${NC}"
else
    echo -e "${YELLOW}             Installation Complete (with warnings)${NC}"
fi
echo -e "${BLUE}================================================================${NC}"
echo ""
echo "Hooks installed:"
echo -e "  ${GREEN}ok${NC} pre-tool-use-hook   - Scope validation, dangerous command blocking"
echo -e "  ${GREEN}ok${NC} post-tool-use-hook  - Failure tracking, escalation detection"
echo -e "  ${GREEN}ok${NC} stop-hook           - Exit control, checkpoint save"
echo -e "  ${GREEN}ok${NC} persistence-hook    - Abandonment prevention"
echo -e "  ${GREEN}ok${NC} scope-check         - Git pre-commit scope validation"
echo -e "  ${GREEN}ok${NC} session-start       - Session initialization, context loading"
echo -e "  ${GREEN}ok${NC} session-end         - Session cleanup, memory persistence"
echo -e "  ${GREEN}ok${NC} pre-compact         - State preservation before compaction"
echo ""
echo "Next steps:"
echo "  1. Restart Claude Code for hooks to take effect"
echo "  2. Run './hooks/tests/test-hooks.sh' to verify"
echo "  3. See './hooks/README.md' for configuration options"
echo ""

if [[ $ERRORS -gt 0 ]]; then
    echo -e "${YELLOW}Warning: $ERRORS hook(s) may not be properly installed.${NC}"
    echo ""
fi
