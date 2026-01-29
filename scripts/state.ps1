# DevTeam State Management Functions (PowerShell)
# Dot-source this file to use state functions in hooks and commands

# Configuration
$script:DEVTEAM_DIR = if ($env:DEVTEAM_DIR) { $env:DEVTEAM_DIR } else { ".devteam" }
$script:DB_FILE = Join-Path $script:DEVTEAM_DIR "devteam.db"

# Ensure database exists
function _Ensure-Database {
    if (-not (Test-Path $script:DB_FILE)) {
        $scriptDir = Split-Path -Parent $MyInvocation.ScriptName
        & "$scriptDir\db-init.ps1"
    }
}

# Execute SQLite query
function Invoke-SQLite {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Query,
        [switch]$Json
    )

    _Ensure-Database

    $args = @($script:DB_FILE, $Query)
    if ($Json) {
        $args = @("-json", $script:DB_FILE, $Query)
    }

    & sqlite3 @args
}

# ============================================================================
# SESSION MANAGEMENT
# ============================================================================

function New-SessionId {
    $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
    $random = -join ((48..57) + (97..102) | Get-Random -Count 8 | ForEach-Object {[char]$_})
    return "session-$timestamp-$random"
}

function Start-DevTeamSession {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Command,
        [Parameter(Mandatory=$true)]
        [string]$CommandType,
        [string]$ExecutionMode = "normal"
    )

    _Ensure-Database

    $sessionId = New-SessionId
    $query = @"
        INSERT INTO sessions (id, command, command_type, execution_mode, status, current_phase)
        VALUES ('$sessionId', '$Command', '$CommandType', '$ExecutionMode', 'running', 'initializing');
"@

    Invoke-SQLite -Query $query
    return $sessionId
}

function Stop-DevTeamSession {
    param(
        [string]$Status = "completed",
        [string]$ExitReason = "Success"
    )

    $query = @"
        UPDATE sessions
        SET status = '$Status',
            exit_reason = '$ExitReason',
            ended_at = CURRENT_TIMESTAMP
        WHERE status = 'running';
"@

    Invoke-SQLite -Query $query
}

function Get-CurrentSessionId {
    _Ensure-Database
    Invoke-SQLite -Query "SELECT id FROM sessions WHERE status = 'running' ORDER BY started_at DESC LIMIT 1;"
}

function Test-SessionRunning {
    $count = Invoke-SQLite -Query "SELECT COUNT(*) FROM sessions WHERE status = 'running';"
    return [int]$count -gt 0
}

# ============================================================================
# STATE GETTERS
# ============================================================================

function Get-SessionState {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Field,
        [string]$SessionId
    )

    if (-not $SessionId) {
        $SessionId = Get-CurrentSessionId
    }

    Invoke-SQLite -Query "SELECT $Field FROM sessions WHERE id = '$SessionId';"
}

function Get-CurrentPhase {
    Get-SessionState -Field "current_phase"
}

function Get-CurrentAgent {
    Get-SessionState -Field "current_agent"
}

function Get-CurrentModel {
    Get-SessionState -Field "current_model"
}

function Get-CurrentIteration {
    Get-SessionState -Field "current_iteration"
}

function Get-ConsecutiveFailures {
    Get-SessionState -Field "consecutive_failures"
}

function Get-ExecutionMode {
    Get-SessionState -Field "execution_mode"
}

function Test-EcoMode {
    (Get-ExecutionMode) -eq "eco"
}

function Test-BugCouncilActive {
    (Get-SessionState -Field "bug_council_activated") -eq "1"
}

# ============================================================================
# STATE SETTERS
# ============================================================================

function Set-SessionState {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Field,
        [Parameter(Mandatory=$true)]
        [string]$Value,
        [string]$SessionId
    )

    if (-not $SessionId) {
        $SessionId = Get-CurrentSessionId
    }

    $query = @"
        UPDATE sessions
        SET $Field = '$Value'
        WHERE id = '$SessionId';
"@

    Invoke-SQLite -Query $query
}

function Set-CurrentPhase {
    param([Parameter(Mandatory=$true)][string]$Phase)
    Set-SessionState -Field "current_phase" -Value $Phase
}

function Set-CurrentAgent {
    param([Parameter(Mandatory=$true)][string]$Agent)
    Set-SessionState -Field "current_agent" -Value $Agent
}

function Set-CurrentModel {
    param([Parameter(Mandatory=$true)][string]$Model)
    Set-SessionState -Field "current_model" -Value $Model
}

function Add-Iteration {
    param([string]$SessionId)

    if (-not $SessionId) {
        $SessionId = Get-CurrentSessionId
    }

    $query = @"
        UPDATE sessions
        SET current_iteration = current_iteration + 1
        WHERE id = '$SessionId';
"@

    Invoke-SQLite -Query $query
}

function Add-Failure {
    param([string]$SessionId)

    if (-not $SessionId) {
        $SessionId = Get-CurrentSessionId
    }

    $query = @"
        UPDATE sessions
        SET consecutive_failures = consecutive_failures + 1
        WHERE id = '$SessionId';
"@

    Invoke-SQLite -Query $query
}

function Reset-Failures {
    param([string]$SessionId)

    if (-not $SessionId) {
        $SessionId = Get-CurrentSessionId
    }

    $query = @"
        UPDATE sessions
        SET consecutive_failures = 0
        WHERE id = '$SessionId';
"@

    Invoke-SQLite -Query $query
}

function Enable-BugCouncil {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Reason,
        [string]$SessionId
    )

    if (-not $SessionId) {
        $SessionId = Get-CurrentSessionId
    }

    $query = @"
        UPDATE sessions
        SET bug_council_activated = TRUE,
            bug_council_reason = '$Reason'
        WHERE id = '$SessionId';
"@

    Invoke-SQLite -Query $query
}

# ============================================================================
# COST TRACKING
# ============================================================================

function Add-Tokens {
    param(
        [int]$TokensInput,
        [int]$TokensOutput,
        [int]$CostCents,
        [string]$SessionId
    )

    if (-not $SessionId) {
        $SessionId = Get-CurrentSessionId
    }

    $query = @"
        UPDATE sessions
        SET total_tokens_input = total_tokens_input + $TokensInput,
            total_tokens_output = total_tokens_output + $TokensOutput,
            total_cost_cents = total_cost_cents + $CostCents
        WHERE id = '$SessionId';
"@

    Invoke-SQLite -Query $query
}

function Get-TotalCostDollars {
    param([string]$SessionId)

    if (-not $SessionId) {
        $SessionId = Get-CurrentSessionId
    }

    Invoke-SQLite -Query "SELECT ROUND(total_cost_cents / 100.0, 4) FROM sessions WHERE id = '$SessionId';"
}

# ============================================================================
# MODEL ESCALATION
# ============================================================================

function Get-NextModel {
    param([Parameter(Mandatory=$true)][string]$Current)

    switch ($Current) {
        "haiku"  { return "sonnet" }
        "sonnet" { return "opus" }
        "opus"   { return "bug_council" }
        default  { return "sonnet" }
    }
}

function Add-Escalation {
    param(
        [Parameter(Mandatory=$true)][string]$FromModel,
        [Parameter(Mandatory=$true)][string]$ToModel,
        [Parameter(Mandatory=$true)][string]$Reason,
        [string]$Agent,
        [string]$SessionId
    )

    if (-not $SessionId) {
        $SessionId = Get-CurrentSessionId
    }

    $iteration = Get-CurrentIteration

    $query = @"
        INSERT INTO escalations (session_id, from_model, to_model, reason, agent, iteration)
        VALUES ('$SessionId', '$FromModel', '$ToModel', '$Reason', '$Agent', $iteration);
"@

    Invoke-SQLite -Query $query
    Set-CurrentModel -Model $ToModel
}

# ============================================================================
# UTILITY FUNCTIONS
# ============================================================================

function Get-SessionSummary {
    param([string]$SessionId)

    if (-not $SessionId) {
        $SessionId = Get-CurrentSessionId
    }

    Invoke-SQLite -Query "SELECT * FROM v_session_summary WHERE id = '$SessionId';" -Json
}

function Stop-SessionAbort {
    param([string]$Reason = "User aborted")
    Stop-DevTeamSession -Status "aborted" -ExitReason $Reason
}

function Test-MaxIterationsReached {
    $current = [int](Get-CurrentIteration)
    $max = [int](Get-SessionState -Field "max_iterations")
    return $current -ge $max
}
