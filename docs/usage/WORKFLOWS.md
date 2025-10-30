# Orchestration Patterns (Pragmatic Approach)

**IMPORTANT:** This document originally described YAML workflows, but the pragmatic approach uses **slash commands** instead.

**How it works:**
- Slash commands in `.claude/commands/` contain markdown prompts
- Claude reads these prompts and manually orchestrates agents
- Claude uses the Task tool to launch agents sequentially
- Claude tracks state (iterations, T1/T2 switching) in responses

**See `.claude/commands/` for actual orchestration prompts.**

---

## Original YAML Workflow Reference (For Understanding Only)

The content below shows the original YAML workflow designs. These are NOT executed automatically.
Instead, Claude follows similar logic manually when orchestrating agents:

### File: `.claude/workflows/prd-generation.yaml`

```yaml
name: prd-generation
description: Interactive PRD creation through structured Q&A
trigger: manual
command: "/prd generate"

steps:
  - name: initialize
    agent: prd-generator
    action: start_conversation
    parameters:
      greeting: "I'll help you create a comprehensive PRD. Let's start with your technology stack."

  - name: gather_requirements
    agent: prd-generator
    action: structured_interview
    flow: interactive
    phases:
      - tech_stack_selection
      - problem_and_solution
      - users_and_use_cases
      - technical_context
      - success_criteria
      - constraints_and_dependencies
      - details_if_needed

  - name: validate_completeness
    agent: prd-generator
    action: check_requirements
    validations:
      - tech_stack_chosen: true
      - min_requirements: 3
      - success_metrics_defined: true
      - constraints_identified: true

  - name: generate_prd
    agent: prd-generator
    action: create_document
    output:
      file: "docs/planning/PROJECT_PRD.yaml"
      format: yaml

  - name: confirm_next_steps
    agent: prd-generator
    action: provide_guidance
    message: |
      PRD saved to docs/planning/PROJECT_PRD.yaml
      
      Next steps:
      1. `/planning analyze` - Break PRD into tasks
      2. `/planning sprints` - Organize tasks into sprints
      3. `/sprint execute SPRINT-001` - Start development

completion:
  status: "PRD created successfully"
  next_workflow: "project-planning"
```

### File: `.claude/workflows/project-planning.yaml`

```yaml
name: project-planning
description: Decomposes PRD into tasks and organizes into sprints
trigger: manual
command: "/planning analyze"

steps:
  - name: analyze_prd
    agent: task-graph-analyzer
    action: read_prd
    input:
      file: "docs/planning/PROJECT_PRD.yaml"

  - name: identify_features
    agent: task-graph-analyzer
    action: extract_features
    process:
      - parse must-have requirements
      - parse should-have requirements
      - identify technical foundations needed

  - name: decompose_tasks
    agent: task-graph-analyzer
    action: break_down_features
    for_each: feature
    generate:
      - task_definition
      - acceptance_criteria
      - technical_requirements
      - complexity_estimate
      - dependencies
      - task_type (fullstack/backend/frontend/database/python-generic/infrastructure)

  - name: analyze_dependencies
    agent: task-graph-analyzer
    action: build_dependency_graph
    process:
      - identify blocking relationships
      - identify parallel opportunities
      - validate no circular dependencies

  - name: create_task_files
    agent: task-graph-analyzer
    action: generate_files
    output:
      directory: "docs/planning/tasks/"
      pattern: "TASK-{number:03d}.yaml"
      summary: "docs/planning/TASK_SUMMARY.md"

  - name: organize_sprints
    agent: sprint-planner
    action: read_tasks
    input:
      directory: "docs/planning/tasks/"

  - name: plan_sprints
    agent: sprint-planner
    action: create_sprints
    strategy:
      - respect dependencies
      - balance workload
      - deliver value early
      - enable parallelization
      - create checkpoints

  - name: generate_sprint_files
    agent: sprint-planner
    action: write_files
    output:
      directory: "docs/sprints/"
      pattern: "SPRINT-{number:03d}.yaml"
      overview: "docs/sprints/SPRINT_OVERVIEW.md"

  - name: confirm_completion
    action: notify
    message: |
      Planning complete!
      
      Generated:
      - {task_count} tasks in docs/planning/tasks/
      - {sprint_count} sprints in docs/sprints/
      
      Summary: docs/planning/TASK_SUMMARY.md
      Overview: docs/sprints/SPRINT_OVERVIEW.md
      
      Ready to execute:
      `/sprint execute SPRINT-001`

completion:
  status: "Planning complete"
  next_workflow: "sprint-execution"
```

### File: `.claude/workflows/sprint-execution.yaml`

```yaml
name: sprint-execution
description: Orchestrates entire sprint from start to finish
trigger: manual
command: "/sprint execute {sprint_id}"

parameters:
  - name: sprint_id
    type: string
    required: true
    pattern: "SPRINT-\\d{3}"

steps:
  - name: initialize_sprint
    agent: sprint-orchestrator
    action: read_sprint_file
    input:
      file: "docs/sprints/{sprint_id}.yaml"

  - name: create_execution_log
    agent: sprint-orchestrator
    action: initialize_logging
    output:
      file: "docs/sprints/{sprint_id}-execution.log"
      status_file: "docs/sprints/{sprint_id}-status.md"

  - name: analyze_task_groups
    agent: sprint-orchestrator
    action: build_execution_order
    process:
      - extract task_order from sprint file
      - identify parallel_groups
      - identify sequential dependencies

  - name: execute_task_groups
    agent: sprint-orchestrator
    action: iterate_groups
    for_each: task_group
    parallel: if group is parallel_group
    sequential: if group is sequential
    
    task_execution:
      workflow: task-execution
      parameters:
        task_id: "{task_id}"
        sprint_id: "{sprint_id}"
      
      on_success:
        - mark_complete
        - log_completion
        - update_status_file
        - record_tier_usage (T1/T2 statistics)
      
      on_failure:
        - log_failure
        - check_blocking_impact
        - notify_human

  - name: validate_sprint_completion
    agent: sprint-orchestrator
    action: check_all_tasks
    validations:
      - all_tasks_complete: true
      - all_deliverables_achieved: true
      - all_quality_gates_passed: true

  - name: generate_sprint_summary
    agent: sprint-orchestrator
    action: create_summary
    output:
      file: "docs/sprints/{sprint_id}-summary.md"
    include:
      - task_performance
      - iteration_statistics
      - tier_usage_statistics (T1 vs T2)
      - quality_metrics
      - lessons_learned
      - next_sprint_readiness

  - name: notify_completion
    action: message
    content: |
      ✓ {sprint_id} complete!
      
      Summary:
      - {task_count}/{task_count} tasks completed
      - Total iterations: {iteration_count}
      - T1→T2 switches: {tier_switch_count}
      - All deliverables achieved
      
      Full report: docs/sprints/{sprint_id}-summary.md
      
      Next: `/sprint execute {next_sprint_id}`

completion:
  status: "Sprint complete"
  next_action: "Start next sprint or review backlog"

error_handling:
  task_failure:
    - pause_sprint
    - generate_failure_report
    - request_human_intervention
    - options:
        - retry_with_guidance
        - skip_task_with_debt
        - adjust_requirements
```

### File: `.claude/workflows/task-execution.yaml`

```yaml
name: task-execution
description: Executes single task with iterative quality validation and T1/T2 switching
trigger: internal
called_by: sprint-orchestrator

parameters:
  - name: task_id
    type: string
    required: true
  - name: sprint_id
    type: string
    required: false

configuration:
  max_iterations: 5
  validation_required: true
  tier_switching:
    enabled: true
    t1_iterations: 2
    t2_starts_at: 3

steps:
  - name: initialize_task
    agent: task-orchestrator
    action: read_task_file
    input:
      file: "docs/planning/tasks/{task_id}.yaml"

  - name: create_execution_log
    agent: task-orchestrator
    action: initialize_logging
    output:
      file: "docs/planning/tasks/{task_id}-execution.yaml"

  - name: determine_workflow
    agent: task-orchestrator
    action: select_workflow_type
    based_on: task.type
    options:
      fullstack: fullstack-feature
      backend: api-development
      frontend: frontend-development
      database: database-only
      python-generic: generic-python-development
      infrastructure: infrastructure-setup

  - name: iteration_loop
    agent: task-orchestrator
    action: execute_with_validation
    max_iterations: 5
    
    iteration:
      - name: determine_tier
        action: calculate_tier
        logic: |
          if iteration <= 2:
            tier = "t1"
          else:
            tier = "t2"
      
      - name: execute_workflow
        action: run_workflow
        workflow: "{selected_workflow}"
        context:
          task: "{task_data}"
          iteration: "{current_iteration}"
          tier: "{calculated_tier}"
          previous_gaps: "{gaps_from_last_iteration}"

      - name: collect_artifacts
        action: gather_outputs
        from:
          - database_implementation
          - api_implementation
          - frontend_implementation
          - python_implementation
          - tests
          - security_audit
          - documentation

      - name: validate_requirements
        agent: requirements-validator
        action: validate_task
        input:
          task_file: "docs/planning/tasks/{task_id}.yaml"
          artifacts: "{collected_artifacts}"
          iteration: "{current_iteration}"
          tier_used: "{calculated_tier}"
        
        output:
          file: "docs/planning/tasks/{task_id}-validation-iteration-{iteration}.yaml"

      - name: check_validation_result
        action: evaluate
        conditions:
          - condition: validation.status == "PASS"
            then: complete_task
          
          - condition: validation.status == "FAIL" AND iteration < max_iterations
            then: restart_with_gaps
            parameters:
              gaps: "{validation.outstanding_requirements}"
              recommended_agents: "{validation.recommended_agents}"
              next_tier: "{tier_for_next_iteration}"
          
          - condition: validation.status == "FAIL" AND iteration >= max_iterations
            then: escalate_failure

  - name: complete_task
    when: validation_passed
    actions:
      - mark_task_complete
      - generate_completion_report
      - record_tier_statistics
      - update_sprint_status
      - notify_success

  - name: escalate_failure
    when: max_iterations_exceeded
    actions:
      - generate_failure_report
      - identify_blocking_impact
      - notify_human
      - provide_options

completion:
  on_success:
    status: "complete"
    report: "docs/planning/tasks/{task_id}-completion.md"
    metrics:
      - iterations_used
      - tier_switches
      - time_elapsed
  
  on_failure:
    status: "failed"
    report: "docs/planning/tasks/{task_id}-failure.md"
    options:
      - "Review and provide guidance"
      - "Adjust validation requirements"
      - "Skip task (creates technical debt)"
```

### File: `.claude/workflows/fullstack-feature.yaml`

```yaml
name: fullstack-feature
description: Complete fullstack feature implementation with T1/T2 switching
trigger: internal
called_by: task-orchestrator

parameters:
  - name: task
    type: object
    required: true
  - name: iteration
    type: integer
    default: 1
  - name: tier
    type: string
    default: "t1"
  - name: previous_gaps
    type: array
    default: []

steps:
  - name: load_prd
    action: read_file
    file: "docs/planning/PROJECT_PRD.yaml"
    extract: technical.backend.language

  - name: database_layer
    sequence:
      - name: design_schema
        agent: database-designer
        action: design
        input: "{task.technical_requirements.database}"
        output: "docs/database/schema-{task.id}.yaml"
        
        skip_if: iteration > 1 AND "database" not in previous_gaps

      - name: implement_schema
        agent: database-developer-{backend_language}-{tier}
        action: implement
        input: "docs/database/schema-{task.id}.yaml"
        output:
          models: "src/models/"
          migrations: "migrations/" or "prisma/migrations/"
        
        tier_selection:
          iteration_1: t1
          iteration_2: t1
          iteration_3_plus: t2
        
        skip_if: iteration > 1 AND "database" not in previous_gaps

  - name: api_layer
    sequence:
      - name: design_api
        agent: api-designer
        action: design
        input:
          task: "{task}"
          database_schema: "docs/database/schema-{task.id}.yaml"
        output: "docs/api/{task.id}-api-spec.yaml"
        
        skip_if: iteration > 1 AND "api" not in previous_gaps

      - name: implement_api
        agent: api-developer-{backend_language}-{tier}
        action: implement
        input:
          spec: "docs/api/{task.id}-api-spec.yaml"
          task: "{task}"
        output: "src/api/" or "src/routes/"
        
        tier_selection:
          iteration_1: t1
          iteration_2: t1
          iteration_3_plus: t2
        
        skip_if: iteration > 1 AND "api" not in previous_gaps

      - name: review_backend
        agent: backend-code-reviewer-{backend_language}
        action: review
        input:
          code: "src/"
          task: "{task}"
        output: "docs/reviews/{task.id}-backend-review.md"

  - name: frontend_layer
    sequence:
      - name: design_components
        agent: frontend-designer
        action: design
        input:
          task: "{task}"
          api_contract: "docs/api/{task.id}-api-spec.yaml"
        output: "docs/frontend/{task.id}-design.md"
        
        skip_if: iteration > 1 AND "frontend" not in previous_gaps

      - name: implement_frontend
        agent: frontend-developer-{tier}
        action: implement
        input:
          design: "docs/frontend/{task.id}-design.md"
          api_contract: "docs/api/{task.id}-api-spec.yaml"
        output: "src/frontend/components/"
        
        tier_selection:
          iteration_1: t1
          iteration_2: t1
          iteration_3_plus: t2
        
        skip_if: iteration > 1 AND "frontend" not in previous_gaps

      - name: review_frontend
        agent: frontend-code-reviewer
        action: review
        input:
          code: "src/frontend/"
          task: "{task}"
        output: "docs/reviews/{task.id}-frontend-review.md"

  - name: quality_layer
    parallel: true
    steps:
      - name: write_tests
        agent: test-writer
        action: generate_tests
        input:
          backend_code: "src/api/" or "src/models/"
          frontend_code: "src/frontend/"
          task: "{task}"
        output: "tests/"

      - name: security_audit
        agent: security-auditor
        action: audit
        input:
          backend: "src/"
          frontend: "src/frontend/"
          task: "{task}"
        output: "docs/security/{task.id}-audit.md"

  - name: documentation
    agent: documentation-coordinator
    action: generate_docs
    input:
      task: "{task}"
      database: "docs/database/schema-{task.id}.yaml"
      api: "docs/api/{task.id}-api-spec.yaml"
      frontend: "docs/frontend/{task.id}-design.md"
    output:
      api_docs: "docs/api/{task.id}.md"
      user_guide: "docs/features/{task.id}.md"

output:
  artifacts:
    database_implementation: "src/models/"
    api_implementation: "src/api/"
    frontend_implementation: "src/frontend/"
    tests: "tests/"
    security_audit: "docs/security/{task.id}-audit.md"
    documentation: "docs/"
  
  metrics:
    tier_used: "{tier}"
    iteration: "{iteration}"
```

### File: `.claude/workflows/api-development.yaml`

```yaml
name: api-development
description: Backend API implementation (no frontend) with T1/T2 switching
trigger: internal
called_by: task-orchestrator

parameters:
  - name: task
    type: object
    required: true
  - name: iteration
    type: integer
    default: 1
  - name: tier
    type: string
    default: "t1"

steps:
  - name: load_tech_stack
    action: read_prd
    extract: technical.backend.language

  - name: database_if_needed
    condition: task.technical_requirements.database exists
    sequence:
      - agent: database-designer
        action: design
      
      - agent: database-developer-{backend_language}-{tier}
        action: implement
        tier_selection:
          iteration_1: t1
          iteration_2: t1
          iteration_3_plus: t2

  - name: api_layer
    sequence:
      - name: design
        agent: api-designer
        action: design_api
      
      - name: implement
        agent: api-developer-{backend_language}-{tier}
        action: implement_api
        tier_selection:
          iteration_1: t1
          iteration_2: t1
          iteration_3_plus: t2
      
      - name: review
        agent: backend-code-reviewer-{backend_language}
        action: review_code

  - name: quality
    parallel: true
    steps:
      - agent: test-writer
        action: write_backend_tests
      
      - agent: security-auditor
        action: audit_backend

  - name: documentation
    agent: documentation-coordinator
    action: document_api

output:
  artifacts:
    api_implementation: "src/api/"
    tests: "tests/api/"
    security_audit: "docs/security/"
    documentation: "docs/api/"
  
  metrics:
    tier_used: "{tier}"
```

### File: `.claude/workflows/frontend-development.yaml`

```yaml
name: frontend-development
description: Frontend-only implementation (uses existing API) with T1/T2 switching
trigger: internal
called_by: task-orchestrator

parameters:
  - name: task
    type: object
    required: true
  - name: iteration
    type: integer
    default: 1
  - name: tier
    type: string
    default: "t1"
  - name: previous_gaps
    type: array
    default: []

steps:
  - name: load_api_contract
    action: read_file
    file: "docs/api/{existing_api_spec}.yaml"
    note: "Frontend implements against existing API"

  - name: design
    agent: frontend-designer
    action: design_components
    input:
      task: "{task}"
      api_contract: "{api_spec}"
    output: "docs/frontend/{task.id}-design.md"
    
    skip_if: iteration > 1

  - name: implement
    agent: frontend-developer-{tier}
    action: implement_components
    input:
      design: "docs/frontend/{task.id}-design.md"
      api_contract: "{api_spec}"
    output: "src/frontend/components/"
    
    tier_selection:
      iteration_1: t1
      iteration_2: t1
      iteration_3_plus: t2

  - name: review
    agent: frontend-code-reviewer
    action: review_code
    input:
      code: "src/frontend/"
      task: "{task}"

  - name: test
    agent: test-writer
    action: write_frontend_tests
    input:
      components: "src/frontend/components/"
      task: "{task}"
    output: "tests/frontend/"

  - name: documentation
    agent: documentation-coordinator
    action: document_components
    input:
      components: "src/frontend/components/"
      task: "{task}"
    output: "docs/components/{task.id}.md"

output:
  artifacts:
    frontend_implementation: "src/frontend/"
    tests: "tests/frontend/"
    documentation: "docs/components/"
  
  metrics:
    tier_used: "{tier}"
```

### File: `.claude/workflows/generic-python-development.yaml`

```yaml
name: generic-python-development
description: Non-backend Python development (utilities, scripts, CLI tools, algorithms)
trigger: internal
called_by: task-orchestrator

parameters:
  - name: task
    type: object
    required: true
  - name: iteration
    type: integer
    default: 1
  - name: tier
    type: string
    default: "t1"
  - name: previous_gaps
    type: array
    default: []

steps:
  - name: implement
    agent: python-developer-generic-{tier}
    action: implement_code
    input:
      task: "{task}"
      requirements: "{task.technical_requirements}"
    output: "src/utils/" or "src/scripts/" or "src/cli/" or "src/lib/"
    
    tier_selection:
      iteration_1: t1
      iteration_2: t1
      iteration_3_plus: t2

  - name: test
    agent: test-writer
    action: write_python_tests
    input:
      code: "{implementation_output}"
      task: "{task}"
    output: "tests/"

  - name: security_audit
    agent: security-auditor
    action: audit_python
    input:
      code: "{implementation_output}"
      task: "{task}"
    output: "docs/security/{task.id}-audit.md"

  - name: documentation
    agent: documentation-coordinator
    action: document_python
    input:
      code: "{implementation_output}"
      task: "{task}"
    output: "docs/python/"

output:
  artifacts:
    python_implementation: "src/"
    tests: "tests/"
    security_audit: "docs/security/"
    documentation: "docs/python/"
  
  metrics:
    tier_used: "{tier}"
```

---

## Workflow Execution Notes

### Conditional Execution

Workflows support conditional logic:
```yaml
skip_if: iteration > 1 AND "frontend" not in previous_gaps
```

This allows efficient re-execution, only running agents that need to fix gaps.

### Parallel Execution

Some steps run in parallel:
```yaml
parallel: true
steps:
  - agent: test-writer
  - agent: security-auditor
```

### Sequential Dependencies

Workflows enforce proper ordering:
```yaml
sequence:
  - design_schema
  - implement_schema  # waits for design
  - implement_api     # waits for implement_schema
```

### Dynamic Agent Selection

Workflows adapt to tech stack and tier:
```yaml
agent: database-developer-{backend_language}-{tier}
# Becomes: database-developer-python-t1 or database-developer-python-t2
```

### Tier Selection Logic

Workflows support automatic T1→T2 switching:
```yaml
agent: api-developer-{backend_language}-{tier}

tier_selection:
  iteration_1: t1      # First attempt (Haiku)
  iteration_2: t1      # First fix (Haiku)
  iteration_3_plus: t2 # Complex fixes (Sonnet)
```

This enables cost optimization while ensuring quality for complex scenarios.

### Error Handling

Each workflow includes error handling:
```yaml
on_failure:
  - log_error
  - determine_severity
  - notify_orchestrator
  - provide_recovery_options
```

### Output Collection

Workflows collect artifacts for validation:
```yaml
output:
  artifacts:
    database_implementation: "src/models/"
    api_implementation: "src/api/"
    tests: "tests/"
  
  metrics:
    tier_used: "{tier}"
    iteration: "{iteration}"
```

These artifacts and metrics are passed to requirements-validator for quality gate validation and sprint reporting.

---

## Workflow Commands

Users interact via commands:

```bash
# Phase 1: Planning
/prd generate              # Interactive PRD creation
/planning analyze          # Generate tasks from PRD
/planning sprints          # Organize tasks into sprints

# Phase 2: Execution
/sprint execute SPRINT-001 # Execute entire sprint
/task execute TASK-001     # Execute single task

# Status & Monitoring
/sprint status SPRINT-001  # Check sprint progress
/task status TASK-001      # Check task progress
/task validation TASK-001  # View validation history
/task tier-usage TASK-001  # View T1/T2 usage for task

# Advanced
/sprint pause SPRINT-001   # Pause execution
/sprint resume SPRINT-001  # Resume execution
/task retry TASK-001       # Force retry after failure
```

---

## Integration with Orchestrators

### Sprint Orchestrator uses workflows:
1. Reads sprint file
2. For each task: calls `task-execution` workflow
3. Tracks progress, completion, and tier usage statistics

### Task Orchestrator uses workflows:
1. Determines task type (from task.type field)
2. Selects appropriate workflow:
   - `fullstack` → fullstack-feature
   - `backend` → api-development
   - `frontend` → frontend-development
   - `database` → database-only
   - `python-generic` → generic-python-development
   - `infrastructure` → infrastructure-setup
3. Calculates tier (T1 for iterations 1-2, T2 for 3+)
4. Executes workflow with tier parameter
5. Submits to requirements-validator
6. If FAIL: Restarts with gaps and appropriate tier
7. If PASS: Task complete

### Requirements Validator validates workflow output:
1. Receives artifacts from workflow
2. Checks all acceptance criteria
3. Returns PASS or FAIL with gaps and recommended agents
4. If FAIL: Task orchestrator re-runs workflow with:
   - Specific gaps to address
   - Correct tier (T1 or T2)
   - Only affected agents re-execute

---

## T1→T2 Quality Escalation

### How It Works

**Iteration 1 (T1):**
- All developer agents use T1 (Haiku) tier
- Cost-optimized first attempt
- Straightforward implementation

**Iteration 2 (T1):**
- Validation failed, need fixes
- Continue with T1 (Haiku) tier
- Address straightforward gaps

**Iteration 3+ (T2):**
- Two T1 attempts failed
- Switch to T2 (Sonnet) tier for remaining iterations
- Enhanced reasoning for complex problems
- Better edge case handling

### Benefits

**Cost Efficiency:**
- 70% of tasks complete with T1 only
- Only complex scenarios need T2
- Automatic escalation based on validation

**Quality Assurance:**
- T1 handles standard implementations
- T2 handles complex scenarios
- No manual intervention needed

**Performance Tracking:**
- Sprint reports show T1 vs T2 usage
- Identify which task types need T2
- Optimize planning for future sprints

---

## Workflow Examples

### Example 1: Simple Task (T1 Only)

```
TASK-001: Create basic CRUD API
Type: backend

Execution:
[10:00] Iteration 1 (T1)
  - api-designer: Complete
  - api-developer-python-t1: Complete
  - test-writer: Complete
  - requirements-validator: PASS ✓

Result: Complete in 1 iteration with T1
Time: 45 minutes
Cost: Low (Haiku only)
```

### Example 2: Moderate Task (T1 with Fix)

```
TASK-002: User profile with validation
Type: fullstack

Execution:
[10:00] Iteration 1 (T1)
  - All agents execute with T1
  - requirements-validator: FAIL
    Gap: Missing edge case validation
  
[10:30] Iteration 2 (T1)
  - api-developer-python-t1: Fix validation
  - test-writer: Add edge case tests
  - requirements-validator: PASS ✓

Result: Complete in 2 iterations with T1
Time: 1.5 hours
Cost: Low (Haiku only)
```

### Example 3: Complex Task (T1→T2 Switch)

```
TASK-003: Complex authentication with OAuth
Type: fullstack

Execution:
[10:00] Iteration 1 (T1)
  - All agents execute with T1
  - requirements-validator: FAIL
    Gap: OAuth flow incomplete
  
[11:00] Iteration 2 (T1)
  - api-developer-python-t1: Attempt fix
  - requirements-validator: FAIL
    Gap: Complex token handling issues
  
[12:00] Iteration 3 (T2) ← SWITCH
  - api-developer-python-t2: Complex fix with enhanced reasoning
  - test-writer: Comprehensive OAuth tests
  - requirements-validator: PASS ✓

Result: Complete in 3 iterations (T1→T2)
Time: 3 hours
Cost: Medium (Haiku + Sonnet)
Quality: High (T2 resolved complexity)
```

### Example 4: Generic Python Task

```
TASK-004: Data processing utility
Type: python-generic

Execution:
[10:00] Iteration 1 (T1)
  - python-developer-generic-t1: Implement utility
  - test-writer: Write tests
  - security-auditor: Check for path traversal
  - requirements-validator: FAIL
    Gap: Missing error handling for edge cases
  
[10:30] Iteration 2 (T1)
  - python-developer-generic-t1: Add error handling
  - requirements-validator: PASS ✓

Result: Complete in 2 iterations with T1
Time: 1 hour
Cost: Low (Haiku only)
```

---

## Sprint-Level Reporting

After sprint completes, summary includes:

```markdown
Sprint SPRINT-001 Summary

Tasks: 5 completed
Total Iterations: 12
Average Iterations: 2.4

Tier Usage:
- T1 Only: 3 tasks (60%)
- T1→T2: 2 tasks (40%)
- T2 Switches: 2

Cost Analysis:
- T1 Hours: 18 (Haiku)
- T2 Hours: 6 (Sonnet)
- Cost Efficiency: 75% T1

Quality Metrics:
- All validation passed
- Test coverage: 87% average
- Security: 0 critical issues

Recommendations:
- Tasks requiring OAuth: Consider starting with T2
- Database tasks: T1 sufficient
- Frontend tasks: T1 sufficient with good designs
```

This data helps optimize future sprint planning and agent selection.
