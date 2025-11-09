# Testing Requirements and Policies

This document outlines the rigorous testing requirements enforced by the Multi-Agent Development System.

---

## Overview

The system enforces **100% test pass rate** and **mandatory runtime verification** for all sprints. These requirements are validated by the **Workflow Compliance** agent and cannot be bypassed.

---

## Core Policies

### 1. 100% Test Pass Rate (Non-Negotiable)

**Policy:**
- ALL tests must pass
- NOT 99%, NOT 95%, NOT "mostly passing"
- X/X passed (where X = total executable tests)
- ANY failing test = FAIL status

**Enforcement:**
- Runtime Verifier executes all tests
- Workflow Compliance validates results
- Sprint cannot complete with failing tests

**Example:**
```
✅ PASS: 45/45 tests passed
❌ FAIL: 44/45 tests passed (1 failure)
❌ FAIL: 43/45 tests passed (2 skipped for wrong reason)
```

### 2. External API Test Exception

**Policy:**
Tests that call third-party APIs (Stripe, Twilio, SendGrid, AWS, etc.) may be skipped if valid credentials are not available.

**Requirements for skipping:**
```python
# Python example
@pytest.mark.skip(reason="requires valid Stripe API key")
def test_stripe_webhook():
    # Test implementation
```

```javascript
// JavaScript example
test.skip('Stripe webhook processing', () => {
  // Test implementation
});
```

**Must be documented in TESTING_SUMMARY.md:**
```markdown
## Skipped Tests
- test_stripe_webhook (requires Stripe API key)
- test_sendgrid_email (requires SendGrid API key)
```

**These do NOT count against pass rate:**
- ✅ 45 passed, 2 skipped (external API) = 100% pass rate
- ❌ 44 passed, 1 failed, 2 skipped = FAIL

### 3. Actual Test Execution Required

**Policy:**
Tests must actually execute, not just check imports or compilation.

**NOT ACCEPTABLE:**
```bash
# ❌ Only checks imports
python -c "import app"

# ❌ Only checks compilation
npm run build

# ❌ Only checks syntax
go build ./...

# ❌ Shortcuts
echo "All tests pass" > test_results.txt
```

**REQUIRED:**
```bash
# ✅ Python: Actual test execution
uv run pytest -v --cov=. --cov-report=term-missing

# ✅ TypeScript: Actual test execution
npm test -- --coverage

# ✅ Go: Actual test execution
go test -v -cover ./...

# ✅ Java: Actual test execution
mvn test

# ✅ C#: Actual test execution
dotnet test

# ✅ Ruby: Actual test execution
bundle exec rspec

# ✅ PHP: Actual test execution
./vendor/bin/phpunit
```

---

## TESTING_SUMMARY.md Requirements

### Mandatory Artifact

Every sprint MUST generate `docs/runtime-testing/TESTING_SUMMARY.md` (or `SPRINT-XXX-TESTING_SUMMARY.md`).

### Required Contents

```markdown
# Testing Summary

## Test Execution
- **Framework**: [pytest/jest/junit/etc] [version]
- **Total Tests**: [number]
- **Passed**: [number]
- **Failed**: [number]
- **Skipped**: [number] ([reason])
- **Pass Rate**: [percentage] ([passed]/[total executable])
- **Coverage**: [percentage]

## Test Files
- [test file 1] ([X] tests)
- [test file 2] ([Y] tests)
- ...

## Skipped Tests (if any)
- [test name] ([reason - must be external API])
- ...

## Duration
- Total: [time]

## Command to Reproduce
\`\`\`bash
[exact command to run tests]
\`\`\`

## Notes (optional)
[Any relevant notes about test execution]
```

### Example

```markdown
# Testing Summary

## Test Execution
- **Framework**: pytest 7.4.0
- **Total Tests**: 47
- **Passed**: 45
- **Failed**: 0
- **Skipped**: 2 (external API tests)
- **Pass Rate**: 100% (45/45 executable tests)
- **Coverage**: 87%

## Test Files
- tests/test_auth.py (12 tests)
- tests/test_tasks.py (18 tests)
- tests/test_api.py (15 tests)
- tests/integration/test_workflows.py (2 tests)

## Skipped Tests
- test_stripe_payment_webhook (requires valid Stripe API key)
- test_sendgrid_email_delivery (requires valid SendGrid API key)

## Duration
- Total: 3.2 seconds

## Command to Reproduce
\`\`\`bash
uv run pytest -v --cov=. --cov-report=term-missing
\`\`\`

## Notes
All core functionality tested. External API integration tests skipped due to missing credentials but marked for production environment validation.
```

---

## Runtime Verification Process

### Steps Executed by Runtime Verifier Agent

1. **Build Application**
   - Compile/build if needed
   - Check for build errors

2. **Launch Application (if applicable)**
   - Start via Docker or local command
   - Verify startup without errors
   - Check health endpoints

3. **Execute ALL Tests**
   - Run complete test suite
   - Capture output
   - Parse results

4. **Generate TESTING_SUMMARY.md**
   - Extract test counts
   - Calculate pass rate
   - Document skipped tests
   - Record coverage

5. **Create Manual Testing Guide**
   - Document manual test procedures
   - Provide curl commands for APIs
   - Include expected outcomes

6. **Validate Results**
   - Check 100% pass rate
   - Verify no runtime errors
   - Confirm coverage threshold (≥80%)

### Workflow Compliance Validation

After Runtime Verifier completes, **Workflow Compliance** agent validates:

- ✅ TESTING_SUMMARY.md exists
- ✅ Contains all required sections
- ✅ Actual tests were run (checks for test output)
- ✅ 100% pass rate achieved
- ✅ Coverage meets threshold
- ✅ Skipped tests properly documented
- ✅ No failing tests
- ✅ No runtime errors

**If ANY check fails → Sprint FAILS**

---

## Language-Specific Testing Requirements

### Python

**Required commands:**
```bash
# Install dependencies
uv pip install -r requirements.txt

# Run tests with coverage
uv run pytest -v --cov=. --cov-report=term-missing

# Must show output like:
# tests/test_auth.py::test_login PASSED
# tests/test_auth.py::test_register PASSED
# ...
# =========== 45 passed, 2 skipped in 3.2s ===========
```

**Framework options:**
- pytest (recommended)
- unittest
- nose2

### TypeScript/JavaScript

**Required commands:**
```bash
# Install dependencies
npm install

# Run tests with coverage
npm test -- --coverage

# Must show output like:
# PASS  src/components/Login.test.tsx
# PASS  src/utils/auth.test.ts
# ...
# Test Suites: 12 passed, 12 total
# Tests:       45 passed, 45 total
```

**Framework options:**
- Jest (recommended)
- Vitest
- Mocha + Chai

### Java

**Required commands:**
```bash
# Maven
mvn test

# Or Gradle
./gradlew test

# Must show output like:
# [INFO] Tests run: 45, Failures: 0, Errors: 0, Skipped: 2
```

**Framework options:**
- JUnit 5 (recommended)
- TestNG

### C#

**Required commands:**
```bash
# Run tests
dotnet test

# Must show output like:
# Passed!  - Failed:     0, Passed:    45, Skipped:     2, Total:    47
```

**Framework options:**
- xUnit (recommended)
- NUnit
- MSTest

### Go

**Required commands:**
```bash
# Run tests with coverage
go test -v -cover ./...

# Must show output like:
# === RUN   TestAuthHandler
# --- PASS: TestAuthHandler (0.01s)
# ...
# PASS
# coverage: 87.3% of statements
```

### Ruby

**Required commands:**
```bash
# Install dependencies
bundle install

# Run tests
bundle exec rspec

# Must show output like:
# AuthController
#   #login
#     returns JWT token
# ...
# 45 examples, 0 failures
```

### PHP

**Required commands:**
```bash
# Install dependencies
composer install

# Run tests
./vendor/bin/phpunit

# Must show output like:
# PHPUnit 10.0.0 by Sebastian Bergmann and contributors.
# ...............................................   45 / 45 (100%)
# OK (45 tests, 128 assertions)
```

---

## Coverage Requirements

### Minimum Threshold

**80% code coverage required**

Measured by:
- Line coverage
- Branch coverage (where supported)

### Enforcement

- Runtime Verifier checks coverage
- Must be ≥80% to pass
- Documented in TESTING_SUMMARY.md

### Exceptions

Coverage can be below 80% only if:
- Third-party code excluded
- Auto-generated code excluded
- Explicitly documented why certain code isn't tested

---

## Manual Testing Documentation

### Required Artifact

`docs/runtime-testing/SPRINT-XXX-manual-tests.md`

### Contents

1. **Prerequisites**
   - What needs to be set up
   - Required credentials
   - Environment setup

2. **Test Procedures**
   - Step-by-step instructions
   - Expected outcomes
   - Pass/fail criteria

3. **API Testing** (if applicable)
   - curl commands for each endpoint
   - Expected responses
   - Error cases to test

4. **Database Verification** (if applicable)
   - SQL queries to verify state
   - Expected data

5. **Security Testing**
   - Authentication tests
   - Authorization tests
   - Input validation tests

### Example

```markdown
# Manual Testing Guide - Sprint 001

## Prerequisites
- Application running on http://localhost:8000
- PostgreSQL database initialized
- Redis server running

## Test Procedures

### 1. User Registration
**Steps:**
1. Open http://localhost:8000/register
2. Enter email: test@example.com
3. Enter password: SecurePass123
4. Click "Register"

**Expected Outcome:**
- Redirect to dashboard
- User created in database
- JWT token stored in localStorage

**Verification:**
\`\`\`sql
SELECT * FROM users WHERE email = 'test@example.com';
\`\`\`

### 2. API Testing

**Login Endpoint:**
\`\`\`bash
curl -X POST http://localhost:8000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"SecurePass123"}'
\`\`\`

**Expected Response:**
\`\`\`json
{
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "user_id": "uuid-here"
}
\`\`\`

...
```

---

## Common Violations and Fixes

### Violation: "Application imports successfully"

**Problem:**
```python
# ❌ This is not a test
python -c "import app"
print("Application imports successfully")
```

**Fix:**
```bash
# ✅ Actually run tests
uv run pytest -v
```

### Violation: Missing TESTING_SUMMARY.md

**Problem:**
No documentation of test results.

**Fix:**
Runtime Verifier automatically generates this. If missing, workflow compliance fails.

### Violation: Tests not passing

**Problem:**
```
Tests run: 45, Failures: 1, Errors: 0
```

**Fix:**
- Investigate and fix the failing test
- Do NOT skip the test unless it's an external API test
- Do NOT mark the sprint complete until 100% pass

### Violation: Skipped tests without valid reason

**Problem:**
```python
@pytest.mark.skip(reason="fix later")
def test_important_feature():
    ...
```

**Fix:**
```python
# ❌ Not allowed
@pytest.mark.skip(reason="fix later")

# ✅ Only allowed for external APIs
@pytest.mark.skip(reason="requires valid Stripe API key")
```

---

## Quality Metrics Dashboard

### What Gets Tracked

For each sprint:
- Total tests
- Pass rate
- Coverage percentage
- Number of skipped tests
- Test execution time
- Runtime errors (must be 0)

### Historical Tracking

State files preserve:
- Test metrics per sprint
- Quality trends over time
- Compliance violations

---

## Best Practices

### 1. Write Tests First (TDD)

```python
# Write test
def test_user_registration():
    response = client.post("/api/auth/register", json={...})
    assert response.status_code == 201

# Then implement
@app.post("/api/auth/register")
def register(data: RegisterSchema):
    ...
```

### 2. Test Edge Cases

```python
def test_registration_duplicate_email():
    # First registration
    client.post("/api/auth/register", json={...})
    # Duplicate should fail
    response = client.post("/api/auth/register", json={...})
    assert response.status_code == 400
```

### 3. Use Fixtures for Setup

```python
@pytest.fixture
def authenticated_client():
    client = TestClient(app)
    # Login
    response = client.post("/api/auth/login", ...)
    token = response.json()["token"]
    client.headers["Authorization"] = f"Bearer {token}"
    return client

def test_protected_endpoint(authenticated_client):
    response = authenticated_client.get("/api/profile")
    assert response.status_code == 200
```

### 4. Document External API Tests

```python
@pytest.mark.skip(reason="requires valid Stripe API key")
def test_stripe_payment():
    """
    This test requires STRIPE_API_KEY environment variable.
    Run in production environment with:
    STRIPE_API_KEY=sk_live_xxx pytest tests/test_payments.py::test_stripe_payment
    """
    ...
```

---

## Troubleshooting

### "Workflow compliance failed: Missing TESTING_SUMMARY.md"

**Cause:** Runtime Verifier didn't generate the file.

**Solution:**
1. Check runtime-verifier logs
2. Ensure tests actually ran
3. Re-run sprint

### "Workflow compliance failed: Tests not actually run"

**Cause:** Shortcut was used instead of running tests.

**Solution:**
1. Actually run the test command
2. Provide real test output
3. Generate proper TESTING_SUMMARY.md

### "Pass rate below 100%"

**Cause:** One or more tests failed.

**Solution:**
1. Review test failures
2. Fix the code or tests
3. Re-run until all pass
4. Do NOT skip tests unless external API

---

## Summary

### Non-Negotiable Requirements

✅ 100% test pass rate (no exceptions except external APIs)
✅ TESTING_SUMMARY.md generated with complete results
✅ Actual test execution (no shortcuts)
✅ ≥80% code coverage
✅ Manual testing guide created
✅ No runtime errors

### Enforcement

- Runtime Verifier executes tests
- Workflow Compliance validates results
- Sprint cannot complete without compliance
- Shortcuts are detected and blocked

### Benefits

- **High quality** - Rigorous testing catches bugs
- **Clear documentation** - TESTING_SUMMARY.md provides transparency
- **Production ready** - Code is thoroughly tested before deployment
- **Audit trail** - Complete testing history preserved

---

**Testing is not optional. It's enforced by the system architecture.**
