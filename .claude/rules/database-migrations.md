---
paths:
  - "**/migrations/**"
  - "**/alembic/**"
  - "**/*.sql"
  - "**/schema*"
  - "**/prisma/**"
---
When working with database migrations:
- Always create reversible migrations (include down/rollback)
- Never modify existing migrations — create new ones
- Test migrations on a copy before applying to production schemas
- Use explicit column types, never rely on defaults
- Add indexes for foreign keys and frequently queried columns
- Use transactions for multi-step migrations
