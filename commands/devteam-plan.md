# DevTeam Plan Command

**Command:** `/devteam:plan [options]`

Conduct interactive requirements gathering, research the codebase, create a PRD, and generate a development plan with tasks and sprints.

## Usage

```bash
/devteam:plan                                # Start interactive planning
/devteam:plan "Build a task manager"         # Start with description
/devteam:plan --feature "Add dark mode"      # Plan a feature for existing project
/devteam:plan --from spec.md                 # Load from single spec file
/devteam:plan --from specs/                  # Load from folder of spec files
/devteam:plan --from existing                # Auto-detect existing docs in project
/devteam:plan --skip-research                # Skip research phase
```

## Options

| Option | Description |
|--------|-------------|
| `--feature "<desc>"` | Plan a feature for existing project |
| `--from <path>` | Load from spec file or folder |
| `--skip-research` | Skip codebase research phase |
| `--skip-interview` | Skip interview (use with --from) |

## File-Based Specification Support

### Supported File Formats

| Format | Extensions | Best For |
|--------|------------|----------|
| Markdown | `.md` | Human-readable specs, PRDs |
| YAML | `.yaml`, `.yml` | Structured specs, existing PRDs |
| JSON | `.json` | API specs, structured data |
| Plain Text | `.txt` | Simple requirements lists |
| PDF | `.pdf` | Formal documents (extracted) |

### Single File Mode (`--from file.md`)

Reads a specification file and extracts:
- Project description
- Features/requirements (from headers, lists)
- Technical constraints
- User stories
- Acceptance criteria

**Example Input (`project-spec.md`):**
```markdown
# Task Manager App

## Overview
A simple task management app for teams.

## Features
- User authentication with OAuth
- Create, edit, delete tasks
- Assign tasks to team members
- Due date reminders

## Technical Requirements
- Backend: FastAPI
- Database: PostgreSQL
- Frontend: React + TypeScript
```

**Process:**
1. Read and parse file
2. Extract structured information
3. Confirm understanding with user (brief)
4. Skip redundant interview questions
5. Generate PRD from extracted data

### Folder Mode (`--from specs/`)

Reads all spec files from a folder and merges them:

```
specs/
├── overview.md           # Project overview
├── features/
│   ├── auth.md          # Authentication spec
│   ├── tasks.md         # Task management spec
│   └── notifications.md # Notification spec
├── api-design.yaml      # API specification
└── wireframes.md        # UI descriptions
```

**Process:**
1. Scan folder recursively
2. Categorize files by type/content
3. Merge into unified understanding
4. Resolve conflicts (ask user if ambiguous)
5. Generate comprehensive PRD

### Auto-Detect Mode (`--from existing`)

Searches project for existing documentation:

**Search locations:**
```
docs/                    # Common docs folder
documentation/           # Alternative name
spec/                    # Spec folder
specifications/          # Alternative name
requirements/            # Requirements folder
*.md in root            # README, CONTRIBUTING, etc.
.github/                # Issue templates, etc.
```

**Process:**
1. Scan project structure
2. Find and list discovered docs
3. Ask user to confirm which to use
4. Parse and extract requirements
5. Fill gaps with brief questions

### File Parsing Examples

**From Markdown with headers:**
```markdown
# Feature: User Authentication

## Requirements
- [ ] OAuth 2.0 support (Google, GitHub)
- [ ] Session management
- [ ] Password reset flow

## Acceptance Criteria
1. User can sign in with Google
2. Session persists for 7 days
3. Password reset email sent within 1 minute
```

→ Extracted as:
```json
{
  "feature": {
    "name": "User Authentication",
    "requirements": [
      "OAuth 2.0 support (Google, GitHub)",
      "Session management",
      "Password reset flow"
    ],
    "acceptance_criteria": [
      "User can sign in with Google",
      "Session persists for 7 days",
      "Password reset email sent within 1 minute"
    ]
  }
}
```

**From YAML directly:**
```yaml
# Already structured - use as-is
project:
  name: Task Manager
features:
  - name: Authentication
    priority: must_have
```

**From JSON (OpenAPI):**
```json
{
  "openapi": "3.0.0",
  "paths": {
    "/tasks": { "get": {...}, "post": {...} }
  }
}
```

→ Extract API endpoints as features

### User Confirmation

After parsing file-based specs, always confirm:

```
📄 Loaded specification from: project-spec.md

Extracted:
  • Project: Task Manager App
  • Features: 4 identified
  • Tech Stack: FastAPI + PostgreSQL + React
  • Constraints: None specified

Is this correct? (yes/edit/add more)
```

If `edit`: Allow user to modify extracted data
If `add more`: Continue with remaining interview questions

## Your Process

This command combines PRD generation and sprint planning into a single workflow.

### Phase 0: Git Repository Check (REQUIRED)

Before any planning, verify git repository exists:

```bash
# Check for git repository
git rev-parse --git-dir 2>/dev/null
```

**If NOT a git repository:**

```
┌──────────────────────────────────────────────────────────────┐
│  📁 Git Repository Required                                  │
│                                                              │
│  DevTeam requires a git repository for:                      │
│  • Change tracking and rollback                              │
│  • Parallel plan execution (worktrees)                       │
│  • Safe merge of feature branches                            │
│  • Circuit breaker recovery                                  │
│                                                              │
│  Initialize a git repository now? (yes/no): _                │
└──────────────────────────────────────────────────────────────┘
```

If user says **yes**:
```bash
git init
git add .
git commit -m "Initial commit before DevTeam planning"
echo "✅ Git repository initialized"
```

If user says **no**:
```
❌ Cannot proceed without git repository.

To initialize manually:
  git init
  git add .
  git commit -m "Initial commit"

Then run /devteam:plan again.
```

**If git repo exists but has uncommitted changes:**

```
⚠️  Uncommitted Changes Detected

You have uncommitted changes in your working directory.
It's recommended to commit before planning.

Options:
  1. Commit changes now (recommended)
  2. Stash changes temporarily
  3. Continue anyway (changes tracked but not snapshotted)

Select option (1/2/3): _
```

Option 1:
```bash
git add -A
git commit -m "Pre-planning snapshot"
echo "✅ Changes committed"
```

### Phase 1: Requirements Interview

**Skip if:** `--from` flag provided with comprehensive spec and `--skip-interview` flag.

**Technology Stack Selection (FIRST):**
1. Ask: "What external services, APIs, or integrations will you need?"
2. Based on answer, recommend Python or TypeScript with reasoning:
   - Python: Better for data processing, ML, scientific computing
   - TypeScript: Better for web apps, real-time features, npm ecosystem
3. Confirm with user
4. Document choice

**Requirements Gathering (ONE question at a time):**
1. "What problem are you solving?"
2. "Who are the primary users?"
3. "What are the must-have features?"
4. "What are the nice-to-have features?"
5. "What scale do you expect? (users, data volume)"
6. "Any specific constraints? (timeline, budget, compliance)"
7. "How will you measure success?"

**Be efficient:** If user provides comprehensive initial description, skip questions already answered.

### Phase 2: Research Phase

**Skip if:** `--skip-research` flag provided.

**Purpose:** Investigate the codebase and technologies before planning to:
- Identify existing patterns to follow
- Find potential blockers early
- Make informed technology recommendations
- Prevent "discover problems during implementation" scenarios

**Research Agent Tasks:**

```javascript
// Spawn Research Agent
const researchResults = await Task({
    subagent_type: "research:research-agent",
    model: "opus",
    prompt: `Research for: ${projectDescription}

        Investigate:
        1. CODEBASE ANALYSIS
           - Existing project structure
           - Current tech stack in use
           - Coding patterns and conventions
           - Related existing features

        2. TECHNOLOGY EVALUATION
           - Recommended libraries/frameworks
           - Compatibility with existing stack
           - Community support and maintenance status
           - Security considerations

        3. IMPLEMENTATION PATTERNS
           - Similar features in codebase
           - Patterns to follow
           - Anti-patterns to avoid

        4. POTENTIAL BLOCKERS
           - Technical debt that might interfere
           - Missing dependencies
           - Breaking changes required
           - Integration challenges

        5. RECOMMENDATIONS
           - Suggested approach
           - Alternative approaches considered
           - Risk assessment

        Output structured findings with evidence.`
})
```

**Research Output Format:**

```yaml
research_findings:
  codebase_analysis:
    project_structure: "monorepo with packages/"
    existing_stack:
      backend: "FastAPI"
      frontend: "React + TypeScript"
      database: "PostgreSQL with SQLAlchemy"
    patterns_identified:
      - "Repository pattern for data access"
      - "React Query for server state"
      - "Tailwind for styling"

  technology_evaluation:
    recommended:
      - name: "Zod"
        reason: "Schema validation, already used in 3 places"
        confidence: high
    alternatives_considered:
      - name: "Yup"
        reason: "More verbose, different pattern than existing"
        rejected: true

  implementation_patterns:
    follow:
      - pattern: "Use existing AuthContext for user state"
        location: "src/contexts/AuthContext.tsx"
      - pattern: "API routes follow RESTful conventions"
        location: "src/api/routes/"
    avoid:
      - pattern: "Direct database access in components"
        reason: "Violates existing architecture"

  potential_blockers:
    - blocker: "User table lacks 'preferences' column"
      severity: medium
      resolution: "Migration required before feature"
    - blocker: "Current auth doesn't support OAuth"
      severity: high
      resolution: "Auth refactor needed first"

  recommendations:
    primary_approach: "Extend existing UserService with preferences"
    estimated_complexity: 7
    risks:
      - "OAuth integration more complex than expected"
    prerequisites:
      - "Database migration for user preferences"
```

**Display Research Progress:**

```
═══════════════════════════════════════════════════════════════════
 Research Phase
═══════════════════════════════════════════════════════════════════

Analyzing codebase and technologies...

  ✅ Project structure analyzed
  ✅ Existing patterns identified (5 found)
  ✅ Technology compatibility checked
  ⚠️  2 potential blockers identified
  ✅ Recommendations generated

Research Summary:
  • Existing stack: FastAPI + React + PostgreSQL
  • Patterns to follow: Repository pattern, React Query
  • Blockers found: 2 (1 high, 1 medium severity)
  • Recommended approach: Extend existing UserService

Proceeding to follow-up questions...
```

### Phase 3: Follow-up Questions (Research-Informed)

Based on research findings, ask clarifying questions:

```yaml
follow_up_triggers:
  - condition: blocker_found
    question: "Research found {blocker}. Should we address this first, or work around it?"

  - condition: multiple_approaches
    question: "There are two ways to implement this: {approach_a} or {approach_b}. Which do you prefer?"

  - condition: prerequisites_needed
    question: "This feature requires {prerequisite} first. Should we include that in the plan?"

  - condition: technology_choice
    question: "Research suggests using {recommended} because {reason}. Does that work for you?"
```

**Example Follow-up:**

```
═══════════════════════════════════════════════════════════════════
 Follow-up Questions (from Research)
═══════════════════════════════════════════════════════════════════

Research identified some items that need your input:

Q1: A database migration is needed to add user preferences.
    Should we include this in Sprint 1? (yes/no/skip feature)

Q2: Two implementation approaches are possible:
    A) Extend existing UserService (recommended, lower risk)
    B) Create new PreferencesService (cleaner, more work)
    Which approach do you prefer? (a/b)

Q3: OAuth integration is more complex than a simple feature.
    Should we:
    A) Include OAuth in this plan (adds ~2 sprints)
    B) Use existing auth, add OAuth later
    C) Descope to just username/password
    Select option (a/b/c):
```

### Phase 4: Generate PRD

Create `docs/planning/PROJECT_PRD.json`:

```json
{
  "version": "1.0",
  "project_name": "[Name]",
  "created": "[Date]",
  "technology_stack": {
    "primary_language": "python | typescript",
    "backend_framework": "fastapi | django | express | nestjs",
    "frontend_framework": "react | vue | svelte | none",
    "database": "postgresql | mongodb | sqlite",
    "orm": "sqlalchemy | prisma | typeorm | drizzle",
    "package_manager": "uv | npm | pnpm"
  },
  "problem_statement": "[Clear description of the problem]",
  "solution_overview": "[How this project solves it]",
  "users": {
    "primary": [
      {
        "type": "[User type]",
        "needs": ["need1", "need2"]
      }
    ],
    "secondary": [
      {
        "type": "[User type]",
        "needs": ["need1"]
      }
    ]
  },
  "features": {
    "must_have": [
      {
        "id": "F001",
        "name": "[Feature name]",
        "description": "[Description]",
        "acceptance_criteria": [
          "[Criterion 1]",
          "[Criterion 2]"
        ]
      }
    ],
    "nice_to_have": [
      {
        "id": "F010",
        "name": "[Feature name]",
        "description": "[Description]"
      }
    ]
  },
  "non_functional_requirements": {
    "performance": ["[Requirement]"],
    "security": ["[Requirement]"],
    "scalability": ["[Requirement]"]
  },
  "constraints": {
    "timeline": "[if specified]",
    "budget": "[if specified]",
    "compliance": "[if specified]"
  },
  "success_metrics": [
    "[Metric 1]",
    "[Metric 2]"
  ]
}
```

### Phase 5: Task Breakdown

Generate tasks in `docs/planning/tasks/`:

**For each must-have feature:**
1. Analyze complexity
2. Break into implementation tasks
3. Identify dependencies
4. Assign complexity scores (1-14)

**Task file format (`TASK-XXX.json`):**
```json
{
  "id": "TASK-001",
  "title": "[Task title]",
  "description": "[Detailed description]",
  "feature_ref": "F001",
  "task_type": "backend | frontend | database | fullstack | testing | infrastructure",
  "complexity": {
    "score": 6,
    "factors": {
      "files_affected": 4,
      "estimated_lines": 150,
      "new_dependencies": 1,
      "risk_flags": []
    }
  },
  "dependencies": ["TASK-000"],
  "acceptance_criteria": [
    "[Criterion 1]",
    "[Criterion 2]"
  ],
  "suggested_agent": "backend:api-developer-{language} | frontend:developer | ..."
}
```

### Phase 6: Sprint Planning

Organize tasks into sprints in `docs/sprints/`:

**Sprint organization rules:**
1. Respect dependencies (dependent tasks in later sprints)
2. Balance complexity across sprints
3. Group related tasks
4. First sprint = foundation/setup

**Sprint file format (`SPRINT-001.json`):**
```json
{
  "id": "SPRINT-001",
  "name": "[Sprint name]",
  "goal": "[Sprint goal]",
  "tasks": [
    "TASK-001",
    "TASK-002",
    "TASK-003"
  ],
  "estimated_complexity": 15,
  "dependencies": {
    "sprints": []
  },
  "quality_gates": [
    "All tests pass",
    "No type errors",
    "Code review complete"
  ]
}
```

### Phase 7: Initialize State

Initialize project state in SQLite database via the scripts layer:

```bash
# Source the state management functions
source scripts/state.sh

# Initialize the database (creates .devteam/devteam.db if needed)
source scripts/db-init.sh

# Set project metadata
set_kv_state "metadata.project_name" "[name]"
set_kv_state "metadata.project_type" "project"
set_kv_state "metadata.created_at" "$(date -u +%Y-%m-%dT%H:%M:%SZ)"

# Initialize sprints
set_kv_state "sprints.SPRINT-001.status" "pending"
set_kv_state "sprints.SPRINT-001.tasks_total" "3"
set_kv_state "sprints.SPRINT-002.status" "pending"
set_kv_state "sprints.SPRINT-002.tasks_total" "4"
# ... repeat for each sprint

# Initialize tasks
set_kv_state "tasks.TASK-001.status" "pending"
set_kv_state "tasks.TASK-001.complexity.score" "6"
set_kv_state "tasks.TASK-001.complexity.tier" "moderate"
# ... repeat for each task

# Set execution phase
set_phase "planning_complete"
```

Or via direct SQLite:

```bash
sqlite3 "${DEVTEAM_DB:-".devteam/devteam.db"}" "INSERT INTO session_state (session_id, key, value) VALUES ('<session_id>', 'metadata.project_name', '[name]');"
```

## Output Summary

After completion, display:

```
╔══════════════════════════════════════════╗
║  📋 PROJECT PLAN COMPLETE                ║
╚══════════════════════════════════════════╝

Project: [Name]

Technology Stack:
  • Backend: [Language + Framework]
  • Frontend: [Framework]
  • Database: [Database + ORM]

Planning Summary:
  • Features: [X] must-have, [Y] nice-to-have
  • Tasks: [N] total tasks
  • Sprints: [M] sprints planned
  • Estimated complexity: [score]

Files created:
  • docs/planning/PROJECT_PRD.json
  • docs/planning/tasks/TASK-*.json ([N] files)
  • docs/sprints/SPRINT-*.json ([M] files)
  • .devteam/devteam.db (state initialized)

Research Findings:
  • Patterns to follow: [N] identified
  • Blockers addressed: [N]
  • Approach: [Recommended approach]

Next steps:
  1. Review the PRD and tasks
  2. Run /devteam:implement to start implementation
  3. Or run /devteam:implement --sprint 1 for first sprint only
```

## Parallel Track Planning

When a project has independent feature areas that can be developed in parallel, the planner automatically organizes work into **parallel tracks**.

### Automatic Worktree Configuration

When multiple tracks are planned, worktrees are configured automatically in the SQLite state database:

```bash
# Parallel track configuration stored in SQLite (.devteam/devteam.db)
source scripts/state.sh

set_kv_state "parallel_tracks.mode" "worktrees"
set_kv_state "parallel_tracks.track_info.01.name" "Backend API"
set_kv_state "parallel_tracks.track_info.01.sprints" "SPRINT-001,SPRINT-002"
set_kv_state "parallel_tracks.track_info.01.status" "pending"
set_kv_state "parallel_tracks.track_info.02.name" "Frontend"
set_kv_state "parallel_tracks.track_info.02.sprints" "SPRINT-003,SPRINT-004"
set_kv_state "parallel_tracks.track_info.02.status" "pending"
```

**Note:** Users never need to interact with worktrees directly. The system handles:
- Creation of worktrees when execution begins
- Isolation of track work in separate directories
- Automatic merging when all tracks complete
- Cleanup of worktrees after merge

For debugging worktree issues, advanced users can use:
- `/devteam:worktree status` - View worktree state
- `/devteam:worktree list` - List all worktrees
- `/devteam:implement --show-worktrees` - See worktree operations during execution

## Important Notes

- Ask ONE question at a time
- Be conversational but efficient
- Provide technology recommendations with reasoning
- Don't generate files until you have all required information
- Initialize state in SQLite database (.devteam/devteam.db) for progress tracking
- Research phase prevents costly discoveries during implementation
- Parallel tracks are automatically managed with git worktrees (hidden from users)

## See Also

- `/devteam:implement` - Execute the plan
- `/devteam:list` - List available plans
- `/devteam:status` - Check planning status
