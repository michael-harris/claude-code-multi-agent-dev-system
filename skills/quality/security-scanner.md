# Security Scanner Skill

Comprehensive security analysis for identifying and fixing vulnerabilities.

## Activation

This skill activates when:
- Security audit requested
- New code touches auth/data handling
- Dependencies updated
- Pre-deployment checks

## OWASP Top 10 Detection

### 1. Injection (A03:2021)

#### SQL Injection
```python
# VULNERABLE
query = f"SELECT * FROM users WHERE id = {user_input}"

# SECURE
query = "SELECT * FROM users WHERE id = %s"
cursor.execute(query, (user_input,))
```

#### Command Injection
```python
# VULNERABLE
os.system(f"ping {user_input}")

# SECURE
import shlex
subprocess.run(["ping", shlex.quote(user_input)])
```

### 2. Broken Authentication (A07:2021)

```python
# ISSUES TO CHECK
- Weak password requirements
- Missing rate limiting
- Session fixation
- Credential stuffing vulnerability
- Missing MFA option

# SECURE EXAMPLE
from argon2 import PasswordHasher

ph = PasswordHasher(
    time_cost=3,
    memory_cost=65536,
    parallelism=4
)

def hash_password(password: str) -> str:
    return ph.hash(password)

def verify_password(hash: str, password: str) -> bool:
    try:
        return ph.verify(hash, password)
    except:
        return False
```

### 3. Sensitive Data Exposure (A02:2021)

```yaml
# CHECK FOR
- Hardcoded secrets
- Unencrypted PII
- Sensitive data in logs
- Missing HTTPS
- Weak encryption

# DETECTION PATTERNS
patterns:
  - "password\\s*=\\s*['\"]"
  - "api_key\\s*=\\s*['\"]"
  - "secret\\s*=\\s*['\"]"
  - "AWS_ACCESS_KEY"
  - "private_key"
```

### 4. XML External Entities (A05:2021)

```python
# VULNERABLE
from xml.etree import ElementTree
tree = ElementTree.parse(user_file)

# SECURE
import defusedxml.ElementTree as ET
tree = ET.parse(user_file)
```

### 5. Broken Access Control (A01:2021)

```python
# VULNERABLE - Direct object reference
@app.get("/users/{user_id}/data")
def get_user_data(user_id: int):
    return db.get_user_data(user_id)

# SECURE - Authorization check
@app.get("/users/{user_id}/data")
def get_user_data(user_id: int, current_user: User = Depends(get_current_user)):
    if current_user.id != user_id and not current_user.is_admin:
        raise HTTPException(403, "Not authorized")
    return db.get_user_data(user_id)
```

### 6. Security Misconfiguration (A05:2021)

```yaml
# CHECK FOR
- Debug mode in production
- Default credentials
- Unnecessary features enabled
- Missing security headers
- Verbose error messages

# REQUIRED HEADERS
headers:
  X-Content-Type-Options: nosniff
  X-Frame-Options: DENY
  X-XSS-Protection: 1; mode=block
  Strict-Transport-Security: max-age=31536000; includeSubDomains
  Content-Security-Policy: default-src 'self'
```

### 7. Cross-Site Scripting (A03:2021)

```javascript
// VULNERABLE
element.innerHTML = userInput;

// SECURE
element.textContent = userInput;

// Or with sanitization
import DOMPurify from 'dompurify';
element.innerHTML = DOMPurify.sanitize(userInput);
```

### 8. Insecure Deserialization (A08:2021)

```python
# VULNERABLE
import pickle
data = pickle.loads(user_input)

# SECURE - Use safe formats
import json
data = json.loads(user_input)

# Or validate before deserializing
import hmac
def safe_deserialize(data, signature, key):
    expected = hmac.new(key, data, 'sha256').hexdigest()
    if not hmac.compare_digest(signature, expected):
        raise SecurityError("Invalid signature")
    return json.loads(data)
```

### 9. Using Components with Known Vulnerabilities (A06:2021)

```bash
# Python
pip-audit
safety check

# Node.js
npm audit
snyk test

# Go
govulncheck ./...

# Rust
cargo audit
```

### 10. Insufficient Logging & Monitoring (A09:2021)

```python
# REQUIRED LOGGING
import structlog

logger = structlog.get_logger()

# Log security events
logger.warning("login_failed", user=username, ip=request.client.host)
logger.info("permission_denied", user=current_user.id, resource=resource_id)
logger.critical("potential_breach", details=details)
```

## Dependency Scanning

```yaml
# .github/workflows/security.yml
name: Security Scan

on: [push, pull_request]

jobs:
  security:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Run Trivy vulnerability scanner
        uses: aquasecurity/trivy-action@master
        with:
          scan-type: 'fs'
          scan-ref: '.'
          severity: 'CRITICAL,HIGH'

      - name: Run Snyk
        uses: snyk/actions/node@master
        env:
          SNYK_TOKEN: ${{ secrets.SNYK_TOKEN }}
```

## Security Report

```markdown
## Security Scan Report

**Scan Date:** 2025-01-28
**Repository:** myapp
**Branch:** main

### Summary

| Severity | Count |
|----------|-------|
| Critical | 2 |
| High | 5 |
| Medium | 12 |
| Low | 23 |

### Critical Issues

#### 1. SQL Injection in User Search
**File:** `src/routes/search.py:45`
**CWE:** CWE-89
**CVSS:** 9.8

```python
# Vulnerable code
query = f"SELECT * FROM users WHERE name LIKE '%{search}%'"
```

**Remediation:**
```python
query = "SELECT * FROM users WHERE name LIKE %s"
cursor.execute(query, (f"%{search}%",))
```

#### 2. Hardcoded API Key
**File:** `src/config.py:12`
**CWE:** CWE-798
**CVSS:** 9.1

**Remediation:**
Move to environment variable or secrets manager.

### Dependency Vulnerabilities

| Package | Version | Vulnerability | Fix |
|---------|---------|---------------|-----|
| lodash | 4.17.20 | Prototype Pollution | 4.17.21 |
| axios | 0.21.0 | SSRF | 0.21.1 |

### Recommendations

1. Enable Dependabot for automatic updates
2. Add pre-commit hooks for secret detection
3. Implement WAF rules for injection protection
4. Enable audit logging for all auth events
```

## Quality Checks

- [ ] No critical/high vulnerabilities
- [ ] Dependencies up to date
- [ ] Security headers configured
- [ ] Secrets not in code
- [ ] Input validation present
- [ ] Auth/authz implemented correctly
- [ ] Logging configured
- [ ] HTTPS enforced
