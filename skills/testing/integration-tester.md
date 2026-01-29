# Integration Tester Skill

**Skill ID:** `testing:integration-tester`
**Category:** Testing
**Model:** `sonnet`

## Purpose

Create and maintain integration tests that verify components work together correctly. Focuses on API contracts, database interactions, and service integrations.

## Capabilities

### 1. API Integration Tests
- Request/response validation
- Authentication flows
- Error handling scenarios
- Rate limiting behavior

### 2. Database Integration
- CRUD operations
- Transaction handling
- Migration testing
- Data integrity checks

### 3. Service Integration
- External API mocking
- Message queue testing
- Cache behavior
- Service discovery

### 4. Contract Testing
- API contract validation
- Schema compatibility
- Version compatibility
- Breaking change detection

## Activation Triggers

```yaml
triggers:
  keywords:
    - integration test
    - api test
    - database test
    - service test
    - contract test
    - e2e

  task_types:
    - integration_testing
    - api_testing
    - contract_testing
```

## Process

### Step 1: Identify Integration Points

```javascript
const integrationPoints = {
    apis: findAPIEndpoints(),
    databases: findDatabaseConnections(),
    externalServices: findExternalCalls(),
    messageQueues: findQueueConnections()
}
```

### Step 2: Design Test Scenarios

```yaml
test_scenarios:
  happy_path:
    - Create user → Get user → Update user → Delete user
    - Login → Access protected resource → Logout

  error_handling:
    - Invalid input → 400 response
    - Unauthorized → 401 response
    - Not found → 404 response
    - Server error → 500 response with proper logging

  edge_cases:
    - Concurrent requests
    - Large payloads
    - Network timeouts
    - Database connection loss
```

### Step 3: Create Test Fixtures

```javascript
// Test database setup
beforeAll(async () => {
    await testDb.migrate()
    await testDb.seed('integration-test-data')
})

afterAll(async () => {
    await testDb.cleanup()
})

// Per-test isolation
beforeEach(async () => {
    await testDb.beginTransaction()
})

afterEach(async () => {
    await testDb.rollback()
})
```

### Step 4: Write Integration Tests

```javascript
describe('User API Integration', () => {
    it('should create and retrieve user', async () => {
        // Create
        const createResponse = await api.post('/users', {
            name: 'Test User',
            email: 'test@example.com'
        })
        expect(createResponse.status).toBe(201)

        // Retrieve
        const getResponse = await api.get(`/users/${createResponse.data.id}`)
        expect(getResponse.status).toBe(200)
        expect(getResponse.data.name).toBe('Test User')
    })

    it('should handle database transaction rollback', async () => {
        // Start operation that will fail midway
        await expect(api.post('/orders', invalidOrder))
            .rejects.toMatchObject({ status: 400 })

        // Verify no partial data was saved
        const orders = await db.query('SELECT * FROM orders')
        expect(orders).toHaveLength(0)
    })
})
```

## Test Patterns

### API Contract Test
```javascript
describe('API Contract', () => {
    it('should match OpenAPI spec', async () => {
        const response = await api.get('/users/1')
        expect(response).toMatchSchema(openApiSpec.paths['/users/{id}'].get)
    })
})
```

### Database Integration Test
```javascript
describe('Repository Integration', () => {
    it('should persist and retrieve entity', async () => {
        const user = new User({ name: 'Test' })
        await userRepository.save(user)

        const retrieved = await userRepository.findById(user.id)
        expect(retrieved).toEqual(user)
    })
})
```

### External Service Mock
```javascript
describe('Payment Service', () => {
    beforeEach(() => {
        nock('https://api.stripe.com')
            .post('/charges')
            .reply(200, { id: 'ch_123', status: 'succeeded' })
    })

    it('should process payment', async () => {
        const result = await paymentService.charge(100, 'tok_visa')
        expect(result.status).toBe('succeeded')
    })
})
```

## Output Format

```yaml
integration_test_report:
  summary:
    tests_created: 15
    integration_points_covered: 8
    scenarios_tested: 24

  coverage:
    api_endpoints: "95% (19/20)"
    database_operations: "100% (12/12)"
    external_services: "80% (4/5)"

  files_created:
    - tests/integration/user.integration.test.ts
    - tests/integration/order.integration.test.ts
    - tests/fixtures/integration-data.ts
```

## See Also

- `skills/testing/e2e-tester.md` - End-to-end testing
- `skills/testing/test-generator.md` - Unit test generation
- `agents/quality/test-writer.md` - Comprehensive test writing
