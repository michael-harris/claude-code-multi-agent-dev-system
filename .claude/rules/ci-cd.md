---
paths:
  - ".github/workflows/**"
  - ".gitlab-ci*"
  - "Jenkinsfile*"
  - ".circleci/**"
  - "**/pipeline*"
---
When working with CI/CD configuration:
- Pin action versions to specific commits or tags
- Cache dependencies between runs
- Run tests in parallel where possible
- Use matrix builds for multi-version testing
- Separate build, test, and deploy stages
- Use environment-specific secrets
- Include deployment rollback steps
