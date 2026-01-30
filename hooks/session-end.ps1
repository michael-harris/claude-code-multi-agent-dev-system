# DevTeam Session End Hook (PowerShell)
# Saves session context for future resumption

$ErrorActionPreference = "Stop"

# Configuration
$MEMORY_DIR = ".devteam\memory"
$STATE_FILE = ".devteam\state.yaml"
$Timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$MEMORY_FILE = "$MEMORY_DIR\session-$Timestamp.md"

# Logging function
function Write-Log {
    param([string]$Message)
    Write-Host "[DevTeam Session End] $Message"
}

# ============================================
# EXTRACT STATE INFORMATION
# ============================================
function Get-StateInfo {
    $State = @{
        CurrentSprint = "unknown"
        CurrentTask = "unknown"
        Phase = "unknown"
        CompletedTasks = 0
        TotalTasks = 0
    }

    if (Test-Path $STATE_FILE) {
        $Content = Get-Content $STATE_FILE -Raw

        if ($Content -match "current_sprint:\s*(.+)") {
            $State.CurrentSprint = $Matches[1].Trim()
        }
        if ($Content -match "current_task:\s*(.+)") {
            $State.CurrentTask = $Matches[1].Trim()
        }
        if ($Content -match "phase:\s*(.+)") {
            $State.Phase = $Matches[1].Trim()
        }

        # Count completed tasks
        $CompletedMatches = [regex]::Matches($Content, "status:\s*completed")
        $State.CompletedTasks = $CompletedMatches.Count

        # Count total tasks
        $TaskMatches = [regex]::Matches($Content, "TASK-")
        $State.TotalTasks = $TaskMatches.Count
    }

    return $State
}

# ============================================
# SAVE SESSION MEMORY
# ============================================
function Save-Memory {
    # Ensure directory exists
    if (-not (Test-Path $MEMORY_DIR)) {
        New-Item -ItemType Directory -Path $MEMORY_DIR -Force | Out-Null
    }

    $State = Get-StateInfo
    $IsoDate = Get-Date -Format "yyyy-MM-ddTHH:mm:ssK"
    $CurrentDate = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

    $MemoryContent = @"
# Session Memory - $IsoDate

## Context at Session End

- **Sprint:** $($State.CurrentSprint)
- **Task:** $($State.CurrentTask)
- **Phase:** $($State.Phase)
- **Progress:** $($State.CompletedTasks) / $($State.TotalTasks) tasks completed

## State File Location

The full project state is stored in: ``$STATE_FILE``

## Resumption Instructions

To resume this work:
1. The state file contains all progress information
2. Run ``/devteam:implement --resume`` to continue autonomous execution
3. Or run ``/devteam:sprint <sprint-id>`` to continue a specific sprint

## Notes

This session ended at $CurrentDate.

If this was an unexpected interruption (context limit, timeout, etc.),
the work can be resumed from the last saved state.

"@

    $MemoryContent | Out-File -FilePath $MEMORY_FILE -Encoding UTF8
    Write-Log "Session memory saved to $MEMORY_FILE"
}

# ============================================
# CLEANUP OLD MEMORY FILES
# ============================================
function Cleanup-OldMemories {
    # Keep only the last 10 memory files
    if (Test-Path $MEMORY_DIR) {
        $Files = Get-ChildItem -Path $MEMORY_DIR -Filter "session-*.md" -ErrorAction SilentlyContinue |
                 Sort-Object LastWriteTime -Descending

        if ($Files.Count -gt 10) {
            Write-Log "Cleaning up old memory files (keeping last 10)"
            $FilesToRemove = $Files | Select-Object -Skip 10
            $FilesToRemove | Remove-Item -Force
        }
    }
}

# ============================================
# MAIN EXECUTION
# ============================================
function Main {
    Write-Log "Saving session state..."

    # Save memory file
    Save-Memory

    # Cleanup old files
    Cleanup-OldMemories

    Write-Log "Session end complete"
}

# Run main function
Main
