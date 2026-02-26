# DevTeam Config Command

**Command:** `/devteam:config [action] [key] [value]`

View and modify DevTeam configuration settings.

## Usage

```bash
/devteam:config                           # Show current configuration
/devteam:config show                      # Same as above
/devteam:config get eco.enabled           # Get specific setting
/devteam:config set eco.enabled true      # Set specific setting
/devteam:config reset                     # Reset to defaults
/devteam:config init                      # Initialize configuration
```

## Actions

| Action | Description |
|--------|-------------|
| `show` | Display all configuration (default) |
| `get <key>` | Get a specific setting |
| `set <key> <value>` | Set a specific setting |
| `reset` | Reset all settings to defaults |
| `init` | Initialize configuration for new project |

## Configuration Options

### Execution Settings
| Key | Type | Default | Description |
|-----|------|---------|-------------|
| `execution.mode` | string | `normal` | Default mode: normal, eco |
| `execution.max_iterations` | int | `10` | Max Task Loop iterations |
| `execution.parallel_gates` | bool | `true` | Run quality gates in parallel |

### Model Settings
| Key | Type | Default | Description |
|-----|------|---------|-------------|
| `models.escalation_threshold` | int | `2` | Failures before escalation |
| `models.eco_threshold` | int | `4` | Escalation threshold in eco mode |

### Quality Gates
| Key | Type | Default | Description |
|-----|------|---------|-------------|
| `gates.tests.enabled` | bool | `true` | Run tests |
| `gates.tests.command` | string | `auto` | Test command (auto-detect) |
| `gates.lint.enabled` | bool | `true` | Run linting |
| `gates.typecheck.enabled` | bool | `true` | Run type checking |
| `gates.security.enabled` | bool | `false` | Run security scan |

### Interview Settings
| Key | Type | Default | Description |
|-----|------|---------|-------------|
| `interview.enabled` | bool | `true` | Enable interview phase |
| `interview.max_questions` | int | `5` | Max questions per interview |
| `interview.skip_for_plans` | bool | `true` | Skip for planned tasks |

### Research Settings
| Key | Type | Default | Description |
|-----|------|---------|-------------|
| `research.enabled` | bool | `true` | Enable research phase |
| `research.timeout_minutes` | int | `5` | Research timeout |

## Your Process

### Step 1: Load Configuration

```javascript
const configPath = '.devteam/config.yaml'

function loadConfig() {
    if (existsSync(configPath)) {
        return yaml.parse(readFileSync(configPath))
    }
    return getDefaultConfig()
}
```

### Step 2: Handle Actions

```javascript
switch (action) {
    case 'show':
        displayConfig(config)
        break

    case 'get':
        const value = getNestedValue(config, key)
        console.log(`${key}: ${value}`)
        break

    case 'set':
        setNestedValue(config, key, parseValue(value))
        saveConfig(config)
        console.log(`✓ Set ${key} = ${value}`)
        break

    case 'reset':
        const defaults = getDefaultConfig()
        saveConfig(defaults)
        console.log('✓ Configuration reset to defaults')
        break

    case 'init':
        await initializeConfig()
        break
}
```

### Step 3: Display Configuration

```markdown
╔═══════════════════════════════════════════════════════════════╗
║  DevTeam Configuration                                         ║
╚═══════════════════════════════════════════════════════════════╝

Execution
───────────────────────────────────────────────────────────────
  mode:              normal
  max_iterations:    10
  parallel_gates:    true

Models
───────────────────────────────────────────────────────────────
  escalation_threshold:  2
  eco_threshold:         4

Quality Gates
───────────────────────────────────────────────────────────────
  tests:      ✓ enabled (npm test)
  lint:       ✓ enabled (npm run lint)
  typecheck:  ✓ enabled (npm run typecheck)
  security:   ✗ disabled

Interview
───────────────────────────────────────────────────────────────
  enabled:           true
  max_questions:     5
  skip_for_plans:    true

Research
───────────────────────────────────────────────────────────────
  enabled:           true
  timeout_minutes:   5

───────────────────────────────────────────────────────────────
Config file: .devteam/config.yaml
Edit: /devteam:config set <key> <value>
```

### Step 4: Initialize Configuration

```javascript
async function initializeConfig() {
    // Detect project type
    const projectType = await detectProjectType()

    // Ask configuration questions
    const answers = await interview([
        {
            key: 'execution.mode',
            question: 'Default execution mode?',
            options: ['normal', 'eco'],
            default: 'normal'
        },
        {
            key: 'gates.security.enabled',
            question: 'Enable security scanning?',
            type: 'boolean',
            default: false
        }
    ])

    // Generate config based on project
    const config = {
        ...getDefaultConfig(),
        ...answers,
        project: {
            type: projectType.type,
            language: projectType.language,
            detected: new Date().toISOString()
        }
    }

    // Save configuration
    mkdirSync('.devteam', { recursive: true })
    saveConfig(config)

    console.log(`
✓ Configuration initialized

  Project type: ${projectType.type}
  Language: ${projectType.language}
  Config file: .devteam/config.yaml

Edit settings: /devteam:config set <key> <value>
View settings: /devteam:config show
`)
}
```

## Examples

```bash
# Enable eco mode by default
/devteam:config set execution.mode eco

# Increase max iterations
/devteam:config set execution.max_iterations 15

# Disable security scanning
/devteam:config set gates.security.enabled false

# Change escalation threshold
/devteam:config set models.escalation_threshold 3
```

## Config File Location

Configuration is stored in `.devteam/config.yaml`:

```yaml
version: "3.0"

execution:
  mode: normal
  max_iterations: 10
  parallel_gates: true

models:
  default_tier: auto
  escalation_threshold: 2
  eco_threshold: 4

gates:
  tests:
    enabled: true
    command: auto
  lint:
    enabled: true
  typecheck:
    enabled: true
  security:
    enabled: false

interview:
  enabled: true
  max_questions: 5
  skip_for_plans: true

research:
  enabled: true
  timeout_minutes: 5
```

## See Also

- `/devteam:status` - View system status
- `/devteam:reset` - Reset system state
