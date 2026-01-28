# Performance Optimizer Skill

Analyzes and optimizes code, queries, and systems for maximum performance.

## Activation

This skill activates when:
- Performance issues reported
- Slow response times detected
- Resource usage is high
- User requests optimization

## Analysis Areas

### 1. Code Performance

#### Algorithmic Complexity
- Identify O(n²) or worse algorithms
- Suggest more efficient alternatives
- Optimize loops and iterations

```python
# Before: O(n²)
def find_duplicates(items):
    duplicates = []
    for i in range(len(items)):
        for j in range(i + 1, len(items)):
            if items[i] == items[j]:
                duplicates.append(items[i])
    return duplicates

# After: O(n)
def find_duplicates(items):
    seen = set()
    duplicates = set()
    for item in items:
        if item in seen:
            duplicates.add(item)
        seen.add(item)
    return list(duplicates)
```

#### Memory Optimization
- Identify memory leaks
- Reduce unnecessary allocations
- Use appropriate data structures

### 2. Database Performance

#### Query Optimization
- Identify slow queries
- Add missing indexes
- Optimize JOINs
- Implement pagination

```sql
-- Before: Full table scan
SELECT * FROM orders WHERE customer_name LIKE '%Smith%';

-- After: Use indexed column with proper filter
CREATE INDEX idx_orders_customer_id ON orders(customer_id);
SELECT o.* FROM orders o
JOIN customers c ON o.customer_id = c.id
WHERE c.last_name = 'Smith';
```

#### N+1 Query Prevention

```python
# Before: N+1 queries
users = User.objects.all()
for user in users:
    print(user.profile.bio)  # Additional query per user

# After: Eager loading
users = User.objects.select_related('profile').all()
for user in users:
    print(user.profile.bio)  # No additional queries
```

### 3. Frontend Performance

#### Bundle Size
- Code splitting
- Tree shaking
- Lazy loading
- Dynamic imports

```javascript
// Before: Large initial bundle
import { Chart, Table, Form, Modal } from 'heavy-library';

// After: Dynamic imports
const Chart = lazy(() => import('./Chart'));
const Table = lazy(() => import('./Table'));
```

#### Rendering Performance
- Virtual scrolling for lists
- Memoization
- Debouncing/throttling
- Image optimization

```javascript
// Before: Re-renders on every change
function UserList({ users }) {
  return users.map(user => <UserCard user={user} />);
}

// After: Memoized components
const UserCard = memo(function UserCard({ user }) {
  return <div>{user.name}</div>;
});

function UserList({ users }) {
  return users.map(user => <UserCard key={user.id} user={user} />);
}
```

### 4. API Performance

#### Response Time
- Implement caching
- Compress responses
- Optimize serialization
- Connection pooling

```python
from functools import lru_cache
from redis import Redis

redis = Redis()

@lru_cache(maxsize=1000)
def get_user_cached(user_id: int):
    """In-memory cache for frequently accessed users."""
    return db.query(User).filter(User.id == user_id).first()

def get_user_redis(user_id: int):
    """Redis cache for distributed caching."""
    cache_key = f"user:{user_id}"
    cached = redis.get(cache_key)
    if cached:
        return json.loads(cached)

    user = db.query(User).filter(User.id == user_id).first()
    redis.setex(cache_key, 300, json.dumps(user.dict()))
    return user
```

### 5. Infrastructure Performance

#### Horizontal Scaling
- Load balancing
- Database replication
- CDN configuration
- Container optimization

#### Resource Utilization
- CPU profiling
- Memory profiling
- I/O optimization
- Network optimization

## Profiling Tools

### Python
```bash
# CPU profiling
python -m cProfile -o profile.stats app.py
snakeviz profile.stats

# Memory profiling
python -m memory_profiler app.py

# Line profiling
kernprof -l -v app.py
```

### Node.js
```bash
# CPU profiling
node --prof app.js
node --prof-process isolate-*.log > profile.txt

# Memory profiling
node --inspect app.js
# Use Chrome DevTools Memory tab
```

### Go
```go
import "runtime/pprof"

// CPU profiling
f, _ := os.Create("cpu.prof")
pprof.StartCPUProfile(f)
defer pprof.StopCPUProfile()

// Memory profiling
f, _ := os.Create("mem.prof")
pprof.WriteHeapProfile(f)
```

## Optimization Report

```markdown
## Performance Optimization Report

### Summary
- **Overall Improvement:** 47% faster response time
- **Memory Reduction:** 32%
- **Database Queries Reduced:** 85%

### Critical Issues Fixed

1. **N+1 Query in User List**
   - Before: 101 queries for 100 users
   - After: 1 query with eager loading
   - Improvement: 99% reduction

2. **Unindexed Query**
   - Before: 2.3s average
   - After: 12ms with index
   - Improvement: 99.5% faster

3. **Memory Leak in Event Handler**
   - Before: Memory grew 50MB/hour
   - After: Stable memory usage
   - Fix: Added cleanup on unmount

### Recommendations

| Priority | Issue | Impact | Effort |
|----------|-------|--------|--------|
| High | Add Redis caching | 60% faster | Medium |
| Medium | Implement CDN | 40% faster | Low |
| Low | Code splitting | 30% smaller bundle | High |

### Metrics After Optimization

| Metric | Before | After | Change |
|--------|--------|-------|--------|
| Page Load | 3.2s | 1.7s | -47% |
| API Response | 450ms | 89ms | -80% |
| Memory Usage | 512MB | 348MB | -32% |
| DB Queries/req | 45 | 7 | -84% |
```

## Quality Checks

- [ ] No premature optimization
- [ ] Benchmarks before/after
- [ ] No functionality regression
- [ ] Load testing performed
- [ ] Monitoring configured
