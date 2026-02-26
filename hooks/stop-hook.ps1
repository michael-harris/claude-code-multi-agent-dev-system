# DevTeam Stop Hook (PowerShell)
# Implements session persistence for autonomous mode
#
# Exit codes:
#   0 = Allow exit
#   2 = Block exit and re-inject prompt

$ErrorActionPreference = "Stop"

# Source common library
. "$PSScriptRoot\lib\hook-common.ps1"

Initialize-Hook "stop"

# ============================================================================
# CONFIGURATION
# ============================================================================

$MESSAGE = if ($env:STOP_HOOK_MESSAGE) { $env:STOP_HOOK_MESSAGE } else { $env:CLAUDE_OUTPUT }

# ============================================================================
# VALID EXIT SIGNALS
# ============================================================================

$VALID_EXIT_SIGNALS = @(
    "EXIT_SIGNAL: true",
    "EXIT_SIGNAL:true",
    "All quality gates passed",
    "Task completed successfully",
    "Implementation complete",
    "Session ended",
    "All tasks completed",
    "Sprint completed",
    "/devteam:end"
)

# ============================================================================
# EXIT SIGNAL DETECTION
# ============================================================================

function Test-ValidExitSignal {
    param([string]$Message)

    foreach ($signal in $VALID_EXIT_SIGNALS) {
        if ($Message -match [regex]::Escape($signal)) {
            return $true
        }
    }
    return $false
}

# ============================================================================
# SESSION STATE CHECK
# ============================================================================

function Test-IncompleteWork {
    $sessionId = Get-CurrentSession
    if (-not $sessionId) { return $false }

    # Check for in-progress tasks
    if (Test-DatabaseExists) {
        $safeSessionId = $sessionId -replace "'", "''"
        $inProgress = Invoke-DbQuery "SELECT COUNT(*) FROM tasks WHERE session_id = '$safeSessionId' AND status = 'in_progress';"
        if ([int]$inProgress -gt 0) {
            Write-HookInfo "stop" "Found $inProgress in-progress tasks"
            return $true
        }
    }

    # Check session status
    $safeSessionId = $sessionId -replace "'", "''"
    $sessionStatus = Invoke-DbQuery "SELECT status FROM sessions WHERE id = '$safeSessionId';"
    if ($sessionStatus -eq "running") {
        $recentFailures = Invoke-DbQuery "SELECT COUNT(*) FROM events WHERE session_id = '$safeSessionId' AND event_type IN ('gate_failed', 'agent_failed', 'task_failed') AND timestamp > datetime('now', '-5 minutes');"
        if ([int]$recentFailures -gt 0) {
            Write-HookInfo "stop" "Found $recentFailures recent failures"
            return $true
        }
    }

    # Check database for pending work (fallback)
    if (Test-DatabaseExists) {
        $pending = Invoke-DbQuery "SELECT COUNT(*) FROM tasks WHERE status = 'pending';"
        $inProg = Invoke-DbQuery "SELECT COUNT(*) FROM tasks WHERE status = 'in_progress';"
        if ([int]$pending -gt 0 -or [int]$inProg -gt 0) {
            Write-HookInfo "stop" "Database shows pending: $pending, in_progress: $inProg"
            return $true
        }
    }

    return $false
}

# ============================================================================
# CHECKPOINT AND CLEANUP
# ============================================================================

function Save-ExitCheckpoint {
    $sessionId = Get-CurrentSession
    if ($sessionId) {
        Write-HookInfo "stop" "Saving checkpoint before exit"
        Save-Checkpoint "Auto-checkpoint before exit"
        Write-EventToDb "checkpoint_created" "session" "Auto-checkpoint before exit"
    }
}

function Clear-Session {
    param([string]$ExitReason = "completed")

    # Remove autonomous mode marker
    if (Test-Path $script:AUTONOMOUS_MARKER) {
        Remove-Item $script:AUTONOMOUS_MARKER -Force
    }

    # Update session status
    $sessionId = Get-CurrentSession
    if ($sessionId) {
        $safeSessionId = $sessionId -replace "'", "''"
        $safeExitReason = $ExitReason -replace "'", "''"
        Invoke-DbQuery "UPDATE sessions SET status = 'completed', exit_reason = '$safeExitReason', ended_at = datetime('now') WHERE id = '$safeSessionId';"
    }

    $safeExitReason = ConvertTo-SafeJsonString $ExitReason
    Send-McpNotification "session_exit" "{`"authorized`": true, `"reason`": `"$safeExitReason`"}"
}

# ============================================================================
# MAIN EXECUTION
# ============================================================================

# Check if autonomous mode is active
if (-not (Test-AutonomousMode)) {
    Write-HookDebug "stop" "Not in autonomous mode, allowing exit"
    exit 0
}

# Check for valid exit signal
if ($MESSAGE -and (Test-ValidExitSignal $MESSAGE)) {
    Write-HookInfo "stop" "Valid exit signal detected"
    Save-ExitCheckpoint
    Clear-Session "completed"
    exit 0
}

# Check circuit breaker
if (Test-CircuitBreakerOpen) {
    Write-HookWarn "stop" "Circuit breaker OPEN - allowing exit"
    Save-ExitCheckpoint
    Clear-Session "circuit_breaker"

    $message = Get-SystemMessage "circuit-breaker" @"
CIRCUIT BREAKER TRIPPED

Maximum consecutive failures ($($script:MAX_FAILURES)) reached.
Human intervention is required.
"@
    Write-Output $message
    exit 0
}

# Check max iterations
if (Test-MaxIterationsReached) {
    Write-HookWarn "stop" "Maximum iterations reached"
    Save-ExitCheckpoint
    Clear-Session "max_iterations"

    $message = Get-SystemMessage "max-iterations" @"
MAXIMUM ITERATIONS REACHED

The session has reached $($script:MAX_ITERATIONS) iterations.
"@
    Write-Output $message
    exit 0
}

# In autonomous mode without a valid exit signal, always block
# This matches the Bash version's behavior - autonomous mode requires explicit exit signal
Write-HookWarn "stop" "Exit blocked - no valid exit signal in autonomous mode"
Write-EventToDb "exit_blocked" "persistence" "Exit blocked - no valid exit signal"

$sessionId = Get-CurrentSession
$taskId = Get-CurrentTask
$iteration = Get-CurrentIteration

$message = Get-SystemMessage "exit-blocked" @"
EXIT BLOCKED

Autonomous mode requires a valid exit signal.

Current state:
- Session: $sessionId
- Task: $taskId
- Iteration: $iteration/$($script:MAX_ITERATIONS)

You must either:
1. Complete the task (all quality gates pass)
2. Use devteam_save_checkpoint to save progress
3. Use devteam_end_session with appropriate status

Include EXIT_SIGNAL: true when properly complete.
"@
Write-Output $message

# Increment iteration
if ($sessionId) {
    $safeId = $sessionId -replace "'", "''"
    Invoke-DbQuery "UPDATE sessions SET current_iteration = $($iteration + 1) WHERE id = '$safeId';"
}

Send-McpNotification "exit_blocked" (Get-ClaudeContext)
exit 2
