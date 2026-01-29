# DevTeam Stop Hook (PowerShell)
# Implements Ralph-style session persistence for autonomous mode
#
# Exit codes:
#   0 = Allow exit (work complete or not in autonomous mode)
#   2 = Block exit and re-inject prompt (work not complete)

$ErrorActionPreference = "Stop"

# Configuration
$STATE_FILE = ".devteam\state.yaml"
$CIRCUIT_BREAKER_FILE = ".devteam\circuit-breaker.json"
$AUTONOMOUS_MARKER = ".devteam\autonomous-mode"
$MAX_FAILURES = 5
$MAX_ITERATIONS = 100

# Logging function
function Write-Log {
    param([string]$Message)
    Write-Host "[DevTeam Stop Hook] $Message"
}

# Check if autonomous mode is active
if (-not (Test-Path $AUTONOMOUS_MARKER)) {
    # Not in autonomous mode, allow normal exit
    exit 0
}

# Check for explicit EXIT_SIGNAL in Claude's output
# The STOP_HOOK_MESSAGE environment variable contains the last message
$stopHookMessage = $env:STOP_HOOK_MESSAGE
if ($stopHookMessage) {
    if ($stopHookMessage -match "EXIT_SIGNAL:\s*true") {
        Write-Log "EXIT_SIGNAL received. Project complete."
        Remove-Item -Path $AUTONOMOUS_MARKER -Force -ErrorAction SilentlyContinue
        exit 0
    }
}

# Initialize circuit breaker if it doesn't exist
if (-not (Test-Path $CIRCUIT_BREAKER_FILE)) {
    $circuitBreakerDir = Split-Path $CIRCUIT_BREAKER_FILE -Parent
    if (-not (Test-Path $circuitBreakerDir)) {
        New-Item -ItemType Directory -Path $circuitBreakerDir -Force | Out-Null
    }
    @{
        consecutive_failures = 0
        total_iterations = 0
        last_failure = $null
    } | ConvertTo-Json | Set-Content $CIRCUIT_BREAKER_FILE
}

# Read circuit breaker state
try {
    $circuitBreaker = Get-Content $CIRCUIT_BREAKER_FILE -Raw | ConvertFrom-Json
    $FAILURES = $circuitBreaker.consecutive_failures
    $ITERATIONS = $circuitBreaker.total_iterations
} catch {
    $FAILURES = 0
    $ITERATIONS = 0
}

# Check circuit breaker threshold
if ($FAILURES -ge $MAX_FAILURES) {
    Write-Log "Circuit breaker OPEN: $FAILURES consecutive failures."
    Write-Log "Human intervention required. Check .devteam\state.yaml for details."
    Remove-Item -Path $AUTONOMOUS_MARKER -Force -ErrorAction SilentlyContinue
    exit 0
}

# Check maximum iterations
if ($ITERATIONS -ge $MAX_ITERATIONS) {
    Write-Log "Maximum iterations ($MAX_ITERATIONS) reached."
    Write-Log "Review progress in .devteam\state.yaml"
    Remove-Item -Path $AUTONOMOUS_MARKER -Force -ErrorAction SilentlyContinue
    exit 0
}

# Check state file for completion status
if (Test-Path $STATE_FILE) {
    $stateContent = Get-Content $STATE_FILE -Raw

    # Count task statuses
    $PENDING = ([regex]::Matches($stateContent, "status:\s*pending")).Count
    $IN_PROGRESS = ([regex]::Matches($stateContent, "status:\s*in_progress")).Count

    # If no pending or in-progress tasks, work is complete
    if ($PENDING -eq 0 -and $IN_PROGRESS -eq 0) {
        Write-Log "All work complete. Allowing exit."
        Remove-Item -Path $AUTONOMOUS_MARKER -Force -ErrorAction SilentlyContinue
        exit 0
    }
}

# Work not complete - increment iteration and continue
$ITERATIONS++

# Update circuit breaker file
try {
    $circuitBreaker.total_iterations = $ITERATIONS
    $circuitBreaker | ConvertTo-Json | Set-Content $CIRCUIT_BREAKER_FILE
} catch {
    Write-Log "Warning: Could not update circuit breaker file"
}

Write-Log "Work in progress (iteration $ITERATIONS/$MAX_ITERATIONS). Continuing..."
Write-Log "Pending: $PENDING, In Progress: $IN_PROGRESS"

# Exit code 2 tells Claude Code to block exit and re-inject the prompt
exit 2
