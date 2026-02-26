# DevTeam Persistence Hook (PowerShell)
# Detects and prevents premature task abandonment
#
# Exit codes:
#   0 = Allow (output is acceptable)
#   2 = Block and re-engage (detected abandonment attempt)

$ErrorActionPreference = "Stop"

# Source common library
. "$PSScriptRoot\lib\hook-common.ps1"

Initialize-Hook "persistence"

# ============================================================================
# CONFIGURATION
# ============================================================================

$MESSAGE = $env:CLAUDE_OUTPUT
$ABANDONMENT_LOG = Join-Path $script:DEVTEAM_DIR "abandonment-attempts.log"

# If no message, allow
if ([string]::IsNullOrEmpty($MESSAGE)) {
    exit 0
}

# ============================================================================
# ABANDONMENT DETECTION PATTERNS
# ============================================================================

# Direct abandonment phrases
$GIVE_UP_PATTERNS = @(
    # Direct abandonment
    "I cannot complete this",
    "I'm unable to",
    "I can't figure out",
    "I don't know how to",
    "I'm not sure how to proceed",
    "I give up",
    "I'm stuck",
    "This is beyond my",
    "I cannot determine",
    "I'm at a loss",
    "I have no idea",

    # Premature completion claims
    "I've done what I can",
    "That's all I can do",
    "I've tried everything",
    "Nothing else I can try",
    "I'm out of ideas",
    "I've exhausted",
    "No other options",

    # Deflection to user
    "You should try",
    "You might want to",
    "You'll need to manually",
    "This requires human",
    "A human needs to",
    "You could try",
    "Perhaps you could",
    "Maybe you should",

    # False completion
    "I'll stop here",
    "Let me stop",
    "I think we should stop",
    "We can stop here",
    "I'm going to stop",
    "That should be enough",
    "I'll leave it here",

    # Excuse patterns
    "This is too complex",
    "This would take too long",
    "I don't have access",
    "I can't access",
    "Outside my capabilities",
    "Beyond my ability",
    "Not possible for me",
    "I lack the ability"
)

# Passive abandonment patterns
$PASSIVE_ABANDONMENT_PATTERNS = @(
    "Let me know if you need",
    "Let me know if you want",
    "Let me know if you'd like",
    "Feel free to",
    "You can try",
    "You might try",
    "would you like me to",
    "should I",
    "I can stop here",
    "we could stop",
    "that should work",
    "should be working",
    "I hope this helps",
    "Hope that helps",
    "Let me know if",
    "If you need anything else",
    "I'm here if you need"
)

# Permission-seeking patterns
$PERMISSION_SEEKING_PATTERNS = @(
    "Should I proceed",
    "Do you want me to",
    "Would you like me to",
    "Shall I",
    "Want me to",
    "Can I",
    "May I",
    "Is it okay if",
    "Would it be okay",
    "Do you mind if"
)

# Legitimate completion patterns
$LEGITIMATE_STOP_PATTERNS = @(
    "EXIT_SIGNAL: true",
    "EXIT_SIGNAL:true",
    "All tests passing",
    "All quality gates passed",
    "Task completed successfully",
    "Implementation complete",
    "Ready for review",
    "Committed and pushed",
    "All acceptance criteria met",
    "Successfully completed",
    "/devteam:end"
)

# ============================================================================
# DETECTION LOGIC
# ============================================================================

# Check for legitimate completion first
foreach ($pattern in $LEGITIMATE_STOP_PATTERNS) {
    if ($MESSAGE -match [regex]::Escape($pattern)) {
        Write-HookInfo "persistence" "Legitimate completion detected: $pattern"
        exit 0
    }
}

$DETECTED_PATTERN = $null
$DETECTION_TYPE = $null

# Check for direct abandonment
foreach ($pattern in $GIVE_UP_PATTERNS) {
    if ($MESSAGE -match [regex]::Escape($pattern)) {
        $DETECTED_PATTERN = $pattern
        $DETECTION_TYPE = "direct_abandonment"
        break
    }
}

# Check for passive abandonment
if (-not $DETECTED_PATTERN) {
    foreach ($pattern in $PASSIVE_ABANDONMENT_PATTERNS) {
        if ($MESSAGE -match [regex]::Escape($pattern)) {
            $DETECTED_PATTERN = $pattern
            $DETECTION_TYPE = "passive_abandonment"
            break
        }
    }
}

# Check for permission-seeking (only when there's an active task)
if (-not $DETECTED_PATTERN) {
    $activeSession = Get-CurrentSession
    $activeTask = Get-CurrentTask

    if ($activeSession -and $activeTask) {
        foreach ($pattern in $PERMISSION_SEEKING_PATTERNS) {
            if ($MESSAGE -match [regex]::Escape($pattern)) {
                $DETECTED_PATTERN = $pattern
                $DETECTION_TYPE = "permission_seeking"
                break
            }
        }
    }
}

# If no abandonment detected, allow
if (-not $DETECTED_PATTERN) {
    exit 0
}

# ============================================================================
# ABANDONMENT RESPONSE
# ============================================================================

Write-HookWarn "persistence" "Abandonment attempt detected ($DETECTION_TYPE): '$DETECTED_PATTERN'"

# Get current task info
$TASK_ID = Get-CurrentTask
if (-not $TASK_ID) { $TASK_ID = "unknown" }

# Log to abandonment file
if (-not (Test-Path (Split-Path $ABANDONMENT_LOG -Parent))) {
    New-Item -ItemType Directory -Path (Split-Path $ABANDONMENT_LOG -Parent) -Force | Out-Null
}
$timestamp = Get-Date -Format "o"
"[$timestamp] $DETECTION_TYPE`: '$DETECTED_PATTERN' (task: $TASK_ID)" | Add-Content $ABANDONMENT_LOG

# Count abandonment attempts
$ATTEMPT_COUNT = 0
if (Test-Path $ABANDONMENT_LOG) {
    $ATTEMPT_COUNT = (Get-Content $ABANDONMENT_LOG | Measure-Object -Line).Lines
}

Write-HookInfo "persistence" "Abandonment attempt #$ATTEMPT_COUNT for task: $TASK_ID"

# Escape values for safe JSON embedding
$SafePattern = ConvertTo-SafeJsonString $DETECTED_PATTERN
$SafeType = ConvertTo-SafeJsonString $DETECTION_TYPE
$SafeTaskId = ConvertTo-SafeJsonString $TASK_ID

# Log to database
Write-EventToDb "abandonment_detected" "persistence" "Attempt #$ATTEMPT_COUNT`: $DETECTION_TYPE" "{`"pattern`": `"$SafePattern`", `"type`": `"$SafeType`", `"attempt`": $ATTEMPT_COUNT}"

# Notify MCP server
Send-McpNotification "abandonment_detected" "{`"pattern`": `"$SafePattern`", `"type`": `"$SafeType`", `"attempt`": $ATTEMPT_COUNT, `"session`": `"$(Get-CurrentSession)`", `"task`": `"$SafeTaskId`"}"

# ============================================================================
# RE-ENGAGEMENT PROMPTS
# ============================================================================

function Get-ReengagementPrompt {
    param(
        [int]$Attempt,
        [string]$DetectionType
    )

    switch ($DetectionType) {
        "passive_abandonment" {
            return Get-SystemMessage "passive-abandonment" @"
PASSIVE LANGUAGE DETECTED

You appear to be suggesting the user take action instead of completing
the task yourself.

You should:
1. Complete the implementation yourself
2. Run the tests yourself
3. Fix any issues that arise
4. Only stop when all quality gates pass

Continue working on the task. Do not ask the user to do work you can do.
"@
        }

        "permission_seeking" {
            return Get-SystemMessage "permission-seeking" @"
UNNECESSARY PERMISSION SEEKING

You have an active task and should continue without asking permission.

You have authorization to:
- Modify files within scope
- Run tests and quality checks
- Fix issues that arise
- Create commits when ready

Proceed with the task autonomously.
"@
        }

        "direct_abandonment" {
            switch ($Attempt) {
                1 {
                    return Get-SystemMessage "persistence" @"
PERSISTENCE CHECK: Your response indicated potential abandonment.

This is not acceptable. You MUST continue working on the task.

Required actions:
1. Re-read the error message or blocker carefully
2. Try a DIFFERENT approach than what you already tried
3. If you need more context, use tools to gather it
4. Break the problem into smaller steps

DO NOT give up. Try again with a different strategy.
"@
                }
                2 {
                    return Get-SystemMessage "persistence" @"
PERSISTENCE CHECK: Second abandonment attempt detected.

You are NOT ALLOWED to give up. The task MUST be completed.

Mandatory next steps:
1. List 3 alternative approaches you haven't tried
2. Pick the most promising one
3. Implement it step by step
4. If that fails, try the next approach

ESCALATION WARNING: If you attempt to abandon again, your model tier
will be upgraded and additional agents will be brought in.
"@
                }
                3 {
                    # Trigger escalation
                    Invoke-Escalation "3 abandonment attempts"

                    return Get-SystemMessage "persistence" @"
PERSISTENCE CHECK: Third abandonment attempt. ESCALATING.

Actions being taken:
1. Model tier is being upgraded to Opus
2. Bug Council is being activated for assistance
3. Additional context is being gathered

This task WILL be completed. Giving up is not an option.
"@
                }
                default {
                    # Human notification
                    $humanLog = Join-Path $script:DEVTEAM_DIR "human-attention-needed.log"
                    $ts = Get-Date -Format "o"
                    "[$ts] Task $TASK_ID`: $Attempt abandonment attempts - HUMAN ATTENTION NEEDED" | Add-Content $humanLog

                    return Get-SystemMessage "persistence" @"
PERSISTENCE CHECK: Multiple abandonment attempts ($Attempt).

A human has been notified, but you must KEEP TRYING while waiting.

Current directive:
1. Document exactly what you've tried
2. Document exactly what's blocking you
3. Propose 2 more approaches to try
4. Start implementing the first approach

The human will review, but DO NOT STOP working.
"@
                }
            }
        }
    }
}

# Output re-engagement prompt
$prompt = Get-ReengagementPrompt -Attempt $ATTEMPT_COUNT -DetectionType $DETECTION_TYPE
Write-Output $prompt

# Block and force continuation
exit 2
