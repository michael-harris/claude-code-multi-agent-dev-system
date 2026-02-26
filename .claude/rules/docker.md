---
paths:
  - "**/Dockerfile*"
  - "**/docker-compose*"
  - "**/.dockerignore"
---
When working with Docker files:
- Use multi-stage builds to minimize image size
- Pin base image versions (never use :latest in production)
- Use non-root users in containers
- Order layers from least to most frequently changed
- Use .dockerignore to exclude unnecessary files
- Use HEALTHCHECK instructions
- Prefer COPY over ADD
