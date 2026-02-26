# Hook-Common Library (PowerShell)
# Bridge between hook scripts and DevTeam infrastructure
# All PowerShell hook scripts source this file for a stable API layer.

# Resolve plugin root from this file's location (hooks/lib/ -> project root)
$script:HOOK_LIB_DIR = Split-Path -Parent $MyInvocation.MyCommand.Path
$script:PLUGIN_ROOT = Split-Path -Parent (Split-Path -Parent $script:HOOK_LIB_DIR)

# ============================================================================
# CONFIGURATION DEFAULTS
# ============================================================================

$script:DEVTEAM_DIR = if ($env:DEVTEAM_DIR) { $env:DEVTEAM_DIR } else { ".devteam" }
$script:DB_FILE = Join-Path $script:DEVTEAM_DIR "devteam.db"
$script:MAX_ITERATIONS = if ($env:DEVTEAM_MAX_ITERATIONS) { [int]$env:DEVTEAM_MAX_ITERATIONS } else { 100 }
$script:MAX_FAILURES = if ($env:DEVTEAM_MAX_FAILURES) { [int]$env:DEVTEAM_MAX_FAILURES } else { 5 }
$script:ECO_MODE = if ($env:DEVTEAM_ECO_MODE) { $env:DEVTEAM_ECO_MODE } else { "false" }
$script:AUTONOMOUS_MARKER = Join-Path $script:DEVTEAM_DIR "autonomous-mode"
$script:CIRCUIT_BREAKER_FILE = Join-Path $script:DEVTEAM_DIR "circuit-breaker.json"
$script:CURRENT_HOOK = "unknown"

# ============================================================================
# DATABASE AUTO-INITIALIZATION
# ============================================================================

function Initialize-DevTeamDatabase {
    $schemaDir = Join-Path $script:PLUGIN_ROOT "scripts"
    $schemaFile = Join-Path $schemaDir "schema.sql"
    $schemaVersion = 4

    # Need the base schema file at minimum
    if (-not (Test-Path $schemaFile)) {
        return
    }

    # Create database with base schema
    $schemaContent = Get-Content $schemaFile -Raw
    try {
        & sqlite3 $script:DB_FILE $schemaContent 2>$null
    } catch {
        return
    }

    # Create schema_version table
    try {
        & sqlite3 $script:DB_FILE "CREATE TABLE IF NOT EXISTS schema_version (version INTEGER PRIMARY KEY, applied_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP);" 2>$null
    } catch {}

    # Apply migrations v2, v3, v4
    foreach ($v in 2, 3, 4) {
        $migrationFile = Join-Path $schemaDir "schema-v${v}.sql"
        if (Test-Path $migrationFile) {
            $migrationContent = Get-Content $migrationFile -Raw
            try {
                & sqlite3 $script:DB_FILE $migrationContent 2>$null
            } catch {}
        }
    }

    # Record final schema version
    try {
        & sqlite3 $script:DB_FILE "INSERT OR REPLACE INTO schema_version (version) VALUES ($schemaVersion);" 2>$null
    } catch {}

    Write-Host "[hook-common] Auto-initialized database: $($script:DB_FILE) (schema v${schemaVersion})" -ForegroundColor Green
}

# ============================================================================
# HOOK INITIALIZATION
# ============================================================================

function Initialize-Hook {
    param([string]$HookName = "unknown")
    $script:CURRENT_HOOK = $HookName

    # Ensure runtime directories exist
    if (-not (Test-Path $script:DEVTEAM_DIR)) {
        New-Item -ItemType Directory -Path $script:DEVTEAM_DIR -Force -ErrorAction SilentlyContinue | Out-Null
    }

    # Auto-initialize database if it doesn't exist
    if (-not (Test-Path $script:DB_FILE)) {
        try {
            $null = & sqlite3 --version 2>&1
            Initialize-DevTeamDatabase
        } catch {
            # sqlite3 not available, skip auto-init
        }
    }
}

# ============================================================================
# LOGGING
# ============================================================================

function Write-HookDebug {
    param([string]$Context, [string]$Message)
    Write-Host "[debug] [$Context] $Message" -ForegroundColor DarkGray
}

function Write-HookInfo {
    param([string]$Context, [string]$Message)
    Write-Host "[info]  [$Context] $Message" -ForegroundColor Green
}

function Write-HookWarn {
    param([string]$Context, [string]$Message)
    Write-Host "[warn]  [$Context] $Message" -ForegroundColor Yellow
}

function Write-HookError {
    param([string]$Context, [string]$Message)
    Write-Host "[error] [$Context] $Message" -ForegroundColor Red
}

# ============================================================================
# DATABASE HELPERS
# ============================================================================

function Test-DatabaseExists {
    (Test-Path $script:DB_FILE) -and (Get-Command sqlite3 -ErrorAction SilentlyContinue)
}

function Invoke-DbQuery {
    param([string]$Sql)
    if (Test-DatabaseExists) {
        try {
            $result = & sqlite3 $script:DB_FILE $Sql 2>$null
            return $result
        } catch {
            return ""
        }
    }
    return ""
}

# ============================================================================
# SESSION & STATE ACCESSORS
# ============================================================================

function Get-CurrentSession {
    if (Test-DatabaseExists) {
        $result = Invoke-DbQuery "SELECT id FROM sessions WHERE status = 'running' ORDER BY started_at DESC LIMIT 1;"
        return $result
    }
    return ""
}

function Get-CurrentTask {
    $sessionId = Get-CurrentSession
    if (-not $sessionId) { return "" }
    $safeId = $sessionId -replace "'", "''"
    return Invoke-DbQuery "SELECT current_task_id FROM sessions WHERE id = '$safeId';"
}

function Get-CurrentIteration {
    $sessionId = Get-CurrentSession
    if (-not $sessionId) { return 0 }
    $safeId = $sessionId -replace "'", "''"
    $val = Invoke-DbQuery "SELECT current_iteration FROM sessions WHERE id = '$safeId';"
    if ($val -match '^\d+$') { return [int]$val }
    return 0
}

function Get-ConsecutiveFailures {
    $sessionId = Get-CurrentSession
    if (-not $sessionId) { return 0 }
    $safeId = $sessionId -replace "'", "''"
    $val = Invoke-DbQuery "SELECT consecutive_failures FROM sessions WHERE id = '$safeId';"
    if ($val -match '^\d+$') { return [int]$val }
    return 0
}

function Get-CurrentModel {
    $sessionId = Get-CurrentSession
    if (-not $sessionId) { return "sonnet" }
    $safeId = $sessionId -replace "'", "''"
    $val = Invoke-DbQuery "SELECT current_model FROM sessions WHERE id = '$safeId';"
    if ($val) { return $val }
    return "sonnet"
}

function Add-Failure {
    $sessionId = Get-CurrentSession
    if ($sessionId -and (Test-DatabaseExists)) {
        $safeId = $sessionId -replace "'", "''"
        Invoke-DbQuery "UPDATE sessions SET consecutive_failures = consecutive_failures + 1 WHERE id = '$safeId';"
    }
}

function Reset-Failures {
    $sessionId = Get-CurrentSession
    if ($sessionId -and (Test-DatabaseExists)) {
        $safeId = $sessionId -replace "'", "''"
        Invoke-DbQuery "UPDATE sessions SET consecutive_failures = 0 WHERE id = '$safeId';"
    }
}

# ============================================================================
# CONTEXT INJECTION
# ============================================================================

function Send-SystemMessage {
    param([string]$Id, [string]$Message)
    $escapedMsg = $Message -replace '\\', '\\\\' -replace '"', '\"' -replace "`t", '\t' -replace "`n", '\n'
    Write-Output "{`"id`":`"devteam-${Id}`",`"type`":`"system`",`"message`":`"${escapedMsg}`"}"
}

# ============================================================================
# SCOPE CHECKING
# ============================================================================

function Test-FileInScope {
    param([string]$FilePath)
    $scopeFile = Join-Path $script:DEVTEAM_DIR "task-scope.txt"
    if (-not (Test-Path $scopeFile)) { return $true }

    $patterns = Get-Content $scopeFile | Where-Object { $_ -and -not $_.StartsWith('#') }
    foreach ($pattern in $patterns) {
        if ($FilePath -like $pattern) { return $true }
    }
    return $false
}

function Get-ScopeFiles {
    $scopeFile = Join-Path $script:DEVTEAM_DIR "task-scope.txt"
    if (Test-Path $scopeFile) {
        return Get-Content $scopeFile | Where-Object { $_ -and -not $_.StartsWith('#') }
    }
    return "(no scope defined - all files allowed)"
}

# ============================================================================
# EVENT LOGGING
# ============================================================================

function Write-EventToDb {
    param(
        [string]$EventType,
        [string]$Category,
        [string]$Message,
        [string]$Data = "{}"
    )
    if (Test-DatabaseExists) {
        $sessionId = Get-CurrentSession
        $safeSession = ($sessionId ?? "") -replace "'", "''"
        $safeMsg = $Message -replace "'", "''"
        $safeData = $Data -replace "'", "''"
        $safeType = $EventType -replace "'", "''"
        $safeCat = $Category -replace "'", "''"
        Invoke-DbQuery "INSERT INTO events (session_id, event_type, category, message, data, timestamp) VALUES ('$safeSession', '$safeType', '$safeCat', '$safeMsg', '$safeData', datetime('now'));"
    }
}

# ============================================================================
# AUTONOMOUS MODE & CIRCUIT BREAKER
# ============================================================================

function Test-AutonomousMode {
    Test-Path $script:AUTONOMOUS_MARKER
}

function Test-CircuitBreakerOpen {
    $failures = Get-ConsecutiveFailures
    return ($failures -ge $script:MAX_FAILURES)
}

function Test-MaxIterationsReached {
    $iteration = Get-CurrentIteration
    return ($iteration -ge $script:MAX_ITERATIONS)
}

# ============================================================================
# CHECKPOINTS
# ============================================================================

function Save-Checkpoint {
    param([string]$Message = "Auto-checkpoint")
    $sessionId = Get-CurrentSession
    if (-not $sessionId) { return }
    $safeSession = $sessionId -replace "'", "''"
    $safeMsg = $Message -replace "'", "''"
    if (Test-DatabaseExists) {
        Invoke-DbQuery "INSERT OR IGNORE INTO checkpoints (session_id, message, created_at) VALUES ('$safeSession', '$safeMsg', datetime('now'));"
    }
}

# ============================================================================
# CLAUDE CONTEXT
# ============================================================================

function Get-ClaudeContext {
    $sessionId = Get-CurrentSession
    $taskId = Get-CurrentTask
    $iteration = Get-CurrentIteration
    $failures = Get-ConsecutiveFailures
    $model = Get-CurrentModel
    $safeSession = ($sessionId ?? "") -replace '"', '\"'
    $safeTask = ($taskId ?? "") -replace '"', '\"'
    return "{`"session`":`"$safeSession`",`"task`":`"$safeTask`",`"iteration`":$iteration,`"failures`":$failures,`"model`":`"$model`",`"hook`":`"$($script:CURRENT_HOOK)`"}"
}

# ============================================================================
# ESCALATION
# ============================================================================

function Invoke-Escalation {
    param([string]$Reason)
    Write-HookWarn $script:CURRENT_HOOK "Escalation triggered: $Reason"
    $safeReason = $Reason -replace '"', '\"'
    Write-EventToDb "model_escalated" "escalation" "Escalation: $Reason" "{`"reason`":`"$safeReason`"}"
}
