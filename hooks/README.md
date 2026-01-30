# DevTeam Hook Scripts

Claude Code hooks that enable autonomous execution and session persistence.

## Overview

These hooks integrate with Claude Code's hook system to provide:
- Autonomous execution until completion
- Session memory persistence
- State preservation across context compaction
- Automatic project language detection
- Anti-abandonment enforcement
- Scope validation

## Cross-Platform Support

All hooks are available in both Bash (Linux/macOS) and PowerShell (Windows) versions:

| Hook | Linux/macOS | Windows |
|------|-------------|---------|
| Stop Hook | `stop-hook.sh` | `stop-hook.ps1` |
| Persistence Hook | `persistence-hook.sh` | `persistence-hook.ps1` |
| Scope Check | `scope-check.sh` | `scope-check.ps1` |
| Session Start | `session-start.sh` | (coming soon) |
| Session End | `session-end.sh` | (coming soon) |
| Pre-Compact | `pre-compact.sh` | (coming soon) |

## Installation

### Linux / macOS

Add to your `~/.claude/settings.json` or project `.claude/settings.json`:

```json
{
  "hooks": {
    "Stop": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "/path/to/project/hooks/stop-hook.sh"
          }
        ]
      }
    ],
    "PostToolUse": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "/path/to/project/hooks/persistence-hook.sh"
          }
        ]
      }
    ],
    "PreCompact": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "/path/to/project/hooks/pre-compact.sh"
          }
        ]
      }
    ]
  }
}
```

Make hooks executable:
```bash
chmod +x hooks/*.sh
```

### Windows (PowerShell)

Add to your `%USERPROFILE%\.claude\settings.json` or project `.claude\settings.json`:

```json
{
  "hooks": {
    "Stop": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "powershell.exe -ExecutionPolicy Bypass -File C:\\path\\to\\project\\hooks\\stop-hook.ps1"
          }
        ]
      }
    ],
    "PostToolUse": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "powershell.exe -ExecutionPolicy Bypass -File C:\\path\\to\\project\\hooks\\persistence-hook.ps1"
          }
        ]
      }
    ]
  }
}
```

**Important Windows Notes:**
- Use full absolute paths with backslashes
- Include `-ExecutionPolicy Bypass` to allow script execution
- PowerShell 5.1+ or PowerShell Core 7+ required

### WSL (Windows Subsystem for Linux)

If using WSL, you can use the Bash scripts directly:
```json
{
  "hooks": {
    "Stop": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "wsl /path/to/project/hooks/stop-hook.sh"
          }
        ]
      }
    ]
  }
}
```

## Hook Descriptions

### persistence-hook.sh / persistence-hook.ps1

**Purpose**: Detects and prevents premature task abandonment.

**Behavior**:
1. Analyzes Claude's output for "give up" patterns
2. Detects phrases like "I cannot", "I give up", "You should manually"
3. Blocks abandonment and injects re-engagement prompts
4. Escalates model tier after repeated attempts
5. Activates Bug Council if agent remains stuck

**Exit Codes**:
- `0`: Allow (output acceptable, no abandonment detected)
- `2`: Block and re-engage (detected abandonment attempt)

**Abandonment Response Escalation**:
| Attempt | Response |
|---------|----------|
| 1st | Gentle redirect - try different approach |
| 2nd | Forceful redirect - list 3 alternatives, warning |
| 3rd | Model upgrade + additional agent |
| 4th | Bug Council activation |
| 5th+ | Human notification (but keep trying) |

**Configuration**: See `.devteam/persistence-config.yaml`

### stop-hook.sh / stop-hook.ps1

**Purpose**: Implements Ralph-style autonomous execution loop.

**Behavior**:
1. Checks for `EXIT_SIGNAL: true` in Claude's output
2. If not found and autonomous mode active, blocks exit (exit code 2)
3. Monitors circuit breaker for consecutive failures
4. Tracks iteration count against maximum

**Exit Codes**:
- `0`: Allow exit (work complete or autonomous mode disabled)
- `2`: Block exit and continue (re-inject prompt)

**Autonomous Mode Activation**:

Linux/macOS:
```bash
# Create marker file to enable
touch .devteam/autonomous-mode

# Or use /devteam:implement command which creates it automatically
```

Windows PowerShell:
```powershell
# Create marker file to enable
New-Item -ItemType File -Path .devteam\autonomous-mode -Force

# Or use /devteam:implement command which creates it automatically
```

### session-start.sh

**Purpose**: Initialize session context at startup.

**Behavior**:
1. Detects project languages from file extensions
2. Identifies package managers in use
3. Loads previous session memory if available
4. Outputs context for Claude to use

**Detection**:
- Languages: Python, TypeScript, JavaScript, Go, Rust, Java, C#, Ruby, PHP
- Package Managers: uv, poetry, pip, npm, pnpm, yarn, bun, cargo, go mod

### session-end.sh

**Purpose**: Persist session memory on exit.

**Behavior**:
1. Saves session summary to `.devteam/memory/session-{timestamp}.md`
2. Cleans up old memory files (keeps last 10)
3. Records project state snapshot

### pre-compact.sh

**Purpose**: Preserve critical state before context compaction.

**Behavior**:
1. Saves current task/sprint context
2. Records autonomous mode status
3. Captures circuit breaker state
4. Outputs recovery instructions

### scope-check.sh / scope-check.ps1

**Purpose**: Enforce strict scope compliance at commit time.

**Behavior**:
1. Reads current task ID from `.devteam/current-task.txt`
2. Loads task scope from task definition file
3. Validates all staged files against allowed/forbidden lists
4. **BLOCKS commit if any file is out of scope**

**Exit Codes**:
- `0`: All changes within scope, commit allowed
- `1`: Scope violation detected, commit blocked

**Usage as pre-commit hook**:

Linux/macOS:
```bash
# In project .git/hooks/pre-commit
#!/bin/bash
./hooks/scope-check.sh
```

Windows:
```powershell
# In project .git/hooks/pre-commit
powershell.exe -ExecutionPolicy Bypass -File .\hooks\scope-check.ps1
```

**Or via Claude Code hooks**:
```json
{
  "hooks": {
    "PreCommit": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "/path/to/project/hooks/scope-check.sh"
          }
        ]
      }
    ]
  }
}
```

**Scope Definition in Task**:
```yaml
# docs/planning/tasks/TASK-XXX.yaml
scope:
  allowed_files:
    - "src/auth/session.ts"
  allowed_patterns:
    - "tests/auth/**/*.test.ts"
  forbidden_files:
    - "src/auth/oauth.ts"
  forbidden_directories:
    - "src/api/"
  max_files_changed: 5
```

## State Files

The hooks read/write these files:

| File | Purpose |
|------|---------|
| `.devteam/state.yaml` | Main state tracking |
| `.devteam/autonomous-mode` | Autonomous mode marker |
| `.devteam/circuit-breaker.json` | Failure tracking |
| `.devteam/memory/*.md` | Session memory files |
| `.devteam/current-task.txt` | Active task ID |
| `.devteam/abandonment-attempts.log` | Abandonment tracking |
| `.devteam/escalation-trigger` | Model escalation signals |

## Circuit Breaker

The circuit breaker prevents infinite loops:

```json
{
  "consecutive_failures": 0,
  "max_failures": 5,
  "last_failure_timestamp": null,
  "last_failure_reason": null,
  "state": "closed"
}
```

**States**:
- `closed`: Normal operation
- `open`: Too many failures, auto-exit enabled

## Troubleshooting

### Hooks not executing (Linux/macOS)

1. Verify hooks are executable:
```bash
chmod +x hooks/*.sh
```

2. Check hook paths in settings.json are absolute paths

3. Verify Claude Code version supports hooks

### Hooks not executing (Windows)

1. Verify PowerShell execution policy allows scripts:
```powershell
Get-ExecutionPolicy
# If "Restricted", the hooks need -ExecutionPolicy Bypass flag
```

2. Check paths use backslashes and are absolute

3. Verify PowerShell version:
```powershell
$PSVersionTable.PSVersion
# Should be 5.1+ or 7+
```

### Autonomous mode not working

Linux/macOS:
```bash
ls -la .devteam/autonomous-mode
cat .devteam/circuit-breaker.json
```

Windows:
```powershell
Get-Item .devteam\autonomous-mode
Get-Content .devteam\circuit-breaker.json
```

### Memory not persisting

1. Check `.devteam/memory/` directory exists
2. Verify write permissions
3. Look for errors in hook output

## Dependencies

### Linux/macOS
- `bash` (4.0+)
- `yq` (optional, for YAML parsing - falls back to grep)
- `jq` (optional, for JSON parsing - falls back to grep)
- `date`, `mkdir`, `cat`, `grep` (standard Unix tools)

### Windows
- PowerShell 5.1+ or PowerShell Core 7+
- No additional dependencies (uses built-in cmdlets)

## Security Notes

- Hooks run with user permissions
- State files may contain project details
- Add `.devteam/` to `.gitignore` for sensitive projects
- On Windows, `-ExecutionPolicy Bypass` only affects the specific script execution
