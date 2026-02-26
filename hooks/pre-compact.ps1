# DevTeam Pre-Compact Hook (PowerShell)
# Saves critical state before context compaction to preserve important information

$ErrorActionPreference = "Stop"

# Source common library for SQLite helpers
. "$PSScriptRoot\lib\hook-common.ps1"

# Configuration
$MEMORY_DIR = ".devteam\memory"
$Timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$COMPACT_FILE = "$MEMORY_DIR\pre-compact-$Timestamp.md"

# Logging function
function Write-Log {
    param([string]$Message)
    Write-Host "[DevTeam Pre-Compact] $Message"
}

# ============================================
# SAVE CRITICAL CONTEXT
# ============================================
function Save-CriticalContext {
    # Ensure directory exists
    if (-not (Test-Path $MEMORY_DIR)) {
        New-Item -ItemType Directory -Path $MEMORY_DIR -Force | Out-Null
    }

    $Header = @"
# Pre-Compaction State Snapshot

This file was created automatically before context compaction.
It preserves critical information that should not be lost.

"@

    $StateSection = ""

    # Add current task context from SQLite database
    if (Test-DatabaseExists) {
        $sid = Invoke-DbQuery "SELECT id FROM sessions WHERE status='running' ORDER BY started_at DESC LIMIT 1;"
        if (-not $sid) { $sid = "unknown" }

        $CurrentSprint = Invoke-DbQuery "SELECT sprint_id FROM sessions WHERE id = '$sid';"
        $CurrentTask = Invoke-DbQuery "SELECT current_task_id FROM sessions WHERE id = '$sid';"
        $Phase = Invoke-DbQuery "SELECT current_phase FROM sessions WHERE id = '$sid';"

        if (-not $CurrentSprint) { $CurrentSprint = "none" }
        if (-not $CurrentTask) { $CurrentTask = "none" }
        if (-not $Phase) { $Phase = "unknown" }

        $StateSection = @"
## Current Execution State

- Sprint: $CurrentSprint
- Task: $CurrentTask
- Phase: $Phase

"@

        # Get current task details if in progress
        if ($CurrentTask -and $CurrentTask -ne "none") {
            $TaskStatus = Invoke-DbQuery "SELECT status FROM tasks WHERE id='$CurrentTask';"
            $TaskIteration = Invoke-DbQuery "SELECT actual_iterations FROM tasks WHERE id='$CurrentTask';"
            $TaskTier = Invoke-DbQuery "SELECT estimated_effort FROM tasks WHERE id='$CurrentTask';"

            if (-not $TaskStatus) { $TaskStatus = "unknown" }
            if (-not $TaskIteration) { $TaskIteration = "0" }
            if (-not $TaskTier) { $TaskTier = "unknown" }

            $StateSection += @"
### Current Task Details

- Status: $TaskStatus
- Iteration: $TaskIteration
- Complexity Tier: $TaskTier

"@
        }
    }

    $AutonomousSection = ""

    # Add autonomous mode status
    if (Test-Path ".devteam\autonomous-mode") {
        $AutonomousSection = @"
## Autonomous Mode

Autonomous mode is ACTIVE. Continue working until EXIT_SIGNAL.

"@

        if (Test-Path ".devteam\circuit-breaker.json") {
            $CircuitBreaker = Get-Content ".devteam\circuit-breaker.json" -Raw
            $AutonomousSection += @"
### Circuit Breaker Status
``````json
$CircuitBreaker
``````

"@
        }
    }

    $Footer = @"

## Important Reminders

1. Full state is in ``.devteam/devteam.db`` (SQLite) - query it to understand progress
2. Check task status before starting work
3. Update database state after completing tasks
4. Output ``EXIT_SIGNAL: true`` only when ALL work is genuinely complete

## Recovery Instructions

If resuming after compaction:
1. Query ``.devteam/devteam.db`` to understand current state
2. Continue from the current task/sprint
3. Do not restart completed work

"@

    $FullContent = $Header + $StateSection + $AutonomousSection + $Footer
    $FullContent | Out-File -FilePath $COMPACT_FILE -Encoding UTF8

    Write-Log "Critical context saved to $COMPACT_FILE"
}

# ============================================
# OUTPUT CONTEXT FOR CLAUDE
# ============================================
function Output-Context {
    # This output will be preserved in Claude's context after compaction
    Write-Output ""
    Write-Output "## Post-Compaction Context"
    Write-Output ""

    if (Test-Path $COMPACT_FILE) {
        Get-Content $COMPACT_FILE
    }
}

# ============================================
# MAIN EXECUTION
# ============================================
function Main {
    Write-Log "Preparing for context compaction..."

    # Save critical context
    Save-CriticalContext

    # Output for Claude
    Output-Context

    Write-Log "Pre-compact preparation complete"
}

# Run main function
Main
