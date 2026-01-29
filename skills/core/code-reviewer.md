# Code Reviewer Skill

A comprehensive code review skill that analyzes code for quality, security, performance, and best practices.

## Activation

This skill activates when:
- User asks for code review
- PR/commit is submitted for review
- `/devteam:review` command is used

## Review Checklist

### 1. Code Quality
- [ ] Follows project style guide
- [ ] Meaningful variable/function names
- [ ] Appropriate comments (not excessive)
- [ ] DRY principle followed
- [ ] Single Responsibility Principle
- [ ] Appropriate abstraction level

### 2. Logic & Correctness
- [ ] Business logic is correct
- [ ] Edge cases handled
- [ ] Error handling appropriate
- [ ] No off-by-one errors
- [ ] Null/undefined checks
- [ ] Type safety maintained

### 3. Security
- [ ] No hardcoded secrets
- [ ] Input validation present
- [ ] SQL injection prevented
- [ ] XSS prevention
- [ ] CSRF protection
- [ ] Proper authentication/authorization

### 4. Performance
- [ ] No N+1 queries
- [ ] Appropriate caching
- [ ] No memory leaks
- [ ] Efficient algorithms
- [ ] Lazy loading where appropriate
- [ ] Pagination for large datasets

### 5. Testing
- [ ] Unit tests exist
- [ ] Tests are meaningful
- [ ] Edge cases tested
- [ ] Mocks used appropriately
- [ ] Coverage adequate

### 6. Documentation
- [ ] Public APIs documented
- [ ] Complex logic explained
- [ ] README updated if needed
- [ ] Changelog entry added

## Review Output Format

```markdown
## Code Review Summary

**Files Reviewed:** 5
**Issues Found:** 3 (1 critical, 2 minor)

### Critical Issues

#### 1. SQL Injection Vulnerability
**File:** `src/routes/users.py:45`
**Severity:** Critical
**Issue:** Raw SQL query with user input
```python
# Current (vulnerable)
query = f"SELECT * FROM users WHERE id = {user_id}"

# Recommended
query = "SELECT * FROM users WHERE id = %s"
cursor.execute(query, (user_id,))
```

### Minor Issues

#### 2. Missing Error Handling
**File:** `src/services/api.ts:78`
**Severity:** Minor
**Issue:** API call without error handling
```typescript
// Add try/catch and handle errors appropriately
```

### Suggestions

- Consider extracting the validation logic to a separate function
- The function `processData` could benefit from better naming

### Approved: ⏳ Pending fixes

Please address the critical issues before merging.
```

## Language-Specific Checks

### Python
- PEP 8 compliance
- Type hints present
- Docstrings for public functions
- No bare except clauses
- Context managers for resources

### TypeScript/JavaScript
- Strict mode enabled
- Proper async/await usage
- No any types (unless justified)
- Proper error boundaries
- React hooks rules followed

### Go
- Error handling (no ignored errors)
- Proper goroutine cleanup
- Context propagation
- Interface usage
- Effective Go patterns

### Rust
- No unwrap() in production code
- Proper error propagation
- Lifetime annotations
- Clippy compliance
- Safe abstractions
