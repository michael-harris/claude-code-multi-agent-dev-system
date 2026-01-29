# Learning Optimizer Skill

**Skill ID:** `meta:learning-optimizer`
**Category:** Meta
**Model:** `haiku`

## Purpose

Capture patterns from successful executions to improve future task handling. Learns from both successes and failures to optimize agent selection, model choices, and approaches.

## Capabilities

### 1. Pattern Recognition
- Identify successful approaches
- Detect failure patterns
- Recognize task similarities
- Track effective strategies

### 2. Optimization Suggestions
- Agent selection improvements
- Model tier recommendations
- Approach refinements
- Resource allocation

### 3. Metrics Tracking
- Success rates by task type
- Token efficiency
- Time to completion
- Quality gate pass rates

### 4. Knowledge Persistence
- Store learned patterns
- Update recommendations
- Prune outdated learnings
- Share across sessions

## Activation Triggers

```yaml
triggers:
  automatic:
    - Task completion
    - Quality gate failure
    - Model escalation
    - Session end

  keywords:
    - optimize
    - learn
    - improve
    - patterns
```

## Process

### Step 1: Capture Execution Data

```javascript
function captureExecution(task, result) {
    return {
        task: {
            type: task.type,
            complexity: task.complexity,
            keywords: extractKeywords(task.description),
            files_involved: task.filesModified
        },
        execution: {
            agents_used: result.agentsInvolved,
            models_used: result.modelsTried,
            iterations: result.iterations,
            escalations: result.escalations,
            duration: result.duration,
            tokens_used: result.totalTokens
        },
        outcome: {
            success: result.success,
            quality_gates_passed: result.gateResults,
            issues_encountered: result.issues,
            fixes_applied: result.fixes
        }
    }
}
```

### Step 2: Analyze Patterns

```javascript
function analyzePatterns(executions) {
    return {
        // Success patterns
        successful_approaches: findSuccessfulPatterns(executions),

        // Failure patterns
        common_failures: findFailurePatterns(executions),

        // Efficiency patterns
        optimal_agents: findOptimalAgentsByTaskType(executions),
        optimal_models: findOptimalModelsByComplexity(executions),

        // Anti-patterns
        inefficient_paths: findInefficiencies(executions)
    }
}

function findSuccessfulPatterns(executions) {
    const successful = executions.filter(e => e.outcome.success)

    return {
        // Tasks that succeeded first try
        first_try_success: groupBy(
            successful.filter(e => e.execution.iterations === 1),
            'task.type'
        ),

        // Effective agent combinations
        agent_combinations: findEffectiveCombinations(successful),

        // Optimal model selections
        model_choices: analyzeModelChoices(successful)
    }
}
```

### Step 3: Generate Recommendations

```yaml
recommendations:
  agent_selection:
    - task_pattern: "API endpoint implementation"
      recommended: "api-developer-{language}-t1"
      confidence: 0.85
      basis: "92% success rate, avg 1.2 iterations"

    - task_pattern: "Complex refactoring"
      recommended: "refactoring-agent"
      confidence: 0.78
      basis: "Better than generic developer for restructuring"

  model_selection:
    - complexity_range: "1-4"
      recommended: "haiku"
      success_rate: 0.94
      avg_tokens: 3500

    - complexity_range: "5-8"
      recommended: "sonnet"
      success_rate: 0.89
      when_to_escalate: "After 2 quality gate failures"

    - complexity_range: "9+"
      recommended: "opus"
      success_rate: 0.82
      note: "Consider task breakdown if complexity > 12"

  approach_optimizations:
    - pattern: "Test failures"
      optimization: "Run lint before tests (catches 60% of issues)"

    - pattern: "Type errors"
      optimization: "Type check incrementally, not at end"
```

### Step 4: Persist Learnings

```javascript
// Store in SQLite
async function persistLearnings(learnings) {
    await db.run(`
        INSERT INTO learnings (
            task_pattern,
            recommendation_type,
            recommendation,
            confidence,
            sample_size,
            last_updated
        ) VALUES (?, ?, ?, ?, ?, datetime('now'))
        ON CONFLICT(task_pattern, recommendation_type)
        DO UPDATE SET
            recommendation = excluded.recommendation,
            confidence = excluded.confidence,
            sample_size = sample_size + excluded.sample_size,
            last_updated = excluded.last_updated
    `, [
        learnings.pattern,
        learnings.type,
        JSON.stringify(learnings.recommendation),
        learnings.confidence,
        learnings.sampleSize
    ])
}

// Retrieve learnings for task
async function getLearningsForTask(task) {
    const patterns = extractPatterns(task)

    return await db.all(`
        SELECT * FROM learnings
        WHERE task_pattern IN (?)
        AND confidence > 0.6
        ORDER BY confidence DESC
    `, [patterns])
}
```

## Metrics Dashboard

```yaml
metrics_summary:
  overall:
    total_tasks: 150
    success_rate: "87%"
    avg_iterations: 1.8
    avg_tokens_per_task: 12500

  by_task_type:
    feature:
      count: 60
      success_rate: "85%"
      avg_complexity: 6.2

    bug_fix:
      count: 45
      success_rate: "92%"
      avg_complexity: 4.1

    refactoring:
      count: 25
      success_rate: "84%"
      avg_complexity: 5.8

  model_efficiency:
    haiku:
      usage: "45%"
      success_rate: "91%"
      avg_cost: "$0.02"

    sonnet:
      usage: "40%"
      success_rate: "88%"
      avg_cost: "$0.15"

    opus:
      usage: "15%"
      success_rate: "82%"
      avg_cost: "$0.85"

  improvement_trends:
    last_30_days:
      success_rate_change: "+5%"
      avg_iterations_change: "-0.3"
      token_efficiency_change: "+12%"
```

## Integration with Ralph

```javascript
// Ralph uses learnings for decisions
async function selectAgentWithLearnings(task) {
    const learnings = await getLearningsForTask(task)

    if (learnings.agentRecommendation) {
        log(`Using learned agent: ${learnings.agentRecommendation.agent}`)
        return learnings.agentRecommendation.agent
    }

    // Fall back to default selection
    return selectAgentByRules(task)
}

// Adjust escalation based on patterns
function shouldEscalate(failures, task) {
    const learnings = getLearningsForTask(task)

    // If this pattern typically needs more iterations, be patient
    if (learnings.avgIterations > 3) {
        return failures > learnings.escalationThreshold
    }

    return failures > defaultThreshold
}
```

## Output Format

```yaml
learning_report:
  session_learnings:
    tasks_analyzed: 5
    new_patterns_identified: 2
    recommendations_updated: 3

  key_insights:
    - "TypeScript API tasks succeed 15% more often with sonnet vs haiku"
    - "Running tests before lint reduces iterations by 0.4 on average"
    - "Bug Council activation correlated with 25% higher success on complex bugs"

  updated_recommendations:
    - type: "agent_selection"
      pattern: "database migration"
      old: "database-developer-t1"
      new: "database-designer + database-developer-t1"
      reason: "Schema design step improves success rate"
```

## See Also

- `skills/meta/context-manager.md` - Context optimization
- `agents/orchestration/ralph-orchestrator.md` - Uses learnings
- `scripts/schema.sql` - Learnings storage schema
