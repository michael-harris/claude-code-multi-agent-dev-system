#!/bin/bash

# Local Installation Script for claude-devteam plugin

echo "🔧 Installing claude-devteam plugin locally..."

PLUGIN_DIR="$(cd "$(dirname "$0")" && pwd)"
TARGET_PROJECT="${1:-.}"

echo "📁 Plugin location: $PLUGIN_DIR"
echo "📁 Target project: $(cd "$TARGET_PROJECT" && pwd)"

# Navigate to target project
cd "$TARGET_PROJECT" || exit 1

# Initialize .claude-plugin directory if needed
mkdir -p .claude-plugin

# Initialize marketplace.json if needed
if [ ! -f .claude-plugin/marketplace.json ]; then
    echo '{"plugins": []}' > .claude-plugin/marketplace.json
    echo "✅ Initialized .claude-plugin/marketplace.json"
fi

# Add plugin to marketplace
MARKETPLACE_FILE=".claude-plugin/marketplace.json"

# Check if plugin already exists
if grep -q "claude-devteam" "$MARKETPLACE_FILE" 2>/dev/null; then
    echo "⚠️  Plugin already in marketplace, updating..."
    # Remove old entry
    jq 'del(.plugins[] | select(.name == "claude-devteam"))' "$MARKETPLACE_FILE" > "$MARKETPLACE_FILE.tmp"
    mv "$MARKETPLACE_FILE.tmp" "$MARKETPLACE_FILE"
fi

# Add plugin entry
jq --arg path "$PLUGIN_DIR" '.plugins += [{
    "name": "claude-devteam",
    "path": $path,
    "type": "local"
}]' "$MARKETPLACE_FILE" > "$MARKETPLACE_FILE.tmp"
mv "$MARKETPLACE_FILE.tmp" "$MARKETPLACE_FILE"

echo "✅ Plugin added to marketplace"
echo ""
echo "🎉 Installation complete!"
echo ""
echo "The plugin is now available in this project."
echo ""
echo "📖 Usage:"
echo "   /devteam:plan           - Interactive planning (PRD + tasks + sprints)"
echo "   /devteam:auto           - Autonomous execution until complete"
echo "   /devteam:sprint SPRINT-001  - Execute specific sprint"
echo "   /devteam:issue 123      - Fix GitHub issue #123"
echo ""
echo "   Or launch individual agents:"
echo "   Task("
echo "     subagent_type=\"multi-agent:database:designer\","
echo "     model=\"opus\","
echo "     prompt=\"Design user schema\""
echo "   )"
echo ""
echo "📚 Documentation: $PLUGIN_DIR/README.md"
