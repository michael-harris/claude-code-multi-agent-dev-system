# Multi-Agent Development System - Usage Guide

**Version:** 2.1 (Pragmatic Approach)
**Purpose:** Complete guide for using Claude Code with manual agent orchestration and T1/T2 quality tiers

**IMPORTANT:** This system uses slash commands that prompt Claude to manually orchestrate agents.
- Commands are in `.claude/commands/` (markdown prompts)
- Claude uses the Task tool to launch agents
- Claude tracks iterations and manages T1→T2 switching manually
- No YAML workflow execution - pure prompt-based orchestration

---

## Table of Contents

1. [Quick Start](#quick-start)
2. [Phase 1: Planning](#phase-1-planning)
3. [Phase 2: Execution](#phase-2-execution)
4. [Monitoring & Status](#monitoring--status)
5. [Understanding Iterations](#understanding-iterations)
6. [Handling Failures](#handling-failures)
7. [Command Reference](#command-reference)
8. [Best Practices](#best-practices)

---

## Quick Start

### Complete Workflow

```bash
# 1. Setup (one time, from SETUP.md)
"Claude Code, please set up the multi-agent system from SETUP.md"

# 2. Planning Phase
/prd generate              # Interactive PRD creation (10-15 minutes)
/planning analyze          # Generate tasks (2-5 minutes)
/planning sprints          # Organize sprints (1-2 minutes)

# 3. Execution Phase
/sprint execute SPRINT-001 # Automated development (varies by sprint size)

# 4. Monitor
/sprint status SPRINT-001  # Check progress anytime
```

---

## Phase 1: Planning

Planning generates all documents before any code is written.

### Step 1: Generate PRD

```bash
/prd generate
```

**What happens:**
- prd-generator agent starts interactive Q&A
- Asks about integrations and tech stack FIRST
- Recommends stack based on your needs
- Walks through structured questions
- Generates `docs/planning/PROJECT_PRD.yaml`

**Example interaction:**

```
Agent: "What external services or libraries will you integrate with?"

You: "We need TensorFlow for ML models and Stripe for payments"

Agent: "Based on your ML requirements, I recommend:
       
       Backend: Python with FastAPI
       - Native TensorFlow support
       - Async support for ML inference
       - Modern, fast framework
       
       Frontend: TypeScript with React
       Database: PostgreSQL with SQLAlchemy
       
       Does this work for you?"

You: "Yes, that sounds good"

Agent: "Perfect. Now let's understand your project.
       What problem are you trying to solve, and for whom?"

[... continues through all questions ...]

Agent: "PRD saved to docs/planning/PROJECT_PRD.yaml
       
       Next: /planning analyze to break into tasks"
```

**Tips:**
- Have clear answers ready for: problem, users, MVP scope
- Be specific about integration requirements
- Define success metrics (they become acceptance criteria)
- Identify what's out of scope upfront

### Step 2: Analyze & Decompose

```bash
/planning analyze
```

**What happens:**
- task-graph-analyzer reads PRD
- Identifies all features and requirements
- Breaks into discrete, implementable tasks
- Assigns task types to each task
- Analyzes dependencies between tasks
- Generates individual task files
- Creates dependency graph

**Output:**
```
Generated 15 tasks in docs/planning/tasks/

Tasks:
- TASK-001: Design Database Schema (database)
- TASK-002: Implement User Authentication (fullstack)
- TASK-003: Create User Profile API (backend)
- TASK-004: Build data processing utility (python-generic)
- TASK-005: User Dashboard UI (frontend)
- ... (10 more)

Summary: docs/planning/TASK_SUMMARY.md

Dependency graph shows:
- Foundation layer: TASK-001, TASK-002 (no dependencies)
- Layer 2: TASK-003, TASK-004 (depend on foundation)
- Layer 3: TASK-005 through TASK-010

Task Types:
- fullstack: 6 tasks
- backend: 4 tasks
- frontend: 3 tasks
- python-generic: 2 tasks

Next: /planning sprints to organize into cycles
```

**What to check:**
- Review `docs/planning/TASK_SUMMARY.md` for overview
- Check individual task files for completeness
- Verify dependency graph makes sense
- Confirm task types are appropriate
- Confirm complexity estimates are reasonable

### Step 3: Organize Sprints

```bash
/planning sprints
```

**What happens:**
- sprint-planner reads all tasks
- Groups by dependencies and priorities
- Balances workload across sprints
- Creates logical sprint goals
- Generates sprint files

**Output:**
```
Created 3 sprints in docs/sprints/

Sprint 1: Foundation & Authentication (5 tasks, 2 weeks)
Sprint 2: Core Features (7 tasks, 2 weeks)
Sprint 3: Advanced Features (3 tasks, 1 week)

Overview: docs/sprints/SPRINT_OVERVIEW.md

Ready to execute: /sprint execute SPRINT-001
```

**What to check:**
- Review `docs/sprints/SPRINT_OVERVIEW.md`
- Verify sprint goals align with your priorities
- Check sprint durations are realistic
- Confirm dependencies are properly sequenced

### Planning Phase Complete

At this point you have:
- ✅ Comprehensive PRD with tech stack defined
- ✅ All tasks decomposed with acceptance criteria and types
- ✅ Dependency graph showing task relationships
- ✅ Sprints organized with realistic timelines
- ✅ No code written yet - pure planning

**Time investment:** 15-20 minutes of your time (interactive Q&A)  
**Value:** Complete roadmap for automated development

---

## Phase 2: Execution

Execution is fully automated with quality gates and T1/T2 tier switching.

### Execute Sprint

```bash
/sprint execute SPRINT-001
```

**What happens:**

1. **Sprint Orchestrator initializes:**
   ```
   Sprint SPRINT-001 started: Foundation & Authentication
   Goal: Establish technical foundation and user login
   Tasks: 5 (TASK-001 through TASK-005)
   ```

2. **Tasks execute in dependency order:**
   ```
   Starting parallel group 1:
   - TASK-001: Design Database Schema
   - TASK-002: Set up CI/CD Pipeline
   
   [Both tasks run simultaneously]
   
   ✓ TASK-001 complete after 2 iterations, T1 only (1.5 hours)
   ✓ TASK-002 complete after 1 iteration, T1 only (45 minutes)
   
   Starting sequential tasks:
   - TASK-003: Implement User Authentication
     (depends on TASK-001)
   ```

3. **Each task goes through workflow with T1/T2 switching:**
   ```
   Executing TASK-003: Implement User Authentication
   
   Iteration 1 (T1):
   → database-designer creates schema
   → database-developer-python-t1 implements models
   → api-designer creates API spec
   → api-developer-python-t1 implements endpoints
   → frontend-designer designs components
   → frontend-developer-t1 implements UI
   → test-writer creates tests
   → security-auditor reviews security
   → documentation-coordinator writes docs
   
   → requirements-validator checks all acceptance criteria
   
   Validation: FAIL
   Outstanding requirements:
   - Missing: Error handling for network failures
   - Missing: Test coverage only 65% (target: 80%)
   
   Starting iteration 2 with targeted fixes (T1)...
   → api-developer-python-t1 adds error handling
   → test-writer adds more tests
   
   → requirements-validator checks again
   
   Validation: FAIL
   Outstanding requirements:
   - Complex OAuth token refresh logic incomplete
   - Edge case in session handling
   
   Starting iteration 3 (T2 takes over)...
   → api-developer-python-t2 implements complex OAuth logic
   → frontend-developer-t2 handles session edge cases
   → test-writer adds edge case tests
   
   → requirements-validator checks again
   
   Validation: PASS
   ✓ All acceptance criteria met
   ✓ Test coverage: 87%
   ✓ Security review: Clean
   ✓ Documentation: Complete
   
   ✓ TASK-003 complete after 3 iterations, T1→T2 switch (4 hours)
   ```

4. **Sprint completes:**
   ```
   ✓ Sprint SPRINT-001 complete!
   
   Summary:
   - 5/5 tasks completed successfully
   - 12 total iterations across all tasks
   - Average: 2.4 iterations per task
   - T1 only: 3 tasks (60%)
   - T1→T2: 2 tasks (40%)
   - All deliverables achieved
   - All quality gates passed
   
   Deliverables:
   ✓ User authentication working
   ✓ Database schema deployed
   ✓ CI/CD pipeline operational
   
   Full report: docs/sprints/SPRINT-001-summary.md
   
   Next: /sprint execute SPRINT-002
   ```

### What Happens During Execution

**Automated workflow:**
1. Task orchestrator determines task type (fullstack/backend/frontend/python-generic)
2. Appropriate workflow executes with specialized agents
3. Iteration 1-2: T1 (Haiku) agents implement and fix
4. Iteration 3+: T2 (Sonnet) agents take over if needed
5. Requirements validator checks ALL acceptance criteria
6. If validation fails: Loop back with specific gaps
7. If validation passes: Task complete
8. Sprint orchestrator moves to next task
9. Repeat until sprint complete

**You don't need to do anything** - just watch the progress.

---

## Monitoring & Status

### Check Sprint Progress

```bash
/sprint status SPRINT-001
```

**Output:**
```
Sprint SPRINT-001: Foundation & Authentication
Status: In Progress
Started: 2025-01-15 10:00
Progress: 3/5 tasks complete (60%)

Completed Tasks:
✓ TASK-001: Design Database Schema (2 iterations, T1, 1.5h)
✓ TASK-002: Set up CI/CD Pipeline (1 iteration, T1, 45min)
✓ TASK-003: Implement User Authentication (3 iterations, T1→T2, 4h)

In Progress:
⟳ TASK-004: Create User Profile API (iteration 1, T1)
   Started: 2025-01-15 15:00
   Current agent: api-developer-python-t1
   Status: Implementing endpoints

Pending:
⏸ TASK-005: User Profile Management UI (depends on TASK-004)

Tier Statistics:
- T1 completions: 2 tasks
- T1→T2 switches: 1 task

Estimated completion: 2 hours
```

### Check Task Details

```bash
/task status TASK-004
```

**Output:**
```
TASK-004: Create User Profile API
Status: In Progress
Type: backend
Current Iteration: 1 of 5 max
Current Tier: T1 (Haiku)

Acceptance Criteria:
1. GET /users/{id}/profile returns profile data
   Status: In Progress
2. PUT /users/{id}/profile updates profile
   Status: Not Started
3. Proper authorization (users can only update own profile)
   Status: Not Started
4. Test coverage >80%
   Status: Not Started

Current Agent: api-developer-python-t1
Action: Implementing GET endpoint

Started: 2025-01-15 15:00
Duration: 15 minutes

Previous Iterations: None (first iteration)
Tier History: T1 (iteration 1)
```

### View Validation History

```bash
/task validation TASK-003
```

**Output:**
```
TASK-003: Implement User Authentication
Validation History

Iteration 1 (T1): FAIL (2025-01-15 12:30)
Outstanding Requirements:
- Error handling for network failures
- Test coverage 65% (target: 80%)
- Missing password strength validation

Iteration 2 (T1): FAIL (2025-01-15 13:15)
Outstanding Requirements:
- Complex OAuth token refresh logic incomplete
- Edge case in session handling

Iteration 3 (T2): PASS (2025-01-15 14:30)
All acceptance criteria met:
✓ User can login with email/password
✓ OAuth integration working
✓ System shows specific error for invalid credentials
✓ Login persists across browser sessions
✓ Password requirements enforced
✓ Test coverage: 87%
✓ Security review: Clean

Completed after 3 iterations (T1→T2 switch)
Total time: 4 hours
T1 time: 2.5 hours
T2 time: 1.5 hours
```

---

## Understanding Iterations

### Why Iterations Happen

Requirements validation ensures quality:
1. Workflow executes with all specialized agents
2. Requirements validator checks EVERY acceptance criterion
3. If ANY criterion not met → FAIL → Iteration 2
4. Task orchestrator routes only to agents needed for gaps
5. Validation checks again
6. Repeat until PASS

**This is good!** Iterations ensure:
- No shortcuts
- No incomplete features
- No untested code
- No security gaps
- No missing documentation

### T1→T2 Quality Escalation

**Iteration 1-2 (T1 - Haiku):**
- Cost-optimized implementation
- Straightforward bug fixes
- Standard patterns
- Handles 70% of work effectively

**Iteration 3+ (T2 - Sonnet):**
- Activated when T1 fails twice
- Complex problem solving
- Advanced patterns
- Performance optimization
- Better handling of edge cases
- Handles complex 30% that needs enhanced reasoning

**This ensures:**
- Cost efficiency for simple tasks (70% complete with T1)
- Quality for complex scenarios (T2 handles difficult 30%)
- Automatic escalation (no manual intervention)
- Same quality outcomes at lower cost

### Typical Iteration Counts

**1 iteration (ideal):**
- Simple tasks
- Clear requirements
- Straightforward implementation
- T1 sufficient

**2-3 iterations (common):**
- Moderate complexity
- Some edge cases missed
- Test coverage adjustments
- Documentation refinements
- Usually T1 sufficient, occasionally T1→T2

**4-5 iterations (acceptable):**
- Complex features
- Security issues found
- Performance optimization needed
- Integration challenges
- T2 likely involved

**>5 iterations (problem):**
- Requirements unclear
- Scope too large
- Task needs splitting
- Human intervention needed

### What Gets Fixed in Iterations

**Iteration 1 typical gaps:**
- Initial implementation complete
- Some edge cases missed
- Test coverage needs improvement

**Iteration 2 (T1) typical gaps:**
- Error handling for edge cases
- Test coverage below threshold
- Missing input validation
- Documentation incomplete

**Iteration 3+ (T2) typical gaps (if T1 couldn't fix):**
- Complex business logic edge cases
- Advanced security scenarios
- Performance optimization
- Sophisticated integration patterns
- Architectural refinements

---

## Handling Failures

### Task Failure After Max Iterations

If a task fails after 5 iterations:

```
✗ TASK-004 failed after 5 iterations

Tier progression: T1 (iter 1-2) → T2 (iter 3-5)

Outstanding issues:
- Complex authorization logic not working correctly
- Integration with external API timing out
- Test coverage stuck at 75%

Options:
1. Review code and provide specific guidance
2. Adjust validation requirements (lower coverage threshold)
3. Split into smaller tasks (recommended)
4. Skip task and create technical debt ticket

What would you like to do?
```

**Recommended actions:**

**Option 1: Provide Guidance**
```bash
# Review the code yourself
# Then provide specific instructions

"For TASK-004, the authorization issue is because we need to check 
 both user.id and profile.user_id. Update the authorization middleware 
 to validate profile.user_id matches the authenticated user.id."

/task retry TASK-004
```

**Option 2: Adjust Requirements**
```bash
# If requirements are too strict
/task adjust-validation TASK-004 --test-coverage 70

# Then retry
/task retry TASK-004
```

**Option 3: Split Task (Best)**
```bash
# Create smaller, focused tasks
# This is usually the right answer for complex failures

"Split TASK-004 into:
 TASK-004A: Basic profile CRUD (no complex authorization)
 TASK-004B: Advanced authorization rules
 Update sprint plan accordingly"
```

**Option 4: Skip (Last Resort)**
```bash
# Only if task is non-critical
/task skip TASK-004 --create-debt-ticket

# Creates technical debt tracking
# Sprint continues without this task
```

### Sprint-Level Failures

If a critical task fails:

```
TASK-002 (CI/CD Pipeline) failed - blocks 8 dependent tasks

Sprint SPRINT-001 paused

Impact analysis:
- 8 tasks cannot start (depend on TASK-002)
- Sprint deliverables at risk
- Estimated delay: 1-2 days if not resolved

Recommendations:
1. Review TASK-002 failure details
2. Provide guidance or adjust approach
3. Consider if task needs to be broken down

Sprint will resume once TASK-002 completes or is skipped.
```

**Resolution:**
```bash
# Review failure
/task validation TASK-002

# Provide guidance
"The CI/CD pipeline is failing because GitHub Actions needs the 
 DEPLOY_KEY secret. Add it to repository secrets, then retry."

# Retry task
/task retry TASK-002

# Resume sprint
/sprint resume SPRINT-001
```

---

## Command Reference

### Planning Commands

```bash
# PRD Generation
/prd generate              # Start interactive PRD creation
/prd show                  # Display current PRD
/prd edit                  # Modify PRD (regenerates tasks/sprints)

# Task Planning
/planning analyze          # Generate tasks from PRD
/planning show             # Display task summary
/planning graph            # Show dependency graph
/planning task-types       # Show task type distribution

# Sprint Planning
/planning sprints          # Organize tasks into sprints
/planning sprint-overview  # Display sprint overview
```

### Execution Commands

```bash
# Sprint Execution
/sprint execute SPRINT-001 # Execute entire sprint
/sprint pause SPRINT-001   # Pause sprint execution
/sprint resume SPRINT-001  # Resume paused sprint
/sprint status SPRINT-001  # Check progress
/sprint report SPRINT-001  # Generate full report

# Task Execution
/task execute TASK-001     # Execute single task
/task retry TASK-001       # Retry failed task
/task status TASK-001      # Check task progress
/task validation TASK-001  # View validation history
/task tier-usage TASK-001  # View T1/T2 tier usage
```

### Advanced Commands

```bash
# Adjustments
/task adjust-validation TASK-001 --test-coverage 70
/task adjust-validation TASK-001 --disable security-check-X

# Technical Debt
/task skip TASK-001 --create-debt-ticket
/task debt-report          # Show all technical debt

# Debugging
/task logs TASK-001        # View execution logs
/task artifacts TASK-001   # View generated artifacts
/sprint timeline SPRINT-001 # Show timeline visualization

# Force Actions (use sparingly)
/sprint force-complete TASK-001  # Mark complete without validation
/sprint skip-task TASK-001       # Skip task in sprint
```

### Information Commands

```bash
# System Info
/system status             # Overall system health
/system stats              # Execution statistics
/system tier-usage         # T1/T2 usage statistics
/agents list               # Show all agents
/workflows list            # Show all workflows

# Project Info
/project overview          # Project summary
/project tech-stack        # Current technology stack
/project metrics           # Quality metrics across project
```

---

## Best Practices

### Planning Best Practices

**1. Be specific in PRD:**
- ✅ "Users can login with email and password"
- ❌ "Authentication should work"

**2. Define clear acceptance criteria:**
- ✅ "Test coverage >80%"
- ❌ "Good test coverage"

**3. Identify integrations early:**
- Drives tech stack selection
- Affects architecture decisions
- Impacts task breakdown

**4. Define what's out of scope:**
- Prevents scope creep
- Keeps sprints focused
- Sets clear boundaries

**5. Consider task types:**
- Fullstack for complete features
- Backend for API-only work
- Frontend for UI-only work
- Python-generic for utilities/scripts

### Execution Best Practices

**1. Let iterations happen:**
- Don't intervene on first iteration failure
- Quality gates are working as designed
- 2-3 iterations is normal and good

**2. Trust T1→T2 escalation:**
- System knows when to escalate
- 70% T1 completion is healthy
- T2 handles genuine complexity
- Don't manually override tier selection

**3. Monitor but don't micromanage:**
- Check status periodically
- Review validation failures
- Provide guidance only when needed

**4. Intervene at 4+ iterations:**
- Review what's stuck
- Provide specific guidance
- Consider splitting task

**5. Trust the validation:**
- If validator says FAIL, something is missing
- Review validation report details
- Fix gaps, don't adjust requirements (usually)

### Quality Best Practices

**1. Don't lower standards:**
- 80% test coverage is minimum
- Security review is mandatory
- Documentation is required
- Resist temptation to skip for speed

**2. Address technical debt immediately:**
- Don't accumulate skipped tasks
- Plan debt paydown in next sprint
- Track debt with proper tickets

**3. Review sprint summaries:**
- Learn from iteration patterns
- Learn from tier usage patterns
- Adjust task sizing for future
- Improve requirement clarity

**4. Celebrate quality:**
- Tasks passing validation on iteration 1
- High percentage of T1-only completions
- High test coverage
- Clean security audits
- Complete documentation

### Productivity Best Practices

**1. Batch planning work:**
- Do all planning up front
- Don't plan during execution
- Avoid partial planning

**2. Run sprints continuously:**
- Start SPRINT-002 immediately after SPRINT-001
- Don't wait days between sprints
- Maintain momentum

**3. Parallel where possible:**
- Some tasks can run simultaneously
- Sprint orchestrator handles this
- Don't serialize unnecessarily

**4. Learn from patterns:**
- Which tasks iterate most?
- Which tasks need T2?
- Which agents need clearer requirements?
- Which dependencies were missed?
- Improve future planning

### Cost Optimization Best Practices

**1. Monitor tier usage:**
- Review sprint reports for T1/T2 ratios
- Identify task types that need T2
- Adjust planning to reduce unnecessary complexity

**2. Optimize task sizing:**
- Smaller, focused tasks complete with T1
- Large, complex tasks trigger T2
- Split complex tasks in planning phase

**3. Improve requirement clarity:**
- Clear requirements reduce iterations
- Fewer iterations reduce T2 usage
- Better acceptance criteria help T1 succeed

**4. Track cost trends:**
- Monitor tier usage across sprints
- Identify optimization opportunities
- Balance cost with quality

---

## What Success Looks Like

**After Setup:**
- ✅ All 27 agents defined
- ✅ All 8 workflows configured
- ✅ Directory structure created
- ✅ Ready for `/prd generate`

**After Planning:**
- ✅ Comprehensive PRD with tech stack
- ✅ 10-30 tasks with clear acceptance criteria and types
- ✅ 2-5 sprints with realistic timelines
- ✅ Dependency graph makes sense
- ✅ You understand the roadmap

**During Execution:**
- ✅ Tasks complete automatically
- ✅ 1-3 iterations per task
- ✅ ~70% complete with T1 only
- ✅ ~30% escalate to T2 for complexity
- ✅ All quality gates pass
- ✅ Minimal human intervention
- ✅ Steady progress

**After Sprint:**
- ✅ All tasks complete
- ✅ All deliverables working
- ✅ Test coverage >80%
- ✅ Security review clean
- ✅ Documentation complete
- ✅ Tier usage tracked
- ✅ Ready for next sprint

**After Project:**
- ✅ MVP fully functional
- ✅ All features tested
- ✅ Security audited
- ✅ Performance optimized
- ✅ Fully documented
- ✅ Cost-optimized execution
- ✅ Ready for deployment

---

## Getting Help

### Common Issues

**"PRD generation is taking too long"**
- Interactive Q&A takes 10-15 minutes
- Have answers prepared beforehand
- This time investment saves hours later

**"Too many iterations on tasks"**
- Review validation reports for patterns
- Tasks might be too large → split them
- Requirements might be unclear → refine PRD
- Normal for complex features

**"Too many T2 escalations"**
- Review which tasks trigger T2
- Consider splitting complex tasks earlier
- Improve acceptance criteria clarity
- 30% T2 usage is normal and healthy

**"Task failed after 5 iterations"**
- Review validation details carefully
- Provide specific guidance
- Consider splitting task
- Don't skip unless non-critical

**"Sprint is blocked"**
- Check which task is blocking
- Review that task's failure reason
- Resolve blocker first
- Resume sprint execution

### Support Resources

- **Setup Guide:** `SETUP.md` - Initial configuration
- **Agent Reference:** `AGENTS.md` - All 27 agents detailed
- **Workflow Reference:** `WORKFLOWS.md` - All 8 workflows explained
- **This Guide:** `USAGE.md` - How to use the system

### System Logs

All execution is logged:
```
docs/sprints/SPRINT-001-execution.log    # Sprint-level logs
docs/planning/tasks/TASK-001-execution.yaml  # Task-level logs
docs/planning/tasks/TASK-001-validation-iteration-X.yaml  # Validation details
```

Review these for debugging and understanding what happened.

---

## Next Steps

Now that you understand how to use the system:

1. **Complete setup** (if not done): Give `SETUP.md` to Claude Code
2. **Start planning**: Run `/prd generate` and answer questions
3. **Review plans**: Check tasks and sprints make sense
4. **Execute**: Run `/sprint execute SPRINT-001`
5. **Monitor**: Check status periodically
6. **Learn**: Review tier usage patterns
7. **Iterate**: Learn and improve for next project

The system is designed to automate 90% of development work while maintaining quality and optimizing cost. Your role is:
- Guide planning with clear requirements
- Monitor progress
- Provide guidance when stuck
- Review tier usage and optimize
- Celebrate success

Good luck building!
