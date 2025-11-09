# API-First Full-Stack Workflow

This guide demonstrates how to build full-stack applications using an **API Design First** approach, ensuring backend and frontend are always in sync through a standardized OpenAPI specification.

---

## The Problem

When building full-stack applications, common issues include:
- Frontend guessing endpoint URLs and request/response formats
- Backend implementing different schemas than frontend expects
- Mismatched authentication flows
- Inconsistent error handling
- API changes breaking the frontend

## The Solution: API Design First

Create an OpenAPI 3.0 specification BEFORE any implementation. Both backend and frontend reference this single source of truth.

---

## Complete Workflow Example

### Project: Task Management Application

**Tech Stack:**
- Backend: Python FastAPI
- Frontend: TypeScript React
- API Spec: OpenAPI 3.0

### Step 1: Generate PRD with API-First Requirements

```bash
/prd
```

**When prompted, specify:**

```yaml
project_name: TaskFlow
description: Task management application with web frontend

technical_requirements:
  approach: "API Design First"
  backend:
    language: Python
    framework: FastAPI
    features:
      - RESTful API
      - JWT authentication
      - PostgreSQL database

  frontend:
    language: TypeScript
    framework: React
    features:
      - Type-safe API client
      - Auto-generated from OpenAPI spec

  api_specification:
    format: OpenAPI 3.0
    location: docs/api/openapi.yaml
    validation: Required for all implementations

workflow_requirements:
  - API specification must be created FIRST (before any code)
  - Backend MUST implement exactly what spec defines
  - Frontend MUST generate client from spec (no manual endpoints)
  - Both validate against specification in CI/CD

features:
  - User authentication (register, login, logout)
  - Task CRUD operations
  - Task filtering and search
  - Task assignment to users
```

### Step 2: Run Planning with API-First Task Structure

```bash
/planning
```

The planning phase will create tasks with proper dependencies:

#### Expected Task Structure

```yaml
# docs/planning/tasks/TASK-001.yaml
id: TASK-001
title: Design Complete API Specification
description: Create OpenAPI 3.0 spec for entire application
agent: backend:api-designer
dependencies: []  # Runs FIRST - no dependencies
priority: critical
acceptance_criteria:
  - OpenAPI 3.0 spec created at docs/api/openapi.yaml
  - All endpoints documented with full schemas
  - Authentication flow defined (JWT)
  - Error response formats standardized (400, 401, 404, 500)
  - Request/response examples included
  - Pagination pattern defined
  - Passes openapi-spec-validator
deliverables:
  - docs/api/openapi.yaml
  - docs/api/API_DESIGN_DECISIONS.md

---

# docs/planning/tasks/TASK-002.yaml
id: TASK-002
title: Design Database Schema
description: Design PostgreSQL schema based on API data models
agent: database:designer
dependencies: [TASK-001]  # Waits for API spec
acceptance_criteria:
  - Schema matches data models in openapi.yaml
  - Proper indexes for API query patterns
  - Foreign keys for relationships
deliverables:
  - docs/design/database/schema.yaml

---

# docs/planning/tasks/TASK-003.yaml
id: TASK-003
title: Implement Database Models
description: Implement SQLAlchemy models from schema
agent: database:developer-python-t1
dependencies: [TASK-002]
acceptance_criteria:
  - Models match database schema design
  - Alembic migrations created
  - Models align with API response schemas
deliverables:
  - backend/models/*.py
  - alembic/versions/*.py

---

# docs/planning/tasks/TASK-004.yaml
id: TASK-004
title: Implement Backend API
description: Implement FastAPI endpoints from OpenAPI spec
agent: backend:api-developer-python-t1
dependencies: [TASK-001, TASK-003]  # Needs API spec AND database models
acceptance_criteria:
  - Implements ALL endpoints from docs/api/openapi.yaml
  - Exact request/response schemas match spec
  - Pydantic models generated from OpenAPI schemas
  - FastAPI auto-validates against spec
  - /docs endpoint serves the specification
  - Passes openapi-spec-validator
  - NO endpoints not in spec
  - NO schema deviations from spec
validation:
  - Run: openapi-spec-validator docs/api/openapi.yaml
  - Run: pytest tests/test_api_compliance.py
  - Verify: curl http://localhost:8000/docs matches spec
deliverables:
  - backend/routes/*.py
  - backend/schemas/*.py (from OpenAPI)
  - tests/test_api_compliance.py

---

# docs/planning/tasks/TASK-005.yaml
id: TASK-005
title: Generate Frontend API Client
description: Auto-generate TypeScript API client from OpenAPI spec
agent: frontend:developer-t1
dependencies: [TASK-001]  # Only needs API spec
acceptance_criteria:
  - Client generated using openapi-typescript-codegen
  - TypeScript types match API schemas exactly
  - All endpoints have type-safe methods
  - Authentication handled automatically
  - NO manual endpoint definitions
  - Compilation ensures type safety
validation:
  - Verify: No hardcoded API endpoints in src/
  - Verify: All API calls use generated client
  - Run: npm run type-check (must pass)
deliverables:
  - src/api/generated/* (auto-generated, committed)
  - src/api/client.ts (wrapper around generated)
  - package.json (with codegen script)

---

# docs/planning/tasks/TASK-006.yaml
id: TASK-006
title: Implement Frontend UI
description: Build React UI using generated API client
agent: frontend:developer-t1
dependencies: [TASK-005]  # Needs generated API client
acceptance_criteria:
  - Uses ONLY generated API client (no fetch/axios directly)
  - TypeScript ensures compile-time API correctness
  - Proper error handling for all error codes from spec
  - Loading states for async operations
deliverables:
  - src/components/*.tsx
  - src/pages/*.tsx
  - src/hooks/useApi.ts

---

# docs/planning/tasks/TASK-007.yaml
id: TASK-007
title: Integration Testing
description: Verify frontend and backend work together
agent: quality:test-writer
dependencies: [TASK-004, TASK-006]  # Needs both implementations
acceptance_criteria:
  - End-to-end tests verify API contract
  - Tests use OpenAPI spec for validation
  - Backend responses match schemas
  - Frontend handles all response types
deliverables:
  - tests/integration/test_api_contract.py
  - e2e/tests/*.spec.ts
```

### Step 3: Execute Sprint

```bash
/sprint SPRINT-001
```

The sprint will execute tasks in dependency order, ensuring the API spec is created first.

---

## Detailed Task Execution

### TASK-001: Design API Specification

**Agent:** `backend:api-designer`

**Prompt:**
```javascript
Task(
  subagent_type="multi-agent:backend:api-designer",
  model="sonnet",
  description="Design complete API specification",
  prompt=`Design comprehensive OpenAPI 3.0 specification for TaskFlow application.

Requirements:

1. AUTHENTICATION
   - POST /api/auth/register
   - POST /api/auth/login (returns JWT)
   - POST /api/auth/logout
   - POST /api/auth/refresh

2. USERS
   - GET /api/users/me
   - PATCH /api/users/me
   - GET /api/users (list, paginated)

3. TASKS
   - POST /api/tasks (create)
   - GET /api/tasks (list, with filtering, pagination)
   - GET /api/tasks/{task_id}
   - PATCH /api/tasks/{task_id}
   - DELETE /api/tasks/{task_id}
   - POST /api/tasks/{task_id}/assign

4. SCHEMAS
   - User: id, email, name, created_at
   - Task: id, title, description, status, priority, assigned_to, created_by, due_date, created_at, updated_at
   - Error: code, message, details

5. AUTHENTICATION
   - JWT Bearer token in Authorization header
   - Token structure: { user_id, email, exp }

6. ERROR RESPONSES
   - 400: Validation error (with field details)
   - 401: Unauthorized
   - 403: Forbidden
   - 404: Not found
   - 500: Internal server error

7. PAGINATION
   - Query params: page, page_size
   - Response: { items: [], total: int, page: int, page_size: int }

Output: docs/api/openapi.yaml

CRITICAL: This spec is the contract. Backend MUST implement exactly this. Frontend WILL generate client from this. Any changes require updating this spec first.`
)
```

**Expected Output:**

```yaml
# docs/api/openapi.yaml
openapi: 3.0.0
info:
  title: TaskFlow API
  version: 1.0.0
  description: Task management API

servers:
  - url: http://localhost:8000/api
    description: Development server

components:
  securitySchemes:
    BearerAuth:
      type: http
      scheme: bearer
      bearerFormat: JWT

  schemas:
    User:
      type: object
      required: [id, email, name]
      properties:
        id:
          type: string
          format: uuid
        email:
          type: string
          format: email
        name:
          type: string
        created_at:
          type: string
          format: date-time

    Task:
      type: object
      required: [id, title, status, created_by]
      properties:
        id:
          type: string
          format: uuid
        title:
          type: string
          maxLength: 200
        description:
          type: string
          nullable: true
        status:
          type: string
          enum: [todo, in_progress, done]
        priority:
          type: string
          enum: [low, medium, high]
          default: medium
        assigned_to:
          type: string
          format: uuid
          nullable: true
        created_by:
          type: string
          format: uuid
        due_date:
          type: string
          format: date-time
          nullable: true
        created_at:
          type: string
          format: date-time
        updated_at:
          type: string
          format: date-time

    TaskCreate:
      type: object
      required: [title]
      properties:
        title:
          type: string
          maxLength: 200
        description:
          type: string
        status:
          type: string
          enum: [todo, in_progress, done]
          default: todo
        priority:
          type: string
          enum: [low, medium, high]
          default: medium
        due_date:
          type: string
          format: date-time

    PaginatedTasks:
      type: object
      required: [items, total, page, page_size]
      properties:
        items:
          type: array
          items:
            $ref: '#/components/schemas/Task'
        total:
          type: integer
        page:
          type: integer
        page_size:
          type: integer

    Error:
      type: object
      required: [code, message]
      properties:
        code:
          type: string
        message:
          type: string
        details:
          type: object

paths:
  /auth/register:
    post:
      summary: Register new user
      requestBody:
        required: true
        content:
          application/json:
            schema:
              type: object
              required: [email, password, name]
              properties:
                email:
                  type: string
                  format: email
                password:
                  type: string
                  minLength: 8
                name:
                  type: string
      responses:
        '201':
          description: User created
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/User'
        '400':
          description: Validation error
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/Error'

  /auth/login:
    post:
      summary: Login user
      requestBody:
        required: true
        content:
          application/json:
            schema:
              type: object
              required: [email, password]
              properties:
                email:
                  type: string
                password:
                  type: string
      responses:
        '200':
          description: Login successful
          content:
            application/json:
              schema:
                type: object
                properties:
                  access_token:
                    type: string
                  token_type:
                    type: string
                    default: bearer
                  user:
                    $ref: '#/components/schemas/User'
        '401':
          description: Invalid credentials

  /tasks:
    get:
      summary: List tasks
      security:
        - BearerAuth: []
      parameters:
        - name: page
          in: query
          schema:
            type: integer
            default: 1
        - name: page_size
          in: query
          schema:
            type: integer
            default: 20
        - name: status
          in: query
          schema:
            type: string
            enum: [todo, in_progress, done]
        - name: assigned_to
          in: query
          schema:
            type: string
      responses:
        '200':
          description: Tasks retrieved
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/PaginatedTasks'

    post:
      summary: Create task
      security:
        - BearerAuth: []
      requestBody:
        required: true
        content:
          application/json:
            schema:
              $ref: '#/components/schemas/TaskCreate'
      responses:
        '201':
          description: Task created
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/Task'

  /tasks/{task_id}:
    get:
      summary: Get task by ID
      security:
        - BearerAuth: []
      parameters:
        - name: task_id
          in: path
          required: true
          schema:
            type: string
            format: uuid
      responses:
        '200':
          description: Task found
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/Task'
        '404':
          description: Task not found
```

---

### TASK-004: Implement Backend (References Spec)

**Agent:** `backend:api-developer-python-t1`

**Prompt:**
```javascript
Task(
  subagent_type="multi-agent:backend:api-developer-python-t1",
  model="haiku",
  description="Implement FastAPI backend from OpenAPI spec",
  prompt=`Implement FastAPI backend that EXACTLY matches docs/api/openapi.yaml

CRITICAL RULES:
1. Implement ONLY endpoints defined in openapi.yaml
2. Request/response schemas MUST match spec exactly
3. Use Pydantic models generated from OpenAPI schemas
4. Validate all responses against spec
5. NO deviations from spec allowed

Implementation requirements:
- Generate Pydantic models from OpenAPI schemas
- Implement all endpoints with exact paths
- JWT authentication matching spec
- Error responses matching spec formats
- Pagination matching spec structure
- Enable FastAPI automatic OpenAPI docs at /docs

Validation:
- FastAPI /docs must match openapi.yaml
- Run: openapi-spec-validator docs/api/openapi.yaml
- Create tests that validate responses against schemas

File structure:
backend/
  schemas/          # Generated from OpenAPI
    user.py
    task.py
    common.py
  routes/
    auth.py         # Implements /auth/* endpoints
    tasks.py        # Implements /tasks/* endpoints
  main.py           # FastAPI app with /docs

Tests:
tests/test_api_compliance.py  # Validates implementation matches spec

DO NOT create endpoints not in spec. DO NOT modify schemas from spec.`
)
```

**Expected Implementation:**

```python
# backend/schemas/task.py (Generated from OpenAPI)
from pydantic import BaseModel, Field
from typing import Optional
from datetime import datetime
from enum import Enum
from uuid import UUID

class TaskStatus(str, Enum):
    TODO = "todo"
    IN_PROGRESS = "in_progress"
    DONE = "done"

class TaskPriority(str, Enum):
    LOW = "low"
    MEDIUM = "medium"
    HIGH = "high"

class TaskCreate(BaseModel):
    """Matches TaskCreate schema in openapi.yaml"""
    title: str = Field(..., max_length=200)
    description: Optional[str] = None
    status: TaskStatus = TaskStatus.TODO
    priority: TaskPriority = TaskPriority.MEDIUM
    due_date: Optional[datetime] = None

class Task(BaseModel):
    """Matches Task schema in openapi.yaml"""
    id: UUID
    title: str
    description: Optional[str]
    status: TaskStatus
    priority: TaskPriority
    assigned_to: Optional[UUID]
    created_by: UUID
    due_date: Optional[datetime]
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True

class PaginatedTasks(BaseModel):
    """Matches PaginatedTasks schema in openapi.yaml"""
    items: list[Task]
    total: int
    page: int
    page_size: int
```

```python
# backend/routes/tasks.py
from fastapi import APIRouter, Depends, Query
from backend.schemas.task import Task, TaskCreate, PaginatedTasks
from backend.auth import get_current_user

router = APIRouter(prefix="/tasks", tags=["tasks"])

@router.post("", response_model=Task, status_code=201)
async def create_task(
    task_data: TaskCreate,  # Pydantic validates against OpenAPI schema
    current_user = Depends(get_current_user)
):
    """Implements POST /tasks from openapi.yaml"""
    # Implementation
    pass

@router.get("", response_model=PaginatedTasks)
async def list_tasks(
    page: int = Query(1, ge=1),
    page_size: int = Query(20, ge=1, le=100),
    status: Optional[TaskStatus] = None,
    assigned_to: Optional[UUID] = None,
    current_user = Depends(get_current_user)
):
    """Implements GET /tasks from openapi.yaml with exact query params"""
    # Implementation - returns PaginatedTasks matching spec
    pass

@router.get("/{task_id}", response_model=Task)
async def get_task(
    task_id: UUID,
    current_user = Depends(get_current_user)
):
    """Implements GET /tasks/{task_id} from openapi.yaml"""
    # Implementation
    pass
```

---

### TASK-005: Generate Frontend Client (From Spec)

**Agent:** `frontend:developer-t1`

**Prompt:**
```javascript
Task(
  subagent_type="multi-agent:frontend:developer-t1",
  model="haiku",
  description="Generate TypeScript API client from OpenAPI spec",
  prompt=`Generate type-safe TypeScript API client from docs/api/openapi.yaml

CRITICAL RULES:
1. Use openapi-typescript-codegen to generate client
2. DO NOT manually define any API endpoints
3. DO NOT hardcode any URLs
4. ALL API calls MUST use generated client

Setup:
1. Install: npm install --save-dev openapi-typescript-codegen
2. Add script to package.json:
   "generate-api": "openapi-typescript-codegen --input docs/api/openapi.yaml --output src/api/generated --client axios"
3. Run generation: npm run generate-api
4. Commit generated files to git

Create wrapper:
src/api/client.ts - Configures base URL, auth tokens

Usage pattern:
import { TasksService } from '@/api/generated'

// Type-safe, matches OpenAPI spec exactly
const tasks = await TasksService.listTasks({ page: 1, status: 'todo' })

Validation:
- Verify NO fetch() or axios calls outside generated client
- Verify TypeScript compilation passes (ensures type safety)
- Verify all API types imported from generated/

Files to create:
package.json (with generate-api script)
src/api/generated/* (auto-generated, committed)
src/api/client.ts (wrapper with config)
.github/workflows/verify-api-client.yml (ensures regeneration if spec changes)`
)
```

**Expected Setup:**

```json
// package.json
{
  "scripts": {
    "generate-api": "openapi-typescript-codegen --input docs/api/openapi.yaml --output src/api/generated --client axios",
    "predev": "npm run generate-api",
    "prebuild": "npm run generate-api"
  },
  "devDependencies": {
    "openapi-typescript-codegen": "^0.25.0"
  }
}
```

```typescript
// src/api/generated/models/Task.ts (AUTO-GENERATED)
export type Task = {
    id: string;
    title: string;
    description?: string | null;
    status: 'todo' | 'in_progress' | 'done';
    priority: 'low' | 'medium' | 'high';
    assigned_to?: string | null;
    created_by: string;
    due_date?: string | null;
    created_at: string;
    updated_at: string;
};
```

```typescript
// src/api/generated/services/TasksService.ts (AUTO-GENERATED)
export class TasksService {
    public static async listTasks(params: {
        page?: number;
        pageSize?: number;
        status?: 'todo' | 'in_progress' | 'done';
        assignedTo?: string;
    }): Promise<PaginatedTasks> {
        // Auto-generated implementation
    }

    public static async createTask(requestBody: TaskCreate): Promise<Task> {
        // Auto-generated implementation
    }
}
```

```typescript
// src/api/client.ts (Custom wrapper)
import { OpenAPI } from './generated';

// Configure base URL and auth
OpenAPI.BASE = import.meta.env.VITE_API_URL || 'http://localhost:8000/api';
OpenAPI.TOKEN = () => localStorage.getItem('access_token');

export * from './generated';
```

---

### TASK-006: Implement Frontend UI (Uses Generated Client)

**Agent:** `frontend:developer-t1`

**Prompt:**
```javascript
Task(
  subagent_type="multi-agent:frontend:developer-t1",
  model="haiku",
  description="Implement React UI using generated API client",
  prompt=`Implement React UI using ONLY the generated API client from src/api/generated

CRITICAL RULES:
1. Import ALL types from src/api/generated
2. Use ONLY generated service classes (TasksService, etc.)
3. NO manual fetch/axios calls
4. TypeScript will enforce API correctness at compile time

Implementation:
src/hooks/useTasks.ts - React Query hooks for API
src/components/TaskList.tsx - Display tasks
src/components/TaskForm.tsx - Create/edit tasks
src/pages/Tasks.tsx - Tasks page

Example - useTasks.ts:
import { useQuery } from '@tanstack/react-query';
import { TasksService, Task } from '@/api/generated';

export function useTasks(filters: { status?: string }) {
  return useQuery({
    queryKey: ['tasks', filters],
    queryFn: () => TasksService.listTasks(filters)
  });
}

Example - TaskList.tsx:
import { Task } from '@/api/generated';

interface Props {
  tasks: Task[];  // Type from generated client
}

Benefits:
- Compile-time type safety
- Auto-completion for all API calls
- Impossible to call non-existent endpoints
- Schema changes break compilation (good!)`
)
```

---

## Enforcement and Validation

### CI/CD Pipeline

```yaml
# .github/workflows/api-compliance.yml
name: API Compliance

on: [push, pull_request]

jobs:
  validate-spec:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3

      - name: Validate OpenAPI Spec
        run: |
          pip install openapi-spec-validator
          openapi-spec-validator docs/api/openapi.yaml

  backend-compliance:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3

      - name: Check Backend Matches Spec
        run: |
          # Start backend
          python backend/main.py &
          sleep 5

          # Download spec from /docs endpoint
          curl http://localhost:8000/docs/openapi.json > actual-spec.json

          # Compare with source spec
          diff <(jq -S . docs/api/openapi.yaml) <(jq -S . actual-spec.json)

  frontend-compliance:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3

      - name: Verify No Manual API Calls
        run: |
          # Ensure no fetch/axios outside generated client
          ! grep -r "fetch\|axios" src/ --exclude-dir=api/generated

      - name: Verify Client Is Up-to-Date
        run: |
          npm run generate-api
          git diff --exit-code src/api/generated/
```

---

## Benefits

✅ **Single Source of Truth**: OpenAPI spec defines the contract
✅ **No Endpoint Mismatches**: Frontend uses only what backend implements
✅ **Type Safety**: TypeScript compilation catches API errors
✅ **Automatic Validation**: Both sides validate against spec
✅ **Self-Documenting**: OpenAPI spec serves as live documentation
✅ **Version Control**: API changes tracked in git
✅ **CI/CD Enforcement**: Pipelines prevent deviations

---

## Summary

**Workflow Order:**
1. Design OpenAPI spec (TASK-001)
2. Implement backend from spec (TASK-004)
3. Generate frontend client from spec (TASK-005)
4. Build UI using generated client (TASK-006)

**Key Principle:**
The OpenAPI spec is created FIRST and is the contract. Backend implements it exactly. Frontend generates from it automatically. No manual endpoint definitions allowed.

This ensures perfect frontend/backend alignment with compile-time safety.
