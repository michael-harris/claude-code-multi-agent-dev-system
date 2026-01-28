# DevTeam Hook Scripts

Claude Code hooks that enable autonomous execution and session persistence.

## Overview

These hooks integrate with Claude Code's hook system to provide:
- Autonomous execution until completion
- Session memory persistence
- State preservation across context compaction
- Automatic project language detection

## Installation

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
    "PreToolUse": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "/path/to/project/hooks/session-start.sh"
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
            "command": "/path/to/project/hooks/session-end.sh"
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

## Hook Descriptions

### stop-hook.sh

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
```bash
# Create marker file to enable
touch .devteam/autonomous-mode

# Or use /devteam:auto command which creates it automatically
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

## State Files

The hooks read/write these files:

| File | Purpose |
|------|---------|
| `.devteam/state.yaml` | Main state tracking |
| `.devteam/autonomous-mode` | Autonomous mode marker |
| `.devteam/circuit-breaker.json` | Failure tracking |
| `.devteam/memory/*.md` | Session memory files |

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

### Hooks not executing

1. Verify hooks are executable:
```bash
chmod +x hooks/*.sh
```

2. Check hook paths in settings.json are absolute paths

3. Verify Claude Code version supports hooks

### Autonomous mode not working

1. Ensure marker file exists:
```bash
ls -la .devteam/autonomous-mode
```

2. Check circuit breaker isn't open:
```bash
cat .devteam/circuit-breaker.json
```

3. Verify max iterations not exceeded

### Memory not persisting

1. Check `.devteam/memory/` directory exists
2. Verify write permissions
3. Look for errors in hook output

## Dependencies

- `bash` (4.0+)
- `yq` (optional, for YAML parsing - falls back to grep)
- `jq` (optional, for JSON parsing - falls back to grep)
- `date`, `mkdir`, `cat`, `grep` (standard Unix tools)

## Security Notes

- Hooks run with user permissions
- State files may contain project details
- Add `.devteam/` to `.gitignore` for sensitive projects
