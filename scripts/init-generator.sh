#!/bin/bash
# init-generator.sh - Generates project init.sh with environment setup
# Based on Anthropic's "Effective Harnesses for Long-Running Agents"

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="${PROJECT_ROOT:-$(pwd)}"
INIT_FILE="${PROJECT_ROOT}/init.sh"
DEVTEAM_DIR="${PROJECT_ROOT}/.devteam"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() { echo -e "${GREEN}[init-gen]${NC} $1"; }
log_success() { echo -e "${GREEN}[init-gen]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[init-gen]${NC} $1"; }
log_error() { echo -e "${RED}[init-gen]${NC} $1"; }

# Detect project type and package manager
detect_project_type() {
    local project_type="unknown"
    local package_manager=""

    if [[ -f "${PROJECT_ROOT}/package.json" ]]; then
        project_type="node"
        if [[ -f "${PROJECT_ROOT}/yarn.lock" ]]; then
            package_manager="yarn"
        elif [[ -f "${PROJECT_ROOT}/pnpm-lock.yaml" ]]; then
            package_manager="pnpm"
        elif [[ -f "${PROJECT_ROOT}/bun.lockb" ]]; then
            package_manager="bun"
        else
            package_manager="npm"
        fi
    elif [[ -f "${PROJECT_ROOT}/requirements.txt" ]] || [[ -f "${PROJECT_ROOT}/pyproject.toml" ]]; then
        project_type="python"
        if [[ -f "${PROJECT_ROOT}/poetry.lock" ]]; then
            package_manager="poetry"
        elif [[ -f "${PROJECT_ROOT}/Pipfile" ]]; then
            package_manager="pipenv"
        elif [[ -f "${PROJECT_ROOT}/uv.lock" ]]; then
            package_manager="uv"
        else
            package_manager="pip"
        fi
    elif [[ -f "${PROJECT_ROOT}/go.mod" ]]; then
        project_type="go"
        package_manager="go"
    elif [[ -f "${PROJECT_ROOT}/Cargo.toml" ]]; then
        project_type="rust"
        package_manager="cargo"
    elif [[ -f "${PROJECT_ROOT}/Gemfile" ]]; then
        project_type="ruby"
        package_manager="bundler"
    elif [[ -f "${PROJECT_ROOT}/composer.json" ]]; then
        project_type="php"
        package_manager="composer"
    fi

    echo "${project_type}:${package_manager}"
}

# Detect required environment variables
detect_env_vars() {
    local env_vars=()

    # Check for .env.example or .env.template
    if [[ -f "${PROJECT_ROOT}/.env.example" ]]; then
        while IFS= read -r line; do
            if [[ "$line" =~ ^[A-Z_][A-Z0-9_]*= ]]; then
                var_name="${line%%=*}"
                env_vars+=("$var_name")
            fi
        done < "${PROJECT_ROOT}/.env.example"
    fi

    # Check for common env vars in code
    local common_vars=("DATABASE_URL" "API_KEY" "SECRET_KEY" "NODE_ENV" "REDIS_URL" "PORT")
    for var in "${common_vars[@]}"; do
        if grep -rq "$var" "${PROJECT_ROOT}/src" 2>/dev/null || \
           grep -rq "$var" "${PROJECT_ROOT}/app" 2>/dev/null; then
            if [[ ! " ${env_vars[*]} " =~ " ${var} " ]]; then
                env_vars+=("$var")
            fi
        fi
    done

    printf '%s\n' "${env_vars[@]}"
}

# Generate install commands based on project type
generate_install_commands() {
    local project_type="$1"
    local package_manager="$2"

    case "$project_type:$package_manager" in
        node:npm)
            echo "npm ci || npm install"
            ;;
        node:yarn)
            echo "yarn install --frozen-lockfile || yarn install"
            ;;
        node:pnpm)
            echo "pnpm install --frozen-lockfile || pnpm install"
            ;;
        node:bun)
            echo "bun install"
            ;;
        python:pip)
            echo "python -m venv .venv 2>/dev/null || true"
            echo "source .venv/bin/activate 2>/dev/null || true"
            echo "pip install -r requirements.txt"
            ;;
        python:poetry)
            echo "poetry install"
            ;;
        python:pipenv)
            echo "pipenv install"
            ;;
        python:uv)
            echo "uv sync"
            ;;
        go:go)
            echo "go mod download"
            echo "go mod verify"
            ;;
        rust:cargo)
            echo "cargo fetch"
            ;;
        ruby:bundler)
            echo "bundle install"
            ;;
        php:composer)
            echo "composer install"
            ;;
        *)
            echo "# Unknown project type - add install commands manually"
            ;;
    esac
}

# Generate build commands
generate_build_commands() {
    local project_type="$1"
    local package_manager="$2"

    case "$project_type" in
        node)
            if [[ -f "${PROJECT_ROOT}/package.json" ]]; then
                if grep -q '"build"' "${PROJECT_ROOT}/package.json"; then
                    echo "${package_manager} run build"
                fi
                if grep -q '"typecheck"' "${PROJECT_ROOT}/package.json"; then
                    echo "${package_manager} run typecheck"
                fi
            fi
            ;;
        python)
            if [[ -f "${PROJECT_ROOT}/pyproject.toml" ]]; then
                if grep -q "build-backend" "${PROJECT_ROOT}/pyproject.toml"; then
                    echo "python -m build"
                fi
            fi
            ;;
        go)
            echo "go build ./..."
            ;;
        rust)
            echo "cargo build"
            ;;
        *)
            echo "# Add build commands if needed"
            ;;
    esac
}

# Generate test commands
generate_test_commands() {
    local project_type="$1"
    local package_manager="$2"

    case "$project_type" in
        node)
            if [[ -f "${PROJECT_ROOT}/package.json" ]]; then
                if grep -q '"test"' "${PROJECT_ROOT}/package.json"; then
                    echo "${package_manager} run test"
                fi
            fi
            ;;
        python)
            if [[ -f "${PROJECT_ROOT}/pytest.ini" ]] || [[ -f "${PROJECT_ROOT}/pyproject.toml" ]]; then
                echo "pytest"
            elif [[ -d "${PROJECT_ROOT}/tests" ]]; then
                echo "python -m pytest tests/"
            fi
            ;;
        go)
            echo "go test ./..."
            ;;
        rust)
            echo "cargo test"
            ;;
        *)
            echo "# Add test commands if needed"
            ;;
    esac
}

# Generate the init.sh file
generate_init_sh() {
    local detection
    detection=$(detect_project_type)
    local project_type="${detection%%:*}"
    local package_manager="${detection##*:}"

    log_info "Detected project type: ${project_type}"
    log_info "Package manager: ${package_manager}"

    mkdir -p "$DEVTEAM_DIR"

    cat > "$INIT_FILE" << 'HEADER'
#!/bin/bash
# init.sh - Project initialization and environment setup
# Auto-generated by DevTeam init-generator
#
# This script ensures the development environment is properly configured
# Run this at the start of each session or after pulling changes

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_step() { echo -e "${BLUE}==>${NC} $1"; }
log_success() { echo -e "${GREEN}✓${NC} $1"; }
log_warn() { echo -e "${YELLOW}⚠${NC} $1"; }
log_error() { echo -e "${RED}✗${NC} $1"; }

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo " Project Initialization"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

HEADER

    # Add environment variable checks
    echo "" >> "$INIT_FILE"
    echo "# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" >> "$INIT_FILE"
    echo "# Environment Variables" >> "$INIT_FILE"
    echo "# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" >> "$INIT_FILE"
    echo "log_step \"Checking environment variables...\"" >> "$INIT_FILE"
    echo "" >> "$INIT_FILE"

    # Load .env if exists
    echo "if [[ -f .env ]]; then" >> "$INIT_FILE"
    echo "    set -a" >> "$INIT_FILE"
    echo "    source .env" >> "$INIT_FILE"
    echo "    set +a" >> "$INIT_FILE"
    echo "    log_success \"Loaded .env file\"" >> "$INIT_FILE"
    echo "fi" >> "$INIT_FILE"
    echo "" >> "$INIT_FILE"

    local env_vars
    env_vars=$(detect_env_vars)
    if [[ -n "$env_vars" ]]; then
        echo "MISSING_VARS=()" >> "$INIT_FILE"
        while IFS= read -r var; do
            if [[ -n "$var" ]]; then
                echo "if [[ -z \"\${${var}:-}\" ]]; then MISSING_VARS+=(\"${var}\"); fi" >> "$INIT_FILE"
            fi
        done <<< "$env_vars"
        echo "" >> "$INIT_FILE"
        echo "if [[ \${#MISSING_VARS[@]} -gt 0 ]]; then" >> "$INIT_FILE"
        echo "    log_warn \"Missing environment variables:\"" >> "$INIT_FILE"
        echo "    for var in \"\${MISSING_VARS[@]}\"; do" >> "$INIT_FILE"
        echo "        echo \"  - \$var\"" >> "$INIT_FILE"
        echo "    done" >> "$INIT_FILE"
        echo "    echo \"  Copy .env.example to .env and fill in values\"" >> "$INIT_FILE"
        echo "else" >> "$INIT_FILE"
        echo "    log_success \"All required environment variables set\"" >> "$INIT_FILE"
        echo "fi" >> "$INIT_FILE"
    else
        echo "log_success \"No required environment variables detected\"" >> "$INIT_FILE"
    fi

    # Add dependency installation
    echo "" >> "$INIT_FILE"
    echo "# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" >> "$INIT_FILE"
    echo "# Dependencies" >> "$INIT_FILE"
    echo "# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" >> "$INIT_FILE"
    echo "log_step \"Installing dependencies...\"" >> "$INIT_FILE"
    echo "" >> "$INIT_FILE"

    local install_cmds
    install_cmds=$(generate_install_commands "$project_type" "$package_manager")
    while IFS= read -r cmd; do
        if [[ -n "$cmd" ]]; then
            echo "$cmd" >> "$INIT_FILE"
        fi
    done <<< "$install_cmds"
    echo "log_success \"Dependencies installed\"" >> "$INIT_FILE"

    # Add build commands
    local build_cmds
    build_cmds=$(generate_build_commands "$project_type" "$package_manager")
    if [[ -n "$build_cmds" ]]; then
        echo "" >> "$INIT_FILE"
        echo "# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" >> "$INIT_FILE"
        echo "# Build" >> "$INIT_FILE"
        echo "# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" >> "$INIT_FILE"
        echo "log_step \"Building project...\"" >> "$INIT_FILE"
        echo "" >> "$INIT_FILE"
        while IFS= read -r cmd; do
            if [[ -n "$cmd" ]]; then
                echo "$cmd" >> "$INIT_FILE"
            fi
        done <<< "$build_cmds"
        echo "log_success \"Build complete\"" >> "$INIT_FILE"
    fi

    # Add test commands (optional verification)
    local test_cmds
    test_cmds=$(generate_test_commands "$project_type" "$package_manager")
    if [[ -n "$test_cmds" ]]; then
        echo "" >> "$INIT_FILE"
        echo "# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" >> "$INIT_FILE"
        echo "# Verify Setup (Optional)" >> "$INIT_FILE"
        echo "# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" >> "$INIT_FILE"
        echo "if [[ \"\${1:-}\" == \"--verify\" ]]; then" >> "$INIT_FILE"
        echo "    log_step \"Running tests to verify setup...\"" >> "$INIT_FILE"
        while IFS= read -r cmd; do
            if [[ -n "$cmd" ]]; then
                echo "    $cmd" >> "$INIT_FILE"
            fi
        done <<< "$test_cmds"
        echo "    log_success \"All tests passed\"" >> "$INIT_FILE"
        echo "fi" >> "$INIT_FILE"
    fi

    # Add footer
    cat >> "$INIT_FILE" << 'FOOTER'

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Complete
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
log_success "Initialization complete!"
echo ""
echo "Ready for development. Run with --verify to also run tests."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
FOOTER

    chmod +x "$INIT_FILE"
    log_success "Generated init.sh"

    # Also save metadata
    cat > "${DEVTEAM_DIR}/init-metadata.json" << EOF
{
    "generated_at": "$(date -Iseconds)",
    "project_type": "${project_type}",
    "package_manager": "${package_manager}",
    "init_file": "${INIT_FILE}"
}
EOF

    log_success "Saved init metadata to ${DEVTEAM_DIR}/init-metadata.json"
}

# Main
case "${1:-generate}" in
    generate)
        generate_init_sh
        ;;
    detect)
        detect_project_type
        ;;
    *)
        echo "Usage: $0 [generate|detect]"
        exit 1
        ;;
esac
