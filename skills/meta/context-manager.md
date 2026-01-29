# Context Manager Skill

**Skill ID:** `meta:context-manager`
**Category:** Meta
**Model:** `haiku`

## Purpose

Optimize context usage across agent interactions to reduce token consumption and improve efficiency. Manages context compression, summarization, and selective inclusion.

## Capabilities

### 1. Context Compression
- Summarize verbose outputs
- Extract key information
- Remove redundant content
- Compress code representations

### 2. Selective Context
- Include only relevant files
- Filter by task requirements
- Prioritize recent changes
- Exclude boilerplate

### 3. Handoff Optimization
- Create agent handoff summaries
- Preserve critical context
- Drop transient details
- Format for receiving agent

### 4. Memory Management
- Long-term context storage
- Session continuity
- Knowledge persistence
- Incremental updates

## Activation Triggers

```yaml
triggers:
  automatic:
    - Context approaching limit
    - Agent handoff occurring
    - Session compaction
    - Long-running task

  keywords:
    - context
    - summarize
    - compress
    - optimize
```

## Process

### Step 1: Analyze Current Context

```javascript
function analyzeContext(context) {
    return {
        totalTokens: countTokens(context),
        breakdown: {
            systemPrompt: countTokens(context.system),
            conversationHistory: countTokens(context.messages),
            codeFiles: countTokens(context.files),
            toolResults: countTokens(context.toolResults)
        },
        redundancy: findRedundantContent(context),
        staleness: findStaleContent(context)
    }
}
```

### Step 2: Prioritize Content

```yaml
priority_rules:
  critical:
    - Current task description
    - Error messages being fixed
    - Files being actively edited
    - Recent user instructions

  important:
    - Related code files
    - Test results
    - Recent conversation
    - Relevant documentation

  optional:
    - Historical context
    - Completed tasks
    - Verbose tool outputs
    - Boilerplate code

  droppable:
    - Redundant file reads
    - Superseded information
    - Verbose success messages
    - Intermediate states
```

### Step 3: Compression Strategies

```javascript
// Summarize verbose outputs
function summarizeToolOutput(output, maxTokens = 500) {
    if (countTokens(output) <= maxTokens) return output

    return {
        summary: extractKeyPoints(output),
        status: output.success ? 'success' : 'failure',
        keyData: extractCriticalData(output),
        fullOutputAvailable: true
    }
}

// Compress code context
function compressCodeContext(files) {
    return files.map(file => ({
        path: file.path,
        summary: extractCodeSummary(file),
        relevantSections: extractRelevantCode(file, currentTask),
        // Only include full content if actively editing
        content: file.isBeingEdited ? file.content : undefined
    }))
}

// Summarize conversation history
function summarizeHistory(messages, keepRecent = 5) {
    const recent = messages.slice(-keepRecent)
    const older = messages.slice(0, -keepRecent)

    return [
        { role: 'system', content: `Previous context summary: ${summarize(older)}` },
        ...recent
    ]
}
```

### Step 4: Agent Handoff Format

```yaml
handoff_template:
  task_summary:
    description: "Brief task description"
    status: "Current progress"
    blocking_issues: ["Any blockers"]

  relevant_context:
    files_modified:
      - path: "file.ts"
        changes: "Summary of changes"
    decisions_made:
      - "Decision 1 and rationale"
    test_status: "Current test state"

  next_steps:
    - "What receiving agent should do"

  excluded_context:
    - "What was intentionally left out"
    - "Where to find it if needed"
```

## Optimization Techniques

### Progressive Summarization
```javascript
// Level 1: Light compression
const light = removeVerboseOutput(context)

// Level 2: Medium compression
const medium = summarizeOlderMessages(light)

// Level 3: Heavy compression
const heavy = extractEssentialsOnly(medium)

// Select based on remaining capacity
function selectCompression(currentTokens, maxTokens) {
    const ratio = currentTokens / maxTokens
    if (ratio < 0.6) return 'none'
    if (ratio < 0.8) return 'light'
    if (ratio < 0.95) return 'medium'
    return 'heavy'
}
```

### Smart File Inclusion
```javascript
function selectRelevantFiles(allFiles, task) {
    const scores = allFiles.map(file => ({
        file,
        score: calculateRelevance(file, task)
    }))

    // Include high-relevance files fully
    const fullInclude = scores
        .filter(s => s.score > 0.8)
        .map(s => s.file)

    // Include medium-relevance as summaries
    const summaryInclude = scores
        .filter(s => s.score > 0.4 && s.score <= 0.8)
        .map(s => ({ ...s.file, content: summarize(s.file) }))

    return [...fullInclude, ...summaryInclude]
}
```

### Code-Specific Compression
```javascript
function compressCode(code) {
    return {
        // Keep signatures and structure
        signatures: extractFunctionSignatures(code),
        types: extractTypeDefinitions(code),
        exports: extractExports(code),

        // Summarize implementations
        implementations: summarizeImplementations(code),

        // Full code only for focus area
        focusArea: extractFocusArea(code, currentTask)
    }
}
```

## Output Format

```yaml
context_optimization_report:
  before:
    total_tokens: 45000
    breakdown:
      system: 2000
      history: 15000
      files: 25000
      tools: 3000

  after:
    total_tokens: 18000
    breakdown:
      system: 2000
      history: 5000
      files: 10000
      tools: 1000

  savings:
    tokens_saved: 27000
    percentage: "60%"

  techniques_applied:
    - "Summarized 15 older messages"
    - "Compressed 8 code files to summaries"
    - "Removed 5 redundant tool outputs"

  preserved_context:
    - "Current task details"
    - "3 actively edited files"
    - "Recent 5 messages"
    - "Critical error information"
```

## See Also

- `skills/meta/prompt-engineer.md` - Prompt optimization
- `hooks/pre-compact.sh` - Pre-compaction handling
- `agents/orchestration/task-orchestrator.md` - Task context management
