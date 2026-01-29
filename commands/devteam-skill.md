# DevTeam Skill Command

**Command:** `/devteam:skill <name> [options]`

Execute a specific skill with optional parameters.

## Usage

```bash
/devteam:skill debugger                    # Run debugger skill
/devteam:skill refactorer --file src/      # Run refactorer on directory
/devteam:skill accessibility-checker       # Run accessibility audit
/devteam:skill e2e-tester --coverage       # Run e2e tests with coverage
```

## Available Skills

### Core Skills
| Skill | ID | Description |
|-------|-------|-------------|
| Code Reviewer | `core:code-reviewer` | Review code for quality and standards |
| Debugger | `core:debugger` | Systematic debugging and issue diagnosis |
| Refactorer | `core:refactorer` | Code restructuring without changing functionality |

### Testing Skills
| Skill | ID | Description |
|-------|-------|-------------|
| Test Generator | `testing:test-generator` | Generate unit tests |
| Integration Tester | `testing:integration-tester` | API and database integration tests |
| E2E Tester | `testing:e2e-tester` | End-to-end browser tests |

### Quality Skills
| Skill | ID | Description |
|-------|-------|-------------|
| Performance Optimizer | `quality:performance-optimizer` | Performance analysis and optimization |
| Security Scanner | `quality:security-scanner` | Security vulnerability scanning |
| Accessibility Checker | `quality:accessibility-checker` | WCAG compliance auditing |

### Workflow Skills
| Skill | ID | Description |
|-------|-------|-------------|
| CI/CD Engineer | `workflow:ci-cd-engineer` | Pipeline configuration |
| Git Specialist | `workflow:git-specialist` | Git operations and history |
| Deployment Manager | `workflow:deployment-manager` | Deployment and release management |

### Frontend Skills
| Skill | ID | Description |
|-------|-------|-------------|
| UI/UX Pro | `frontend:ui-ux-pro` | UI/UX design and implementation |
| Responsive Design | `frontend:responsive-design` | Mobile-first responsive layouts |
| Accessibility Expert | `frontend:accessibility-expert` | Accessible-first development |

### Meta Skills
| Skill | ID | Description |
|-------|-------|-------------|
| Prompt Engineer | `meta:prompt-engineer` | Optimize prompts and instructions |
| Context Manager | `meta:context-manager` | Context optimization and compression |
| Learning Optimizer | `meta:learning-optimizer` | Pattern learning and recommendations |

## Options

| Option | Description |
|--------|-------------|
| `--file <path>` | Target specific file or directory |
| `--output <format>` | Output format: text, json, yaml |
| `--verbose` | Show detailed progress |
| `--eco` | Use cost-optimized execution |

## Your Process

### Step 1: Resolve Skill

```javascript
function resolveSkill(name) {
    // Try exact match first
    const exact = skills.find(s => s.id === name || s.name === name)
    if (exact) return exact

    // Try partial match
    const partial = skills.find(s =>
        s.id.includes(name) || s.name.toLowerCase().includes(name.toLowerCase())
    )
    if (partial) return partial

    // Suggest similar
    const similar = findSimilar(name, skills)
    throw new Error(`Skill "${name}" not found. Did you mean: ${similar.join(', ')}?`)
}
```

### Step 2: Load Skill Definition

```javascript
const skill = resolveSkill(skillName)
const definition = await readFile(`skills/${skill.category}/${skill.file}`)

// Extract skill metadata
const metadata = parseSkillFrontmatter(definition)
```

### Step 3: Execute Skill

```javascript
// Create skill execution context
const context = {
    skill: metadata,
    target: options.file || process.cwd(),
    options: options
}

// Execute with appropriate model
const model = options.eco ? 'haiku' : metadata.defaultModel

await Task({
    subagent_type: 'skill',
    model: model,
    prompt: `Execute skill: ${skill.id}
             Target: ${context.target}
             Options: ${JSON.stringify(options)}

             Skill definition:
             ${definition}`
})
```

### Step 4: Output Results

```yaml
skill_result:
  skill: "quality:accessibility-checker"
  target: "src/components/"
  duration: "45s"
  model_used: "sonnet"

  findings:
    issues_found: 12
    issues_fixed: 8
    remaining: 4

  details:
    - category: "Missing alt text"
      count: 3
      status: "fixed"
    - category: "Color contrast"
      count: 5
      status: "fixed"
    - category: "Missing labels"
      count: 4
      status: "needs_manual_review"

  recommendations:
    - "Add captions to video content"
    - "Review focus order in modal components"
```

## Examples

### Run Code Review
```bash
/devteam:skill code-reviewer --file src/services/UserService.ts
```

### Run Security Scan
```bash
/devteam:skill security-scanner --output json
```

### Run Performance Analysis
```bash
/devteam:skill performance-optimizer --file src/ --verbose
```

## Error Handling

**Skill not found:**
```
Error: Skill "debuger" not found.

Did you mean:
  - core:debugger
  - core:refactorer

Available skills: /devteam:skills
```

**Invalid target:**
```
Error: Target path "src/missing/" does not exist.

Please specify a valid file or directory.
```

## See Also

- `/devteam:skills` - List all available skills
- `/devteam:help skills` - Detailed skills documentation
