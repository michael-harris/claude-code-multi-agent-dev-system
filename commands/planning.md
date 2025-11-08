# Planning Command

You are orchestrating the **project planning phase** using the pragmatic approach. This involves two sequential agent invocations with optional parallel development track support.

## Command Usage

```bash
/multi-agent:planning                    # Single track (default)
/multi-agent:planning 3                  # Request 3 parallel development tracks (state-only mode)
/multi-agent:planning 3 --use-worktrees  # Request 3 tracks with git worktrees for isolation
/multi-agent:planning 5                  # Request 5 parallel tracks (will use max possible if less)
```

## Your Process

### Step 0: Parse Parameters

Extract the number of requested parallel tracks and worktree mode from the command:
- If no parameter provided: tracks = 1 (single track mode), use_worktrees = false
- If parameter provided: tracks = requested number
- If `--use-worktrees` flag present: use_worktrees = true, otherwise use_worktrees = false
- Pass both tracks and use_worktrees to sprint-planner in Step 2

**Worktree Mode:**
- `false` (default): State-only mode - tracks use logical separation via state files
- `true`: Git worktrees mode - each track gets isolated directory and branch

### Step 1: Task Analysis
1. Read `docs/planning/PROJECT_PRD.yaml`
2. Launch the **task-graph-analyzer** agent using the Task tool:
   - Pass the PRD content
   - Ask it to break down requirements into tasks
   - Ask it to identify dependencies between tasks
   - **NEW:** Ask it to calculate maximum possible parallel development tracks
3. Have the agent create individual task files: `docs/planning/tasks/TASK-001.yaml`, `TASK-002.yaml`, etc.
4. Have the agent create `docs/planning/task-dependency-graph.md` showing relationships
5. **NEW:** Agent should report the max possible parallel tracks in its summary

### Step 2: Sprint Planning
1. After task analysis completes, launch the **sprint-planner** agent using the Task tool:
   - Pass all task definitions
   - Pass the dependency graph
   - Pass number of requested tracks (from Step 0)
   - Pass max possible tracks (from Step 1)
   - **NEW:** Pass use_worktrees flag (from Step 0)
   - Ask it to organize tasks into sprints
2. If tracks > 1:
   - Have agent create sprint files with track suffix: `docs/sprints/SPRINT-XXX-YY.yaml`
   - Have agent initialize state file: `docs/planning/.project-state.yaml`
   - Example: `SPRINT-001-01.yaml`, `SPRINT-001-02.yaml` for 2 tracks
   - **NEW:** If use_worktrees = true:
     - Have agent create git worktrees: `.multi-agent/track-01/`, `.multi-agent/track-02/`, etc.
     - Have agent create branches: `dev-track-01`, `dev-track-02`, etc.
     - Have agent copy planning artifacts to each worktree
     - State file should include worktree paths and branch names
3. If tracks = 1 (default):
   - Have agent create traditional sprint files: `docs/sprints/SPRINT-001.yaml`, `SPRINT-002.yaml`, etc.
   - Still initialize state file for progress tracking
   - No worktrees needed for single track

## Special Pattern: API-First Full-Stack Applications

**Use this pattern when building applications with separate backend and frontend that communicate via API.**

### When to Use API-First Pattern

Use this when your PRD indicates:
- Full-stack application (backend + frontend)
- REST API or GraphQL API
- Mobile app + backend
- Microservices architecture
- Any scenario with API contract between components

### How API-First Works

1. **First Task = API Design**: Create OpenAPI specification BEFORE any code
2. **Backend implements FROM spec**: Exact schemas, no deviations
3. **Frontend generates FROM spec**: Auto-generated type-safe client
4. **Result**: Perfect alignment, compile-time safety

### Task Structure Template

When you detect a full-stack project, ensure tasks follow this order:

```
TASK-001: Design API Specification (NO dependencies)
  ├── Agent: backend:api-designer
  ├── Output: docs/api/openapi.yaml
  └── Critical: This runs FIRST

TASK-002: Design Database Schema (depends on TASK-001)
  └── Agent: database:designer

TASK-003: Implement Database Models (depends on TASK-002)
  └── Agent: database:developer-{language}-t1

TASK-004: Implement Backend API (depends on TASK-001, TASK-003)
  ├── Agent: backend:api-developer-{language}-t1
  ├── Input: docs/api/openapi.yaml
  └── Must match spec EXACTLY

TASK-005: Generate Frontend API Client (depends on TASK-001 ONLY)
  ├── Agent: frontend:developer-t1
  ├── Input: docs/api/openapi.yaml
  ├── Tool: openapi-typescript-codegen
  └── Output: Auto-generated type-safe client

TASK-006: Implement Frontend UI (depends on TASK-005)
  └── Agent: frontend:developer-t1
  └── Uses ONLY generated client
```

### Important Dependencies

- **Backend depends on**: API spec + Database models
- **Frontend client depends on**: API spec ONLY (not backend implementation!)
- **Frontend UI depends on**: Generated client

This allows frontend and backend to develop in parallel after the API spec is complete.

### Validation Requirements

When creating tasks for API-first projects, include these acceptance criteria:

**For TASK-001 (API Design):**
- OpenAPI 3.0 specification at docs/api/openapi.yaml
- Passes openapi-spec-validator
- All endpoints, schemas, errors documented

**For TASK-004 (Backend):**
- Implements ONLY endpoints in spec
- Schemas match spec EXACTLY
- Passes openapi-spec-validator
- /docs endpoint serves the specification

**For TASK-005 (Frontend Client):**
- Client auto-generated from spec
- NO manual endpoint definitions
- TypeScript types from spec
- CI verifies client is up-to-date

**For TASK-006 (Frontend UI):**
- Uses ONLY generated client
- NO fetch/axios outside generated code
- TypeScript compilation enforces correctness

### Example Detection

If PRD contains:
- "backend API" + "frontend application"
- "REST API" + "React/Vue/Angular"
- "mobile app" + "API server"
- "microservices" with communication

Then recommend API-first pattern and structure tasks accordingly.

### Reference

See complete example: `examples/api-first-fullstack-workflow.md`
See task templates: `docs/templates/api-first-tasks.yaml`

---

## Agent References

- Task Graph Analyzer: `.claude/agents/multi-agent:planning/task-graph-analyzer.md`
- Sprint Planner: `.claude/agents/multi-agent:planning/multi-agent:sprint-planner.md`

## After Completion

### Report Format - Single Track Mode

```
Planning complete!

Task Analysis:
- Created 15 tasks in docs/planning/tasks/
- Max possible parallel tracks: 3
- Critical path: 5 tasks (20 hours)

Sprint Planning:
- Created 3 sprints in docs/sprints/
- SPRINT-001: Foundation (5 tasks, 40 hours)
- SPRINT-002: Core Features (6 tasks, 52 hours)
- SPRINT-003: Polish (4 tasks, 36 hours)

Artifacts:
- Tasks: docs/planning/tasks/
- Sprints: docs/sprints/
- Dependency graph: docs/planning/task-dependency-graph.md
- State file: docs/planning/.project-state.yaml

Ready to start development:
/multi-agent:sprint all              # Execute all sprints
/multi-agent:sprint SPRINT-001       # Execute specific sprint

Tip: For parallel development, try:
/multi-agent:planning 3                  # Re-run with 3 tracks for faster execution
/multi-agent:planning 3 --use-worktrees  # Use worktrees for physical isolation
```

### Report Format - Parallel Track Mode (State-Only)

```
Planning complete!

Task Analysis:
- Created 15 tasks in docs/planning/tasks/
- Max possible parallel tracks: 3
- Critical path: 5 tasks (20 hours)

Sprint Planning:
- Requested tracks: 5
- Max possible: 3
- Using: 3 tracks
- Mode: State-only (logical separation)

Track Distribution:
- Track 1: 5 tasks, 42 hours (SPRINT-001-01, SPRINT-002-01)
- Track 2: 6 tasks, 48 hours (SPRINT-001-02, SPRINT-002-02)
- Track 3: 4 tasks, 38 hours (SPRINT-001-03, SPRINT-002-03)

Total: 15 tasks, ~128 hours development time
Parallel execution time: ~48 hours (62% faster)

Artifacts:
- Tasks: docs/planning/tasks/
- Sprints: docs/sprints/ (6 sprint files across 3 tracks)
- Dependency graph: docs/planning/task-dependency-graph.md
- State file: docs/planning/.project-state.yaml

Ready to start development:
/multi-agent:sprint all              # Execute all tracks sequentially
/multi-agent:sprint all 01           # Execute track 1 only
/multi-agent:sprint all 02           # Execute track 2 only
/multi-agent:sprint all 03           # Execute track 3 only

Or run in parallel (multiple terminals):
Terminal 1: /multi-agent:sprint all 01
Terminal 2: /multi-agent:sprint all 02
Terminal 3: /multi-agent:sprint all 03

Tip: For stronger isolation, try:
/multi-agent:planning 3 --use-worktrees  # Use git worktrees for physical separation
```

### Report Format - Parallel Track Mode (With Worktrees)

```
Planning complete!

Task Analysis:
- Created 15 tasks in docs/planning/tasks/
- Max possible parallel tracks: 3
- Critical path: 5 tasks (20 hours)

Sprint Planning:
- Requested tracks: 5
- Max possible: 3
- Using: 3 tracks
- Mode: Git worktrees (physical isolation)

Worktree Configuration:
  ✓ Track 1: .multi-agent/track-01/ (branch: dev-track-01)
  ✓ Track 2: .multi-agent/track-02/ (branch: dev-track-02)
  ✓ Track 3: .multi-agent/track-03/ (branch: dev-track-03)

Track Distribution:
- Track 1: 5 tasks, 42 hours (SPRINT-001-01, SPRINT-002-01)
- Track 2: 6 tasks, 48 hours (SPRINT-001-02, SPRINT-002-02)
- Track 3: 4 tasks, 38 hours (SPRINT-001-03, SPRINT-002-03)

Total: 15 tasks, ~128 hours development time
Parallel execution time: ~48 hours (62% faster)

Artifacts:
- Tasks: docs/planning/tasks/
- Sprints: docs/sprints/ (6 sprint files across 3 tracks)
- Dependency graph: docs/planning/task-dependency-graph.md
- State file: docs/planning/.project-state.yaml
- Worktrees: .multi-agent/track-01/, track-02/, track-03/

Ready to start development:
/multi-agent:sprint all              # Execute all tracks sequentially
/multi-agent:sprint all 01           # Execute track 1 (auto-switches to worktree)
/multi-agent:sprint all 02           # Execute track 2 (auto-switches to worktree)
/multi-agent:sprint all 03           # Execute track 3 (auto-switches to worktree)

Or run in parallel (multiple terminals):
Terminal 1: /multi-agent:sprint all 01
Terminal 2: /multi-agent:sprint all 02
Terminal 3: /multi-agent:sprint all 03

After all tracks complete, merge them:
/multi-agent:merge-tracks            # Merges all tracks, cleans up worktrees
```

## Important Notes

- Use the Task tool to launch each agent
- Wait for each agent to complete before moving to the next
- Agents should reference the PRD's technology stack for language-specific tasks
- Ensure dependency order is preserved in sprint plans
