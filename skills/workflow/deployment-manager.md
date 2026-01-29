# Deployment Manager Skill

**Skill ID:** `workflow:deployment-manager`
**Category:** Workflow
**Model:** `sonnet`

## Purpose

Manage deployment processes across environments. Handles deployment strategies, rollback procedures, and environment-specific configurations.

## Capabilities

### 1. Deployment Strategies
- Blue-green deployments
- Canary releases
- Rolling updates
- Feature flags

### 2. Environment Management
- Development → Staging → Production
- Environment-specific configs
- Secret management
- Infrastructure provisioning

### 3. Release Management
- Version tagging
- Changelog generation
- Release notes
- Semantic versioning

### 4. Rollback Procedures
- Quick rollback execution
- Database migration rollback
- Health check monitoring
- Incident response

## Activation Triggers

```yaml
triggers:
  keywords:
    - deploy
    - release
    - rollback
    - environment
    - staging
    - production
    - blue-green
    - canary

  task_types:
    - deployment
    - release
    - environment_setup
```

## Process

### Step 1: Pre-Deployment Checks

```yaml
pre_deployment_checklist:
  code_quality:
    - All tests pass
    - No linting errors
    - Security scan clean
    - Code review approved

  environment:
    - Target environment accessible
    - Required secrets configured
    - Database migrations ready
    - Rollback plan documented

  communication:
    - Team notified
    - Change window approved
    - Monitoring dashboards ready
```

### Step 2: Deployment Strategy Selection

```yaml
strategy_selection:
  blue_green:
    when: "Zero-downtime required, instant rollback needed"
    how: "Deploy to idle environment, switch traffic"

  canary:
    when: "Gradual rollout, risk mitigation needed"
    how: "Deploy to subset, monitor, expand"

  rolling:
    when: "Resource constraints, acceptable brief degradation"
    how: "Update instances one at a time"

  feature_flag:
    when: "Decouple deploy from release"
    how: "Deploy dark, enable via flag"
```

### Step 3: Execute Deployment

```javascript
// Blue-Green Deployment
async function blueGreenDeploy(version) {
    // 1. Deploy to inactive environment
    const inactiveEnv = await getInactiveEnvironment()
    await deployToEnvironment(inactiveEnv, version)

    // 2. Run smoke tests
    const smokeTestResult = await runSmokeTests(inactiveEnv)
    if (!smokeTestResult.passed) {
        throw new DeploymentError('Smoke tests failed')
    }

    // 3. Switch traffic
    await switchTraffic(inactiveEnv)

    // 4. Monitor for issues
    await monitorForMinutes(5)

    // 5. Mark deployment complete
    return { success: true, version, environment: inactiveEnv }
}

// Canary Deployment
async function canaryDeploy(version, stages = [5, 25, 50, 100]) {
    for (const percentage of stages) {
        // Route percentage of traffic to new version
        await setCanaryWeight(version, percentage)

        // Monitor error rates
        const metrics = await monitorForMinutes(10)
        if (metrics.errorRate > threshold) {
            await rollbackCanary()
            throw new DeploymentError(`Error rate too high at ${percentage}%`)
        }

        log(`Canary at ${percentage}% - metrics healthy`)
    }

    return { success: true, version }
}
```

### Step 4: Post-Deployment Verification

```yaml
post_deployment:
  health_checks:
    - Application responding
    - Database connections healthy
    - External services reachable
    - Cache warming complete

  monitoring:
    - Error rate within bounds
    - Response times acceptable
    - No memory leaks
    - Logs showing expected patterns

  documentation:
    - Deployment logged
    - Version updated in tracker
    - Changelog published
```

## Rollback Procedures

```javascript
async function rollback(deploymentId) {
    const deployment = await getDeployment(deploymentId)

    // 1. Switch traffic back
    await switchToVersion(deployment.previousVersion)

    // 2. Rollback database if needed
    if (deployment.hasMigrations) {
        await rollbackMigrations(deployment.migrationVersion)
    }

    // 3. Clear caches
    await clearCaches()

    // 4. Verify rollback
    const health = await checkHealth()
    if (!health.healthy) {
        alert('CRITICAL: Rollback verification failed')
    }

    // 5. Document incident
    await createIncidentReport(deployment, 'rollback')

    return { success: health.healthy }
}
```

## Environment Configuration

```yaml
environments:
  development:
    url: "https://dev.example.com"
    auto_deploy: true
    branch: "develop"

  staging:
    url: "https://staging.example.com"
    auto_deploy: false
    branch: "main"
    requires_approval: false

  production:
    url: "https://example.com"
    auto_deploy: false
    branch: "main"
    requires_approval: true
    deployment_window: "Mon-Thu 10:00-16:00"
```

## Output Format

```yaml
deployment_report:
  summary:
    version: "2.3.1"
    environment: "production"
    strategy: "blue-green"
    status: "success"
    duration: "4m 32s"

  stages:
    - name: "Pre-deployment checks"
      status: "passed"
      duration: "45s"

    - name: "Deploy to blue"
      status: "passed"
      duration: "2m 15s"

    - name: "Smoke tests"
      status: "passed"
      duration: "30s"

    - name: "Traffic switch"
      status: "passed"
      duration: "5s"

    - name: "Monitoring"
      status: "passed"
      duration: "1m"

  metrics:
    error_rate: "0.01%"
    p99_latency: "145ms"
    deployment_frequency: "3/week"

  rollback_info:
    previous_version: "2.3.0"
    rollback_command: "deploy rollback 2.3.0"
```

## See Also

- `agents/devops/cicd-specialist.md` - CI/CD pipeline management
- `skills/workflow/ci-cd-engineer.md` - CI/CD configuration
- `agents/devops/kubernetes-specialist.md` - Kubernetes deployments
