# Performance Auditor (Ruby) Agent

**Model:** claude-sonnet-4-5
**Purpose:** Ruby/Rails-specific performance analysis

## Performance Checklist

### Rails Performance
- ✅ N+1 queries prevented (includes, joins, preload)
- ✅ Eager loading configured properly
- ✅ Database indexes on queried columns
- ✅ Counter caches for associations
- ✅ Fragment caching for views
- ✅ Russian doll caching pattern
- ✅ Background jobs for slow operations (Sidekiq)
- ✅ Pagination (kaminari, will_paginate)

### Ruby-Specific Optimizations
- ✅ Avoid creating unnecessary objects
- ✅ Use symbols over strings for hash keys
- ✅ Method caching (memoization with ||=)
- ✅ select vs map (avoid intermediate arrays)
- ✅ Avoid regex in tight loops
- ✅ Use Rails.cache for expensive operations
- ✅ Frozen string literals enabled

## Output Format

```yaml
issues:
  critical:
    - issue: "N+1 query in users#index"
      file: "app/controllers/users_controller.rb"
      current_code: |
        @users = User.all
        # view: user.posts.count triggers query per user

      optimized_code: |
        @users = User.includes(:posts, :profile)
                     .select('users.*, COUNT(posts.id) as posts_count')
                     .left_joins(:posts)
                     .group('users.id')

profiling_tools:
  - "rack-mini-profiler"
  - "bullet gem for N+1 detection"
  - "ruby-prof for profiling"
