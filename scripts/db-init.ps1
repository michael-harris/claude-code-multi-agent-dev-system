# DevTeam Database Initialization (PowerShell)
# Creates and initializes the SQLite database if it doesn't exist

$ErrorActionPreference = "Stop"

# Configuration
$DEVTEAM_DIR = if ($env:DEVTEAM_DIR) { $env:DEVTEAM_DIR } else { ".devteam" }
$DB_FILE = Join-Path $DEVTEAM_DIR "devteam.db"
$SCRIPT_DIR = Split-Path -Parent $MyInvocation.MyCommand.Path
$SCHEMA_FILE = Join-Path $SCRIPT_DIR "schema.sql"

function Write-DevTeamInfo {
    param([string]$Message)
    Write-Host "[devteam] $Message" -ForegroundColor Green
}

function Write-DevTeamWarn {
    param([string]$Message)
    Write-Host "[devteam] $Message" -ForegroundColor Yellow
}

function Write-DevTeamError {
    param([string]$Message)
    Write-Host "[devteam] $Message" -ForegroundColor Red
}

# Check for sqlite3
function Test-SQLite {
    try {
        $null = & sqlite3 --version 2>&1
        return $true
    } catch {
        Write-DevTeamError "sqlite3 is not installed. Please install it:"
        Write-DevTeamError "  Windows: Download from https://sqlite.org/download.html"
        Write-DevTeamError "  Or use: choco install sqlite"
        Write-DevTeamError "  Or use: winget install SQLite.SQLite"
        return $false
    }
}

# Create .devteam directory if needed
function Initialize-DevTeamDir {
    if (-not (Test-Path $DEVTEAM_DIR)) {
        New-Item -ItemType Directory -Path $DEVTEAM_DIR -Force | Out-Null
        Write-DevTeamInfo "Created $DEVTEAM_DIR directory"
    }
}

# Initialize database
function Initialize-Database {
    if (-not (Test-Path $DB_FILE)) {
        Write-DevTeamInfo "Initializing DevTeam database..."

        if (-not (Test-Path $SCHEMA_FILE)) {
            Write-DevTeamError "Schema file not found: $SCHEMA_FILE"
            exit 1
        }

        $schemaContent = Get-Content $SCHEMA_FILE -Raw
        & sqlite3 $DB_FILE $schemaContent

        Write-DevTeamInfo "Database created: $DB_FILE"
    } else {
        # Re-run schema to add any missing tables (IF NOT EXISTS handles this safely)
        Write-DevTeamInfo "Database exists, checking schema..."
        $schemaContent = Get-Content $SCHEMA_FILE -Raw
        try {
            & sqlite3 $DB_FILE $schemaContent 2>$null
        } catch {
            # Ignore errors from IF NOT EXISTS
        }
    }
}

# Verify database integrity
function Test-DatabaseIntegrity {
    $integrity = & sqlite3 $DB_FILE "PRAGMA integrity_check;"

    if ($integrity -ne "ok") {
        Write-DevTeamError "Database integrity check failed!"
        Write-DevTeamError "Consider backing up and reinitializing: Move-Item $DB_FILE ${DB_FILE}.bak"
        exit 1
    }
}

# Clean up old state files (migration from YAML)
function Remove-OldStateFiles {
    $oldFiles = @(
        (Join-Path $DEVTEAM_DIR "state.yaml"),
        (Join-Path $DEVTEAM_DIR "circuit-breaker.json"),
        (Join-Path $DEVTEAM_DIR "rate-limit-state.json"),
        (Join-Path $DEVTEAM_DIR "abandonment-attempts.log")
    )

    foreach ($file in $oldFiles) {
        if (Test-Path $file) {
            Write-DevTeamWarn "Found old state file: $file"
            Write-DevTeamWarn "Consider removing after verifying migration: Remove-Item $file"
        }
    }
}

# Main
function Main {
    if (-not (Test-SQLite)) {
        exit 1
    }

    Initialize-DevTeamDir
    Initialize-Database
    Test-DatabaseIntegrity
    Remove-OldStateFiles

    Write-DevTeamInfo "Database ready: $DB_FILE"
}

# Run if executed directly
if ($MyInvocation.InvocationName -ne '.') {
    Main
}
