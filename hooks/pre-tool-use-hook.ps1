# DevTeam Pre-Tool-Use Hook (PowerShell)
# Runs BEFORE each tool call to validate and inject context
#
# Exit codes:
#   0 = Allow tool call
#   2 = Block tool call with message

$ErrorActionPreference = "Stop"

# Source common library
. "$PSScriptRoot\lib\hook-common.ps1"

Initialize-Hook "pre-tool-use"

# ============================================================================
# CONFIGURATION
# ============================================================================

$ToolName = $env:CLAUDE_TOOL_NAME
$ToolInput = $env:CLAUDE_TOOL_INPUT

# ============================================================================
# DANGEROUS COMMAND PATTERNS
# ============================================================================

$DangerousPatterns = @(
    # Destructive file operations
    "rm -rf /",
    "rm -rf /*",
    "Remove-Item.*-Recurse.*-Force.*/",
    "del /s /q c:\\",

    # Disk/system destruction
    "Format-Volume",
    "Clear-Disk",
    "Initialize-Disk",

    # Git force push to main/master
    "git push.*--force.*main",
    "git push.*--force.*master",
    "git push.*-f.*main",
    "git push.*-f.*master",

    # Database destruction
    "DROP DATABASE",
    "DROP TABLE",
    "TRUNCATE TABLE",

    # Credential exposure
    "Get-Content.*\.ssh\\id_",
    "type.*\.ssh\\id_",

    # Remote code execution
    "Invoke-Expression.*Invoke-WebRequest",
    "iex.*iwr",
    "curl.*\|.*bash",
    "wget.*\|.*bash"
)

# ============================================================================
# SCOPE VALIDATION
# ============================================================================

function Test-FileOperation {
    param(
        [string]$Tool,
        [string]$Input
    )

    $filePath = $null

    switch ($Tool) {
        { $_ -in @("Write", "Edit", "NotebookEdit") } {
            if ($Input -match '"file_path"\s*:\s*"([^"]+)"') {
                $filePath = $Matches[1]
            }
        }
        "Bash" {
            if ($Input -match '>\s*([^\s;&|]+)') {
                $filePath = $Matches[1]
            }
        }
        default {
            return $true
        }
    }

    if ($filePath) {
        $filePath = $filePath.Trim('"')
        if (-not (Test-FileInScope $filePath)) {
            Write-HookWarn "pre-tool-use" "Scope violation attempted: $filePath"
            $safeFilePath = ConvertTo-SafeJsonString $filePath
            Write-EventToDb "scope_violation" "warning" "Attempted to modify out-of-scope file: $safeFilePath"

            $scopeList = (Get-ScopeFiles | Select-Object -First 10) -join "`n"
            $message = Get-SystemMessage "scope-warning" @"
SCOPE VIOLATION BLOCKED

You attempted to modify: $filePath

This file is outside your allowed scope for this task.

Allowed scope:
$scopeList

Please only modify files within the allowed scope.
"@
            Write-Output $message
            exit 2
        }
    }

    return $true
}

# ============================================================================
# DANGEROUS COMMAND DETECTION
# ============================================================================

function Test-DangerousCommand {
    param(
        [string]$Tool,
        [string]$Input
    )

    if ($Tool -ne "Bash") { return $true }

    $command = $Input
    if ($Input -match '"command"\s*:\s*"([^"]+)"') {
        $command = $Matches[1]
    }

    foreach ($pattern in $DangerousPatterns) {
        if ($command -match $pattern) {
            Write-HookError "pre-tool-use" "Dangerous command blocked: $pattern"
            $safePattern = ConvertTo-SafeJsonString $pattern
            Write-EventToDb "dangerous_command" "error" "Blocked dangerous command matching: $safePattern"

            $message = Get-SystemMessage "danger-blocked" @"
DANGEROUS COMMAND BLOCKED

The command you attempted contains a potentially destructive pattern:
  Pattern: $pattern

This command has been blocked for safety.

If this is intentional and authorized:
1. Ask the user for explicit confirmation
2. Explain why this destructive operation is necessary
"@
            Write-Output $message
            exit 2
        }
    }

    return $true
}

# ============================================================================
# ITERATION WARNING
# ============================================================================

function Write-IterationContext {
    $iteration = Get-CurrentIteration
    $remaining = $script:MAX_ITERATIONS - $iteration

    if ($remaining -le 5 -and $remaining -gt 0) {
        $message = Get-SystemMessage "iteration-warning" @"
ITERATION WARNING

You have $remaining iterations remaining before max iterations reached.
Current iteration: $iteration/$($script:MAX_ITERATIONS)

Focus on fixing the most critical issues first.
"@
        Write-Output $message
    }
    elseif ($remaining -le 0) {
        $message = Get-SystemMessage "iteration-limit" @"
ITERATION LIMIT REACHED

You have reached the maximum iteration count ($($script:MAX_ITERATIONS)).
The session will end after this iteration.

Ensure you:
1. Save any important progress
2. Document current state
3. Report what was completed vs remaining

Use EXIT_SIGNAL: true to cleanly end the session.
"@
        Write-Output $message
    }
}

# ============================================================================
# CIRCUIT BREAKER CHECK
# ============================================================================

function Test-CircuitBreaker {
    $failures = Get-ConsecutiveFailures
    $warningThreshold = $script:MAX_FAILURES - 2

    if ($failures -ge $warningThreshold -and $failures -lt $script:MAX_FAILURES) {
        $message = Get-SystemMessage "failure-warning" @"
FAILURE WARNING

Consecutive failures: $failures / $($script:MAX_FAILURES)

The circuit breaker will trip after $($script:MAX_FAILURES) consecutive failures.

Consider trying a different approach.
"@
        Write-Output $message
    }
}

# ============================================================================
# MAIN EXECUTION
# ============================================================================

if (-not $ToolName) {
    exit 0
}

Write-HookDebug "pre-tool-use" "Validating tool: $ToolName"

# Check dangerous commands first
Test-DangerousCommand $ToolName $ToolInput | Out-Null

# Validate scope for file operations
Test-FileOperation $ToolName $ToolInput | Out-Null

# Check circuit breaker
Test-CircuitBreaker

# Inject iteration context
Write-IterationContext

# Notify MCP server
Send-McpNotification "pre_tool_use" (Get-ClaudeContext)

exit 0
