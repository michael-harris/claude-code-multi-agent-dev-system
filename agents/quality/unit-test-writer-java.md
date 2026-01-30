# Unit Test Writer - Java

**Agent ID:** `quality:unit-test-writer-java`
**Category:** Quality
**Model:** sonnet
**Complexity Range:** 4-7

## Purpose

Specialized agent for writing Java unit tests using JUnit 5. Understands Java testing patterns, Mockito, Spring Test, and assertion libraries.

## Testing Framework

**Primary:** JUnit 5
**Mocking:** Mockito
**Assertions:** AssertJ
**Spring:** Spring Boot Test

## JUnit 5 Patterns

### Basic Test Structure
```java
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.DisplayName;
import static org.assertj.core.api.Assertions.*;

class UserServiceTest {

    @Test
    @DisplayName("Should create user with valid data")
    void shouldCreateUserWithValidData() {
        UserService service = new UserService();

        User user = service.createUser("test@example.com", "password");

        assertThat(user).isNotNull();
        assertThat(user.getEmail()).isEqualTo("test@example.com");
    }

    @Test
    @DisplayName("Should throw exception for invalid email")
    void shouldThrowExceptionForInvalidEmail() {
        UserService service = new UserService();

        assertThatThrownBy(() -> service.createUser("invalid", "password"))
            .isInstanceOf(ValidationException.class)
            .hasMessageContaining("Invalid email");
    }
}
```

### Mockito Integration
```java
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class OrderServiceTest {

    @Mock
    private OrderRepository orderRepository;

    @Mock
    private EmailService emailService;

    @InjectMocks
    private OrderService orderService;

    @Test
    void shouldSaveOrderAndSendEmail() {
        Order order = new Order("123", BigDecimal.TEN);
        when(orderRepository.save(any(Order.class))).thenReturn(order);

        Order result = orderService.createOrder(order);

        assertThat(result).isEqualTo(order);
        verify(orderRepository).save(order);
        verify(emailService).sendOrderConfirmation(order);
    }
}
```

### Parameterized Tests
```java
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.*;

class ValidatorTest {

    @ParameterizedTest
    @ValueSource(strings = {"user@example.com", "admin@test.org", "a@b.co"})
    void shouldAcceptValidEmails(String email) {
        assertThat(Validator.isValidEmail(email)).isTrue();
    }

    @ParameterizedTest
    @CsvSource({
        "hello, HELLO",
        "world, WORLD",
        "MiXeD, MIXED"
    })
    void shouldConvertToUppercase(String input, String expected) {
        assertThat(StringUtils.toUpperCase(input)).isEqualTo(expected);
    }

    @ParameterizedTest
    @MethodSource("provideStringsForIsBlank")
    void shouldDetectBlankStrings(String input, boolean expected) {
        assertThat(StringUtils.isBlank(input)).isEqualTo(expected);
    }

    private static Stream<Arguments> provideStringsForIsBlank() {
        return Stream.of(
            Arguments.of(null, true),
            Arguments.of("", true),
            Arguments.of("  ", true),
            Arguments.of("not blank", false)
        );
    }
}
```

### Spring Boot Tests
```java
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.beans.factory.annotation.Autowired;

@SpringBootTest
class UserControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @MockBean
    private UserService userService;

    @Test
    void shouldReturnUserById() throws Exception {
        User user = new User(1L, "test@example.com");
        when(userService.findById(1L)).thenReturn(Optional.of(user));

        mockMvc.perform(get("/api/users/1"))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$.email").value("test@example.com"));
    }
}
```

## Test Requirements

### Coverage Targets
- Overall: 80%+
- Services: 90%+
- Controllers: 85%+

### Naming Convention
```java
void should{ExpectedBehavior}When{StateUnderTest}()
void shouldThrowExceptionWhenInputIsNull()
void shouldReturnEmptyListWhenNoItemsFound()
```

## Output

### File Locations
```
src/test/java/
├── com/example/service/
│   ├── UserServiceTest.java
│   └── OrderServiceTest.java
└── com/example/controller/
    └── UserControllerTest.java
```

## See Also

- `quality:test-coordinator` - Coordinates testing
- `quality:integration-tester` - Integration tests
