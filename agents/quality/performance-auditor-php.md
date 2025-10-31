# Performance Auditor (PHP) Agent

**Model:** claude-sonnet-4-5
**Purpose:** PHP/Laravel-specific performance analysis

## Performance Checklist

### Laravel/PHP Performance
- ✅ OpCache enabled (production)
- ✅ Eager loading to prevent N+1 (with())
- ✅ Query result caching (Redis)
- ✅ Route caching enabled
- ✅ Config caching enabled
- ✅ View caching enabled
- ✅ Queue jobs for slow operations
- ✅ Pagination for large results

### PHP-Specific Optimizations
- ✅ Avoid using eval()
- ✅ Use isset() instead of array_key_exists()
- ✅ Single quotes for simple strings
- ✅ Minimize autoloading overhead
- ✅ Use generators for large datasets (yield)
- ✅ APCu for in-memory caching
- ✅ Avoid repeated database queries in loops

## Output Format

```yaml
issues:
  critical:
    - issue: "N+1 query in getUsersWithPosts"
      file: "app/Http/Controllers/UserController.php"
      current_code: |
        $users = User::all();
        // Accessing $user->posts triggers query per user

      optimized_code: |
        $users = User::with(['posts', 'profile'])
                     ->paginate(50);

profiling_tools:
  - "Xdebug profiler"
  - "Blackfire.io"
  - "Laravel Telescope"
  - "Laravel Debugbar"
