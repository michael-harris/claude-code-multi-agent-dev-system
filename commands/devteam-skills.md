# DevTeam Skills Command

**Command:** `/devteam:skills [category]`

List all available skills or skills in a specific category.

## Usage

```bash
/devteam:skills                  # List all skills
/devteam:skills core             # List core skills
/devteam:skills testing          # List testing skills
/devteam:skills --verbose        # Show detailed descriptions
```

## Options

| Option | Description |
|--------|-------------|
| `--verbose` | Show full descriptions |
| `--json` | Output as JSON |
| `--category <name>` | Filter by category |

## Your Process

### Step 1: Load Skills

```javascript
const skillsDir = 'skills/'
const categories = ['core', 'testing', 'quality', 'workflow', 'frontend', 'meta']

const skills = []
for (const category of categories) {
    const files = await glob(`${skillsDir}${category}/*.md`)
    for (const file of files) {
        const content = await readFile(file)
        const metadata = parseSkillFrontmatter(content)
        skills.push({
            ...metadata,
            category,
            file: path.basename(file)
        })
    }
}
```

### Step 2: Display Skills

**Default Output:**

```markdown
╔═══════════════════════════════════════════════════════════════╗
║  DevTeam Skills                                                ║
║  18 skills available                                           ║
╚═══════════════════════════════════════════════════════════════╝

Core (3 skills)
───────────────────────────────────────────────────────────────
  code-reviewer      Review code for quality and standards
  debugger           Systematic debugging and issue diagnosis
  refactorer         Code restructuring and improvements

Testing (3 skills)
───────────────────────────────────────────────────────────────
  test-generator     Generate comprehensive unit tests
  integration-tester API and database integration tests
  e2e-tester         End-to-end browser automation tests

Quality (3 skills)
───────────────────────────────────────────────────────────────
  performance-optimizer  Performance analysis and optimization
  security-scanner       Security vulnerability scanning
  accessibility-checker  WCAG compliance auditing

Workflow (3 skills)
───────────────────────────────────────────────────────────────
  ci-cd-engineer      CI/CD pipeline configuration
  git-specialist      Git operations and history analysis
  deployment-manager  Deployment and release management

Frontend (3 skills)
───────────────────────────────────────────────────────────────
  ui-ux-pro           UI/UX design and implementation
  responsive-design   Mobile-first responsive layouts
  accessibility-expert Accessible-first development

Meta (3 skills)
───────────────────────────────────────────────────────────────
  prompt-engineer     Optimize prompts and instructions
  context-manager     Context optimization and compression
  learning-optimizer  Pattern learning and recommendations

───────────────────────────────────────────────────────────────
Usage: /devteam:skill <name> [--file <path>]
Help:  /devteam:help skills
```

**Category Filter:**

```bash
/devteam:skills testing
```

```markdown
╔═══════════════════════════════════════════════════════════════╗
║  Testing Skills (3)                                            ║
╚═══════════════════════════════════════════════════════════════╝

test-generator
  ID: testing:test-generator
  Model: sonnet
  Generate comprehensive unit tests with mocks and edge cases

integration-tester
  ID: testing:integration-tester
  Model: sonnet
  Create API and database integration tests with fixtures

e2e-tester
  ID: testing:e2e-tester
  Model: sonnet
  Build end-to-end tests with Playwright/Cypress

───────────────────────────────────────────────────────────────
Run a skill: /devteam:skill <name>
```

**Verbose Output:**

```bash
/devteam:skills --verbose
```

Shows full capability lists and activation triggers for each skill.

**JSON Output:**

```bash
/devteam:skills --json
```

```json
{
  "skills": [
    {
      "id": "core:code-reviewer",
      "name": "Code Reviewer",
      "category": "core",
      "model": "sonnet",
      "description": "Review code for quality and standards",
      "file": "code-reviewer.md",
      "capabilities": ["Code quality", "Best practices", "Security review"]
    }
  ],
  "total": 18,
  "categories": ["core", "testing", "quality", "workflow", "frontend", "meta"]
}
```

## Categories

| Category | Description |
|----------|-------------|
| `core` | Fundamental development skills |
| `testing` | Test creation and execution |
| `quality` | Code quality and security |
| `workflow` | CI/CD and git operations |
| `frontend` | UI/UX and accessibility |
| `meta` | Context and learning optimization |

## See Also

- `/devteam:skill <name>` - Execute a specific skill
- `/devteam:help skills` - Detailed skills documentation
