---
name: devteam-design
description: Coordinate UX/UI design work across platforms. Launches the UX System Coordinator to orchestrate design specialists.
argument-hint: [target] [--platform <web|mobile|desktop|all>] [--system] [--eco] [--skip-interview]
user-invocable: true
allowed-tools: Read, Edit, Write, Glob, Grep, Bash, Task
model: opus
---

Current session: !`source scripts/state.sh && get_current_session 2>/dev/null || echo "No active session"`
Active sprint: !`source scripts/state.sh && get_kv_state "active_sprint" 2>/dev/null || echo "None"`
Failure count: !`source scripts/state.sh && get_kv_state "consecutive_failures" 2>/dev/null || echo "0"`

# DevTeam Design Command

**Command:** `/devteam:design [target] [options]`

Coordinate UX/UI design work across platforms. Launches the UX System Coordinator to orchestrate design specialists.

## Usage

```bash
# Design for current task/sprint
/devteam:design

# Design specific component
/devteam:design "User settings page"

# Platform-specific design
/devteam:design "Navigation" --platform web
/devteam:design "Navigation" --platform mobile
/devteam:design "Navigation" --platform desktop

# Design system work
/devteam:design --system
/devteam:design --system "Color palette refresh"

# Cost-optimized
/devteam:design "Login form" --eco
```

## Options

| Option | Description |
|--------|-------------|
| `--platform <platform>` | Target platform: web, mobile, desktop, all |
| `--system` | Focus on design system architecture |
| `--eco` | Cost-optimized execution |
| `--skip-interview` | Skip clarifying questions |

## Your Process

### Phase 0: Initialize Session

```bash
source scripts/state.sh
source scripts/events.sh

SESSION_ID=$(start_session "/devteam:design $*" "design")
log_session_started "/devteam:design $*" "design"
```

### Phase 1: Launch UX System Coordinator

Delegate to the `ux:ux-system-coordinator` agent, which will:

1. Analyze design requirements
2. Select appropriate UX specialists based on platform
3. Coordinate design system architecture if needed
4. Ensure consistency across components
5. Validate against design system tokens and patterns

```javascript
const result = await Task({
    subagent_type: "ux:ux-system-coordinator",
    prompt: `Design coordination request: ${target}

        Platform: ${platform || 'auto-detect'}
        Design system mode: ${systemMode}

        Coordinate the appropriate UX specialists to produce:
        1. Component specifications
        2. Layout and interaction patterns
        3. Design tokens (colors, typography, spacing)
        4. Accessibility requirements
        5. Responsive behavior specifications`
})
```

### Phase 2: Quality Gates

- Design consistency check against existing design system
- Accessibility compliance validation
- Cross-platform consistency (if multi-platform)

### Phase 3: Completion

```javascript
log_session_ended('completed', 'Design work complete')
end_session('completed', 'Success')
```

## See Also

- `/devteam:design-drift` - Check for design inconsistencies
- `/devteam:implement` - Implement designed components
- `/devteam:plan` - Create plans that include design tasks
