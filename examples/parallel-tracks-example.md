# Parallel Development Tracks Example

This example demonstrates using parallel development tracks to accelerate a full-stack project.

## Scenario: E-Commerce Platform

Building a full-stack e-commerce platform with:
- Backend API (Python/FastAPI)
- Frontend (React/TypeScript)
- Infrastructure (Docker, K8s)
- Database (PostgreSQL)

## Step 1: Generate PRD

```bash
/devteam:plan
```

**System creates:** `docs/planning/PROJECT_PRD.json`

## Step 2: Planning with Parallel Tracks

```bash
/devteam:plan 3
```

**Task Graph Analyzer Output:**
```
Task Analysis Complete!

Created 18 tasks in docs/planning/tasks/

Dependency Analysis:
  Chain 1 (Backend): TASK-001 → TASK-004 → TASK-008 → TASK-012 → TASK-016 (42 hours)
  Chain 2 (Frontend): TASK-002 → TASK-005 → TASK-009 → TASK-013 → TASK-017 (38 hours)
  Chain 3 (Infrastructure): TASK-003 → TASK-007 → TASK-011 → TASK-015 (28 hours)
  Independent: TASK-006, TASK-010, TASK-014, TASK-018 (20 hours)

Critical Path: Chain 1 (Backend) - 42 hours

Maximum Parallel Development Tracks: 3

Reasoning:
- 3 independent dependency chains exist
- At peak, 3 tasks can run simultaneously
- If using 3 tracks, all chains run in parallel with minimal idle time

Recommendation: /devteam:plan 3
```

**Sprint Planner Output:**
```
Sprint Planning Complete!

Parallel Development Configuration:
- Requested tracks: 3
- Max possible tracks: 3
- Using: 3 tracks

Track Distribution:

Track 1 (Backend API):
  Total: 7 tasks, 52 hours across 2 sprints
  - SPRINT-001-01: Foundation (3 tasks, 24 hours)
    * TASK-001: Database schema design
    * TASK-004: User authentication API
    * TASK-008: Product catalog API
  - SPRINT-002-01: Advanced Features (4 tasks, 28 hours)
    * TASK-012: Shopping cart API
    * TASK-016: Payment integration API
    * TASK-006: Email notification service
    * TASK-018: Admin dashboard API

Track 2 (Frontend):
  Total: 6 tasks, 44 hours across 2 sprints
  - SPRINT-001-02: Foundation (3 tasks, 20 hours)
    * TASK-002: React project setup
    * TASK-005: Login/registration UI
    * TASK-009: Product catalog UI
  - SPRINT-002-02: Advanced Features (3 tasks, 24 hours)
    * TASK-013: Shopping cart UI
    * TASK-017: Checkout flow UI
    * TASK-010: Admin dashboard UI

Track 3 (Infrastructure):
  Total: 5 tasks, 32 hours across 2 sprints
  - SPRINT-001-03: Foundation (2 tasks, 12 hours)
    * TASK-003: Docker containers
    * TASK-007: CI/CD pipeline
  - SPRINT-002-03: Production Ready (3 tasks, 20 hours)
    * TASK-011: Kubernetes manifests
    * TASK-015: Monitoring setup
    * TASK-014: Database backups

Total: 18 tasks, ~128 hours development
Parallel execution time: ~52 hours (vs 128 sequential)
Time savings: 59%

State tracking initialized in SQLite at: .devteam/devteam.db

Ready to execute:
Option 1 - All tracks sequentially:
  /devteam:implement --sprint all

Option 2 - Specific track:
  /devteam:implement --sprint all 01    (Track 1 only)
  /devteam:implement --sprint all 02    (Track 2 only)
  /devteam:implement --sprint all 03    (Track 3 only)

Option 3 - Parallel execution (multiple terminals):
  Terminal 1: /devteam:implement --sprint all 01
  Terminal 2: /devteam:implement --sprint all 02
  Terminal 3: /devteam:implement --sprint all 03
```

## Step 3: Execute Tracks in Parallel

### Terminal 1: Backend Track

```bash
/devteam:implement --sprint all 01
```

**Output:**
```
Loading state from SQLite: .devteam/devteam.db
Track 1 (Backend API) - 2 sprints to execute

═══════════════════════════════════════
SPRINT-001-01: Foundation
═══════════════════════════════════════

Task 1/3: TASK-001 - Database schema design
  Launching database:designer (Sonnet)...
  ✅ Schema designed (8 tables, normalized)

  Launching database:developer-python (Sonnet)...
  ✅ SQLAlchemy models created

  Launching orchestration:requirements-validator (Opus)...
  ✅ PASS (100% criteria met)

  TASK-001 complete (2 iterations, sonnet, 45 min)
  State updated: TASK-001 marked as completed

Task 2/3: TASK-004 - User authentication API
  Launching backend:api-designer (Sonnet)...
  ✅ API specification created (OpenAPI 3.0)

  Launching backend:api-developer-python (Sonnet)...
  ✅ FastAPI endpoints implemented

  Launching quality:test-writer (Sonnet)...
  ✅ Unit and integration tests written (23 tests)

  Launching orchestration:requirements-validator (Opus)...
  ⚠️ FAIL - Missing password reset endpoint

  Re-attempting with sonnet...
  ✅ Password reset endpoint added

  Launching orchestration:requirements-validator (Opus)...
  ✅ PASS (100% criteria met)

  TASK-004 complete (3 iterations, sonnet, 62 min)
  State updated: TASK-004 marked as completed

Task 3/3: TASK-008 - Product catalog API
  Launching backend:api-developer-python (Sonnet)...
  ✅ CRUD endpoints implemented

  Launching orchestration:requirements-validator (Opus)...
  ✅ PASS (100% criteria met)

  TASK-008 complete (1 iteration, sonnet, 38 min)
  State updated: TASK-008 marked as completed

Final Sprint Review...
  Running backend:code-reviewer-python (Sonnet)...
  ✅ Code quality: PASS (minor improvements suggested)

  Running quality:security-auditor (Opus)...
  ✅ Security: PASS (no vulnerabilities)

  Running quality:performance-auditor-python (Sonnet)...
  ✅ Performance: PASS (optimizations documented)

  Updating documentation...
  ✅ API docs updated, README updated

SPRINT-001-01 COMPLETE ✅
Tasks: 3/3 completed
Time: 2.5 hours
Cost: ~$1.20
State updated: SPRINT-001-01 marked as completed

═══════════════════════════════════════
SPRINT-002-01: Advanced Features
═══════════════════════════════════════

[Similar execution for remaining tasks...]

═══════════════════════════════════════
TRACK 1 COMPLETE ✅
═══════════════════════════════════════

Total tasks: 7/7
Total sprints: 2/2
Total time: 5.5 hours
Total cost: ~$3.50
Quality: All checks passed

Next: Wait for other tracks to complete before final project review
```

### Terminal 2: Frontend Track

```bash
/devteam:implement --sprint all 02
```

**Output:**
```
Loading state from SQLite: .devteam/devteam.db
Track 2 (Frontend) - 2 sprints to execute

[Similar execution pattern for frontend tasks...]

TRACK 2 COMPLETE ✅
Total tasks: 6/6
Total sprints: 2/2
Total time: 4.5 hours
Total cost: ~$2.80
```

### Terminal 3: Infrastructure Track

```bash
/devteam:implement --sprint all 03
```

**Output:**
```
Loading state from SQLite: .devteam/devteam.db
Track 3 (Infrastructure) - 2 sprints to execute

[Similar execution pattern for infrastructure tasks...]

TRACK 3 COMPLETE ✅
Total tasks: 5/5
Total sprints: 2/2
Total time: 3.5 hours
Total cost: ~$2.10
```

## Step 4: Final Project Review

After all tracks complete, run final integration review:

```bash
# Automatically triggered after last track completes
# Or manually run:
/devteam:implement --sprint all
```

**Output:**
```
All tracks complete! Running final project review...

Detecting languages used...
  - Python (FastAPI backend)
  - TypeScript (React frontend)
  - Shell (deployment scripts)

Comprehensive Code Review...
  ✅ Python code review: PASS
  ✅ TypeScript code review: PASS
  ✅ Shell scripts review: PASS

Comprehensive Security Audit...
  ✅ OWASP Top 10: All checks passed
  ✅ No secrets in code
  ✅ Authentication properly implemented
  ✅ API security: Rate limiting, CORS configured

Comprehensive Performance Audit...
  ✅ Database indexes optimized
  ✅ API response times < 200ms
  ✅ Frontend bundle size: 145KB (optimized)
  ✅ No N+1 queries detected

Integration Testing...
  ✅ Backend ↔ Frontend integration: PASS
  ✅ API contracts match
  ✅ Authentication flow: PASS
  ✅ Payment flow: PASS

Documentation Review...
  ✅ README complete and up to date
  ✅ API documentation (OpenAPI)
  ✅ Architecture diagrams
  ✅ Deployment guide

╔═══════════════════════════════════════════╗
║  🎉 PROJECT COMPLETION SUCCESSFUL  🎉    ║
╚═══════════════════════════════════════════╝

E-Commerce Platform Development Complete!

Overall Statistics:
  Total tasks: 18/18 completed
  Total sprints: 6 (2 per track × 3 tracks)
  Total iterations: 47
  Sonnet tasks: 14 (78%)
  Opus tasks: 4 (22%)

Execution Time:
  Sequential estimate: ~128 hours
  Parallel execution: ~5.5 hours (wall clock)
  Time saved: 95%+ (with 3 parallel executions)

Cost Breakdown:
  Track 1 (Backend): $3.50
  Track 2 (Frontend): $2.80
  Track 3 (Infrastructure): $2.10
  Final review: $1.20
  Total: ~$9.60

Quality Metrics:
  Code reviews: All passed ✅
  Security audit: All passed ✅
  Performance audit: All passed ✅
  Test coverage: 87%
  Documentation: Complete ✅

Features Delivered:
  ✅ User authentication (login, register, password reset)
  ✅ Product catalog (browse, search, filter)
  ✅ Shopping cart (add, remove, update quantities)
  ✅ Checkout flow (address, payment, confirmation)
  ✅ Admin dashboard (product management, orders)
  ✅ Email notifications (order confirmation, shipping)
  ✅ Containerized deployment (Docker)
  ✅ CI/CD pipeline (GitHub Actions)
  ✅ Kubernetes deployment (production-ready)
  ✅ Monitoring (Prometheus + Grafana)

Ready for deployment! 🚀
```

## Step 5: Viewing State

```bash
# Query task progress from SQLite
sqlite3 .devteam/devteam.db "SELECT * FROM v_sprint_progress;"
```

**Example Query Output:**
```sql
-- Task status summary
sqlite3 .devteam/devteam.db "
  SELECT status, COUNT(*) as count FROM tasks GROUP BY status;
"
-- status     | count
-- completed  | 18

-- Sprint progress
sqlite3 .devteam/devteam.db "
  SELECT id, status, tasks_completed, tasks_total FROM tasks
  WHERE id LIKE 'SPRINT-%';
"

-- Session state
sqlite3 .devteam/devteam.db "
  SELECT key, value FROM session_state WHERE session_id = (
    SELECT id FROM sessions ORDER BY started_at DESC LIMIT 1
  );
"
```

**Key state data tracked in SQLite:**
- **sessions** table: Execution sessions with timestamps and status
- **tasks** table: Each task with status, track, iterations, model used, completion time
- **session_state** table: Key-value pairs for parallel_tracks config, statistics, etc.
- **events** table: Full audit log of all actions

## Resume Example

If execution is interrupted:

```bash
# Terminal 1 crashes during SPRINT-002-01

# Later, resume:
/devteam:implement --sprint all 01

# Output:
Loading state from SQLite: .devteam/devteam.db
Checking track 1 status...

Found completed sprint: SPRINT-001-01 (skipping)
Found in-progress sprint: SPRINT-002-01 (resuming)
  Found completed task: TASK-012 (skipping)
  Resuming from task: TASK-016

═══════════════════════════════════════
SPRINT-002-01: Advanced Features (RESUMING)
═══════════════════════════════════════

Skipping completed tasks: TASK-012 ✓

Task 2/4: TASK-016 - Payment integration API
  [Continues execution...]
```

## Key Benefits Demonstrated

1. **Parallel Execution**: 3 tracks ran simultaneously, reducing 128 hours to ~5.5 hours wall clock time
2. **Resume Capability**: Can interrupt and resume any track at any point
3. **Independent Progress**: Each track tracks its own progress independently
4. **Cost Efficiency**: Model escalation kept costs low (~$9.60 for full project)
5. **Quality Assurance**: Every task validated, comprehensive final review
6. **Audit Trail**: Complete state file shows all work done with timestamps and metadata

## When to Use Parallel Tracks

**Use parallel tracks when:**
- Project has independent components (backend, frontend, infrastructure)
- Multiple developers/teams available
- Time-to-market is critical
- Components have minimal cross-dependencies

**Use single track when:**
- Small projects (< 10 tasks)
- Highly interdependent tasks
- Solo developer with sequential workflow preference
- Learning/experimentation phase

## Tips

1. **Max tracks calculation is automatic** - System analyzes dependencies and tells you max possible
2. **Can run tracks sequentially** - Use `/devteam:implement --sprint all` to run all tracks one after another if no parallelization available
3. **SQLite state enables coordination** - Multiple developers can work on different tracks, SQLite database coordinates progress
4. **Resume anytime** - If interrupted, just rerun the command, system picks up where it left off
