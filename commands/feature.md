# Feature Command

You are implementing a **complete feature workflow** from description to delivery.

## Command Usage

`/feature [feature description]` - Complete workflow: PRD → Planning → Implementation

Examples:
- `/feature Add user authentication with OAuth and 2FA`
- `/feature Implement real-time notifications using WebSockets`
- `/feature Create analytics dashboard with charts and exports`

## Your Process

This is a **macro command** that orchestrates the complete development lifecycle.

### Phase 1: PRD Generation

**Launch PRD Generator:**
```javascript
Task(
  subagent_type="multi-agent-dev-system:planning:prd-generator",
  model="sonnet",
  description="Generate PRD for feature",
  prompt=`Create a Product Requirements Document for this feature:

FEATURE: ${featureDescription}

Conduct interactive interview to gather:
1. Technology stack needed (or use existing project stack)
2. User stories and use cases
3. Acceptance criteria
4. Technical requirements
5. Integration points with existing system
6. Security requirements
7. Performance requirements

Generate PRD at: docs/planning/FEATURE_${featureId}_PRD.yaml

If this is adding to an existing project:
- Review existing code structure
- Maintain consistency with existing tech stack
- Consider integration with existing features
`
)
```

### Phase 2: Planning & Task Breakdown

**Launch Planning Workflow:**
```javascript
// Task Graph Analyzer
Task(
  subagent_type="multi-agent-dev-system:planning:task-graph-analyzer",
  model="sonnet",
  description="Break feature into tasks",
  prompt=`Analyze PRD and create task breakdown:

PRD: docs/planning/FEATURE_${featureId}_PRD.yaml

Create tasks in: docs/planning/tasks/
Prefix task IDs with FEATURE-${featureId}-

Identify dependencies and create dependency graph.
Keep tasks small (1-2 days each).
`
)

// Sprint Planner
Task(
  subagent_type="multi-agent-dev-system:planning:sprint-planner",
  model="sonnet",
  description="Organize tasks into sprints",
  prompt=`Organize feature tasks into sprints:

Tasks: docs/planning/tasks/FEATURE-${featureId}-*
Dependencies: docs/planning/task-dependency-graph.md

Create sprints: docs/sprints/FEATURE_${featureId}_SPRINT-XXX.yaml

Balance sprint capacity and respect dependencies.
`
)
```

### Phase 3: Execute All Sprints

**Launch Sprint Execution:**
```javascript
Task(
  subagent_type="multi-agent-dev-system:orchestration:sprint-orchestrator",
  model="opus",
  description="Execute all feature sprints",
  prompt=`Execute ALL sprints for feature ${featureId} sequentially:

Sprint files: docs/sprints/FEATURE_${featureId}_SPRINT-*.yaml

For each sprint:
1. Execute all tasks with task-orchestrator
2. Run final code review (code, security, performance)
3. Update documentation
4. Generate sprint report

After all sprints:
5. Run comprehensive feature review
6. Verify integration with existing system
7. Update project documentation
8. Generate feature completion report

Do NOT proceed to next sprint unless current sprint passes all quality gates.
`
)
```

### Phase 4: Feature Integration Verification

**After implementation, verify integration:**

```
1. Run all existing tests (ensure no regressions)
2. Test feature in isolation
3. Test feature integrated with existing features
4. Verify API compatibility
5. Check database migrations applied correctly
6. Verify configuration changes documented
```

### Phase 5: Documentation Update

**Update project documentation:**
- Add feature to README
- Update API documentation
- Add feature guide
- Update changelog

### User Communication

**Starting:**
```
🚀 Feature Implementation Workflow Started

Feature: ${featureDescription}

Phase 1/3: Generating PRD...
  Conducting interactive interview to gather requirements...
```

**Progress Updates:**
```
✅ Phase 1 Complete: PRD Generated
   docs/planning/FEATURE_001_PRD.yaml

📋 Phase 2/3: Planning...
   Breaking down into tasks...
   ✅ Created 8 tasks
   ✅ Organized into 2 sprints

🔨 Phase 3/3: Implementation...
   Sprint 1/2: Core functionality
      Task 1/4: Database schema
      Task 2/4: API endpoints
      ...
   ✅ Sprint 1 complete

   Sprint 2/2: Integration & polish
      Task 1/4: Frontend components
      ...
   ✅ Sprint 2 complete

🎯 Running final feature review...
   ✅ Code review passed
   ✅ Security audit passed
   ✅ Performance audit passed
   ✅ Integration tests passed
   ✅ Documentation updated
```

**Completion:**
```
╔══════════════════════════════════════════╗
║  ✅ FEATURE COMPLETE  ✅                ║
╚══════════════════════════════════════════╝

Feature: ${featureDescription}

Implementation Summary:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Tasks Completed: 8/8
Sprints: 2/2
Quality: All checks passed ✅

Files Changed:
  • 12 files modified
  • 847 lines added
  • 45 lines removed

Testing:
  • Unit tests: 23 added, all passing
  • Integration tests: 5 added, all passing
  • Coverage: 87%

Documentation:
  • API docs updated
  • README updated
  • Feature guide created

Ready for review and deployment! 🚀

Next steps:
1. Review changes: git diff main
2. Test feature manually
3. Deploy to staging
4. Create pull request
```

## Error Handling

**Invalid feature description:**
```
Error: Feature description too vague

Please provide more details. Examples:
✅ "Add OAuth login with Google and GitHub"
❌ "Add login"

✅ "Implement WebSocket notifications for task updates"
❌ "Add notifications"
```

**Feature too large:**
```
⚠️  Warning: Feature spans 6 sprints (12+ tasks)

Recommendation: Break into smaller features

Consider splitting into:
1. /feature User authentication (OAuth only)
2. /feature Two-factor authentication
3. /feature Social login integration
```

**Integration conflicts:**
```
❌ Integration test failed

Conflict: New auth system incompatible with existing session handling

Pausing for resolution.

Recommend:
1. Review existing auth code: backend/auth/
2. Decide on migration strategy
3. Update or revert changes
```

## Advanced Usage

**Add to existing project:**
```
/feature Add GraphQL API alongside existing REST API
(System detects existing project structure and integrates)
```

**Specify technical details:**
```
/feature Implement caching layer using Redis with 5-minute TTL for user queries
```

**Complex features:**
```
/feature Build ML-powered recommendation engine using scikit-learn, with API endpoints and admin dashboard
```

## Workflow Diagram

```
User: /feature Add real-time chat

    ↓
1. PRD Generation (interactive)
    ↓
2. Task Breakdown + Sprint Planning
    ↓
3. Sprint Execution (all sprints)
    ├── Sprint 1: Database + API
    ├── Sprint 2: WebSocket server
    └── Sprint 3: Frontend UI
    ↓
4. Feature Integration
    ├── Code review
    ├── Security audit
    ├── Performance audit
    └── Integration tests
    ↓
5. Documentation Update
    ↓
✅ Feature Complete
```

## Cost Estimation

**Small feature (1 sprint, 3-5 tasks):**
- PRD: ~$0.50
- Planning: ~$0.30
- Implementation: ~$2-4
- **Total: ~$3-5**

**Medium feature (2-3 sprints, 8-12 tasks):**
- PRD: ~$0.70
- Planning: ~$0.50
- Implementation: ~$8-15
- **Total: ~$10-20**

**Large feature (4-6 sprints, 15-25 tasks):**
- PRD: ~$1.00
- Planning: ~$1.00
- Implementation: ~$25-50
- **Total: ~$30-60**

Time saved: **90-95% vs manual development**
