# Agent Development Guide

This guide explains how to create, configure, and test new agents for DevTeam.

## Table of Contents

1. [Understanding Agents](#understanding-agents)
2. [Agent Categories](#agent-categories)
3. [Creating a New Agent](#creating-a-new-agent)
4. [Agent Structure](#agent-structure)
5. [Registration](#registration)
6. [Testing Agents](#testing-agents)
7. [Best Practices](#best-practices)

## Understanding Agents

Agents are AI personas with specialized knowledge and capabilities. Each agent is defined in a Markdown file that contains:

- **Role**: What the agent does
- **Capabilities**: What the agent can do
- **Instructions**: How the agent should behave
- **Output Format**: Expected response structure

### How Agents are Selected

1. **Trigger Matching**: Keywords in user request match agent triggers
2. **Weight Scoring**: Higher weight = higher priority when multiple match
3. **Tier Selection**: T1 (specialists) selected before T2 (generalists)
4. **Context Awareness**: Current phase influences agent selection

## Agent Categories

| Category | Path | Purpose |
|----------|------|---------|
| `core/` | `agents/core/` | Orchestration and planning |
| `specialized/` | `agents/specialized/` | Domain expertise |
| `quality/` | `agents/quality/` | Testing and verification |
| `language/` | `agents/language/` | Language-specific |
| `framework/` | `agents/framework/` | Framework-specific |
| `bug-council/` | `agents/bug-council/` | Bug diagnosis |

## Creating a New Agent

### Step 1: Identify the Need

Before creating an agent, ask:
- Does an existing agent cover this domain?
- Is this specialized enough to warrant a dedicated agent?
- What unique value does this agent provide?

### Step 2: Choose Category and Tier

**Tiers:**
- **T1 (Specialist)**: Deep expertise in narrow domain (weight: 70-100)
- **T2 (Generalist)**: Broad knowledge, handles edge cases (weight: 30-60)

### Step 3: Create the Agent File

```bash
# Create from template
cp agents/templates/base-agent.md agents/specialized/my-agent.md
```

### Step 4: Define the Agent

Edit the file with your agent definition (see structure below).

### Step 5: Register in plugin.json

Add entry to the agents array.

### Step 6: Test

Run tests to verify agent selection and behavior.

## Agent Structure

### Complete Template

```markdown
# Agent Name

## Role

A clear, one-sentence description of what this agent does.

## Capabilities

- Capability 1: Brief description
- Capability 2: Brief description
- Capability 3: Brief description

## When to Use

Use this agent when:
- Condition 1
- Condition 2

Do NOT use this agent for:
- Anti-pattern 1
- Anti-pattern 2

## Prerequisites

Before invoking this agent, ensure:
- Prerequisite 1
- Prerequisite 2

## Instructions

### Primary Responsibilities

1. First responsibility
2. Second responsibility
3. Third responsibility

### Approach

Describe the general approach:
1. Step one
2. Step two
3. Step three

### Constraints

- Constraint 1
- Constraint 2

## Output Format

### Success Response

```json
{
  "status": "success",
  "result": {
    "field1": "value",
    "field2": "value"
  },
  "next_steps": ["step1", "step2"]
}
```

### Error Response

```json
{
  "status": "error",
  "error": "Description of what went wrong",
  "suggestions": ["suggestion1", "suggestion2"]
}
```

## Examples

### Example 1: Basic Usage

**Input:**
```
User request here
```

**Output:**
```
Agent response here
```

### Example 2: Complex Scenario

**Input:**
```
Complex user request
```

**Output:**
```
Detailed agent response
```

## Integration Points

This agent interacts with:
- **Agent X**: For capability Y
- **Agent Z**: When condition W

## Escalation

Escalate to a more capable model when:
- Condition requiring escalation 1
- Condition requiring escalation 2

## Related Agents

- `related-agent-1`: Complementary capability
- `related-agent-2`: Alternative for different context
```

### Section Guidelines

#### Role
- One clear sentence
- Start with action verb
- Be specific about domain

**Good:** "Analyzes TypeScript code for type safety issues and suggests fixes."
**Bad:** "Helps with TypeScript stuff."

#### Capabilities
- 3-7 bullet points
- Each starts with action verb
- Specific and measurable

#### When to Use
- Clear inclusion criteria
- Explicit exclusion criteria
- Examples of appropriate requests

#### Instructions
- Numbered steps for processes
- Clear decision points
- Specific actions, not vague guidance

#### Output Format
- JSON structure when applicable
- Include success AND error formats
- Document all fields

#### Examples
- At least 2 examples
- Cover simple and complex cases
- Show realistic input/output

## Registration

### plugin.json Entry

```json
{
  "id": "my-agent",
  "name": "My Agent Display Name",
  "description": "Brief description for selection",
  "path": "agents/specialized/my-agent.md",
  "category": "specialized",
  "tier": "T1",
  "weight": 75,
  "triggers": [
    "keyword1",
    "keyword2",
    "phrase with spaces"
  ],
  "languages": ["typescript", "javascript"],
  "frameworks": ["react", "next"],
  "model_preference": "sonnet"
}
```

### Field Reference

| Field | Required | Description |
|-------|----------|-------------|
| `id` | Yes | Unique identifier (kebab-case) |
| `name` | Yes | Display name |
| `description` | Yes | Brief description for selection |
| `path` | Yes | Relative path to agent file |
| `category` | Yes | Agent category |
| `tier` | Yes | T1 or T2 |
| `weight` | Yes | Selection priority (1-100) |
| `triggers` | Yes | Keywords that activate agent |
| `languages` | No | Applicable languages |
| `frameworks` | No | Applicable frameworks |
| `model_preference` | No | Preferred model tier |

### Trigger Guidelines

1. **Be specific**: Use domain-specific terms
2. **Include variations**: "test", "tests", "testing"
3. **Avoid conflicts**: Check existing agent triggers
4. **Use phrases**: "add feature", "fix bug"

## Testing Agents

### Manual Testing

```bash
# In Claude Code with DevTeam installed
/devteam:status

# Then make a request matching your agent's triggers
"I need help with [your domain]"
```

### Automated Testing

Create a test file:

```bash
# tests/test-agents/test-my-agent.sh

#!/bin/bash
source "$(dirname "$0")/../test-helpers.sh"

test_my_agent_triggers() {
    # Test that agent is selected for expected triggers
    local selected
    selected=$(select_agent_for_request "keyword1 in request")
    assert_equals "my-agent" "$selected" "Agent should be selected for keyword1"
}

test_my_agent_not_selected() {
    # Test that agent is NOT selected for unrelated requests
    local selected
    selected=$(select_agent_for_request "unrelated request")
    assert_not_equals "my-agent" "$selected" "Agent should not be selected"
}

run_test test_my_agent_triggers
run_test test_my_agent_not_selected
```

### Test Checklist

- [ ] Agent file passes markdown lint
- [ ] All required sections present
- [ ] Registered in plugin.json
- [ ] Triggers don't conflict with existing agents
- [ ] Examples are accurate
- [ ] Output format is valid JSON (if applicable)

## Best Practices

### Do

1. **Be specific** - Narrow scope is better than trying to do everything
2. **Include examples** - Real-world scenarios help users and the AI
3. **Define boundaries** - Clear "when NOT to use" prevents misuse
4. **Use structured output** - JSON format enables automation
5. **Document escalation** - Know when to hand off to stronger models
6. **Test thoroughly** - Verify trigger matching and output

### Don't

1. **Overlap with existing agents** - Check what exists first
2. **Use vague instructions** - "Be helpful" is not actionable
3. **Forget error handling** - Define what happens when things fail
4. **Skip examples** - They're essential for AI understanding
5. **Use inconsistent format** - Follow the template
6. **Create overly broad triggers** - Specificity prevents conflicts

### Common Mistakes

| Mistake | Problem | Solution |
|---------|---------|----------|
| Vague role | AI doesn't know what to do | Be specific and actionable |
| No examples | AI guesses output format | Include 2+ concrete examples |
| Overlapping triggers | Wrong agent selected | Check existing triggers first |
| Missing constraints | Agent overreaches | Define clear boundaries |
| No error format | Failures are confusing | Document error responses |

## Advanced Topics

### Multi-Agent Workflows

Agents can invoke other agents:

```markdown
## Integration Points

When encountering [condition], delegate to:
- `test-writer`: To create test cases
- `code-reviewer`: To validate changes
```

### Model-Specific Behavior

```markdown
## Model Considerations

- **Haiku**: Use for simple, well-defined tasks
- **Sonnet**: Default for most operations
- **Opus**: Required for complex reasoning
```

### Context Awareness

```markdown
## Context Handling

Check the current phase before acting:
- In `planning`: Focus on design
- In `executing`: Focus on implementation
- In `quality_check`: Focus on validation
```

## Examples of Good Agents

Study these well-designed agents:
- `agents/orchestration/ralph-orchestrator.md` - Orchestration example
- `agents/quality/test-writer.md` - Testing example
- `agents/security/penetration-tester.md` - Security example

## Getting Help

- Review existing agents for patterns
- Check CONTRIBUTING.md for style guidelines
- Open an issue for guidance on complex agents
