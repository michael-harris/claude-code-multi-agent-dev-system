# DevTeam Scope Check Hook (PowerShell)
# Validates git commits against task scope
#
# Exit codes:
#   0 = Commit allowed
#   1 = Commit blocked (scope violation)

$ErrorActionPreference = "Stop"

# Source common library
. "$PSScriptRoot\lib\hook-common.ps1"

Initialize-Hook "scope-check"

# ============================================================================
# CONFIGURATION
# ============================================================================

$CURRENT_TASK_FILE = Join-Path $script:DEVTEAM_DIR "current-task.txt"

# ============================================================================
# SENSITIVE FILE PATTERNS
# ============================================================================

$SENSITIVE_PATTERNS = @(
    ".env",
    ".env.*",
    "*.env",
    "*credentials*",
    "*secret*",
    "*password*",
    "*.pem",
    "*.key",
    "*.p12",
    "*.pfx",
    "*token*",
    ".aws\*",
    ".ssh\*",
    "*_rsa",
    "*_dsa",
    "*_ecdsa",
    "*_ed25519",
    "id_rsa*",
    "*.keystore",
    "*.jks"
)

# ============================================================================
# GET TASK SCOPE
# ============================================================================

function Get-TaskScope {
    param([string]$TaskId)

    # Try database first
    if (Test-DatabaseExists) {
        $scope = Invoke-DbQuery "SELECT scope_files FROM tasks WHERE id = '$TaskId';"
        if ($scope) {
            return $scope -split ','
        }
    }

    # Try task file (JSON format)
    $taskDirs = @("docs\planning\tasks", "docs\tasks", ".devteam\tasks")
    $taskFile = $null

    foreach ($dir in $taskDirs) {
        $path = Join-Path $script:DEVTEAM_ROOT $dir "$TaskId.json"
        if (Test-Path $path) {
            $taskFile = $path
            break
        }
    }

    if (-not $taskFile) { return @() }

    # Parse JSON for scope
    $scope = @()
    $json = Get-Content $taskFile -Raw | ConvertFrom-Json

    if ($json.scope) {
        if ($json.scope.allowed_files) {
            foreach ($f in $json.scope.allowed_files) { $scope += "+$f" }
        }
        if ($json.scope.allowed_patterns) {
            foreach ($p in $json.scope.allowed_patterns) { $scope += "+$p" }
        }
        if ($json.scope.forbidden_files) {
            foreach ($f in $json.scope.forbidden_files) { $scope += "-$f" }
        }
        if ($json.scope.forbidden_directories) {
            foreach ($d in $json.scope.forbidden_directories) { $scope += "!$d" }
        }
    }

    return $scope
}

# ============================================================================
# SCOPE VALIDATION
# ============================================================================

function Test-FileAgainstScope {
    param(
        [string]$File,
        [array]$Scope
    )

    $allowedFound = $false
    $forbiddenMatch = $null

    foreach ($line in $Scope) {
        if (-not $line) { continue }

        $prefix = $line.Substring(0,1)
        $pattern = $line.Substring(1)

        switch ($prefix) {
            "+" {
                # Allowed pattern
                $regex = $pattern -replace '\*\*', '.*' -replace '\*', '[^/\\]*'
                if ($File -eq $pattern -or $File -match "^$regex$") {
                    $allowedFound = $true
                }
            }
            "-" {
                # Forbidden file
                if ($File -eq $pattern) {
                    $forbiddenMatch = "Explicitly forbidden file"
                }
            }
            "!" {
                # Forbidden directory
                $normalizedDir = $pattern.TrimEnd('/\')
                if ($File -like "$normalizedDir\*" -or $File -like "$normalizedDir/*") {
                    $forbiddenMatch = "In forbidden directory: $pattern"
                }
            }
        }
    }

    if ($forbiddenMatch) {
        return @{ Allowed = $false; Reason = $forbiddenMatch }
    }

    $hasAllowedRules = ($Scope | Where-Object { $_.StartsWith("+") }).Count -gt 0
    if ($hasAllowedRules) {
        if ($allowedFound) {
            return @{ Allowed = $true; Reason = $null }
        } else {
            return @{ Allowed = $false; Reason = "Not in allowed_files or allowed_patterns" }
        }
    }

    return @{ Allowed = $true; Reason = $null }
}

# ============================================================================
# SENSITIVE FILE CHECK
# ============================================================================

function Test-SensitiveFiles {
    param([array]$Files)

    $warnings = @()

    foreach ($file in $Files) {
        foreach ($pattern in $SENSITIVE_PATTERNS) {
            if ($file -like $pattern -or (Split-Path $file -Leaf) -like $pattern) {
                $warnings += $file
                break
            }
        }
    }

    if ($warnings.Count -gt 0) {
        Write-HookWarn "scope-check" "Sensitive files in commit: $($warnings -join ', ')"
        Write-Host ""
        Write-Host "WARNING: Potentially sensitive files detected:" -ForegroundColor Yellow
        foreach ($file in $warnings) {
            Write-Host "  ! $file" -ForegroundColor Yellow
        }
        Write-Host ""
        Write-Host "Please verify these files don't contain secrets."
        Write-Host ""
    }
}

# ============================================================================
# MAIN EXECUTION
# ============================================================================

# Get current task ID
$taskId = $null
if (Test-Path $CURRENT_TASK_FILE) {
    $taskId = (Get-Content $CURRENT_TASK_FILE -Raw).Trim()
}

if (-not $taskId) {
    Write-Host "! No task context found. Scope check skipped." -ForegroundColor Yellow
    exit 0
}

Write-HookDebug "scope-check" "Checking scope for task: $taskId"

# Get scope
$scope = Get-TaskScope $taskId

if ($scope.Count -eq 0) {
    Write-Host "! No scope defined for task $taskId. Scope check skipped." -ForegroundColor Yellow
    exit 0
}

Write-Host "Checking scope for task: $taskId"
Write-Host ""

# Get staged files
$stagedFiles = git diff --cached --name-only --diff-filter=ACMR 2>$null
if (-not $stagedFiles) {
    Write-Host "No files staged for commit." -ForegroundColor Green
    exit 0
}

$stagedFileList = $stagedFiles -split "`n" | Where-Object { $_ }

# Check sensitive files
Test-SensitiveFiles $stagedFileList

# Track violations
$violations = @()
$fileCount = 0

foreach ($file in $stagedFileList) {
    $fileCount++
    $result = Test-FileAgainstScope $file $scope

    if ($result.Allowed) {
        Write-Host "  ok $file" -ForegroundColor Green
    } else {
        $violations += @{ File = $file; Reason = $result.Reason }
        Write-Host "  X $file" -ForegroundColor Red
        Write-Host "      Reason: $($result.Reason)"
    }
}

Write-Host ""

# Report results
if ($violations.Count -gt 0) {
    Write-HookError "scope-check" "$($violations.Count) scope violations"
    Write-EventToDb "scope_violation" "error" "Commit blocked: $($violations.Count) out-of-scope files"

    Write-Host "========================================" -ForegroundColor Red
    Write-Host "  SCOPE VIOLATION - COMMIT BLOCKED" -ForegroundColor Red
    Write-Host "========================================" -ForegroundColor Red
    Write-Host ""
    Write-Host "Task: $taskId"
    Write-Host "Violations: $($violations.Count)"
    Write-Host ""
    Write-Host "Out-of-scope changes:"
    foreach ($v in $violations) {
        Write-Host "  X $($v.File)" -ForegroundColor Red
        Write-Host "      $($v.Reason)"
    }
    Write-Host ""
    Write-Host "To fix:"
    Write-Host "  1. Revert out-of-scope files:"
    foreach ($v in $violations) {
        Write-Host "     git checkout -- $($v.File)"
    }
    Write-Host ""
    Write-Host "  2. Or update task scope if changes are truly required"
    Write-Host ""

    $safeTaskId = ConvertTo-SafeJsonString $taskId
    Send-McpNotification "scope_violation" "{`"task`": `"$safeTaskId`", `"violations`": $($violations.Count)}"
    exit 1
} else {
    Write-HookInfo "scope-check" "Commit scope validated: $fileCount files"

    Write-Host "========================================" -ForegroundColor Green
    Write-Host "  SCOPE CHECK PASSED" -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "All $fileCount files are within task scope."

    $safeTaskId = ConvertTo-SafeJsonString $taskId
    Send-McpNotification "commit_validated" "{`"task`": `"$safeTaskId`", `"files`": $fileCount}"
    exit 0
}
