---
paths:
  - "src/components/**/*.tsx"
  - "src/pages/**/*.tsx"
  - "src/app/**/*.tsx"
  - "**/*.component.tsx"
---
When working with React components:
- Use functional components with hooks (never class components)
- Use TypeScript strict mode types (no `any`)
- Prefer named exports over default exports
- Use React.memo() only when profiling shows need
- Follow existing component file structure in the project
- Use the project's design system components when available
- Use server components by default (Next.js App Router)
