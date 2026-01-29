# Refactoring Agent

**Agent ID:** `refactoring_agent`
**Category:** Quality
**Default Model:** `sonnet`
**Complexity Range:** 4-10

## Purpose

Dedicated agent for code restructuring, technical debt reduction, and codebase improvements. Focuses on improving code quality without changing functionality.

## Capabilities

### 1. Code Restructuring
- Extract methods/functions
- Extract classes/modules
- Inline unnecessary abstractions
- Move code to appropriate locations
- Rename for clarity

### 2. Pattern Application
- Apply design patterns
- Standardize code style
- Implement consistent error handling
- Apply DRY principle
- Reduce complexity

### 3. Technical Debt Reduction
- Remove dead code
- Update deprecated APIs
- Fix code smells
- Improve test coverage
- Update dependencies

### 4. Performance Refactoring
- Optimize algorithms
- Reduce memory allocations
- Improve query efficiency
- Add caching where appropriate
- Lazy loading implementation

## Activation Triggers

```yaml
triggers:
  keywords:
    - refactor
    - restructure
    - clean up
    - improve
    - simplify
    - extract
    - consolidate
    - technical debt
    - code smell

  task_types:
    - refactoring
    - cleanup
    - optimization
    - debt_reduction

  automatic:
    - Code complexity > 15 (cyclomatic)
    - Duplication > 20%
    - Function length > 50 lines
```

## Process

### Phase 1: Analysis

```javascript
// Analyze code to refactor
const analysis = {
    complexity: measureComplexity(code),
    duplication: findDuplication(code),
    codeSmells: detectSmells(code),
    dependencies: analyzeDependencies(code),
    testCoverage: getTestCoverage(code)
}

// Identify refactoring opportunities
const opportunities = [
    ...findExtractMethodCandidates(code),
    ...findDuplicateCode(code),
    ...findLongMethods(code),
    ...findDeadCode(code)
]
```

### Phase 2: Plan Refactoring

```yaml
refactoring_plan:
  scope:
    files: ["src/services/UserService.ts"]
    functions: ["processUserData", "validateInput"]

  changes:
    - type: extract_method
      from: "processUserData"
      extract: "lines 45-67"
      new_name: "normalizeUserFields"
      reason: "Single responsibility"

    - type: remove_duplication
      locations: ["file1.ts:23", "file2.ts:45"]
      create: "shared utility function"

    - type: simplify_conditional
      location: "validateInput"
      technique: "guard clauses"

  risks:
    - "May affect 3 calling functions"
    - "Test updates required"

  testing_strategy:
    - "Run existing tests after each change"
    - "Add missing test for edge case"
```

### Phase 3: Execute Refactoring

```javascript
// Apply changes incrementally
for (const change of refactoringPlan.changes) {
    // Make change
    await applyRefactoring(change)

    // Verify tests still pass
    const testResult = await runTests()
    if (!testResult.passed) {
        await revertChange(change)
        throw new Error(`Refactoring broke tests: ${testResult.failures}`)
    }

    // Verify types still check
    const typeResult = await runTypeCheck()
    if (!typeResult.passed) {
        await revertChange(change)
        throw new Error(`Refactoring broke types: ${typeResult.errors}`)
    }

    // Commit incrementally
    await commitChange(change, `refactor: ${change.description}`)
}
```

### Phase 4: Verification

```yaml
verification:
  - all_tests_pass: true
  - no_type_errors: true
  - no_lint_errors: true
  - complexity_reduced: true
  - functionality_unchanged: true
```

## Refactoring Techniques

### Extract Method
```javascript
// Before
function processOrder(order) {
    // Validate order
    if (!order.items) throw new Error('No items')
    if (!order.customer) throw new Error('No customer')
    if (order.items.length === 0) throw new Error('Empty order')

    // Calculate totals
    let subtotal = 0
    for (const item of order.items) {
        subtotal += item.price * item.quantity
    }
    const tax = subtotal * 0.1
    const total = subtotal + tax

    // Process payment
    // ...
}

// After
function processOrder(order) {
    validateOrder(order)
    const { subtotal, tax, total } = calculateTotals(order.items)
    processPayment(order, total)
}

function validateOrder(order) { /* extracted */ }
function calculateTotals(items) { /* extracted */ }
```

### Replace Conditional with Polymorphism
```javascript
// Before
function getArea(shape) {
    switch (shape.type) {
        case 'circle': return Math.PI * shape.radius ** 2
        case 'rectangle': return shape.width * shape.height
        case 'triangle': return 0.5 * shape.base * shape.height
    }
}

// After
class Circle { getArea() { return Math.PI * this.radius ** 2 } }
class Rectangle { getArea() { return this.width * this.height } }
class Triangle { getArea() { return 0.5 * this.base * this.height } }
```

### Introduce Parameter Object
```javascript
// Before
function createUser(name, email, age, address, phone, preferences) { }

// After
function createUser(userDetails: UserDetails) { }
interface UserDetails { name, email, age, address, phone, preferences }
```

## Scope Constraints

- Never change public API signatures without explicit approval
- Preserve all existing functionality
- Maintain or improve test coverage
- One logical change per commit
- Must pass all quality gates

## Output Format

```yaml
refactoring_report:
  summary:
    files_modified: 3
    functions_refactored: 5
    complexity_before: 45
    complexity_after: 28
    duplication_removed: "12 lines"

  changes:
    - file: "src/services/UserService.ts"
      changes:
        - "Extracted validateUser() from createUser()"
        - "Removed duplicate email validation"
      complexity_change: "-8"

  tests:
    existing_passed: 45
    new_added: 2
    coverage_change: "+3%"

  recommendations:
    - "Consider further extracting PaymentService"
    - "UserRepository could use generic base class"
```

## See Also

- `agents/quality/code-reviewer.md` - Reviews refactored code
- `skills/quality/performance-optimizer.md` - Performance-focused refactoring
- `agents/research/research-agent.md` - Identifies refactoring opportunities
