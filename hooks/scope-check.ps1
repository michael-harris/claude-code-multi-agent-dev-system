# DevTeam Scope Check Hook (PowerShell)
# Validates that commits stay within assigned task scope
#
# Exit codes:
#   0 = All changes within scope, commit allowed
#   1 = Scope violation detected, commit blocked

$ErrorActionPreference = "Stop"

# Configuration
$CURRENT_TASK_FILE = ".devteam\current-task.txt"
$TASKS_DIR = "docs\planning\tasks"

# Logging function
function Write-Log {
    param([string]$Message)
    Write-Host "[Scope Check] $Message"
}

# Get current task ID
if (-not (Test-Path $CURRENT_TASK_FILE)) {
    Write-Log "No current task file found. Skipping scope check."
    exit 0
}

$TASK_ID = (Get-Content $CURRENT_TASK_FILE -Raw).Trim()
if ([string]::IsNullOrEmpty($TASK_ID)) {
    Write-Log "No task ID found. Skipping scope check."
    exit 0
}

Write-Log "Checking scope for task: $TASK_ID"

# Find task definition file
$TASK_FILE = Join-Path $TASKS_DIR "$TASK_ID.yaml"
if (-not (Test-Path $TASK_FILE)) {
    Write-Log "Task file not found: $TASK_FILE. Skipping scope check."
    exit 0
}

# Parse task file for scope (simple YAML parsing)
$taskContent = Get-Content $TASK_FILE -Raw

# Extract scope section
$inScope = $false
$allowedFiles = @()
$allowedPatterns = @()
$forbiddenFiles = @()
$forbiddenDirectories = @()

foreach ($line in (Get-Content $TASK_FILE)) {
    if ($line -match "^scope:") {
        $inScope = $true
        continue
    }

    if ($inScope) {
        # Check for end of scope section (non-indented line)
        if ($line -match "^[a-z]" -and $line -notmatch "^\s") {
            $inScope = $false
            continue
        }

        # Parse allowed_files
        if ($line -match '^\s+allowed_files:') {
            $currentList = "allowed_files"
            continue
        }
        if ($line -match '^\s+allowed_patterns:') {
            $currentList = "allowed_patterns"
            continue
        }
        if ($line -match '^\s+forbidden_files:') {
            $currentList = "forbidden_files"
            continue
        }
        if ($line -match '^\s+forbidden_directories:') {
            $currentList = "forbidden_directories"
            continue
        }

        # Parse list items
        if ($line -match '^\s+-\s+"?([^"]+)"?') {
            $item = $matches[1]
            switch ($currentList) {
                "allowed_files" { $allowedFiles += $item }
                "allowed_patterns" { $allowedPatterns += $item }
                "forbidden_files" { $forbiddenFiles += $item }
                "forbidden_directories" { $forbiddenDirectories += $item }
            }
        }
    }
}

# If no scope defined, allow all
if ($allowedFiles.Count -eq 0 -and $allowedPatterns.Count -eq 0) {
    Write-Log "No scope restrictions defined. Allowing commit."
    exit 0
}

# Get staged files
$stagedFiles = git diff --cached --name-only 2>$null
if ([string]::IsNullOrEmpty($stagedFiles)) {
    Write-Log "No staged files. Allowing commit."
    exit 0
}

$stagedFileList = $stagedFiles -split "`n" | Where-Object { $_ }

# Check each staged file against scope
$violations = @()

foreach ($file in $stagedFileList) {
    $isAllowed = $false

    # Check forbidden directories first
    foreach ($forbiddenDir in $forbiddenDirectories) {
        $normalizedDir = $forbiddenDir.TrimEnd('/\')
        if ($file -like "$normalizedDir*" -or $file -like "$normalizedDir\*" -or $file -like "$normalizedDir/*") {
            $violations += "FORBIDDEN DIRECTORY: $file (in $forbiddenDir)"
            continue
        }
    }

    # Check forbidden files
    foreach ($forbiddenFile in $forbiddenFiles) {
        if ($file -eq $forbiddenFile) {
            $violations += "FORBIDDEN FILE: $file"
            continue
        }
    }

    # Check allowed files (exact match)
    foreach ($allowedFile in $allowedFiles) {
        if ($file -eq $allowedFile) {
            $isAllowed = $true
            break
        }
    }

    # Check allowed patterns (glob-style)
    if (-not $isAllowed) {
        foreach ($pattern in $allowedPatterns) {
            # Convert glob to PowerShell wildcard
            $psPattern = $pattern -replace '\*\*', '**DOUBLESTAR**'
            $psPattern = $psPattern -replace '\*', '*'
            $psPattern = $psPattern -replace '\*\*DOUBLESTAR\*\*', '*'

            if ($file -like $psPattern) {
                $isAllowed = $true
                break
            }
        }
    }

    # If not explicitly allowed and we have scope restrictions, it's a violation
    if (-not $isAllowed -and ($allowedFiles.Count -gt 0 -or $allowedPatterns.Count -gt 0)) {
        # Check if it wasn't already flagged as forbidden
        $alreadyViolation = $violations | Where-Object { $_ -match [regex]::Escape($file) }
        if (-not $alreadyViolation) {
            $violations += "OUT OF SCOPE: $file"
        }
    }
}

# Report results
if ($violations.Count -gt 0) {
    Write-Log "========================================"
    Write-Log "SCOPE VIOLATION DETECTED - COMMIT BLOCKED"
    Write-Log "========================================"
    Write-Log ""
    Write-Log "Task: $TASK_ID"
    Write-Log ""
    Write-Log "Violations:"
    foreach ($v in $violations) {
        Write-Log "  - $v"
    }
    Write-Log ""
    Write-Log "Allowed files:"
    foreach ($f in $allowedFiles) {
        Write-Log "  - $f"
    }
    Write-Log ""
    Write-Log "Allowed patterns:"
    foreach ($p in $allowedPatterns) {
        Write-Log "  - $p"
    }
    Write-Log ""
    Write-Log "To proceed, either:"
    Write-Log "  1. Unstage the out-of-scope files"
    Write-Log "  2. Update the task scope in $TASK_FILE"
    Write-Log "  3. Log observations to .devteam\out-of-scope-observations.md"
    Write-Log ""

    exit 1
}

Write-Log "All $($stagedFileList.Count) staged files are within scope. Commit allowed."
exit 0
