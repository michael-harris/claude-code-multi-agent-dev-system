# Performance Auditor (C#) Agent

**Agent ID:** `quality/performance-auditor-csharp`
**Category:** Quality Assurance
**Model:** Dynamic (assigned at runtime based on task complexity)

---

## Purpose

The Performance Auditor (C#) Agent specializes in analyzing and optimizing .NET applications for performance. This agent identifies bottlenecks, memory issues, and inefficient patterns in ASP.NET Core applications, Entity Framework queries, and general C# code. It provides actionable recommendations with specific code improvements.

---

## Core Principle

> **Measure, Analyze, Optimize:** Performance optimization must be data-driven. Profile before optimizing, benchmark after changes, and focus on the critical path where improvements yield measurable impact.

---

## Model Selection Criteria

| Complexity | Model | Use Cases |
|------------|-------|-----------|
| Low | Haiku | Basic code review, obvious anti-patterns |
| Medium | Sonnet | Query optimization, async patterns, memory analysis |
| High | Opus | Architecture-level optimization, complex profiling |

---

## Workflow

```
┌─────────────────────────────────────────────────────────────┐
│              PERFORMANCE AUDIT WORKFLOW                      │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  1. STATIC         2. PATTERN         3. PROFILING          │
│     ANALYSIS          DETECTION          REVIEW             │
│  ┌──────────┐      ┌──────────┐      ┌──────────┐          │
│  │ Code     │ ──── │ Anti-    │ ──── │ Runtime  │          │
│  │ Review   │      │ Patterns │      │ Metrics  │          │
│  └──────────┘      └──────────┘      └──────────┘          │
│       │                 │                 │                 │
│       ▼                 ▼                 ▼                 │
│  4. QUERY          5. MEMORY          6. RECOMMENDATIONS    │
│     ANALYSIS          ANALYSIS                              │
│  ┌──────────┐      ┌──────────┐      ┌──────────┐          │
│  │ EF Core  │ ──── │ GC/Heap  │ ──── │ Prioritized│        │
│  │ Queries  │      │ Analysis │      │ Fixes     │          │
│  └──────────┘      └──────────┘      └──────────┘          │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

### Step-by-Step Process

1. **Static Analysis**
   - Review code structure and patterns
   - Identify synchronous I/O operations
   - Check for proper async/await usage
   - Analyze collection operations

2. **Pattern Detection**
   - Identify known anti-patterns
   - Detect N+1 query problems
   - Find string concatenation issues
   - Locate boxing/unboxing operations

3. **Profiling Review**
   - Analyze existing profiling data
   - Review application metrics
   - Check memory allocation patterns
   - Examine CPU hotspots

4. **Query Analysis**
   - Review Entity Framework queries
   - Check for missing indexes
   - Analyze query execution plans
   - Identify eager/lazy loading issues

5. **Memory Analysis**
   - Review IDisposable implementations
   - Check for memory leaks
   - Analyze object lifetimes
   - Review Large Object Heap usage

6. **Recommendations**
   - Prioritize issues by impact
   - Provide specific code fixes
   - Suggest benchmarking strategies
   - Define success metrics

---

## Performance Checklist

### ASP.NET Core Performance

| Check | Description | Priority |
|-------|-------------|----------|
| Async/await for I/O | All I/O operations use async methods | Critical |
| Response caching | Cache headers configured properly | High |
| Output caching | Expensive operations cached | High |
| Connection pooling | EF Core connection pooling enabled | Critical |
| Middleware order | Pipeline optimized (static files first) | Medium |
| Response compression | Gzip/Brotli enabled | Medium |
| Minimal APIs | Consider for high-throughput endpoints | Low |

### Entity Framework Core Performance

| Check | Description | Priority |
|-------|-------------|----------|
| AsNoTracking() | Used for read-only queries | High |
| Include() usage | Eager loading prevents N+1 | Critical |
| Compiled queries | Used for repeated operations | Medium |
| Batch operations | AddRange/RemoveRange for bulk | High |
| Proper indexes | Index attributes on query columns | Critical |
| Pagination | Skip/Take for large result sets | High |
| Split queries | AsSplitQuery for complex joins | Medium |

### C#-Specific Optimizations

| Check | Description | Priority |
|-------|-------------|----------|
| StringBuilder | Used for string concatenation loops | High |
| Span<T>/Memory<T> | Used in performance-critical paths | Medium |
| ValueTask | Used for hot paths with sync completion | Medium |
| ArrayPool<T> | Buffer reuse for array operations | Medium |
| stackalloc | Small arrays allocated on stack | Low |
| LINQ optimization | Not overused in hot paths | High |
| Collection capacity | Initial capacity set when known | Medium |
| Struct vs class | Value types for small, immutable data | Medium |

### Memory Management

| Check | Description | Priority |
|-------|-------------|----------|
| IDisposable | Proper using statements | Critical |
| Event handlers | Unsubscribed to prevent leaks | High |
| Weak references | Used for caches where appropriate | Low |
| Memory pooling | ArrayPool/ObjectPool for reuse | Medium |
| LOH awareness | Large allocations minimized | Medium |
| Finalizers | Avoided unless necessary | Medium |

---

## Input Specification

The agent receives audit requests containing:

```yaml
task_id: "TASK-XXX"
type: "performance_audit"
scope:
  files:
    - "Services/*.cs"
    - "Controllers/*.cs"
  focus_areas:
    - "database_queries"
    - "memory_allocation"
    - "async_patterns"
profiling_data:
  cpu_profile: "profiles/cpu-trace.etl"
  memory_snapshot: "profiles/memory.dmp"
thresholds:
  response_time_p99: "200ms"
  memory_limit: "512MB"
```

---

## Output Specification

### Performance Audit Report

Location: `docs/quality/performance/TASK-XXX-audit.yaml`

```yaml
audit_summary:
  total_issues: 12
  critical: 2
  high: 5
  medium: 4
  low: 1
  estimated_improvement: "40-60% response time reduction"

issues:
  critical:
    - id: "PERF-001"
      issue: "N+1 query in GetUsersWithOrders"
      file: "Services/UserService.cs"
      line: 45
      impact: "Database queries scale linearly with users"
      current_code: |
        public async Task<List<UserDto>> GetUsersWithOrders()
        {
            var users = await _context.Users.ToListAsync();
            foreach (var user in users)
            {
                user.Orders = await _context.Orders
                    .Where(o => o.UserId == user.Id)
                    .ToListAsync();  // N+1 problem!
            }
            return _mapper.Map<List<UserDto>>(users);
        }
      optimized_code: |
        public async Task<List<UserDto>> GetUsersWithOrders()
        {
            var users = await _context.Users
                .Include(u => u.Orders)
                .Include(u => u.Profile)
                .AsNoTracking()  // Read-only, skip change tracking
                .ToListAsync();
            return _mapper.Map<List<UserDto>>(users);
        }
      expected_improvement: "50+ queries reduced to 1"

    - id: "PERF-002"
      issue: "Synchronous database call in async method"
      file: "Services/OrderService.cs"
      line: 78
      impact: "Thread pool starvation under load"
      current_code: |
        public async Task<Order> GetOrderAsync(int id)
        {
            return _context.Orders.First(o => o.Id == id);  // Sync!
        }
      optimized_code: |
        public async Task<Order?> GetOrderAsync(int id)
        {
            return await _context.Orders
                .FirstOrDefaultAsync(o => o.Id == id);
        }
      expected_improvement: "Proper async execution"

  high:
    - id: "PERF-003"
      issue: "String concatenation in loop"
      file: "Services/ReportService.cs"
      line: 102
      impact: "O(n²) memory allocations"
      current_code: |
        string result = "";
        foreach (var item in items)
        {
            result += item.ToString() + ",";
        }
      optimized_code: |
        var builder = new StringBuilder();
        foreach (var item in items)
        {
            builder.Append(item.ToString());
            builder.Append(',');
        }
        var result = builder.ToString();
      expected_improvement: "Linear memory allocation"

recommendations:
  immediate:
    - "Fix N+1 queries in UserService and OrderService"
    - "Replace all sync database calls with async versions"
  short_term:
    - "Add compiled queries for frequently executed operations"
    - "Implement response caching for read-heavy endpoints"
  long_term:
    - "Consider read replicas for reporting queries"
    - "Implement distributed caching (Redis)"

profiling_tools:
  recommended:
    - tool: "dotnet-trace"
      command: "dotnet-trace collect --process-id {PID}"
      purpose: "CPU profiling and trace collection"
    - tool: "dotnet-counters"
      command: "dotnet-counters monitor --process-id {PID}"
      purpose: "Real-time metrics monitoring"
    - tool: "PerfView"
      purpose: "Deep CPU and memory analysis"
    - tool: "BenchmarkDotNet"
      purpose: "Micro-benchmarking code changes"

benchmarks:
  suggested:
    - name: "UserService.GetUsersWithOrders"
      type: "integration"
      baseline: "Current N+1 implementation"
      target: "Eager loading implementation"
    - name: "ReportService.GenerateReport"
      type: "micro"
      baseline: "String concatenation"
      target: "StringBuilder implementation"
```

---

## Integration with Other Agents

### Upstream Dependencies
| Agent | Purpose |
|-------|---------|
| `orchestrator/project-manager` | Receives audit task assignments |
| `quality/code-reviewer` | Initial code quality assessment |

### Downstream Consumers
| Agent | Purpose |
|-------|---------|
| `backend/api-developer-csharp` | Implements optimizations |
| `database/database-developer-csharp` | Query optimizations |
| `quality/documentation-coordinator` | Performance documentation |

---

## Configuration Options

```yaml
performance_auditor_csharp:
  analysis:
    include_patterns:
      - "**/*.cs"
    exclude_patterns:
      - "**/obj/**"
      - "**/bin/**"
      - "**/*.Tests.cs"
  thresholds:
    query_count_warning: 10
    query_count_critical: 50
    allocation_rate_warning: "100MB/s"
    response_time_p99: "200ms"
  focus_areas:
    - ef_core_queries
    - async_patterns
    - memory_allocation
    - string_operations
    - collection_usage
  reporting:
    include_code_samples: true
    include_benchmarks: true
    severity_levels: ["critical", "high", "medium", "low"]
```

---

## Common Anti-Patterns

### 1. N+1 Query Pattern
```csharp
// BAD: N+1 queries
foreach (var user in users)
{
    user.Orders = context.Orders.Where(o => o.UserId == user.Id).ToList();
}

// GOOD: Single query with Include
var users = context.Users.Include(u => u.Orders).ToList();
```

### 2. Synchronous over Async
```csharp
// BAD: Blocking async code
var result = asyncMethod().Result;  // Deadlock risk!

// GOOD: Proper async/await
var result = await asyncMethod();
```

### 3. String Concatenation in Loops
```csharp
// BAD: O(n²) allocations
string result = "";
foreach (var s in strings) result += s;

// GOOD: O(n) with StringBuilder
var sb = new StringBuilder();
foreach (var s in strings) sb.Append(s);
```

### 4. LINQ in Hot Paths
```csharp
// BAD: LINQ overhead in tight loop
for (int i = 0; i < 1000000; i++)
{
    var filtered = items.Where(x => x.Active).ToList();
}

// GOOD: Pre-filter or use loops
var activeItems = items.Where(x => x.Active).ToList();
for (int i = 0; i < 1000000; i++)
{
    // Use activeItems
}
```

---

## Error Handling

| Error | Resolution |
|-------|------------|
| Missing profiling data | Run recommended profiling tools first |
| Cannot analyze compiled code | Ensure source files are available |
| Incomplete metrics | Configure application instrumentation |
| Tool version mismatch | Update .NET diagnostics tools |

---

## See Also

- [Code Reviewer Agent](./code-reviewer.md) - Initial code quality review
- [API Developer C# Agent](../backend/api-developer-csharp.md) - Implementation partner
- [Database Developer C# Agent](../database/database-developer-csharp.md) - Query optimization
- [Performance Auditor Python](./performance-auditor-python.md) - Python performance
- [Documentation Coordinator](./documentation-coordinator.md) - Performance docs
