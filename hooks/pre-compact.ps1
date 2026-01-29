# DevTeam Pre-Compact Hook (PowerShell)
# Saves critical state before context compaction to preserve important information

$ErrorActionPreference = "Stop"

# Configuration
$MEMORY_DIR = ".devteam\memory"
$STATE_FILE = ".devteam\state.yaml"
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

    # Add current task context
    if (Test-Path $STATE_FILE) {
        $Content = Get-Content $STATE_FILE -Raw

        $CurrentSprint = "none"
        $CurrentTask = "none"
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

        $StateSection = @"
## Current Execution State

- Sprint: $CurrentSprint
- Task: $CurrentTask
- Phase: $Phase

"@

        # Get current task details if in progress
        if ($CurrentTask -and $CurrentTask -ne "null" -and $CurrentTask -ne "none") {
            $TaskStatus = "unknown"
            $TaskIteration = "0"
            $TaskTier = "unknown"

            # Simple extraction for task details
            if ($Content -match "status:\s*(.+)") {
                $TaskStatus = $Matches[1].Trim()
            }
            if ($Content -match "iterations:\s*(.+)") {
                $TaskIteration = $Matches[1].Trim()
            }
            if ($Content -match "tier:\s*(.+)") {
                $TaskTier = $Matches[1].Trim()
            }

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

1. Full state is in ``.devteam/state.yaml`` - always read it to understand progress
2. Check task status before starting work
3. Update state file after completing tasks
4. Output ``EXIT_SIGNAL: true`` only when ALL work is genuinely complete

## Recovery Instructions

If resuming after compaction:
1. Read ``.devteam/state.yaml`` to understand current state
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
