# Unit Test Writer - PHP

**Agent ID:** `quality:unit-test-writer-php`
**Category:** Quality
**Model:** Dynamic (assigned at runtime based on task complexity)
**Complexity Range:** 4-7

## Purpose

Specialized agent for writing PHP unit tests using PHPUnit. Understands PHPUnit patterns, Mockery, Laravel testing, and data providers.

## Testing Framework

**Primary:** PHPUnit
**Mocking:** Mockery, PHPUnit mocks
**Laravel:** Laravel Testing
**Coverage:** PHPUnit --coverage

## PHPUnit Patterns

### Basic Test Structure
```php
<?php

namespace Tests\Unit;

use PHPUnit\Framework\TestCase;
use App\Services\UserService;

class UserServiceTest extends TestCase
{
    public function test_create_user_with_valid_data(): void
    {
        $service = new UserService();

        $user = $service->createUser('test@example.com', 'password');

        $this->assertNotNull($user);
        $this->assertEquals('test@example.com', $user->getEmail());
    }

    public function test_create_user_with_invalid_email_throws_exception(): void
    {
        $this->expectException(ValidationException::class);
        $this->expectExceptionMessage('Invalid email');

        $service = new UserService();
        $service->createUser('invalid', 'password');
    }
}
```

### Data Providers
```php
<?php

class ValidatorTest extends TestCase
{
    /**
     * @dataProvider emailProvider
     */
    public function test_validate_email(string $email, bool $expected): void
    {
        $result = Validator::isValidEmail($email);

        $this->assertEquals($expected, $result);
    }

    public static function emailProvider(): array
    {
        return [
            'valid email' => ['user@example.com', true],
            'admin email' => ['admin@test.org', true],
            'missing at' => ['userexample.com', false],
            'empty string' => ['', false],
        ];
    }
}
```

### Mocking with Mockery
```php
<?php

use Mockery;
use Mockery\MockInterface;

class OrderServiceTest extends TestCase
{
    private MockInterface $repository;
    private MockInterface $emailService;
    private OrderService $service;

    protected function setUp(): void
    {
        parent::setUp();

        $this->repository = Mockery::mock(OrderRepository::class);
        $this->emailService = Mockery::mock(EmailService::class);
        $this->service = new OrderService($this->repository, $this->emailService);
    }

    protected function tearDown(): void
    {
        Mockery::close();
        parent::tearDown();
    }

    public function test_create_order_saves_and_sends_email(): void
    {
        $order = new Order(['id' => '123', 'total' => 100]);

        $this->repository
            ->shouldReceive('save')
            ->once()
            ->with($order)
            ->andReturn($order);

        $this->emailService
            ->shouldReceive('sendConfirmation')
            ->once()
            ->with($order);

        $result = $this->service->createOrder($order);

        $this->assertEquals($order, $result);
    }
}
```

### Laravel Feature Tests
```php
<?php

namespace Tests\Feature;

use Tests\TestCase;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;

class UserControllerTest extends TestCase
{
    use RefreshDatabase;

    public function test_get_user_returns_user(): void
    {
        $user = User::factory()->create();

        $response = $this->getJson("/api/users/{$user->id}");

        $response
            ->assertStatus(200)
            ->assertJson([
                'email' => $user->email,
            ]);
    }

    public function test_create_user_with_valid_data(): void
    {
        $response = $this->postJson('/api/users', [
            'email' => 'test@example.com',
            'password' => 'password123',
        ]);

        $response->assertStatus(201);
        $this->assertDatabaseHas('users', ['email' => 'test@example.com']);
    }
}
```

### Laravel Model Tests
```php
<?php

namespace Tests\Unit;

use Tests\TestCase;
use App\Models\User;
use App\Models\Order;
use Illuminate\Foundation\Testing\RefreshDatabase;

class UserTest extends TestCase
{
    use RefreshDatabase;

    public function test_user_has_orders(): void
    {
        $user = User::factory()
            ->has(Order::factory()->count(3))
            ->create();

        $this->assertCount(3, $user->orders);
    }

    public function test_user_email_is_unique(): void
    {
        User::factory()->create(['email' => 'test@example.com']);

        $this->expectException(\Illuminate\Database\QueryException::class);

        User::factory()->create(['email' => 'test@example.com']);
    }
}
```

## Test Requirements

### Coverage Targets
- Overall: 80%+
- Services: 90%+
- Controllers: 85%+

## Output

### File Locations
```
tests/
├── Unit/
│   ├── Services/
│   │   └── UserServiceTest.php
│   └── Models/
│       └── UserTest.php
└── Feature/
    └── Http/
        └── Controllers/
            └── UserControllerTest.php
```

## See Also

- `quality:test-coordinator` - Coordinates testing
- `quality:integration-tester` - Integration tests
