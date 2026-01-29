#!/bin/bash
# DevTeam Configuration Validator
# Validates plugin.json and config.yaml against expected schemas
#
# Usage: ./validate-config.sh [options]
#
# Options:
#   --strict    Fail on warnings
#   --verbose   Show detailed output
#   --fix       Attempt to fix minor issues

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

source "${SCRIPT_DIR}/lib/common.sh"

# Configuration
PLUGIN_JSON="$PROJECT_ROOT/plugin.json"
CONFIG_YAML="$PROJECT_ROOT/.devteam/config.yaml"
STRICT_MODE=false
VERBOSE=false
FIX_MODE=false

# Counters
ERRORS=0
WARNINGS=0

# ============================================================================
# VALIDATION HELPERS
# ============================================================================

report_error() {
    local file="$1"
    local message="$2"
    log_error "[$file] $message" "validate"
    ((ERRORS++))
}

report_warning() {
    local file="$1"
    local message="$2"
    log_warn "[$file] $message" "validate"
    ((WARNINGS++))
}

report_info() {
    local file="$1"
    local message="$2"
    if [ "$VERBOSE" = true ]; then
        log_info "[$file] $message" "validate"
    fi
}

# ============================================================================
# PLUGIN.JSON VALIDATION
# ============================================================================

validate_plugin_json() {
    log_info "Validating plugin.json..." "validate"

    if [ ! -f "$PLUGIN_JSON" ]; then
        report_error "plugin.json" "File not found"
        return 1
    fi

    # Check if jq is available
    if ! command -v jq &> /dev/null; then
        report_warning "plugin.json" "jq not installed, skipping detailed validation"
        return 0
    fi

    # Validate JSON syntax
    if ! jq empty "$PLUGIN_JSON" 2>/dev/null; then
        report_error "plugin.json" "Invalid JSON syntax"
        return 1
    fi

    report_info "plugin.json" "JSON syntax valid"

    # Required top-level fields
    local required_fields=("name" "version" "description" "agents" "commands")
    for field in "${required_fields[@]}"; do
        if [ "$(jq "has(\"$field\")" "$PLUGIN_JSON")" != "true" ]; then
            report_error "plugin.json" "Missing required field: $field"
        fi
    done

    # Validate agents array
    validate_agents

    # Validate commands array
    validate_commands

    # Validate no duplicate IDs
    validate_unique_ids
}

validate_agents() {
    local agent_count
    agent_count=$(jq '.agents | length' "$PLUGIN_JSON")

    report_info "plugin.json" "Found $agent_count agents"

    if [ "$agent_count" -eq 0 ]; then
        report_error "plugin.json" "No agents defined"
        return
    fi

    # Check each agent
    local i=0
    while [ $i -lt "$agent_count" ]; do
        local agent_id
        agent_id=$(jq -r ".agents[$i].id // empty" "$PLUGIN_JSON")

        if [ -z "$agent_id" ]; then
            report_error "plugin.json" "Agent at index $i missing 'id'"
            ((i++))
            continue
        fi

        # Required agent fields (v3.1 schema: file instead of path, model instead of tier)
        local required=("name" "category")
        for field in "${required[@]}"; do
            local value
            value=$(jq -r ".agents[$i].$field // empty" "$PLUGIN_JSON")
            if [ -z "$value" ]; then
                report_error "plugin.json" "Agent '$agent_id' missing field: $field"
            fi
        done

        # Validate file path exists (supports both "file" and "path" for backwards compatibility)
        local file_path
        file_path=$(jq -r ".agents[$i].file // .agents[$i].path // empty" "$PLUGIN_JSON")
        if [ -z "$file_path" ]; then
            report_error "plugin.json" "Agent '$agent_id' missing field: file (or path)"
        elif [ ! -f "$PROJECT_ROOT/$file_path" ]; then
            report_error "plugin.json" "Agent '$agent_id' file not found: $file_path"
        fi

        # Validate model (optional, defaults to sonnet)
        local model
        model=$(jq -r ".agents[$i].model // empty" "$PLUGIN_JSON")
        if [ -n "$model" ] && [ "$model" != "opus" ] && [ "$model" != "sonnet" ] && [ "$model" != "haiku" ]; then
            report_error "plugin.json" "Agent '$agent_id' invalid model: $model (must be opus, sonnet, or haiku)"
        fi

        # Validate category
        local category
        category=$(jq -r ".agents[$i].category // empty" "$PLUGIN_JSON")
        local valid_categories=("planning" "research" "orchestration" "python" "typescript" "javascript" "go" "rust" "java" "frontend" "backend" "database" "quality" "security" "bug-council" "documentation" "devops" "workflow" "mobile" "specialized")
        local category_valid=false
        for valid_cat in "${valid_categories[@]}"; do
            if [ "$category" = "$valid_cat" ]; then
                category_valid=true
                break
            fi
        done
        if [ "$category_valid" = false ]; then
            report_warning "plugin.json" "Agent '$agent_id' has unusual category: $category"
        fi

        ((i++))
    done
}

validate_commands() {
    local cmd_count
    cmd_count=$(jq '.commands | length' "$PLUGIN_JSON")

    report_info "plugin.json" "Found $cmd_count commands"

    local i=0
    while [ $i -lt "$cmd_count" ]; do
        local cmd_name
        cmd_name=$(jq -r ".commands[$i].name // empty" "$PLUGIN_JSON")

        if [ -z "$cmd_name" ]; then
            report_error "plugin.json" "Command at index $i missing 'name'"
            ((i++))
            continue
        fi

        # Required command fields
        local required=("description" "path")
        for field in "${required[@]}"; do
            local value
            value=$(jq -r ".commands[$i].$field // empty" "$PLUGIN_JSON")
            if [ -z "$value" ]; then
                report_error "plugin.json" "Command '$cmd_name' missing field: $field"
            fi
        done

        # Validate path exists
        local path
        path=$(jq -r ".commands[$i].path // empty" "$PLUGIN_JSON")
        if [ -n "$path" ] && [ ! -f "$PROJECT_ROOT/$path" ]; then
            report_error "plugin.json" "Command '$cmd_name' path not found: $path"
        fi

        ((i++))
    done
}

validate_unique_ids() {
    # Check for duplicate agent IDs
    local duplicates
    duplicates=$(jq -r '.agents[].id' "$PLUGIN_JSON" | sort | uniq -d)

    if [ -n "$duplicates" ]; then
        report_error "plugin.json" "Duplicate agent IDs: $duplicates"
    fi

    # Check for duplicate command names
    duplicates=$(jq -r '.commands[].name' "$PLUGIN_JSON" | sort | uniq -d)

    if [ -n "$duplicates" ]; then
        report_error "plugin.json" "Duplicate command names: $duplicates"
    fi
}

# ============================================================================
# CONFIG.YAML VALIDATION
# ============================================================================

validate_config_yaml() {
    log_info "Validating config.yaml..." "validate"

    if [ ! -f "$CONFIG_YAML" ]; then
        report_info "config.yaml" "File not found (using defaults)"
        return 0
    fi

    # Check if yq is available for YAML parsing
    if ! command -v yq &> /dev/null; then
        # Fallback to basic validation
        if ! grep -q "^version:" "$CONFIG_YAML"; then
            report_warning "config.yaml" "Missing version field"
        fi
        report_warning "config.yaml" "yq not installed, skipping detailed validation"
        return 0
    fi

    # Validate YAML syntax
    if ! yq eval '.' "$CONFIG_YAML" > /dev/null 2>&1; then
        report_error "config.yaml" "Invalid YAML syntax"
        return 1
    fi

    report_info "config.yaml" "YAML syntax valid"

    # Validate version
    local version
    version=$(yq eval '.version // ""' "$CONFIG_YAML")
    if [ -z "$version" ]; then
        report_warning "config.yaml" "Missing version field"
    fi

    # Validate model_selection thresholds
    local simple threshold
    simple=$(yq eval '.model_selection.thresholds.simple // 0' "$CONFIG_YAML")
    local moderate
    moderate=$(yq eval '.model_selection.thresholds.moderate // 0' "$CONFIG_YAML")
    local complex
    complex=$(yq eval '.model_selection.thresholds.complex // 0' "$CONFIG_YAML")

    if [ "$simple" -ge "$moderate" ]; then
        report_error "config.yaml" "Threshold 'simple' must be less than 'moderate'"
    fi
    if [ "$moderate" -ge "$complex" ]; then
        report_error "config.yaml" "Threshold 'moderate' must be less than 'complex'"
    fi

    # Validate autonomous settings
    local max_iterations
    max_iterations=$(yq eval '.autonomous.max_iterations // 0' "$CONFIG_YAML")
    if [ "$max_iterations" -lt 1 ] || [ "$max_iterations" -gt 1000 ]; then
        report_warning "config.yaml" "max_iterations ($max_iterations) seems unusual (expected 1-1000)"
    fi

    local max_failures
    max_failures=$(yq eval '.autonomous.circuit_breaker.max_consecutive_failures // 0' "$CONFIG_YAML")
    if [ "$max_failures" -lt 1 ] || [ "$max_failures" -gt 20 ]; then
        report_warning "config.yaml" "max_consecutive_failures ($max_failures) seems unusual (expected 1-20)"
    fi

    # Validate parallel settings
    local max_concurrent
    max_concurrent=$(yq eval '.parallel.max_concurrent_tasks // 0' "$CONFIG_YAML")
    if [ "$max_concurrent" -lt 1 ] || [ "$max_concurrent" -gt 10 ]; then
        report_warning "config.yaml" "max_concurrent_tasks ($max_concurrent) seems unusual (expected 1-10)"
    fi
}

# ============================================================================
# CROSS-VALIDATION
# ============================================================================

validate_cross_references() {
    log_info "Checking cross-references..." "validate"

    if ! command -v jq &> /dev/null; then
        report_warning "cross-check" "jq not installed, skipping cross-reference validation"
        return 0
    fi

    # Check that all agent files exist (supports both "file" and "path" fields)
    local agent_files
    agent_files=$(jq -r '.agents[] | .file // .path' "$PLUGIN_JSON")

    for file_path in $agent_files; do
        if [ -n "$file_path" ] && [ ! -f "$PROJECT_ROOT/$file_path" ]; then
            report_error "cross-check" "Agent file not found: $file_path"
        fi
    done

    # Check that all command files exist
    local cmd_paths
    cmd_paths=$(jq -r '.commands[].path' "$PLUGIN_JSON")

    for path in $cmd_paths; do
        if [ -n "$path" ] && [ ! -f "$PROJECT_ROOT/$path" ]; then
            report_error "cross-check" "Command file not found: $path"
        fi
    done

    # Check for orphaned agent files
    local registered_agents
    registered_agents=$(jq -r '.agents[] | .file // .path' "$PLUGIN_JSON" | sort)

    local all_agents
    all_agents=$(find "$PROJECT_ROOT/agents" -name "*.md" -type f | \
                 sed "s|$PROJECT_ROOT/||" | \
                 grep -v "templates/" | \
                 sort)

    for agent_file in $all_agents; do
        if ! echo "$registered_agents" | grep -q "^$agent_file$"; then
            report_warning "cross-check" "Orphaned agent file (not in plugin.json): $agent_file"
        fi
    done
}

# ============================================================================
# MAIN
# ============================================================================

parse_args() {
    while [ $# -gt 0 ]; do
        case "$1" in
            --strict)
                STRICT_MODE=true
                shift
                ;;
            --verbose)
                VERBOSE=true
                shift
                ;;
            --fix)
                FIX_MODE=true
                shift
                ;;
            -h|--help)
                show_help
                exit 0
                ;;
            *)
                log_error "Unknown option: $1"
                exit 1
                ;;
        esac
    done
}

show_help() {
    echo "DevTeam Configuration Validator"
    echo ""
    echo "Usage: $0 [options]"
    echo ""
    echo "Options:"
    echo "  --strict    Fail on warnings"
    echo "  --verbose   Show detailed output"
    echo "  --fix       Attempt to fix minor issues (not implemented)"
    echo "  -h, --help  Show this help"
    echo ""
}

print_summary() {
    echo ""
    echo "================================"
    echo "      Validation Summary        "
    echo "================================"
    echo "Errors:   $ERRORS"
    echo "Warnings: $WARNINGS"
    echo "================================"

    if [ $ERRORS -gt 0 ]; then
        log_error "Validation failed with $ERRORS error(s)" "validate"
        return 1
    fi

    if [ "$STRICT_MODE" = true ] && [ $WARNINGS -gt 0 ]; then
        log_error "Validation failed with $WARNINGS warning(s) (strict mode)" "validate"
        return 1
    fi

    if [ $WARNINGS -gt 0 ]; then
        log_warn "Validation passed with $WARNINGS warning(s)" "validate"
    else
        log_info "Validation passed" "validate"
    fi

    return 0
}

main() {
    parse_args "$@"

    log_info "Starting configuration validation..." "validate"

    validate_plugin_json
    validate_config_yaml
    validate_cross_references

    print_summary
}

main "$@"
