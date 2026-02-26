---
paths:
  - "src/server/**/*.ts"
  - "src/api/**/*.ts"
  - "**/controllers/**/*.ts"
  - "**/middleware/**/*.ts"
  - "**/routes/**/*.ts"
---
When working with Node.js/Express/NestJS:
- Use async/await consistently (never raw promises or callbacks)
- Use proper error middleware for Express
- Use dependency injection in NestJS
- Validate request bodies at the controller layer
- Use proper HTTP status codes
- Handle graceful shutdown
