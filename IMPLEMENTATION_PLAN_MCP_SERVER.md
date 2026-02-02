# DevTeam MCP Server Orchestrator - Implementation Plan

## Overview

Build an MCP (Model Context Protocol) server that acts as the orchestration brain for the DevTeam multi-agent system. This server will manage state, implement the task loop, handle model escalation, and coordinate quality gates - all while integrating natively with Claude Code.

**Technology Stack:**
- TypeScript (Node.js)
- MCP SDK (`@modelcontextprotocol/sdk`)
- SQLite (better-sqlite3 for sync operations)
- Zod for schema validation

**Target Location:** `mcp-server/` directory in the project root

---

## Phase 1: Project Setup and Core Infrastructure

### Task 1.1: Initialize MCP Server Project

```bash
# Create directory structure
mkdir -p mcp-server/src/{tools,resources,state,agents,quality,utils}
cd mcp-server
npm init -y
```

**Install dependencies:**
```json
{
  "dependencies": {
    "@modelcontextprotocol/sdk": "^1.0.0",
    "better-sqlite3": "^11.0.0",
    "zod": "^3.23.0",
    "yaml": "^2.4.0",
    "glob": "^10.3.0",
    "chalk": "^5.3.0"
  },
  "devDependencies": {
    "@types/node": "^20.0.0",
    "@types/better-sqlite3": "^7.6.0",
    "typescript": "^5.4.0",
    "tsx": "^4.7.0"
  }
}
```

**TypeScript configuration** (`tsconfig.json`):
```json
{
  "compilerOptions": {
    "target": "ES2022",
    "module": "NodeNext",
    "moduleResolution": "NodeNext",
    "outDir": "./dist",
    "rootDir": "./src",
    "strict": true,
    "esModuleInterop": true,
    "skipLibCheck": true,
    "declaration": true
  },
  "include": ["src/**/*"],
  "exclude": ["node_modules", "dist"]
}
```

### Task 1.2: Create Database Schema and State Manager

**File: `src/state/schema.ts`**

Define TypeScript interfaces matching the SQLite schema:

```typescript
// Session state
interface Session {
  id: string;
  command: string;
  commandType: 'plan' | 'implement' | 'bug' | 'issue';
  status: 'initializing' | 'running' | 'paused' | 'completed' | 'failed';
  currentPhase: string;
  currentModel: 'haiku' | 'sonnet' | 'opus';
  executionMode: 'normal' | 'eco';
  iteration: number;
  maxIterations: number;
  consecutiveFailures: number;
  tokensInput: number;
  tokensOutput: number;
  costCents: number;
  createdAt: string;
  updatedAt: string;
}

// Task state
interface Task {
  id: string;
  sessionId: string;
  sprintId: string | null;
  description: string;
  status: 'pending' | 'in_progress' | 'completed' | 'failed' | 'blocked';
  complexity: number;
  suggestedAgent: string;
  acceptanceCriteria: string[];
  scopeFiles: string[];
  iteration: number;
  startedAt: string | null;
  completedAt: string | null;
}

// Event log
interface Event {
  id: number;
  sessionId: string;
  eventType: string;
  eventCategory: string;
  message: string;
  data: Record<string, unknown>;
  agent: string | null;
  model: string | null;
  iteration: number;
  timestamp: string;
}

// Quality gate result
interface GateResult {
  id: number;
  sessionId: string;
  taskId: string;
  gate: 'tests' | 'typecheck' | 'lint' | 'security' | 'coverage';
  passed: boolean;
  errorCount: number;
  details: Record<string, unknown>;
  iteration: number;
  timestamp: string;
}

// Escalation record
interface Escalation {
  id: number;
  sessionId: string;
  taskId: string;
  fromModel: string;
  toModel: string;
  reason: string;
  iteration: number;
  timestamp: string;
}
```

**File: `src/state/database.ts`**

Implement database manager:

```typescript
import Database from 'better-sqlite3';

class StateDatabase {
  private db: Database.Database;

  constructor(dbPath: string) {
    this.db = new Database(dbPath);
    this.db.pragma('journal_mode = WAL');
    this.initSchema();
  }

  private initSchema(): void {
    // Read and execute schema-v2.sql
    // Create all tables if not exist
  }

  // Session management
  createSession(session: Omit<Session, 'id' | 'createdAt' | 'updatedAt'>): Session;
  getSession(id: string): Session | null;
  getCurrentSession(): Session | null;
  updateSession(id: string, updates: Partial<Session>): void;

  // Task management
  createTask(task: Omit<Task, 'id'>): Task;
  getTask(id: string): Task | null;
  getTasksForSession(sessionId: string): Task[];
  updateTask(id: string, updates: Partial<Task>): void;

  // Event logging
  logEvent(event: Omit<Event, 'id' | 'timestamp'>): void;
  getEvents(sessionId: string, limit?: number): Event[];

  // Gate results
  recordGateResult(result: Omit<GateResult, 'id' | 'timestamp'>): void;
  getGateResults(sessionId: string, taskId: string): GateResult[];

  // Escalations
  recordEscalation(escalation: Omit<Escalation, 'id' | 'timestamp'>): void;
  getEscalations(sessionId: string): Escalation[];

  // Checkpoints
  saveCheckpoint(sessionId: string, data: Record<string, unknown>): string;
  loadCheckpoint(checkpointId: string): Record<string, unknown> | null;
  listCheckpoints(sessionId: string): { id: string; createdAt: string }[];
}
```

### Task 1.3: Create Agent Parser

**File: `src/agents/parser.ts`**

Parse agent markdown files into structured data:

```typescript
interface AgentDefinition {
  id: string;
  name: string;
  category: string;
  model: 'haiku' | 'sonnet' | 'opus' | 'dynamic';
  complexityRange: [number, number];
  purpose: string;
  role: string;
  instructions: string;
  scope: {
    canModify: string[];
    cannotModify: string[];
  };
  outputs: {
    format: string;
    fields: string[];
  };
}

class AgentParser {
  private agentsDir: string;
  private cache: Map<string, AgentDefinition>;

  constructor(agentsDir: string) {
    this.agentsDir = agentsDir;
    this.cache = new Map();
  }

  // Parse a single agent file
  parseAgent(filePath: string): AgentDefinition;

  // Load all agents from directory
  loadAllAgents(): Map<string, AgentDefinition>;

  // Get agent by ID
  getAgent(id: string): AgentDefinition | null;

  // Search agents by criteria
  findAgents(criteria: {
    category?: string;
    keywords?: string[];
    fileTypes?: string[];
    taskType?: string;
  }): AgentDefinition[];
}
```

### Task 1.4: Create Agent Selector

**File: `src/agents/selector.ts`**

Implement the weighted agent selection algorithm:

```typescript
interface SelectionCriteria {
  taskDescription: string;
  taskType?: 'feature' | 'bug' | 'security' | 'refactor' | 'docs';
  fileTypes: string[];
  keywords: string[];
  language?: string;
  complexity: number;
}

interface SelectionResult {
  primary: AgentDefinition;
  support: AgentDefinition[];
  scores: Map<string, number>;
  reasoning: string;
}

class AgentSelector {
  private parser: AgentParser;
  private capabilities: AgentCapabilities; // From agent-capabilities.yaml

  constructor(parser: AgentParser, capabilitiesPath: string) {
    this.parser = parser;
    this.capabilities = this.loadCapabilities(capabilitiesPath);
  }

  // Main selection method
  selectAgent(criteria: SelectionCriteria): SelectionResult {
    // Weights from agent-selection.md:
    // - Keywords: 40%
    // - File types: 30%
    // - Task type: 20%
    // - Language: 10%
  }

  // Score individual agent
  private scoreAgent(agent: AgentDefinition, criteria: SelectionCriteria): number;

  // Extract keywords from task description
  private extractKeywords(description: string): string[];

  // Detect file types from changed files
  private detectFileTypes(files: string[]): string[];
}
```

---

## Phase 2: Task Loop Implementation

### Task 2.1: Create Task Loop State Machine

**File: `src/orchestration/task-loop.ts`**

```typescript
type TaskLoopState =
  | 'idle'
  | 'initializing'
  | 'selecting_agent'
  | 'executing'
  | 'awaiting_quality_gates'
  | 'evaluating_results'
  | 'escalating'
  | 'activating_bug_council'
  | 'completed'
  | 'failed';

interface TaskLoopContext {
  session: Session;
  task: Task;
  currentAgent: AgentDefinition;
  currentModel: 'haiku' | 'sonnet' | 'opus';
  iteration: number;
  maxIterations: number;
  consecutiveFailures: number;
  failureHistory: FailureRecord[];
  gateResults: GateResult[];
}

interface FailureRecord {
  iteration: number;
  model: string;
  agent: string;
  errors: string[];
  gatesFailed: string[];
}

class TaskLoop {
  private db: StateDatabase;
  private agentSelector: AgentSelector;
  private qualityRunner: QualityGateRunner;
  private state: TaskLoopState;
  private context: TaskLoopContext | null;

  constructor(db: StateDatabase, agentSelector: AgentSelector, qualityRunner: QualityGateRunner) {
    this.db = db;
    this.agentSelector = agentSelector;
    this.qualityRunner = qualityRunner;
    this.state = 'idle';
    this.context = null;
  }

  // Start a new task
  async startTask(taskId: string): Promise<TaskLoopContext>;

  // Get current state and context for MCP tool response
  getStatus(): { state: TaskLoopState; context: TaskLoopContext | null };

  // Called when agent reports completion of work
  async reportAgentCompletion(result: {
    filesChanged: string[];
    summary: string;
  }): Promise<{ nextAction: string; context: string }>;

  // Called after quality gates run
  async processGateResults(results: GateResult[]): Promise<{
    decision: 'complete' | 'iterate' | 'escalate' | 'bug_council';
    reason: string;
    nextInstructions: string;
  }>;

  // Model escalation logic
  private shouldEscalate(): boolean {
    // Escalate after 2 consecutive failures (normal mode)
    // Escalate after 4 consecutive failures (eco mode)
  }

  private escalateModel(): 'sonnet' | 'opus' | 'bug_council' {
    // haiku -> sonnet -> opus -> bug_council
  }

  // Stuck loop detection
  private detectStuckLoop(): boolean {
    // Same files modified 3 times without progress
    // Same test failing 3 times
    // Same error message 3 times
  }

  // Generate context for next iteration
  private buildIterationContext(): string {
    // Include: previous failures, what was tried, specific errors
  }
}
```

### Task 2.2: Create Model Selection Logic

**File: `src/orchestration/model-selector.ts`**

```typescript
interface ModelConfig {
  haiku: { maxComplexity: number; costPer1kInput: number; costPer1kOutput: number };
  sonnet: { maxComplexity: number; costPer1kInput: number; costPer1kOutput: number };
  opus: { maxComplexity: number; costPer1kInput: number; costPer1kOutput: number };
}

class ModelSelector {
  private config: ModelConfig;
  private ecoMode: boolean;

  constructor(ecoMode: boolean = false) {
    this.ecoMode = ecoMode;
    this.config = {
      haiku: { maxComplexity: 4, costPer1kInput: 0.00025, costPer1kOutput: 0.00125 },
      sonnet: { maxComplexity: 8, costPer1kInput: 0.003, costPer1kOutput: 0.015 },
      opus: { maxComplexity: 14, costPer1kInput: 0.015, costPer1kOutput: 0.075 }
    };
  }

  // Select initial model based on complexity
  selectInitialModel(complexity: number): 'haiku' | 'sonnet' | 'opus';

  // Get next model for escalation
  getEscalatedModel(current: 'haiku' | 'sonnet' | 'opus'): 'sonnet' | 'opus' | 'bug_council';

  // Check if escalation is warranted
  shouldEscalate(consecutiveFailures: number, currentModel: string): boolean;

  // Calculate cost for API call
  calculateCost(model: string, inputTokens: number, outputTokens: number): number;
}
```

### Task 2.3: Create Quality Gate Runner

**File: `src/quality/gate-runner.ts`**

```typescript
interface QualityGateConfig {
  tests: { command: string; required: boolean };
  typecheck: { command: string; required: boolean };
  lint: { command: string; required: boolean };
  security: { command: string; required: boolean; haltOnCritical: boolean };
  coverage: { command: string; required: boolean; threshold: number };
}

interface GateRunResult {
  gate: string;
  passed: boolean;
  errorCount: number;
  errors: string[];
  warnings: string[];
  duration: number;
  output: string;
}

class QualityGateRunner {
  private projectRoot: string;
  private config: QualityGateConfig;

  constructor(projectRoot: string) {
    this.projectRoot = projectRoot;
    this.config = this.detectProjectConfig();
  }

  // Auto-detect project type and configure gates
  private detectProjectConfig(): QualityGateConfig {
    // Check for: package.json, pyproject.toml, go.mod, pom.xml, etc.
    // Return appropriate commands for each gate
  }

  // Run all gates
  async runAllGates(): Promise<{
    overall: 'pass' | 'fail' | 'halt';
    results: GateRunResult[];
    blocking: string[];
    summary: string;
  }>;

  // Run individual gate
  async runGate(gate: keyof QualityGateConfig): Promise<GateRunResult>;

  // Parse test output for failures
  private parseTestOutput(output: string, framework: string): { passed: number; failed: number; errors: string[] };

  // Parse lint output
  private parseLintOutput(output: string, linter: string): { errors: string[]; warnings: string[] };

  // Parse security scan output
  private parseSecurityOutput(output: string, scanner: string): { critical: number; high: number; medium: number; low: number; findings: string[] };
}
```

### Task 2.4: Create Bug Council Coordinator

**File: `src/orchestration/bug-council.ts`**

```typescript
interface BugCouncilMember {
  id: string;
  name: string;
  role: string;
  analysisPrompt: string;
}

interface BugCouncilInput {
  task: Task;
  failureHistory: FailureRecord[];
  codeChanges: string[];
  errorContext: string;
}

interface BugCouncilAnalysis {
  member: string;
  findings: string[];
  hypothesis: string;
  suggestedFix: string;
  confidence: number;
}

interface BugCouncilDecision {
  winningProposal: string;
  votes: Map<string, string>;
  rootCause: string;
  recommendedFix: string;
  additionalContext: string;
}

class BugCouncilCoordinator {
  private members: BugCouncilMember[];
  private db: StateDatabase;

  constructor(db: StateDatabase, agentsDir: string) {
    this.db = db;
    this.members = this.loadCouncilMembers(agentsDir);
  }

  // Activate bug council
  async activate(input: BugCouncilInput): Promise<{
    activated: true;
    instructions: string;
    members: string[];
  }>;

  // Record analysis from a council member
  recordAnalysis(memberId: string, analysis: BugCouncilAnalysis): void;

  // Check if all members have submitted
  isComplete(): boolean;

  // Synthesize final decision
  synthesizeDecision(): BugCouncilDecision;

  // Generate prompt for each member
  getMemberPrompt(memberId: string, input: BugCouncilInput): string;
}
```

---

## Phase 3: MCP Tool Implementations

### Task 3.1: Create MCP Server Entry Point

**File: `src/index.ts`**

```typescript
import { Server } from '@modelcontextprotocol/sdk/server/index.js';
import { StdioServerTransport } from '@modelcontextprotocol/sdk/server/stdio.js';

const server = new Server(
  { name: 'devteam-orchestrator', version: '1.0.0' },
  { capabilities: { tools: {}, resources: {} } }
);

// Initialize components
const db = new StateDatabase(process.env.DEVTEAM_DB || '.devteam/state.db');
const agentParser = new AgentParser('./agents');
const agentSelector = new AgentSelector(agentParser, '.devteam/agent-capabilities.yaml');
const qualityRunner = new QualityGateRunner(process.cwd());
const taskLoop = new TaskLoop(db, agentSelector, qualityRunner);
const bugCouncil = new BugCouncilCoordinator(db, './agents/diagnosis');

// Register all tools
registerTools(server, { db, taskLoop, agentSelector, qualityRunner, bugCouncil });

// Start server
const transport = new StdioServerTransport();
await server.connect(transport);
```

### Task 3.2: Implement Core MCP Tools

**File: `src/tools/session-tools.ts`**

```typescript
// Tool: devteam_start_session
// Starts a new orchestrated session
{
  name: 'devteam_start_session',
  description: 'Start a new DevTeam orchestrated session',
  inputSchema: {
    type: 'object',
    properties: {
      command: { type: 'string', description: 'The command being executed (plan, implement, bug, issue)' },
      commandType: { type: 'string', enum: ['plan', 'implement', 'bug', 'issue'] },
      executionMode: { type: 'string', enum: ['normal', 'eco'], default: 'normal' }
    },
    required: ['command', 'commandType']
  },
  handler: async (args) => {
    const session = db.createSession({
      command: args.command,
      commandType: args.commandType,
      executionMode: args.executionMode || 'normal',
      status: 'initializing',
      currentPhase: 'startup',
      currentModel: 'sonnet',
      iteration: 0,
      maxIterations: 10,
      consecutiveFailures: 0,
      tokensInput: 0,
      tokensOutput: 0,
      costCents: 0
    });

    db.logEvent({
      sessionId: session.id,
      eventType: 'session_started',
      eventCategory: 'session',
      message: `Session started: ${args.command}`,
      data: { commandType: args.commandType }
    });

    return {
      content: [{
        type: 'text',
        text: `Session ${session.id} started.\n\nMode: ${args.executionMode}\nMax iterations: 10\n\nCall devteam_start_task to begin working on a task.`
      }]
    };
  }
}

// Tool: devteam_get_session_status
// Returns current session state
{
  name: 'devteam_get_session_status',
  description: 'Get current session status and context',
  inputSchema: { type: 'object', properties: {} },
  handler: async () => {
    const session = db.getCurrentSession();
    if (!session) {
      return { content: [{ type: 'text', text: 'No active session. Call devteam_start_session first.' }] };
    }

    const tasks = db.getTasksForSession(session.id);
    const events = db.getEvents(session.id, 10);

    return {
      content: [{
        type: 'text',
        text: formatSessionStatus(session, tasks, events)
      }]
    };
  }
}

// Tool: devteam_end_session
// Ends current session with status
{
  name: 'devteam_end_session',
  description: 'End the current session',
  inputSchema: {
    type: 'object',
    properties: {
      status: { type: 'string', enum: ['completed', 'failed', 'paused'] },
      reason: { type: 'string' }
    },
    required: ['status']
  }
}
```

**File: `src/tools/task-tools.ts`**

```typescript
// Tool: devteam_start_task
// Initializes task loop for a specific task
{
  name: 'devteam_start_task',
  description: 'Start working on a task with orchestrated quality loop',
  inputSchema: {
    type: 'object',
    properties: {
      taskId: { type: 'string', description: 'Task ID to start (or "adhoc" for ad-hoc task)' },
      description: { type: 'string', description: 'Task description (required for adhoc)' },
      acceptanceCriteria: {
        type: 'array',
        items: { type: 'string' },
        description: 'Acceptance criteria (required for adhoc)'
      },
      scopeFiles: {
        type: 'array',
        items: { type: 'string' },
        description: 'Files allowed to be modified'
      }
    },
    required: ['taskId']
  },
  handler: async (args) => {
    const context = await taskLoop.startTask(args.taskId, args);
    const agent = context.currentAgent;

    return {
      content: [{
        type: 'text',
        text: `
═══════════════════════════════════════════════════════════════
 TASK LOOP STARTED
═══════════════════════════════════════════════════════════════

Task: ${context.task.description}
Agent: ${agent.name} (${agent.id})
Model: ${context.currentModel}
Iteration: ${context.iteration}/${context.maxIterations}

═══════════════════════════════════════════════════════════════
 YOUR ROLE: ${agent.name}
═══════════════════════════════════════════════════════════════

${agent.purpose}

${agent.instructions}

═══════════════════════════════════════════════════════════════
 ACCEPTANCE CRITERIA
═══════════════════════════════════════════════════════════════

${context.task.acceptanceCriteria.map((c, i) => `${i + 1}. ${c}`).join('\n')}

═══════════════════════════════════════════════════════════════
 SCOPE (Files you may modify)
═══════════════════════════════════════════════════════════════

${context.task.scopeFiles.length > 0 ? context.task.scopeFiles.join('\n') : 'No restrictions - use judgment'}

═══════════════════════════════════════════════════════════════

Begin implementation. When done, call devteam_report_completion.
`
      }]
    };
  }
}

// Tool: devteam_report_completion
// Called when agent believes task is complete
{
  name: 'devteam_report_completion',
  description: 'Report that you have completed implementation work',
  inputSchema: {
    type: 'object',
    properties: {
      filesChanged: {
        type: 'array',
        items: { type: 'string' },
        description: 'List of files that were modified'
      },
      summary: {
        type: 'string',
        description: 'Summary of changes made'
      }
    },
    required: ['filesChanged', 'summary']
  },
  handler: async (args) => {
    // Record completion attempt
    const result = await taskLoop.reportAgentCompletion(args);

    // Run quality gates
    const gateResults = await qualityRunner.runAllGates();

    // Process results through task loop
    const decision = await taskLoop.processGateResults(gateResults.results);

    if (decision.decision === 'complete') {
      return {
        content: [{
          type: 'text',
          text: `
═══════════════════════════════════════════════════════════════
 ✅ TASK COMPLETE
═══════════════════════════════════════════════════════════════

All quality gates passed!

${gateResults.summary}

Files Changed:
${args.filesChanged.map(f => `  • ${f}`).join('\n')}

Call devteam_end_session with status "completed" or start next task.

EXIT_SIGNAL: true
`
        }]
      };
    }

    if (decision.decision === 'escalate') {
      return {
        content: [{
          type: 'text',
          text: `
═══════════════════════════════════════════════════════════════
 ⚠️ QUALITY GATES FAILED - ESCALATING
═══════════════════════════════════════════════════════════════

${decision.reason}

Model: ${taskLoop.getStatus().context?.currentModel}
Iteration: ${taskLoop.getStatus().context?.iteration}/${taskLoop.getStatus().context?.maxIterations}

${decision.nextInstructions}

Previous errors to address:
${gateResults.results.filter(r => !r.passed).map(r => `
[${r.gate}]
${r.errors.join('\n')}
`).join('\n')}

Continue with enhanced reasoning. Call devteam_report_completion when done.
`
        }]
      };
    }

    if (decision.decision === 'bug_council') {
      return {
        content: [{
          type: 'text',
          text: `
═══════════════════════════════════════════════════════════════
 🔴 BUG COUNCIL ACTIVATED
═══════════════════════════════════════════════════════════════

Multiple failures detected. Activating 5-member diagnostic team.

${decision.nextInstructions}

Call devteam_bug_council_analyze to get multi-perspective analysis.
`
        }]
      };
    }

    // Iterate
    return {
      content: [{
        type: 'text',
        text: `
═══════════════════════════════════════════════════════════════
 🔄 ITERATE - Quality Gates Failed
═══════════════════════════════════════════════════════════════

${decision.reason}

Iteration: ${taskLoop.getStatus().context?.iteration}/${taskLoop.getStatus().context?.maxIterations}

Issues to fix:
${gateResults.results.filter(r => !r.passed).map(r => `
[${r.gate}] ${r.errorCount} errors
${r.errors.slice(0, 5).join('\n')}
${r.errors.length > 5 ? `... and ${r.errors.length - 5} more` : ''}
`).join('\n')}

Fix these issues and call devteam_report_completion again.
`
      }]
    };
  }
}

// Tool: devteam_get_context
// Returns full context for current task
{
  name: 'devteam_get_context',
  description: 'Get full context including failure history and previous attempts',
  inputSchema: { type: 'object', properties: {} },
  handler: async () => {
    const status = taskLoop.getStatus();
    if (!status.context) {
      return { content: [{ type: 'text', text: 'No active task. Call devteam_start_task first.' }] };
    }

    return {
      content: [{
        type: 'text',
        text: JSON.stringify({
          task: status.context.task,
          agent: status.context.currentAgent.id,
          model: status.context.currentModel,
          iteration: status.context.iteration,
          failureHistory: status.context.failureHistory,
          gateResults: status.context.gateResults
        }, null, 2)
      }]
    };
  }
}
```

**File: `src/tools/quality-tools.ts`**

```typescript
// Tool: devteam_run_quality_gates
// Manually trigger quality gate run
{
  name: 'devteam_run_quality_gates',
  description: 'Run all quality gates and return results',
  inputSchema: {
    type: 'object',
    properties: {
      gates: {
        type: 'array',
        items: { type: 'string', enum: ['tests', 'typecheck', 'lint', 'security', 'coverage'] },
        description: 'Specific gates to run (default: all)'
      }
    }
  },
  handler: async (args) => {
    const results = await qualityRunner.runAllGates(args.gates);
    return {
      content: [{
        type: 'text',
        text: formatGateResults(results)
      }]
    };
  }
}

// Tool: devteam_check_scope
// Validate that files are within allowed scope
{
  name: 'devteam_check_scope',
  description: 'Check if files are within allowed modification scope',
  inputSchema: {
    type: 'object',
    properties: {
      files: {
        type: 'array',
        items: { type: 'string' },
        description: 'Files to check'
      }
    },
    required: ['files']
  },
  handler: async (args) => {
    const status = taskLoop.getStatus();
    if (!status.context) {
      return { content: [{ type: 'text', text: 'No active task context.' }] };
    }

    const scopeFiles = status.context.task.scopeFiles;
    const violations = args.files.filter(f => !isInScope(f, scopeFiles));

    if (violations.length > 0) {
      return {
        content: [{
          type: 'text',
          text: `⚠️ SCOPE VIOLATION\n\nThese files are outside allowed scope:\n${violations.join('\n')}\n\nAllowed scope:\n${scopeFiles.join('\n')}`
        }]
      };
    }

    return {
      content: [{
        type: 'text',
        text: `✅ All files within scope.`
      }]
    };
  }
}
```

**File: `src/tools/bug-council-tools.ts`**

```typescript
// Tool: devteam_bug_council_analyze
// Get Bug Council multi-perspective analysis
{
  name: 'devteam_bug_council_analyze',
  description: 'Get multi-perspective analysis from Bug Council',
  inputSchema: { type: 'object', properties: {} },
  handler: async () => {
    const status = taskLoop.getStatus();
    if (!status.context) {
      return { content: [{ type: 'text', text: 'No active task context.' }] };
    }

    const activation = await bugCouncil.activate({
      task: status.context.task,
      failureHistory: status.context.failureHistory,
      codeChanges: [], // Would need to track this
      errorContext: status.context.failureHistory.map(f => f.errors.join('\n')).join('\n\n')
    });

    return {
      content: [{
        type: 'text',
        text: `
═══════════════════════════════════════════════════════════════
 BUG COUNCIL ACTIVATED
═══════════════════════════════════════════════════════════════

Council Members:
${activation.members.map(m => `  • ${m}`).join('\n')}

${activation.instructions}

You will now analyze this issue from 5 perspectives. For each perspective,
call devteam_bug_council_submit with your analysis.

Perspectives:
1. Root Cause Analyst - Error analysis, hypothesis generation
2. Code Archaeologist - Git history, regression detection
3. Pattern Matcher - Similar bugs, anti-patterns
4. Systems Thinker - Dependencies, architectural issues
5. Adversarial Tester - Edge cases, attack vectors

Start with Root Cause Analyst.
`
      }]
    };
  }
}

// Tool: devteam_bug_council_submit
// Submit analysis from one council member
{
  name: 'devteam_bug_council_submit',
  description: 'Submit analysis from a Bug Council member',
  inputSchema: {
    type: 'object',
    properties: {
      member: {
        type: 'string',
        enum: ['root_cause_analyst', 'code_archaeologist', 'pattern_matcher', 'systems_thinker', 'adversarial_tester']
      },
      findings: { type: 'array', items: { type: 'string' } },
      hypothesis: { type: 'string' },
      suggestedFix: { type: 'string' },
      confidence: { type: 'number', minimum: 0, maximum: 100 }
    },
    required: ['member', 'findings', 'hypothesis', 'suggestedFix', 'confidence']
  },
  handler: async (args) => {
    bugCouncil.recordAnalysis(args.member, {
      member: args.member,
      findings: args.findings,
      hypothesis: args.hypothesis,
      suggestedFix: args.suggestedFix,
      confidence: args.confidence
    });

    if (bugCouncil.isComplete()) {
      const decision = bugCouncil.synthesizeDecision();
      return {
        content: [{
          type: 'text',
          text: `
═══════════════════════════════════════════════════════════════
 BUG COUNCIL DECISION
═══════════════════════════════════════════════════════════════

Root Cause: ${decision.rootCause}

Recommended Fix:
${decision.recommendedFix}

Additional Context:
${decision.additionalContext}

Implement this fix and call devteam_report_completion.
`
        }]
      };
    }

    const nextMember = bugCouncil.getNextMember();
    return {
      content: [{
        type: 'text',
        text: `Analysis recorded. Now analyze as: ${nextMember}`
      }]
    };
  }
}
```

**File: `src/tools/checkpoint-tools.ts`**

```typescript
// Tool: devteam_save_checkpoint
// Save current state for later resume
{
  name: 'devteam_save_checkpoint',
  description: 'Save checkpoint for session resume',
  inputSchema: {
    type: 'object',
    properties: {
      description: { type: 'string', description: 'Checkpoint description' }
    }
  },
  handler: async (args) => {
    const session = db.getCurrentSession();
    if (!session) {
      return { content: [{ type: 'text', text: 'No active session.' }] };
    }

    const status = taskLoop.getStatus();
    const checkpointId = db.saveCheckpoint(session.id, {
      session,
      taskContext: status.context,
      description: args.description || 'Manual checkpoint'
    });

    return {
      content: [{
        type: 'text',
        text: `✅ Checkpoint saved: ${checkpointId}\n\nUse devteam_restore_checkpoint to resume later.`
      }]
    };
  }
}

// Tool: devteam_restore_checkpoint
// Restore from checkpoint
{
  name: 'devteam_restore_checkpoint',
  description: 'Restore session from checkpoint',
  inputSchema: {
    type: 'object',
    properties: {
      checkpointId: { type: 'string', description: 'Checkpoint ID to restore' }
    },
    required: ['checkpointId']
  }
}

// Tool: devteam_list_checkpoints
// List available checkpoints
{
  name: 'devteam_list_checkpoints',
  description: 'List available checkpoints',
  inputSchema: { type: 'object', properties: {} }
}
```

### Task 3.3: Implement MCP Resources

**File: `src/resources/index.ts`**

```typescript
// Resource: devteam://agents
// Lists all available agents
{
  uri: 'devteam://agents',
  name: 'Available Agents',
  description: 'List of all DevTeam agents',
  mimeType: 'application/json'
}

// Resource: devteam://agents/{id}
// Get specific agent details
{
  uri: 'devteam://agents/{id}',
  name: 'Agent Details',
  description: 'Details for a specific agent',
  mimeType: 'application/json'
}

// Resource: devteam://session/current
// Current session state
{
  uri: 'devteam://session/current',
  name: 'Current Session',
  description: 'Current session state and progress',
  mimeType: 'application/json'
}

// Resource: devteam://session/history
// Session history
{
  uri: 'devteam://session/history',
  name: 'Session History',
  description: 'Recent session history',
  mimeType: 'application/json'
}

// Resource: devteam://config
// Current configuration
{
  uri: 'devteam://config',
  name: 'Configuration',
  description: 'DevTeam configuration',
  mimeType: 'application/json'
}
```

---

## Phase 4: Configuration and Integration

### Task 4.1: Create Configuration Loader

**File: `src/config/loader.ts`**

```typescript
interface DevTeamConfig {
  orchestration: {
    maxIterations: number;
    escalationThreshold: number;
    stuckDetection: boolean;
    costTracking: boolean;
  };
  models: {
    haiku: { name: string; maxComplexity: number };
    sonnet: { name: string; maxComplexity: number };
    opus: { name: string; maxComplexity: number };
  };
  qualityGates: {
    tests: { required: boolean; command?: string };
    typecheck: { required: boolean; command?: string };
    lint: { required: boolean; command?: string };
    security: { required: boolean; haltOnCritical: boolean };
    coverage: { required: boolean; threshold: number };
  };
  ecoMode: {
    defaultModel: string;
    escalationThreshold: number;
  };
}

class ConfigLoader {
  private configDir: string;
  private config: DevTeamConfig;

  constructor(configDir: string = '.devteam') {
    this.configDir = configDir;
    this.config = this.loadConfig();
  }

  // Load and merge all config files
  private loadConfig(): DevTeamConfig;

  // Get config value
  get<T>(path: string): T;

  // Validate config
  validate(): { valid: boolean; errors: string[] };
}
```

### Task 4.2: Create Claude Code Configuration Generator

**File: `src/utils/generate-claude-config.ts`**

Script to generate Claude Code MCP configuration:

```typescript
// Generates the configuration for ~/.claude/settings.json
function generateClaudeCodeConfig(projectRoot: string): object {
  return {
    mcpServers: {
      devteam: {
        command: 'node',
        args: [`${projectRoot}/mcp-server/dist/index.js`],
        env: {
          DEVTEAM_DB: `${projectRoot}/.devteam/state.db`,
          DEVTEAM_CONFIG: `${projectRoot}/.devteam`,
          DEVTEAM_AGENTS: `${projectRoot}/agents`
        }
      }
    }
  };
}
```

### Task 4.3: Create Installation Script

**File: `mcp-server/install.sh`**

```bash
#!/bin/bash
# Install DevTeam MCP Server

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

echo "Installing DevTeam MCP Server..."

# Build TypeScript
cd "$SCRIPT_DIR"
npm install
npm run build

# Initialize database
"$PROJECT_ROOT/scripts/db-init.sh"

# Generate Claude Code config
node dist/utils/generate-claude-config.js "$PROJECT_ROOT"

echo ""
echo "Installation complete!"
echo ""
echo "Add the following to ~/.claude/settings.json:"
echo ""
cat << EOF
{
  "mcpServers": {
    "devteam": {
      "command": "node",
      "args": ["$SCRIPT_DIR/dist/index.js"],
      "env": {
        "DEVTEAM_DB": "$PROJECT_ROOT/.devteam/state.db",
        "DEVTEAM_CONFIG": "$PROJECT_ROOT/.devteam",
        "DEVTEAM_AGENTS": "$PROJECT_ROOT/agents"
      }
    }
  }
}
EOF
```

---

## Phase 5: Testing and Documentation

### Task 5.1: Create Test Suite

**File: `mcp-server/tests/`**

```
tests/
├── unit/
│   ├── state/
│   │   ├── database.test.ts
│   │   └── schema.test.ts
│   ├── agents/
│   │   ├── parser.test.ts
│   │   └── selector.test.ts
│   ├── orchestration/
│   │   ├── task-loop.test.ts
│   │   ├── model-selector.test.ts
│   │   └── bug-council.test.ts
│   └── quality/
│       └── gate-runner.test.ts
├── integration/
│   ├── mcp-tools.test.ts
│   └── full-workflow.test.ts
└── fixtures/
    ├── mock-agents/
    └── mock-projects/
```

### Task 5.2: Create Documentation

**File: `mcp-server/README.md`**

Document:
- Installation instructions
- Configuration options
- Available tools and their usage
- Workflow examples
- Troubleshooting guide

---

## Summary: Complete Tool List

| Tool Name | Purpose |
|-----------|---------|
| `devteam_start_session` | Start orchestrated session |
| `devteam_get_session_status` | Get current session state |
| `devteam_end_session` | End session with status |
| `devteam_start_task` | Start task with quality loop |
| `devteam_report_completion` | Report implementation complete |
| `devteam_get_context` | Get full task context |
| `devteam_run_quality_gates` | Manually run quality gates |
| `devteam_check_scope` | Validate file scope |
| `devteam_bug_council_analyze` | Activate Bug Council |
| `devteam_bug_council_submit` | Submit council analysis |
| `devteam_save_checkpoint` | Save checkpoint |
| `devteam_restore_checkpoint` | Restore from checkpoint |
| `devteam_list_checkpoints` | List checkpoints |
| `devteam_escalate` | Manually trigger escalation |
| `devteam_get_agent_info` | Get agent details |
| `devteam_record_tokens` | Record token usage |

---

## Execution Order

1. **Phase 1** (Foundation): Tasks 1.1-1.4
2. **Phase 2** (Task Loop): Tasks 2.1-2.4
3. **Phase 3** (MCP Tools): Tasks 3.1-3.3
4. **Phase 4** (Integration): Tasks 4.1-4.3
5. **Phase 5** (Testing): Tasks 5.1-5.2

**Estimated complexity**: This is a significant implementation (~2000-3000 lines of TypeScript). Build incrementally, testing each phase before proceeding.
