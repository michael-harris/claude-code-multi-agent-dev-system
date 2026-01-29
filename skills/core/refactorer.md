# Refactorer Skill

**Skill ID:** `core:refactorer`
**Category:** Core
**Model:** `sonnet`

## Purpose

Code restructuring and improvement without changing functionality. Focuses on improving readability, maintainability, and reducing technical debt.

## Capabilities

### 1. Code Smell Detection
- Long methods/functions
- Duplicate code
- Complex conditionals
- God classes/objects
- Feature envy

### 2. Refactoring Patterns
- Extract Method/Function
- Extract Class/Module
- Inline unnecessary abstractions
- Rename for clarity
- Move to appropriate location

### 3. Structural Improvements
- Reduce nesting depth
- Simplify conditionals
- Apply DRY principle
- Improve encapsulation
- Separate concerns

### 4. Safe Refactoring
- Ensure tests pass before/after
- Small incremental changes
- Preserve public interfaces
- Document breaking changes

## Activation Triggers

```yaml
triggers:
  keywords:
    - refactor
    - clean up
    - simplify
    - restructure
    - improve
    - extract
    - inline

  task_types:
    - refactoring
    - cleanup
    - code_improvement
```

## Process

### Step 1: Analyze Current State

```javascript
const analysis = {
    complexity: measureCyclomaticComplexity(code),
    duplication: findDuplicateCode(code),
    codeSmells: detectSmells(code),
    dependencies: analyzeDependencies(code),
    testCoverage: getTestCoverage(code)
}
```

### Step 2: Identify Opportunities

```yaml
refactoring_candidates:
  - location: "src/services/UserService.ts:45-120"
    smell: "Long method"
    suggestion: "Extract validateUser, normalizeData, saveUser"
    priority: high

  - location: "src/utils/helpers.ts, src/lib/common.ts"
    smell: "Duplicate code"
    suggestion: "Consolidate into shared utility"
    priority: medium
```

### Step 3: Plan Refactoring

```yaml
refactoring_plan:
  order:
    - Extract pure functions first (easier to test)
    - Then extract classes/modules
    - Finally, structural changes

  constraints:
    - Keep public API unchanged
    - Run tests after each change
    - Commit after each successful refactor
```

### Step 4: Execute Incrementally

```javascript
for (const refactor of refactoringPlan) {
    // Make change
    await applyRefactoring(refactor)

    // Verify tests pass
    const result = await runTests()
    if (!result.passed) {
        await revert(refactor)
        log(`Refactoring ${refactor.name} broke tests`)
        continue
    }

    // Commit
    await commit(`refactor: ${refactor.description}`)
}
```

## Refactoring Techniques

### Extract Method
```javascript
// Before
function processOrder(order) {
    // validate (20 lines)
    // calculate totals (15 lines)
    // apply discounts (10 lines)
    // save (5 lines)
}

// After
function processOrder(order) {
    validate(order)
    const totals = calculateTotals(order)
    const finalTotal = applyDiscounts(totals, order.discounts)
    save(order, finalTotal)
}
```

### Replace Conditional with Polymorphism
```javascript
// Before
function getPrice(item) {
    switch(item.type) {
        case 'book': return item.price * 0.9
        case 'electronics': return item.price * 1.1
        case 'food': return item.price
    }
}

// After
class Book { getPrice() { return this.basePrice * 0.9 } }
class Electronics { getPrice() { return this.basePrice * 1.1 } }
class Food { getPrice() { return this.basePrice } }
```

## Output Format

```yaml
refactoring_report:
  summary:
    files_modified: 3
    functions_refactored: 8
    complexity_before: 45
    complexity_after: 28
    duplication_removed: "35 lines"

  changes:
    - file: "src/services/UserService.ts"
      refactorings:
        - "Extracted validateUser()"
        - "Extracted normalizeData()"
      complexity_change: "-12"

  tests:
    passed_before: 45
    passed_after: 45
    new_tests_added: 2
```

## See Also

- `agents/quality/refactoring-agent.md` - Full refactoring agent
- `skills/quality/performance-optimizer.md` - Performance-focused refactoring
