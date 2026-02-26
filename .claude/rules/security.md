---
paths:
  - "**/auth/**"
  - "**/security/**"
  - "**/middleware/auth*"
  - "**/*authentication*"
  - "**/*authorization*"
---
When working with authentication/security code:
- Never store secrets in code — use environment variables
- Use parameterized queries to prevent SQL injection
- Sanitize all user input
- Use HTTPS for all external communications
- Implement rate limiting on authentication endpoints
- Use secure session management (HttpOnly, Secure, SameSite cookies)
- Hash passwords with bcrypt/argon2 (never MD5/SHA)
- Follow principle of least privilege
