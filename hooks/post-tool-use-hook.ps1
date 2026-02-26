# DevTeam Post-Tool-Use Hook (PowerShell)
# Runs AFTER each tool call to log, detect patterns, and guide next steps
#
# Exit codes:
#   0 = Continue normally

$ErrorActionPreference = "Stop"

# Source common library
. "$PSScriptRoot\lib\hook-common.ps1"

Initialize-Hook "post-tool-use"

# ============================================================================
# CONFIGURATION
# ============================================================================

$ToolName = $env:CLAUDE_TOOL_NAME
$ToolResult = $env:CLAUDE_TOOL_RESULT

# ============================================================================
# OUTCOME DETECTION PATTERNS
# ============================================================================

$FailurePatterns = @(
    "FAIL",
    "FAILED",
    "Error:",
    "error:",
    "ERROR",
    "Exception",
    "Traceback",
    "AssertionError",
    "TypeError",
    "SyntaxError",
    "ModuleNotFoundError",
    "ImportError",
    "exit code [1-9]",
    "Build failed",
    "Test failed",
    "Permission denied",
    "command not found"
)

$SuccessPatterns = @(
    "PASS",
    "PASSED",
    "All tests pass",
    "Build succeeded",
    "Successfully",
    "0 errors",
    "0 failures",
    "exit code 0"
)

# ============================================================================
# OUTCOME DETECTION
# ============================================================================

function Get-Outcome {
    param([string]$Result)

    # Check for failure patterns first (more specific, takes priority)
    foreach ($pattern in $FailurePatterns) {
        if ($Result -match $pattern) {
            return "failure"
        }
    }

    foreach ($pattern in $SuccessPatterns) {
        if ($Result -match $pattern) {
            return "success"
        }
    }

    return "unknown"
}

# ============================================================================
# QUALITY GATE DETECTION
# ============================================================================

function Test-QualityGate {
    param(
        [string]$Tool,
        [string]$Result
    )

    if ($Tool -ne "Bash") { return }

    $gate = $null
    $gateType = $null

    if ($Result -match "(pytest|jest|vitest|go test|npm test|rspec|phpunit)") {
        $gate = "tests"
        $gateType = "test"
    }
    elseif ($Result -match "(tsc|mypy|pyright)") {
        $gate = "typecheck"
        $gateType = "type"
    }
    elseif ($Result -match "(eslint|ruff|golangci-lint|rubocop|pylint)") {
        $gate = "lint"
        $gateType = "lint"
    }
    elseif ($Result -match "(bandit|npm audit|gosec|snyk)") {
        $gate = "security"
        $gateType = "security"
    }

    if ($gate) {
        $outcome = Get-Outcome $Result
        $passed = $outcome -eq "success"

        Write-HookInfo "post-tool-use" "Quality gate detected: $gate ($outcome)"
        $safeGate = ConvertTo-SafeJsonString $gate
        $passedJson = if ($passed) { "true" } else { "false" }
        Write-EventToDb "gate_result" "gate" "Gate $gate`: $outcome" "{`"gate`": `"$safeGate`", `"passed`": $passedJson}"

        if (-not $passed) {
            $message = Get-SystemMessage "gate-failed" @"
QUALITY GATE FAILED: $gate

Next steps:
1. Analyze the specific errors above
2. Fix the issues one at a time
3. Re-run the $gate gate to verify fixes

Do not proceed until this gate passes.
"@
            Write-Output $message
        }
    }
}

# ============================================================================
# FAILURE HANDLING
# ============================================================================

function Invoke-FailureHandler {
    param([string]$Result)

    Add-Failure

    $failures = Get-ConsecutiveFailures
    $currentModel = Get-CurrentModel

    Write-HookWarn "post-tool-use" "Failure detected (consecutive: $failures)"

    # Store error summary
    $errorsFile = Join-Path $script:DEVTEAM_DIR "last-errors.txt"
    ($Result -split "`n" | Where-Object { $_ -match "(error|fail|exception)" } | Select-Object -First 20) -join "`n" | Set-Content $errorsFile -ErrorAction SilentlyContinue

    # Escalation threshold
    $threshold = if ($script:ECO_MODE) { 4 } else { 2 }

    if ($failures -ge $threshold) {
        Invoke-Escalation "$failures consecutive failures"

        $nextModel = switch ($currentModel) {
            "haiku" { "sonnet" }
            "sonnet" { "opus" }
            "opus" { "bug_council" }
            default { $null }
        }

        if ($nextModel -eq "bug_council") {
            $message = Get-SystemMessage "bug-council" @"
BUG COUNCIL ACTIVATION REQUIRED

$failures consecutive failures with $currentModel model.

The Bug Council diagnostic team:
1. Root Cause Analyst
2. Code Archaeologist
3. Pattern Matcher
4. Systems Thinker
5. Adversarial Tester
"@
            Write-Output $message
        }
        elseif ($nextModel) {
            $message = Get-SystemMessage "escalation" @"
MODEL ESCALATED

Previous model: $currentModel
New model: $nextModel
Reason: $failures consecutive failures

Please try a different approach.
"@
            Write-Output $message
        }
    }
}

# ============================================================================
# SUCCESS HANDLING
# ============================================================================

function Invoke-SuccessHandler {
    param([string]$Result)

    Reset-Failures

    Write-HookInfo "post-tool-use" "Success detected"

    if ($Result -match "(All tests pass|0 failed|100% passed)") {
        Write-HookInfo "post-tool-use" "Potential task completion detected"

        $message = Get-SystemMessage "completion-check" @"
Tests appear to be passing.

Before marking complete, verify:
1. All acceptance criteria are met
2. All quality gates pass
3. No scope violations occurred

If complete, use EXIT_SIGNAL: true
"@
        Write-Output $message
    }
}

# ============================================================================
# ERROR PATTERN ANALYSIS
# ============================================================================

function Invoke-ErrorAnalysis {
    param([string]$Result)

    if ($Result -match "(ModuleNotFoundError|Cannot find module)") {
        $message = Get-SystemMessage "missing-dep" @"
MISSING DEPENDENCY DETECTED

Install the missing package and re-run.
"@
        Write-Output $message
    }

    if ($Result -match "(TypeError|type.*mismatch)") {
        $message = Get-SystemMessage "type-error" @"
TYPE ERROR DETECTED

Check expected vs actual types.
"@
        Write-Output $message
    }

    if ($Result -match "(Permission denied|EACCES)") {
        $message = Get-SystemMessage "permission-error" @"
PERMISSION ERROR DETECTED

Check file/directory permissions.
"@
        Write-Output $message
    }
}

# ============================================================================
# MAIN EXECUTION
# ============================================================================

if (-not $ToolResult) {
    exit 0
}

Write-HookDebug "post-tool-use" "Processing result from: $ToolName"

$outcome = Get-Outcome $ToolResult

$safeToolName = ConvertTo-SafeJsonString $ToolName
$safeOutcome = ConvertTo-SafeJsonString $outcome
Write-EventToDb "tool_executed" "general" "Tool: $ToolName, Outcome: $outcome" "{`"tool`": `"$safeToolName`", `"outcome`": `"$safeOutcome`"}"

switch ($outcome) {
    "failure" {
        Invoke-FailureHandler $ToolResult
        Invoke-ErrorAnalysis $ToolResult
    }
    "success" {
        Invoke-SuccessHandler $ToolResult
    }
    "unknown" {
        Write-HookDebug "post-tool-use" "Outcome unknown, no action taken"
    }
}

Test-QualityGate $ToolName $ToolResult

Send-McpNotification "post_tool_use" (Get-ClaudeContext)

exit 0
