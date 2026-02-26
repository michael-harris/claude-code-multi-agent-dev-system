#!/usr/bin/env python3
"""
Batch update all agent markdown files with native subagent frontmatter.

Split model strategy:
- Fixed-model agents: Keep `model` in frontmatter (orchestrators, validators, reviewers, security, diagnosis)
- Dynamic-model agents: Remove `model` from frontmatter (implementation agents in Task Loop escalation chain)

All agents get: `tools` field
Key agents get: `memory: project` (Suggestion 8)
"""

import os
import re
import sys

AGENTS_DIR = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "agents")

# ============================================================================
# AGENT CLASSIFICATION
# ============================================================================

# Fixed-model agents: NOT in Task Loop escalation chain
# These always run at their assigned model
FIXED_MODEL_AGENTS = {
    # Orchestration - always fixed model, coordinate other agents
    "orchestration/autonomous-controller.md":    {"tools": "Read, Glob, Grep, Bash, Task", "memory": "project"},
    "orchestration/bug-council-orchestrator.md": {"tools": "Read, Glob, Grep, Bash, Task", "memory": "project"},
    "orchestration/code-review-coordinator.md":  {"tools": "Read, Glob, Grep, Bash, Task"},
    "orchestration/quality-gate-enforcer.md":    {"tools": "Read, Glob, Grep, Bash", "memory": "project"},
    "orchestration/requirements-validator.md":   {"tools": "Read, Glob, Grep, Bash"},
    "orchestration/scope-validator.md":          {"tools": "Read, Glob, Grep, Bash"},
    "orchestration/sprint-loop.md":              {"tools": "Read, Glob, Grep, Bash, Task"},
    "orchestration/sprint-orchestrator.md":      {"tools": "Read, Glob, Grep, Bash, Task", "memory": "project"},
    "orchestration/task-loop.md":                {"tools": "Read, Glob, Grep, Bash, Task", "memory": "project"},
    "orchestration/track-merger.md":             {"tools": "Read, Glob, Grep, Bash, Task"},
    "orchestration/workflow-compliance.md":       {"tools": "Read, Glob, Grep, Bash"},

    # Diagnosis / Bug Council - always opus, analysis only
    "diagnosis/adversarial-tester.md":  {"tools": "Read, Glob, Grep, Bash"},
    "diagnosis/code-archaeologist.md":  {"tools": "Read, Glob, Grep, Bash"},
    "diagnosis/pattern-matcher.md":     {"tools": "Read, Glob, Grep, Bash"},
    "diagnosis/root-cause-analyst.md":  {"tools": "Read, Glob, Grep, Bash"},
    "diagnosis/systems-thinker.md":     {"tools": "Read, Glob, Grep, Bash"},

    # Code Reviewers - always sonnet, read-only analysis
    "backend/api-design-reviewer.md":           {"tools": "Read, Glob, Grep"},
    "backend/backend-code-reviewer-csharp.md":  {"tools": "Read, Glob, Grep"},
    "backend/backend-code-reviewer-go.md":      {"tools": "Read, Glob, Grep"},
    "backend/backend-code-reviewer-java.md":    {"tools": "Read, Glob, Grep"},
    "backend/backend-code-reviewer-php.md":     {"tools": "Read, Glob, Grep"},
    "backend/backend-code-reviewer-python.md":  {"tools": "Read, Glob, Grep"},
    "backend/backend-code-reviewer-ruby.md":    {"tools": "Read, Glob, Grep"},
    "backend/backend-code-reviewer-typescript.md": {"tools": "Read, Glob, Grep"},
    "frontend/frontend-code-reviewer.md":       {"tools": "Read, Glob, Grep"},
    "mobile/android-code-reviewer.md":          {"tools": "Read, Glob, Grep"},
    "mobile/ios-code-reviewer.md":              {"tools": "Read, Glob, Grep"},
    "database/sql-code-reviewer.md":            {"tools": "Read, Glob, Grep"},
    "database/nosql-code-reviewer.md":          {"tools": "Read, Glob, Grep"},

    # Security auditors - always opus, analysis + security scans
    "security/compliance-engineer.md":          {"tools": "Read, Glob, Grep, Bash"},
    "security/mobile-security-auditor.md":      {"tools": "Read, Glob, Grep, Bash"},
    "security/penetration-tester.md":           {"tools": "Read, Glob, Grep, Bash"},
    "security/security-auditor-csharp.md":      {"tools": "Read, Glob, Grep, Bash"},
    "security/security-auditor-go.md":          {"tools": "Read, Glob, Grep, Bash"},
    "security/security-auditor-java.md":        {"tools": "Read, Glob, Grep, Bash"},
    "security/security-auditor-php.md":         {"tools": "Read, Glob, Grep, Bash"},
    "security/security-auditor-python.md":      {"tools": "Read, Glob, Grep, Bash"},
    "security/security-auditor-ruby.md":        {"tools": "Read, Glob, Grep, Bash"},
    "security/security-auditor-typescript.md":  {"tools": "Read, Glob, Grep, Bash"},

    # Research - always opus, needs web access
    "research/research-agent.md": {"tools": "Read, Glob, Grep, Bash, WebSearch, WebFetch", "memory": "project"},

    # Planning - always sonnet, create plan artifacts
    "planning/prd-generator.md":       {"tools": "Read, Glob, Grep, Bash, Write"},
    "planning/sprint-planner.md":      {"tools": "Read, Glob, Grep, Bash, Write"},
    "planning/task-graph-analyzer.md": {"tools": "Read, Glob, Grep, Bash, Write"},

    # Product - always opus
    "product/product-manager.md": {"tools": "Read, Glob, Grep, Bash, Write"},

    # Architecture - always opus, high-level decisions
    "architecture/architect.md": {"tools": "Read, Glob, Grep, Bash, Write"},

    # Quality coordinators (coordinate, don't implement)
    "quality/test-coordinator.md":      {"tools": "Read, Glob, Grep, Bash, Task"},
    "quality/refactoring-coordinator.md": {"tools": "Read, Glob, Grep, Bash, Task"},
    "quality/security-auditor.md":      {"tools": "Read, Glob, Grep, Bash"},
    "quality/visual-verification-agent.md": {"tools": "Read, Glob, Grep, Bash"},

    # Performance auditors - analysis only, don't write code
    "quality/performance-auditor-android.md":    {"tools": "Read, Glob, Grep, Bash"},
    "quality/performance-auditor-csharp.md":     {"tools": "Read, Glob, Grep, Bash"},
    "quality/performance-auditor-go.md":         {"tools": "Read, Glob, Grep, Bash"},
    "quality/performance-auditor-ios.md":        {"tools": "Read, Glob, Grep, Bash"},
    "quality/performance-auditor-java.md":       {"tools": "Read, Glob, Grep, Bash"},
    "quality/performance-auditor-php.md":        {"tools": "Read, Glob, Grep, Bash"},
    "quality/performance-auditor-python.md":     {"tools": "Read, Glob, Grep, Bash"},
    "quality/performance-auditor-ruby.md":       {"tools": "Read, Glob, Grep, Bash"},
    "quality/performance-auditor-typescript.md": {"tools": "Read, Glob, Grep, Bash"},

    # UX coordinators
    "ux/ux-system-coordinator.md":   {"tools": "Read, Glob, Grep, Bash, Task"},
    "ux/design-system-architect.md": {"tools": "Read, Edit, Write, Glob, Grep, Bash"},

    # Design compliance - always haiku, read-only validation
    "ux/design-compliance-validator.md": {"tools": "Read, Glob, Grep"},
}

# Dynamic-model agents: IN the Task Loop escalation chain
# model field is REMOVED from frontmatter to allow runtime override
DYNAMIC_MODEL_AGENTS_TOOLS = {
    # Backend implementation
    "backend/api-designer.md":              "Read, Edit, Write, Glob, Grep, Bash",
    "backend/api-developer-csharp.md":      "Read, Edit, Write, Glob, Grep, Bash",
    "backend/api-developer-go.md":          "Read, Edit, Write, Glob, Grep, Bash",
    "backend/api-developer-java.md":        "Read, Edit, Write, Glob, Grep, Bash",
    "backend/api-developer-php.md":         "Read, Edit, Write, Glob, Grep, Bash",
    "backend/api-developer-python.md":      "Read, Edit, Write, Glob, Grep, Bash",
    "backend/api-developer-ruby.md":        "Read, Edit, Write, Glob, Grep, Bash",
    "backend/api-developer-typescript.md":  "Read, Edit, Write, Glob, Grep, Bash",

    # Frontend implementation
    "frontend/frontend-designer.md":   "Read, Edit, Write, Glob, Grep, Bash",
    "frontend/frontend-developer.md":  "Read, Edit, Write, Glob, Grep, Bash",

    # Database implementation
    "database/database-designer.md":             "Read, Edit, Write, Glob, Grep, Bash",
    "database/database-developer-android.md":    "Read, Edit, Write, Glob, Grep, Bash",
    "database/database-developer-csharp.md":     "Read, Edit, Write, Glob, Grep, Bash",
    "database/database-developer-go.md":         "Read, Edit, Write, Glob, Grep, Bash",
    "database/database-developer-ios.md":        "Read, Edit, Write, Glob, Grep, Bash",
    "database/database-developer-java.md":       "Read, Edit, Write, Glob, Grep, Bash",
    "database/database-developer-php.md":        "Read, Edit, Write, Glob, Grep, Bash",
    "database/database-developer-python.md":     "Read, Edit, Write, Glob, Grep, Bash",
    "database/database-developer-ruby.md":       "Read, Edit, Write, Glob, Grep, Bash",
    "database/database-developer-typescript.md": "Read, Edit, Write, Glob, Grep, Bash",

    # Mobile implementation
    "mobile/android-designer.md":         "Read, Edit, Write, Glob, Grep, Bash",
    "mobile/android-developer.md":        "Read, Edit, Write, Glob, Grep, Bash",
    "mobile/ios-designer.md":             "Read, Edit, Write, Glob, Grep, Bash",
    "mobile/ios-developer.md":            "Read, Edit, Write, Glob, Grep, Bash",
    "mobile/flutter-developer.md":        "Read, Edit, Write, Glob, Grep, Bash",
    "mobile/react-native-developer.md":   "Read, Edit, Write, Glob, Grep, Bash",

    # Python / Scripting
    "python/python-developer-generic.md":  "Read, Edit, Write, Glob, Grep, Bash",
    "scripting/shell-developer.md":        "Read, Edit, Write, Glob, Grep, Bash",
    "scripting/powershell-developer.md":   "Read, Edit, Write, Glob, Grep, Bash",

    # Data & AI
    "data-ai/data-engineer.md":  "Read, Edit, Write, Glob, Grep, Bash",
    "data-ai/ml-engineer.md":    "Read, Edit, Write, Glob, Grep, Bash",

    # DevOps
    "devops/cicd-specialist.md":       "Read, Edit, Write, Glob, Grep, Bash",
    "devops/docker-specialist.md":     "Read, Edit, Write, Glob, Grep, Bash",
    "devops/kubernetes-specialist.md":  "Read, Edit, Write, Glob, Grep, Bash",
    "devops/mobile-cicd-specialist.md": "Read, Edit, Write, Glob, Grep, Bash",
    "devops/terraform-specialist.md":   "Read, Edit, Write, Glob, Grep, Bash",

    # Infrastructure & SRE
    "infrastructure/configuration-manager.md": "Read, Edit, Write, Glob, Grep, Bash",
    "sre/platform-engineer.md":                "Read, Edit, Write, Glob, Grep, Bash",
    "sre/site-reliability-engineer.md":        "Read, Edit, Write, Glob, Grep, Bash",
    "specialized/observability-engineer.md":   "Read, Edit, Write, Glob, Grep, Bash",

    # Accessibility
    "accessibility/accessibility-specialist.md":        "Read, Edit, Write, Glob, Grep, Bash",
    "accessibility/mobile-accessibility-specialist.md": "Read, Edit, Write, Glob, Grep, Bash",

    # UX specialists (implementation, not coordination)
    "ux/ux-specialist-web.md":          "Read, Edit, Write, Glob, Grep, Bash",
    "ux/ux-specialist-mobile.md":       "Read, Edit, Write, Glob, Grep, Bash",
    "ux/ux-specialist-desktop.md":      "Read, Edit, Write, Glob, Grep, Bash",
    "ux/design-system-orchestrator.md": "Read, Edit, Write, Glob, Grep, Bash, Task",
    "ux/color-palette-specialist.md":   "Read, Edit, Write, Glob, Grep, Bash",
    "ux/typography-specialist.md":      "Read, Edit, Write, Glob, Grep, Bash",
    "ux/ui-style-curator.md":          "Read, Edit, Write, Glob, Grep, Bash",
    "ux/data-visualization-designer.md": "Read, Edit, Write, Glob, Grep, Bash",
    "ux/design-drift-detector.md":      "Read, Glob, Grep, Bash",

    # Quality - test/implementation agents (write test code)
    "quality/test-writer.md":                 "Read, Edit, Write, Glob, Grep, Bash",
    "quality/unit-test-writer-csharp.md":     "Read, Edit, Write, Glob, Grep, Bash",
    "quality/unit-test-writer-go.md":         "Read, Edit, Write, Glob, Grep, Bash",
    "quality/unit-test-writer-java.md":       "Read, Edit, Write, Glob, Grep, Bash",
    "quality/unit-test-writer-php.md":        "Read, Edit, Write, Glob, Grep, Bash",
    "quality/unit-test-writer-python.md":     "Read, Edit, Write, Glob, Grep, Bash",
    "quality/unit-test-writer-ruby.md":       "Read, Edit, Write, Glob, Grep, Bash",
    "quality/unit-test-writer-typescript.md":  "Read, Edit, Write, Glob, Grep, Bash",
    "quality/e2e-tester.md":                  "Read, Edit, Write, Glob, Grep, Bash",
    "quality/mobile-test-writer.md":          "Read, Edit, Write, Glob, Grep, Bash",
    "quality/mobile-e2e-tester.md":           "Read, Edit, Write, Glob, Grep, Bash",
    "quality/runtime-verifier.md":            "Read, Glob, Grep, Bash",
    "quality/documentation-coordinator.md":   "Read, Edit, Write, Glob, Grep, Bash",

    # DevRel
    "devrel/developer-advocate.md": "Read, Edit, Write, Glob, Grep, Bash",

    # Support
    "support/dependency-manager.md": "Read, Edit, Write, Glob, Grep, Bash",
}


def parse_frontmatter(content):
    """Parse YAML frontmatter from markdown content."""
    match = re.match(r'^---\n(.*?)\n---\n', content, re.DOTALL)
    if not match:
        return None, content
    fm_text = match.group(1)
    rest = content[match.end():]

    # Simple YAML parser for our known format
    fm = {}
    for line in fm_text.strip().split('\n'):
        if ':' in line:
            key, _, value = line.partition(':')
            key = key.strip()
            value = value.strip().strip('"').strip("'")
            fm[key] = value
    return fm, rest


def build_frontmatter(fields):
    """Build YAML frontmatter string from dict."""
    lines = ["---"]
    # Ordered output
    order = ["name", "description", "model", "tools", "memory"]
    for key in order:
        if key in fields:
            val = fields[key]
            if key == "description":
                lines.append(f'{key}: "{val}"')
            else:
                lines.append(f"{key}: {val}")
    # Any remaining keys
    for key, val in fields.items():
        if key not in order:
            lines.append(f"{key}: {val}")
    lines.append("---")
    return '\n'.join(lines) + '\n'


def update_agent_file(filepath, rel_path):
    """Update a single agent file with enhanced frontmatter."""
    with open(filepath, 'r') as f:
        content = f.read()

    fm, rest = parse_frontmatter(content)
    if fm is None:
        print(f"  SKIP (no frontmatter): {rel_path}")
        return False

    new_fm = {}
    new_fm["name"] = fm.get("name", "")
    new_fm["description"] = fm.get("description", "")

    if rel_path in FIXED_MODEL_AGENTS:
        # Keep model, add tools and optional memory
        config = FIXED_MODEL_AGENTS[rel_path]
        new_fm["model"] = fm.get("model", "sonnet")
        new_fm["tools"] = config["tools"]
        if "memory" in config:
            new_fm["memory"] = config["memory"]
        strategy = "fixed"

    elif rel_path in DYNAMIC_MODEL_AGENTS_TOOLS:
        # REMOVE model, add tools
        # Model is determined at runtime by the calling orchestrator (Task Loop)
        new_fm["tools"] = DYNAMIC_MODEL_AGENTS_TOOLS[rel_path]
        strategy = "dynamic"

    else:
        print(f"  WARN (uncategorized): {rel_path} — keeping original")
        return False

    new_content = build_frontmatter(new_fm) + rest

    with open(filepath, 'w') as f:
        f.write(new_content)

    model_info = f"model={new_fm.get('model', 'DYNAMIC')}"
    memory_info = f" memory={new_fm.get('memory', '')}" if 'memory' in new_fm else ""
    print(f"  OK [{strategy:7s}] {rel_path:55s} {model_info:15s} tools={new_fm['tools']}{memory_info}")
    return True


def main():
    updated = 0
    skipped = 0
    errors = 0

    print("=" * 80)
    print("Updating agent frontmatter with native subagent fields")
    print("=" * 80)
    print()

    all_expected = set(FIXED_MODEL_AGENTS.keys()) | set(DYNAMIC_MODEL_AGENTS_TOOLS.keys())

    for root, dirs, files in sorted(os.walk(AGENTS_DIR)):
        for filename in sorted(files):
            if not filename.endswith('.md') or filename == 'README.md':
                continue

            filepath = os.path.join(root, filename)
            rel_path = os.path.relpath(filepath, AGENTS_DIR)

            if rel_path.startswith("templates/"):
                print(f"  SKIP (template): {rel_path}")
                skipped += 1
                continue

            if update_agent_file(filepath, rel_path):
                updated += 1
            else:
                skipped += 1

    print()
    print("=" * 80)
    print(f"SUMMARY: {updated} updated, {skipped} skipped")
    print(f"Fixed-model agents: {len(FIXED_MODEL_AGENTS)}")
    print(f"Dynamic-model agents: {len(DYNAMIC_MODEL_AGENTS_TOOLS)}")
    print(f"Total categorized: {len(all_expected)}")
    print("=" * 80)


if __name__ == "__main__":
    main()
