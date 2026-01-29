# DevTeam Skills

Skills are specialized capabilities that enhance agent performance for specific tasks.

## Skill Categories

### Core Skills (`core/`)
Fundamental development skills used across all projects.

| Skill | Description |
|-------|-------------|
| `code-reviewer.md` | Comprehensive code review checklist and patterns |
| `error-debugger.md` | Systematic debugging approaches |
| `documentation-writer.md` | Technical documentation best practices |

### Testing Skills (`testing/`)
Test generation and quality assurance.

| Skill | Description |
|-------|-------------|
| `test-generator.md` | Automatic test case generation |
| `e2e-testing.md` | End-to-end testing patterns |
| `test-data-generator.md` | Generate realistic test data |

### Quality Skills (`quality/`)
Code quality and performance optimization.

| Skill | Description |
|-------|-------------|
| `performance-optimizer.md` | Performance analysis and optimization |
| `security-scanner.md` | OWASP Top 10 and vulnerability detection |
| `accessibility-auditor.md` | WCAG compliance checking |

### Workflow Skills (`workflow/`)
Development workflow and DevOps.

| Skill | Description |
|-------|-------------|
| `git-specialist.md` | Advanced git operations |
| `ci-cd-engineer.md` | Pipeline design and optimization |
| `deployment-manager.md` | Deployment strategies |

### Frontend Skills (`frontend/`)
UI/UX and frontend development.

| Skill | Description |
|-------|-------------|
| `ui-ux-pro-max.md` | 67 styles, 96 color palettes, design systems |
| `component-designer.md` | Reusable component patterns |
| `responsive-design.md` | Mobile-first responsive design |

### Meta Skills (`meta/`)
Skills for improving AI agent performance.

| Skill | Description |
|-------|-------------|
| `prompt-engineer.md` | Craft effective agent prompts |
| `task-decomposer.md` | Break complex tasks into subtasks |
| `context-manager.md` | Manage context across sessions |

## Skill Activation

Skills activate automatically based on:
- Task type detection
- User commands
- Agent requests
- Keyword matching

## Using Skills

### Automatic Activation
Skills are loaded when relevant keywords or patterns are detected in tasks.

### Manual Activation
```bash
# Request specific skill
/devteam:skill security-scanner

# List available skills
/devteam:skills
```

### In Agent Prompts
```markdown
## Skills Required
- security-scanner (for auth code)
- test-generator (for new functions)
- performance-optimizer (for database queries)
```

## Creating New Skills

### Skill Template

```markdown
# [Skill Name] Skill

[Brief description of what this skill does]

## Activation

This skill activates when:
- [trigger condition 1]
- [trigger condition 2]
- [trigger condition 3]

## Capabilities

### [Capability 1]
[Description and examples]

### [Capability 2]
[Description and examples]

## Process

1. [Step 1]
2. [Step 2]
3. [Step 3]

## Output Format

[Expected output structure]

## Quality Checks

- [ ] [Check 1]
- [ ] [Check 2]
- [ ] [Check 3]
```

### Skill Guidelines

1. **Focused**: Each skill should do one thing well
2. **Actionable**: Include concrete steps and examples
3. **Measurable**: Define quality checks
4. **Composable**: Skills should work together

## Skill Combinations

Common skill combinations for different scenarios:

### New Feature Development
- `code-reviewer` + `test-generator` + `documentation-writer`

### Bug Fixing
- `error-debugger` + `git-specialist` + `test-generator`

### Performance Work
- `performance-optimizer` + `security-scanner` + `test-generator`

### UI Development
- `ui-ux-pro-max` + `accessibility-auditor` + `responsive-design`

### DevOps Tasks
- `ci-cd-engineer` + `deployment-manager` + `git-specialist`

## Contributing Skills

1. Create skill file in appropriate category
2. Follow the template structure
3. Include practical examples
4. Add quality checks
5. Update this README
