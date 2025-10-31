#!/bin/bash

# Local Installation Script for multi-agent-dev-system plugin

echo "🔧 Installing multi-agent-dev-system plugin locally..."

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
if grep -q "multi-agent-dev-system" "$MARKETPLACE_FILE" 2>/dev/null; then
    echo "⚠️  Plugin already in marketplace, updating..."
    # Remove old entry
    jq 'del(.plugins[] | select(.name == "multi-agent-dev-system"))' "$MARKETPLACE_FILE" > "$MARKETPLACE_FILE.tmp"
    mv "$MARKETPLACE_FILE.tmp" "$MARKETPLACE_FILE"
fi

# Add plugin entry
jq --arg path "$PLUGIN_DIR" '.plugins += [{
    "name": "multi-agent-dev-system",
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
echo "   /prd                    - Generate PRD"
echo "   /planning               - Create tasks and sprints"
echo "   /sprint SPRINT-001      - Execute sprint"
echo ""
echo "   Or launch individual agents:"
echo "   Task("
echo "     subagent_type=\"multi-agent-dev-system:database:designer\","
echo "     model=\"sonnet\","
echo "     prompt=\"Design user schema\""
echo "   )"
echo ""
echo "📚 Documentation: $PLUGIN_DIR/README.md"
