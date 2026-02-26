---
paths:
  - "**/*fastapi*/**"
  - "**/api/**/*.py"
  - "**/routers/**/*.py"
  - "**/endpoints/**/*.py"
---
When working with FastAPI code:
- Use Pydantic v2 model_validator instead of deprecated validator
- Use async def for all route handlers
- Use Depends() for dependency injection
- Use HTTPException for error responses with appropriate status codes
- Follow router-based organization pattern
- Use response_model for type-safe responses
- Use BackgroundTasks for async operations
