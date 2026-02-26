# Automatic Agent Selection System

This system automatically selects the most appropriate agent(s) for any given task based on task characteristics, keywords, and context.

## Selection Algorithm

```python
def select_agent(task: Task) -> Agent:
    """
    Select the most appropriate agent for a task.

    Algorithm:
    1. Extract task signals (keywords, file types, descriptions)
    2. Match against agent capability index
    3. Score candidates based on match quality
    4. Apply context modifiers (project type, urgency, etc.)
    5. Return best match (or multiple for parallel work)
    """
    signals = extract_signals(task)
    candidates = match_capabilities(signals)
    scored = score_candidates(candidates, task)
    return select_best(scored, task.context)
```

## Signal Extraction

### Keyword Categories

```yaml
keywords:
  # Architecture & Design
  architecture:
    keywords: [architecture, design, system design, scalability, microservices, monolith]
    agents: [architect, tech-lead]

  api_design:
    keywords: [api design, endpoint design, rest api, graphql schema, openapi]
    agents: [api-designer, architect]

  # Implementation
  backend:
    keywords: [backend, server, api endpoint, route, controller, service layer]
    agents: [api-developer-{lang}, backend-code-reviewer-{lang}]

  frontend:
    keywords: [frontend, ui, component, react, vue, angular, css, styling]
    agents: [frontend-developer, frontend-designer, frontend-code-reviewer]

  database:
    keywords: [database, sql, query, migration, schema, orm, model]
    agents: [database-developer-{lang}, database-designer]

  mobile:
    keywords: [mobile, ios, android, swift, kotlin, react native, flutter]
    agents: [ios-developer, android-developer]

  # DevOps & Infrastructure
  cicd:
    keywords: [ci/cd, pipeline, github actions, jenkins, deployment, release]
    agents: [cicd-specialist, release-engineer]

  infrastructure:
    keywords: [infrastructure, terraform, cloudformation, iac, provisioning]
    agents: [terraform-specialist, platform-engineer]

  containers:
    keywords: [docker, container, kubernetes, k8s, helm, pod, deployment]
    agents: [docker-specialist, kubernetes-specialist]

  # Reliability & Operations
  reliability:
    keywords: [reliability, sre, uptime, availability, incident, on-call]
    agents: [site-reliability-engineer]

  monitoring:
    keywords: [monitoring, observability, metrics, logs, traces, alerting]
    agents: [observability-engineer]

  # Security & Compliance
  security:
    keywords: [security, vulnerability, penetration, pentest, owasp]
    agents: [security-auditor, penetration-tester]

  compliance:
    keywords: [compliance, soc2, hipaa, gdpr, pci, audit, regulatory]
    agents: [compliance-engineer]

  # Quality & Testing
  testing:
    keywords: [test, unit test, integration test, e2e, coverage]
    agents: [test-writer, e2e-tester]

  performance:
    keywords: [performance, optimization, profiling, latency, throughput]
    agents: [performance-auditor-{lang}]

  accessibility:
    keywords: [accessibility, a11y, wcag, screen reader, aria]
    agents: [accessibility-specialist]

  # Data & AI
  data:
    keywords: [data engineering, etl, pipeline, data warehouse, spark]
    agents: [data-engineer]

  ml:
    keywords: [machine learning, ml, model, training, inference, ai]
    agents: [ml-engineer]

  analytics:
    keywords: [analytics, metrics, dashboard, reporting, bi]
    agents: [data-scientist, analytics-engineer]

  # Product & Planning
  product:
    keywords: [product, prd, requirements, user story, feature spec]
    agents: [product-manager, prd-generator]

  planning:
    keywords: [planning, roadmap, sprint, backlog, estimation]
    agents: [sprint-planner, product-manager]

  # Documentation & DevRel
  documentation:
    keywords: [documentation, docs, readme, api docs, tutorial]
    agents: [documentation-coordinator, technical-writer]

  devrel:
    keywords: [developer experience, dx, community, advocacy, onboarding]
    agents: [developer-advocate]

  # Bug Fixing
  debugging:
    keywords: [bug, debug, fix, error, issue, crash, exception]
    agents: [root-cause-analyst, code-archaeologist]
    escalation: bug-council-orchestrator  # For complex bugs
```

### File Type Mapping

```yaml
file_types:
  # Backend Languages
  ".py":
    primary: [api-developer-python, database-developer-python]
    review: [backend-code-reviewer-python]
    performance: [performance-auditor-python]

  ".ts":
    primary: [api-developer-typescript, frontend-developer]
    review: [backend-code-reviewer-typescript, frontend-code-reviewer]
    performance: [performance-auditor-typescript]

  ".go":
    primary: [api-developer-go, database-developer-go]
    review: [backend-code-reviewer-go]
    performance: [performance-auditor-go]

  ".java":
    primary: [api-developer-java, database-developer-java]
    review: [backend-code-reviewer-java]
    performance: [performance-auditor-java]

  ".rs":
    primary: [api-developer-rust]
    review: [backend-code-reviewer-rust]

  # Frontend
  ".tsx":
    primary: [frontend-developer]
    review: [frontend-code-reviewer]

  ".jsx":
    primary: [frontend-developer]
    review: [frontend-code-reviewer]

  ".css", ".scss":
    primary: [frontend-developer, frontend-designer]

  # Mobile
  ".swift":
    primary: [ios-developer]

  ".kt":
    primary: [android-developer]

  # Infrastructure
  ".tf":
    primary: [terraform-specialist]

  ".yaml", ".yml":
    context_dependent:
      kubernetes: [kubernetes-specialist]
      github_actions: [cicd-specialist]
      docker_compose: [docker-specialist]

  "Dockerfile":
    primary: [docker-specialist]

  # Database
  ".sql":
    primary: [database-designer, database-developer-{lang}]

  # Shell
  ".sh", ".bash":
    primary: [shell-developer]

  ".ps1":
    primary: [powershell-developer]
```

## Agent Capability Index

### Complete Agent Registry

```yaml
agents:
  # ===== ARCHITECTURE =====
  architect:
    capabilities: [system_design, technical_decisions, scalability, tradeoffs]
    model_default: opus
    complexity_threshold: 9
    triggers:
      keywords: [architecture, system design, scalability, design decision]
      task_types: [architecture, design_review]

  tech-lead:
    capabilities: [code_review, technical_leadership, mentoring, standards]
    model_default: sonnet
    complexity_threshold: 6
    triggers:
      keywords: [review, standards, best practices, technical decision]
      task_types: [code_review, technical_guidance]

  # ===== BACKEND =====
  api-designer:
    capabilities: [api_design, openapi, rest, graphql]
    model_default: sonnet
    triggers:
      keywords: [api design, endpoint design, api spec]
      task_types: [design]

  api-developer-python:
    capabilities: [python, fastapi, django, flask]
    languages: [python]
    frameworks: [fastapi, django, flask]
    triggers:
      files: ["*.py"]
      keywords: [python, fastapi, django]

  api-developer-typescript:
    capabilities: [typescript, node, express, nestjs]
    languages: [typescript, javascript]
    frameworks: [express, nestjs, next]
    triggers:
      files: ["*.ts", "*.js"]
      keywords: [typescript, node, express]

  api-developer-go:
    capabilities: [go, gin, echo, fiber]
    languages: [go]
    frameworks: [gin, echo, fiber]
    triggers:
      files: ["*.go"]
      keywords: [go, golang, gin]

  # [Additional language variants follow same pattern]

  # ===== SRE & PLATFORM =====
  site-reliability-engineer:
    capabilities: [reliability, slos, incident_response, capacity_planning]
    model_default: opus
    complexity_threshold: 8
    triggers:
      keywords: [reliability, sre, incident, availability, slo]
      task_types: [operations, incident_response]

  platform-engineer:
    capabilities: [idp, developer_experience, golden_paths, platform_apis]
    model_default: sonnet
    triggers:
      keywords: [platform, idp, developer experience, self-service]
      task_types: [platform, tooling]

  observability-engineer:
    capabilities: [monitoring, logging, tracing, alerting]
    model_default: sonnet
    triggers:
      keywords: [monitoring, observability, metrics, logging, tracing]
      task_types: [monitoring, observability]

  # ===== SECURITY =====
  security-auditor:
    capabilities: [security_review, vulnerability_assessment, secure_coding]
    model_default: opus
    triggers:
      keywords: [security, vulnerability, secure, audit]
      task_types: [security_review]

  penetration-tester:
    capabilities: [penetration_testing, ethical_hacking, vulnerability_exploitation]
    model_default: opus
    triggers:
      keywords: [pentest, penetration test, ethical hacking, security testing]
      task_types: [security_testing]

  compliance-engineer:
    capabilities: [compliance, regulatory, soc2, hipaa, gdpr, pci]
    model_default: opus
    triggers:
      keywords: [compliance, soc2, hipaa, gdpr, pci, audit, regulatory]
      task_types: [compliance]

  # ===== QUALITY =====
  test-writer:
    capabilities: [unit_tests, integration_tests, test_strategy]
    model_default: sonnet
    triggers:
      keywords: [test, unit test, integration test, coverage]
      task_types: [testing]

  e2e-tester:
    capabilities: [e2e_testing, playwright, cypress, browser_automation]
    model_default: sonnet
    triggers:
      keywords: [e2e, end to end, playwright, cypress, browser test]
      task_types: [e2e_testing]

  accessibility-specialist:
    capabilities: [wcag, a11y, screen_reader, inclusive_design]
    model_default: sonnet
    triggers:
      keywords: [accessibility, a11y, wcag, screen reader, aria]
      task_types: [accessibility]

  # ===== PRODUCT =====
  product-manager:
    capabilities: [product_strategy, roadmap, user_research, prioritization]
    model_default: opus
    triggers:
      keywords: [product, roadmap, user research, prioritization, strategy]
      task_types: [product_planning]

  # ===== DATA & AI =====
  data-engineer:
    capabilities: [data_pipelines, etl, data_modeling, spark, airflow]
    model_default: sonnet
    triggers:
      keywords: [data pipeline, etl, data warehouse, spark]
      task_types: [data_engineering]

  ml-engineer:
    capabilities: [machine_learning, model_training, mlops]
    model_default: opus
    triggers:
      keywords: [machine learning, ml, model, training, inference]
      task_types: [ml_engineering]

  # ===== DEVOPS =====
  cicd-specialist:
    capabilities: [pipelines, github_actions, jenkins, deployment]
    model_default: sonnet
    triggers:
      keywords: [ci/cd, pipeline, github actions, deployment]
      files: [".github/workflows/*", "Jenkinsfile"]

  docker-specialist:
    capabilities: [containers, dockerfile, docker_compose]
    model_default: haiku
    triggers:
      keywords: [docker, container, dockerfile]
      files: ["Dockerfile", "docker-compose.yml"]

  kubernetes-specialist:
    capabilities: [kubernetes, helm, operators, cluster_management]
    model_default: sonnet
    triggers:
      keywords: [kubernetes, k8s, helm, kubectl]
      files: ["*.yaml"]  # with k8s context

  terraform-specialist:
    capabilities: [terraform, infrastructure_as_code, cloud_provisioning]
    model_default: sonnet
    triggers:
      keywords: [terraform, iac, infrastructure]
      files: ["*.tf"]

  # ===== DEVREL =====
  developer-advocate:
    capabilities: [documentation, community, tutorials, developer_experience]
    model_default: sonnet
    triggers:
      keywords: [developer experience, community, tutorial, documentation]
      task_types: [devrel, documentation]

  # ===== DIAGNOSIS (Bug Council) =====
  root-cause-analyst:
    capabilities: [debugging, root_cause_analysis]
    model_default: opus
    bug_council: true

  code-archaeologist:
    capabilities: [git_history, regression_analysis]
    model_default: opus
    bug_council: true

  pattern-matcher:
    capabilities: [pattern_recognition, similar_bugs]
    model_default: opus
    bug_council: true

  systems-thinker:
    capabilities: [architectural_analysis, dependency_tracking]
    model_default: opus
    bug_council: true

  adversarial-tester:
    capabilities: [edge_cases, security_implications]
    model_default: opus
    bug_council: true
```

## Selection Logic

### Primary Selection

```python
def select_primary_agent(task: Task) -> Agent:
    """Select the primary agent for implementation."""

    scores = {}

    for agent in AGENT_REGISTRY:
        score = 0

        # Keyword matching (weight: 40%)
        for keyword in task.keywords:
            if keyword in agent.triggers.keywords:
                score += 40

        # File type matching (weight: 30%)
        for file in task.affected_files:
            ext = get_extension(file)
            if ext in agent.triggers.files:
                score += 30

        # Task type matching (weight: 20%)
        if task.type in agent.triggers.task_types:
            score += 20

        # Language/framework matching (weight: 10%)
        if task.language in agent.languages:
            score += 10
        if task.framework in agent.frameworks:
            score += 10

        scores[agent] = score

    # Return highest scoring agent
    return max(scores, key=scores.get)


def select_supporting_agents(task: Task, primary: Agent) -> list[Agent]:
    """Select supporting agents (reviewers, testers, etc.)."""

    supporting = []

    # Always add code reviewer for implementation tasks
    if task.type == 'implementation':
        reviewer = get_reviewer_for_language(task.language)
        supporting.append(reviewer)

    # Add security auditor for sensitive areas
    if task.has_security_implications:
        supporting.append(AGENTS['security-auditor'])

    # Add test writer if tests needed
    if task.requires_tests:
        supporting.append(AGENTS['test-writer'])

    # Add accessibility for UI work
    if task.type == 'frontend' and task.has_ui_components:
        supporting.append(AGENTS['accessibility-specialist'])

    return supporting
```

### Bug Council Activation

```python
def should_activate_bug_council(task: Task) -> bool:
    """Determine if Bug Council should be activated."""

    # Explicit request
    if task.flags.get('bug_council'):
        return True

    # High severity bugs
    if task.severity in ['critical', 'high']:
        return True

    # Complex bugs (multiple components)
    if len(task.affected_components) > 2:
        return True

    # Previous fix attempts failed
    if task.previous_attempts >= 2:
        return True

    # High complexity score
    if task.complexity_score >= 10:
        return True

    return False
```

## Usage Examples

### Example 1: API Endpoint Implementation

```yaml
task:
  description: "Create user registration endpoint"
  files: ["src/routes/auth.py", "src/models/user.py"]
  keywords: [api, endpoint, registration, python]

selection:
  primary: api-developer-python
  supporting:
    - test-writer
    - backend-code-reviewer-python
  model: sonnet (complexity: 5)
```

### Example 2: Complex Bug Fix

```yaml
task:
  description: "Users randomly logged out"
  severity: high
  affected_components: [auth, session, frontend]
  previous_attempts: 2

selection:
  activate_bug_council: true
  agents:
    - root-cause-analyst
    - code-archaeologist
    - pattern-matcher
    - systems-thinker
    - adversarial-tester
  model: opus (all)
```

### Example 3: Infrastructure Change

```yaml
task:
  description: "Add Redis caching layer"
  files: ["terraform/redis.tf", "src/cache/redis.ts"]
  keywords: [redis, caching, terraform, infrastructure]

selection:
  primary: terraform-specialist
  supporting:
    - api-developer-typescript
    - site-reliability-engineer
  model: sonnet
```

## Integration with Task Loop

The Task Loop uses this system:

```python
def execute_task(task: Task):
    # 1. Select agents
    primary = select_primary_agent(task)
    supporting = select_supporting_agents(task, primary)

    # 2. Activate Bug Council if needed
    if task.type == 'bug' and should_activate_bug_council(task):
        return execute_with_bug_council(task)

    # 3. Execute with primary agent
    result = execute_agent(primary, task)

    # 4. Run supporting agents
    for agent in supporting:
        result = execute_agent(agent, task, previous=result)

    return result
```
