# DevTeam Session Start Hook (PowerShell)
# Loads previous session context and auto-detects project configuration

$ErrorActionPreference = "Stop"

# Configuration
$MEMORY_DIR = ".devteam\memory"
$STATE_FILE = ".devteam\state.yaml"
$CONFIG_FILE = ".devteam\config.yaml"

# Logging function
function Write-Log {
    param([string]$Message)
    Write-Host "[DevTeam Session Start] $Message"
}

# Output to stdout (will be injected into Claude's context)
function Write-Output-Text {
    param([string]$Text)
    Write-Output $Text
}

# ============================================
# LOAD PREVIOUS SESSION MEMORY
# ============================================
function Load-SessionMemory {
    if (Test-Path $MEMORY_DIR) {
        $Latest = Get-ChildItem -Path $MEMORY_DIR -Filter "session-*.md" -ErrorAction SilentlyContinue |
                  Sort-Object LastWriteTime -Descending |
                  Select-Object -First 1

        if ($Latest) {
            Write-Log "Loading previous session context from $($Latest.FullName)"
            Write-Output-Text ""
            Write-Output-Text "## Previous Session Context"
            Write-Output-Text ""
            Get-Content $Latest.FullName
            Write-Output-Text ""
            Write-Output-Text "---"
            Write-Output-Text ""
        }
    }
}

# ============================================
# LOAD CURRENT STATE
# ============================================
function Load-StateSummary {
    if (Test-Path $STATE_FILE) {
        Write-Log "Loading project state"

        # Simple YAML parsing (grep-based extraction)
        $Content = Get-Content $STATE_FILE -Raw

        $CurrentSprint = "unknown"
        $CurrentTask = "unknown"
        $Phase = "unknown"

        if ($Content -match "current_sprint:\s*(.+)") {
            $CurrentSprint = $Matches[1].Trim()
        }
        if ($Content -match "current_task:\s*(.+)") {
            $CurrentTask = $Matches[1].Trim()
        }
        if ($Content -match "phase:\s*(.+)") {
            $Phase = $Matches[1].Trim()
        }

        Write-Output-Text "## Current Project State"
        Write-Output-Text ""
        Write-Output-Text "- **Current Sprint:** $CurrentSprint"
        Write-Output-Text "- **Current Task:** $CurrentTask"
        Write-Output-Text "- **Phase:** $Phase"
        Write-Output-Text ""

        # Check for autonomous mode
        if (Test-Path ".devteam\autonomous-mode") {
            Write-Output-Text "- **Mode:** Autonomous (running until complete)"
            Write-Output-Text ""
        }
    }
}

# ============================================
# AUTO-DETECT PROJECT LANGUAGES
# ============================================
function Detect-Languages {
    Write-Log "Detecting project languages..."

    $Detected = @()

    # Python
    if ((Test-Path "pyproject.toml") -or (Test-Path "requirements.txt") -or (Test-Path "setup.py")) {
        $Detected += "python"
    }

    # TypeScript/JavaScript
    if ((Test-Path "package.json") -or (Test-Path "tsconfig.json")) {
        $Detected += "typescript"
    }

    # Go
    if (Test-Path "go.mod") {
        $Detected += "go"
    }

    # Rust
    if (Test-Path "Cargo.toml") {
        $Detected += "rust"
    }

    # Java
    if ((Test-Path "pom.xml") -or (Test-Path "build.gradle")) {
        $Detected += "java"
    }

    # C#
    if ((Get-ChildItem -Filter "*.csproj" -ErrorAction SilentlyContinue) -or
        (Get-ChildItem -Filter "*.sln" -ErrorAction SilentlyContinue)) {
        $Detected += "csharp"
    }

    # Ruby
    if (Test-Path "Gemfile") {
        $Detected += "ruby"
    }

    # PHP
    if (Test-Path "composer.json") {
        $Detected += "php"
    }

    if ($Detected.Count -gt 0) {
        Write-Output-Text "## Detected Languages"
        Write-Output-Text ""
        foreach ($lang in $Detected) {
            Write-Output-Text "- $lang"
        }
        Write-Output-Text ""
        Write-Output-Text "Consider enabling LSP servers for these languages for better code intelligence."
        Write-Output-Text "See ``mcp-configs/lsp-servers.json`` for configuration."
        Write-Output-Text ""
    }
}

# ============================================
# DETECT PACKAGE MANAGERS
# ============================================
function Detect-PackageManagers {
    Write-Log "Detecting package managers..."

    # Python
    if (Test-Path "uv.lock") {
        Write-Output-Text "- **Python:** uv (recommended)"
    } elseif (Test-Path "poetry.lock") {
        Write-Output-Text "- **Python:** poetry"
    } elseif (Test-Path "Pipfile.lock") {
        Write-Output-Text "- **Python:** pipenv"
    } elseif (Test-Path "requirements.txt") {
        Write-Output-Text "- **Python:** pip"
    }

    # Node.js
    if (Test-Path "pnpm-lock.yaml") {
        Write-Output-Text "- **Node.js:** pnpm"
    } elseif (Test-Path "yarn.lock") {
        Write-Output-Text "- **Node.js:** yarn"
    } elseif (Test-Path "bun.lockb") {
        Write-Output-Text "- **Node.js:** bun"
    } elseif (Test-Path "package-lock.json") {
        Write-Output-Text "- **Node.js:** npm"
    }
}

# ============================================
# MAIN EXECUTION
# ============================================
function Main {
    Write-Output-Text "# DevTeam Session Initialized"
    Write-Output-Text ""

    # Load previous context if available
    Load-SessionMemory

    # Load current state
    Load-StateSummary

    # Detect project configuration
    Detect-Languages

    Write-Output-Text "## Package Managers"
    Write-Output-Text ""
    Detect-PackageManagers
    Write-Output-Text ""

    Write-Log "Session initialization complete"
}

# Run main function
Main
