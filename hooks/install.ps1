# DevTeam Hooks Installer (PowerShell)
# Installs hooks into Claude Code configuration and git
#
# Usage: .\install.ps1 [-Auto]

param(
    [switch]$Auto
)

$ErrorActionPreference = "Stop"

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectRoot = Split-Path -Parent $ScriptDir

Write-Host ""
Write-Host "================================================================" -ForegroundColor Blue
Write-Host "             DevTeam Hooks Installer" -ForegroundColor Blue
Write-Host "================================================================" -ForegroundColor Blue
Write-Host ""

# ============================================================================
# DETECT CLAUDE CODE CONFIG
# ============================================================================

function Get-ClaudeConfigPath {
    $locations = @(
        "$env:USERPROFILE\.claude\settings.json",
        "$env:APPDATA\Claude\settings.json",
        "$env:LOCALAPPDATA\Claude\settings.json"
    )

    foreach ($loc in $locations) {
        $dir = Split-Path $loc -Parent
        if (Test-Path $dir) {
            return $loc
        }
    }

    return $null
}

$ClaudeConfigFile = Get-ClaudeConfigPath

if (-not $ClaudeConfigFile) {
    Write-Host "! Could not auto-detect Claude Code configuration directory." -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  Please manually add hooks to your Claude Code settings."
    Write-Host "  See hooks\README.md for configuration details."
    Write-Host ""
} else {
    Write-Host "ok Found Claude Code config: $ClaudeConfigFile" -ForegroundColor Green
}
Write-Host ""

# ============================================================================
# INSTALL GIT HOOKS
# ============================================================================

$gitDir = Join-Path $ProjectRoot ".git"
if (Test-Path $gitDir) {
    Write-Host "Installing git hooks..."

    $gitHooksDir = Join-Path $gitDir "hooks"
    if (-not (Test-Path $gitHooksDir)) {
        New-Item -ItemType Directory -Path $gitHooksDir -Force | Out-Null
    }

    # Pre-commit hook
    $preCommitPath = Join-Path $gitHooksDir "pre-commit"
    @"
#!/bin/bash
exec "$ScriptDir/scope-check.sh"
"@ | Set-Content $preCommitPath -Encoding UTF8

    Write-Host "ok Git pre-commit hook installed" -ForegroundColor Green
} else {
    Write-Host "! Not a git repository - skipping git hooks" -ForegroundColor Yellow
}
Write-Host ""

# ============================================================================
# GENERATE CLAUDE CODE CONFIG
# ============================================================================

Write-Host "Generating Claude Code hook configuration..."
Write-Host ""

$HooksConfig = @"
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": ".*",
        "hooks": ["powershell -ExecutionPolicy Bypass -File $ScriptDir\pre-tool-use-hook.ps1"]
      }
    ],
    "PostToolUse": [
      {
        "matcher": ".*",
        "hooks": ["powershell -ExecutionPolicy Bypass -File $ScriptDir\post-tool-use-hook.ps1"]
      }
    ],
    "Stop": [
      {
        "matcher": ".*",
        "hooks": ["powershell -ExecutionPolicy Bypass -File $ScriptDir\stop-hook.ps1"]
      }
    ],
    "PostMessage": [
      {
        "matcher": ".*",
        "hooks": ["powershell -ExecutionPolicy Bypass -File $ScriptDir\persistence-hook.ps1"]
      }
    ],
    "SessionStart": [
      {
        "matcher": ".*",
        "hooks": ["powershell -ExecutionPolicy Bypass -File $ScriptDir\session-start.ps1"]
      }
    ],
    "SessionEnd": [
      {
        "matcher": ".*",
        "hooks": ["powershell -ExecutionPolicy Bypass -File $ScriptDir\session-end.ps1"]
      }
    ],
    "PreCompact": [
      {
        "matcher": ".*",
        "hooks": ["powershell -ExecutionPolicy Bypass -File $ScriptDir\pre-compact.ps1"]
      }
    ]
  }
}
"@

Write-Host "Add the following to your Claude Code settings:"
Write-Host ""
Write-Host "----------------------------------------------------------------" -ForegroundColor Blue
Write-Host $HooksConfig
Write-Host "----------------------------------------------------------------" -ForegroundColor Blue
Write-Host ""

# ============================================================================
# AUTO-INSTALL TO SETTINGS
# ============================================================================

function Install-ToSettings {
    param([string]$ConfigFile)

    if (-not (Test-Path $ConfigFile)) {
        # Create new config
        $configDir = Split-Path $ConfigFile -Parent
        if (-not (Test-Path $configDir)) {
            New-Item -ItemType Directory -Path $configDir -Force | Out-Null
        }
        $HooksConfig | Set-Content $ConfigFile -Encoding UTF8
        Write-Host "ok Config file created: $ConfigFile" -ForegroundColor Green
        return $true
    }

    # Backup existing config
    Copy-Item $ConfigFile "$ConfigFile.backup" -Force
    Write-Host "ok Backed up existing config to $ConfigFile.backup" -ForegroundColor Green

    # Try to merge configs
    try {
        $existing = Get-Content $ConfigFile -Raw | ConvertFrom-Json
        $new = $HooksConfig | ConvertFrom-Json

        # Merge hooks
        if (-not $existing.hooks) {
            $existing | Add-Member -NotePropertyName "hooks" -NotePropertyValue @{}
        }

        foreach ($prop in $new.hooks.PSObject.Properties) {
            $existing.hooks | Add-Member -NotePropertyName $prop.Name -NotePropertyValue $prop.Value -Force
        }

        $existing | ConvertTo-Json -Depth 10 | Set-Content $ConfigFile -Encoding UTF8
        Write-Host "ok Hooks merged into config" -ForegroundColor Green
        return $true
    } catch {
        Write-Host "! Could not merge configs: $_" -ForegroundColor Yellow
        Write-Host "  Please manually merge the configuration." -ForegroundColor Yellow
        return $false
    }
}

if ($ClaudeConfigFile) {
    if ($Auto) {
        Install-ToSettings $ClaudeConfigFile | Out-Null
    } else {
        $response = Read-Host "Would you like to automatically add these hooks to your config? [y/N]"
        if ($response -match "^[Yy]$") {
            Install-ToSettings $ClaudeConfigFile | Out-Null
        } else {
            Write-Host "Skipped automatic installation."
            Write-Host "Please manually add the configuration above to: $ClaudeConfigFile"
        }
    }
}

Write-Host ""

# ============================================================================
# CREATE .devteam DIRECTORY
# ============================================================================

Write-Host "Creating .devteam directory..."

$DevteamDir = Join-Path $ProjectRoot ".devteam"
if (-not (Test-Path $DevteamDir)) {
    New-Item -ItemType Directory -Path $DevteamDir -Force | Out-Null
}

# Initialize database if script exists
$dbInitScript = Join-Path $ProjectRoot "scripts" "db-init.ps1"
if (Test-Path $dbInitScript) {
    Write-Host "Initializing database..."
    try {
        & $dbInitScript 2>$null
        Write-Host "ok Database initialized" -ForegroundColor Green
    } catch {
        # Ignore errors
    }
}

# Create hooks-installed marker so db-init.ps1 can detect it
New-Item -ItemType File -Path (Join-Path $DevteamDir ".hooks-installed") -Force | Out-Null

Write-Host "ok .devteam directory ready" -ForegroundColor Green
Write-Host ""

# ============================================================================
# VERIFICATION
# ============================================================================

Write-Host "Verifying installation..."
Write-Host ""

function Test-HookFile {
    param(
        [string]$Path,
        [string]$Name
    )

    if (Test-Path $Path) {
        Write-Host "  ok $Name" -ForegroundColor Green
        return $true
    } else {
        Write-Host "  X $Name (missing)" -ForegroundColor Red
        return $false
    }
}

$errors = 0

if (-not (Test-HookFile (Join-Path $ScriptDir "lib\hook-common.ps1") "hook-common.ps1 (shared library)")) { $errors++ }
if (-not (Test-HookFile (Join-Path $ScriptDir "pre-tool-use-hook.ps1") "pre-tool-use-hook.ps1")) { $errors++ }
if (-not (Test-HookFile (Join-Path $ScriptDir "post-tool-use-hook.ps1") "post-tool-use-hook.ps1")) { $errors++ }
if (-not (Test-HookFile (Join-Path $ScriptDir "stop-hook.ps1") "stop-hook.ps1")) { $errors++ }
if (-not (Test-HookFile (Join-Path $ScriptDir "persistence-hook.ps1") "persistence-hook.ps1")) { $errors++ }
if (-not (Test-HookFile (Join-Path $ScriptDir "scope-check.ps1") "scope-check.ps1")) { $errors++ }
if (-not (Test-HookFile (Join-Path $ScriptDir "session-start.ps1") "session-start.ps1")) { $errors++ }
if (-not (Test-HookFile (Join-Path $ScriptDir "session-end.ps1") "session-end.ps1")) { $errors++ }
if (-not (Test-HookFile (Join-Path $ScriptDir "pre-compact.ps1") "pre-compact.ps1")) { $errors++ }

Write-Host ""

# ============================================================================
# SUMMARY
# ============================================================================

Write-Host "================================================================" -ForegroundColor Blue
if ($errors -eq 0) {
    Write-Host "             Installation Complete" -ForegroundColor Green
} else {
    Write-Host "             Installation Complete (with warnings)" -ForegroundColor Yellow
}
Write-Host "================================================================" -ForegroundColor Blue
Write-Host ""
Write-Host "Hooks installed:"
Write-Host "  ok pre-tool-use-hook   - Scope validation, dangerous command blocking" -ForegroundColor Green
Write-Host "  ok post-tool-use-hook  - Failure tracking, escalation detection" -ForegroundColor Green
Write-Host "  ok stop-hook           - Exit control, checkpoint save" -ForegroundColor Green
Write-Host "  ok persistence-hook    - Abandonment prevention" -ForegroundColor Green
Write-Host "  ok scope-check         - Git pre-commit scope validation" -ForegroundColor Green
Write-Host "  ok session-start       - Session initialization, context loading" -ForegroundColor Green
Write-Host "  ok session-end         - Session cleanup, memory persistence" -ForegroundColor Green
Write-Host "  ok pre-compact         - State preservation before compaction" -ForegroundColor Green
Write-Host ""
Write-Host "Next steps:"
Write-Host "  1. Restart Claude Code for hooks to take effect"
Write-Host "  2. See '.\hooks\README.md' for configuration options"
Write-Host ""

if ($errors -gt 0) {
    Write-Host "Warning: $errors hook(s) may not be properly installed." -ForegroundColor Yellow
    Write-Host ""
}
