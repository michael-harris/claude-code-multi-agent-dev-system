---
paths:
  - "**/*test*/**"
  - "**/*spec*/**"
  - "**/__tests__/**"
  - "**/*.test.*"
  - "**/*.spec.*"
---
When working with test files:
- Follow AAA pattern (Arrange, Act, Assert)
- One assertion per test when possible
- Use descriptive test names that explain the scenario
- Mock external dependencies, not internal modules
- Test behavior, not implementation details
- Include edge cases and error paths
- Keep test files close to the code they test
