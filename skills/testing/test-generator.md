# Test Generator Skill

Automatically generates comprehensive test suites for code.

## Activation

This skill activates when:
- New code is written without tests
- User requests test generation
- Coverage gaps are detected

## Test Types Generated

### Unit Tests
- Function-level testing
- Input/output validation
- Edge case coverage
- Error condition testing

### Integration Tests
- Component interaction testing
- API endpoint testing
- Database operation testing
- External service mocking

### E2E Tests
- User flow testing
- Cross-browser validation
- Mobile responsiveness
- Accessibility checks

## Generation Strategy

### 1. Analyze Code Structure

```python
def analyze_function(func):
    """Extract testable aspects from function."""
    return {
        'parameters': extract_params(func),
        'return_type': extract_return(func),
        'side_effects': detect_side_effects(func),
        'branches': count_branches(func),
        'dependencies': find_dependencies(func),
    }
```

### 2. Generate Test Cases

For each function, generate tests for:

| Category | Test Cases |
|----------|------------|
| Happy Path | Normal inputs, expected outputs |
| Edge Cases | Empty, null, boundary values |
| Error Cases | Invalid inputs, exception handling |
| Type Cases | Different types, coercion |

### 3. Test Templates

#### Python (pytest)

```python
import pytest
from unittest.mock import Mock, patch

class TestUserService:
    @pytest.fixture
    def user_service(self):
        return UserService(db=Mock())

    def test_get_user_returns_user_when_exists(self, user_service):
        # Arrange
        user_service.db.find_one.return_value = {'id': 1, 'name': 'Test'}

        # Act
        result = user_service.get_user(1)

        # Assert
        assert result['name'] == 'Test'

    def test_get_user_raises_when_not_found(self, user_service):
        # Arrange
        user_service.db.find_one.return_value = None

        # Act & Assert
        with pytest.raises(UserNotFoundError):
            user_service.get_user(999)

    @pytest.mark.parametrize('user_id,expected', [
        (1, True),
        (0, False),
        (-1, False),
        (None, False),
    ])
    def test_is_valid_user_id(self, user_id, expected):
        assert is_valid_user_id(user_id) == expected
```

#### TypeScript (Jest)

```typescript
import { UserService } from './user-service';

describe('UserService', () => {
  let service: UserService;
  let mockDb: jest.Mocked<Database>;

  beforeEach(() => {
    mockDb = {
      findOne: jest.fn(),
      insert: jest.fn(),
    } as any;
    service = new UserService(mockDb);
  });

  describe('getUser', () => {
    it('returns user when exists', async () => {
      mockDb.findOne.mockResolvedValue({ id: 1, name: 'Test' });

      const result = await service.getUser(1);

      expect(result.name).toBe('Test');
    });

    it('throws when user not found', async () => {
      mockDb.findOne.mockResolvedValue(null);

      await expect(service.getUser(999)).rejects.toThrow(UserNotFoundError);
    });
  });

  describe.each([
    [1, true],
    [0, false],
    [-1, false],
    [null, false],
  ])('isValidUserId(%s)', (userId, expected) => {
    it(`returns ${expected}`, () => {
      expect(isValidUserId(userId)).toBe(expected);
    });
  });
});
```

#### Go

```go
func TestUserService_GetUser(t *testing.T) {
    t.Run("returns user when exists", func(t *testing.T) {
        mockDB := &MockDB{
            FindOneFunc: func(id int) (*User, error) {
                return &User{ID: 1, Name: "Test"}, nil
            },
        }
        service := NewUserService(mockDB)

        user, err := service.GetUser(1)

        assert.NoError(t, err)
        assert.Equal(t, "Test", user.Name)
    })

    t.Run("returns error when not found", func(t *testing.T) {
        mockDB := &MockDB{
            FindOneFunc: func(id int) (*User, error) {
                return nil, ErrNotFound
            },
        }
        service := NewUserService(mockDB)

        _, err := service.GetUser(999)

        assert.ErrorIs(t, err, ErrNotFound)
    })
}

func TestIsValidUserID(t *testing.T) {
    tests := []struct {
        name     string
        userID   int
        expected bool
    }{
        {"positive ID", 1, true},
        {"zero ID", 0, false},
        {"negative ID", -1, false},
    }

    for _, tt := range tests {
        t.Run(tt.name, func(t *testing.T) {
            result := IsValidUserID(tt.userID)
            assert.Equal(t, tt.expected, result)
        })
    }
}
```

## Coverage Goals

| Type | Target |
|------|--------|
| Line Coverage | 80%+ |
| Branch Coverage | 75%+ |
| Function Coverage | 90%+ |
| Critical Paths | 100% |

## Output

1. Test files matching source structure
2. Mock/fixture files
3. Coverage report
4. Test documentation
