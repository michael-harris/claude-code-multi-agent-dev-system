# Prompt Engineer Skill

Craft effective prompts for AI agents and optimize agent interactions.

## Activation

This skill activates when:
- Agent prompts need improvement
- Subagent performance is poor
- New agent creation needed
- Task delegation optimization

## Prompt Structure

### Effective Prompt Components

```markdown
# [Role] Agent

**Model:** [haiku/sonnet/opus]
**Purpose:** [One-line description]

## Your Role

[2-3 sentences explaining what this agent does and why]

## Context

[Background information the agent needs]

## Instructions

[Numbered steps for the task]

1. First, analyze...
2. Then, implement...
3. Finally, verify...

## Constraints

- Do NOT [constraint 1]
- Always [constraint 2]
- Never [constraint 3]

## Output Format

[Expected output structure]

## Examples

### Example 1: [Scenario]
Input: [example input]
Output: [example output]
```

## Prompt Patterns

### Chain of Thought

```markdown
Think through this step by step:
1. What is the current state?
2. What is the desired state?
3. What are the steps to get there?
4. What could go wrong?
5. How do we verify success?
```

### Few-Shot Learning

```markdown
Here are examples of the task:

Example 1:
Input: "Create a user login API"
Output: POST /api/auth/login with email/password

Example 2:
Input: "Create a user registration API"
Output: POST /api/auth/register with email/password/name

Now complete:
Input: "${user_request}"
Output:
```

### Role Assignment

```markdown
You are an expert [role] with 20 years of experience in [domain].
You specialize in [specialty].
Your approach is [style - methodical/creative/pragmatic].

Given your expertise, [task]...
```

### Constraint Specification

```markdown
## Critical Constraints

MUST:
- Use TypeScript strict mode
- Include error handling
- Add JSDoc comments

MUST NOT:
- Use any type
- Ignore errors
- Skip validation

PREFER:
- Functional approach
- Immutable data
- Descriptive names
```

## Agent Prompt Templates

### Implementation Agent

```markdown
# Implementation Agent

You implement code based on specifications.

## Input
- Task description
- Acceptance criteria
- Technology stack
- Code style guide

## Process
1. Read and understand requirements
2. Plan implementation approach
3. Write code following conventions
4. Add appropriate tests
5. Document public APIs

## Output
- Production-ready code
- Unit tests
- Documentation updates

## Constraints
- Follow existing patterns in codebase
- No premature optimization
- All code must be tested
```

### Review Agent

```markdown
# Review Agent

You perform thorough code reviews.

## Review Checklist
1. Correctness: Does it do what it should?
2. Security: Any vulnerabilities?
3. Performance: Any bottlenecks?
4. Maintainability: Is it readable?
5. Testing: Adequate coverage?

## Output Format
For each issue:
- Location: file:line
- Severity: [critical/major/minor/suggestion]
- Issue: Description
- Fix: Recommended solution

## Constraints
- Be constructive, not critical
- Suggest improvements, don't just complain
- Acknowledge good practices
```

### Debug Agent

```markdown
# Debug Agent

You diagnose and fix bugs systematically.

## Debug Process
1. Reproduce the issue
2. Gather evidence (logs, stack traces)
3. Form hypothesis
4. Test hypothesis
5. Implement fix
6. Verify fix

## Information Needed
- Error message/behavior
- Expected behavior
- Steps to reproduce
- Environment details

## Output
- Root cause analysis
- Fix implementation
- Regression test
- Prevention recommendations
```

## Prompt Optimization

### Reduce Token Usage

```markdown
# Before (verbose)
Please analyze the following code and identify any potential security vulnerabilities that might exist. Look for things like SQL injection, XSS, authentication issues, and other common security problems. Provide a detailed explanation of each issue you find.

# After (concise)
Analyze for security vulnerabilities:
- SQL injection
- XSS
- Auth issues

Output: {file, line, issue, fix}
```

### Improve Clarity

```markdown
# Before (ambiguous)
Make the code better.

# After (specific)
Refactor UserService:
1. Extract validation to separate method
2. Add error handling for DB operations
3. Replace magic numbers with constants
4. Add JSDoc for public methods
```

### Add Guardrails

```markdown
## Safety Constraints

NEVER:
- Execute code from untrusted sources
- Modify files outside project directory
- Expose sensitive information
- Make irreversible changes without confirmation

ALWAYS:
- Validate inputs
- Handle errors gracefully
- Log important operations
- Preserve existing functionality
```

## Multi-Agent Coordination

### Sequential Delegation

```markdown
Task Flow:
1. Architect Agent → Design specification
2. Implementation Agent → Code
3. Test Agent → Test suite
4. Review Agent → Code review
5. Documentation Agent → Docs

Each agent receives output from previous agent.
```

### Parallel Delegation

```markdown
Launch in parallel:
- Frontend Agent: UI components
- Backend Agent: API endpoints
- Database Agent: Schema and migrations

Merge point: Integration Agent combines outputs
```

### Escalation Pattern

```markdown
Attempt with Haiku (cost-efficient):
- If success → Done
- If fail → Escalate

Attempt with Sonnet (balanced):
- If success → Done
- If fail → Escalate

Attempt with Opus (powerful):
- If success → Done
- If fail → Report to human
```

## Quality Checks

- [ ] Prompt is clear and unambiguous
- [ ] Role is well-defined
- [ ] Constraints are explicit
- [ ] Output format is specified
- [ ] Examples provided where helpful
- [ ] Token usage is optimized
- [ ] Guardrails prevent harmful outputs
