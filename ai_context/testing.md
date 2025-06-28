# Testing Philosophy and Standards for Book Scanner

## Testing Philosophy

Testing is not just about verification—it's a design tool that guides us toward better architecture. We follow Michael Feathers' principle that **test pain is design feedback**: when tests are difficult to write or maintain, it signals design problems that need addressing.

### Core Principles

1. **All tests must use `package *_test`** - External testing enforces clean public interfaces
2. **No private function access** - If it needs testing, it should be public
3. **Test pain indicates design issues** - Difficult tests reveal coupling problems
4. **Behavior over implementation** - Test what the code does, not how it does it
5. **Interfaces enable testability** - Dependencies through interfaces allow clean mocking

### The Test Pain Principle

Michael Feathers teaches us that pain in testing is not a testing problem—it's a design problem:

- **Difficult setup** → Too much coupling
- **Need to test private functions** → Poor encapsulation
- **Complex test arrangements** → Violating Single Responsibility Principle
- **Brittle tests that break often** → Testing implementation details
- **Hard to create test scenarios** → Missing abstractions

When tests hurt, **don't make testing easier—make the design better**.

## Overview

This project uses **testify** for all test assertions. This guide documents our testing patterns, standards, and best practices.

## Why Testify?

1. **More readable assertions**: `assert.Equal(t, expected, actual)` vs manual comparison
2. **Better error messages**: Detailed diffs for failed assertions
3. **Helpful utilities**: `require` for fatal errors, `assert` for non-fatal assertions
4. **Table-driven test support**: Works well with subtests
5. **Widely adopted**: Common in the Go community

## Package Naming Convention

### Test Package Naming (_test suffix)

All test files should use the `packagename_test` package naming convention to enforce testing along public interface lines:

```go
// book_test.go
package bookscanner_test  // NOT package bookscanner

import (
    "testing"
    "github.com/fwojciec/bookscanner"
    "github.com/stretchr/testify/assert"
)
```

**Exceptions**: Only use the same package (without _test suffix) when:
- Testing internal/unexported functionality
- Integration tests that need access to internal setup functions
- Test helper functions that are used by multiple test files

### Parallel Test Execution

Use `t.Parallel()` in every test to ensure thread safety and enable faster test execution:

```go
func TestBook_Validate(t *testing.T) {
    t.Parallel()  // First line after test function declaration
    
    // Test implementation...
}

func TestBookService_Create(t *testing.T) {
    t.Parallel()
    
    t.Run("success case", func(t *testing.T) {
        t.Parallel()  // Also use in subtests
        // Test implementation...
    })
}
```

**Exceptions**: Only omit `t.Parallel()` when:
- Testing code that uses global state that cannot be made concurrent-safe
- Testing package initialization or other one-time setup
- The test explicitly validates non-concurrent behavior

## Progressive Testing Strategy

Testing evolves as your code matures. Different phases require different approaches:

### Phase 1: Early Development
- **Focus**: Getting functionality working quickly
- **Pattern**: Simpler test patterns for rapid feedback
- **Acceptable**: Some shortcuts for exploration
- **Goal**: Validate core concepts and user flows

### Phase 2: Stabilization
- **Focus**: Applying test pain principle to improve design
- **Pattern**: Refactor tests to follow best practices
- **Action**: Extract utilities, improve interfaces, reduce coupling
- **Goal**: Clean, sustainable test structure

### Phase 3: Production Ready
- **Focus**: Comprehensive coverage through public interfaces
- **Pattern**: All documented patterns followed consistently
- **Standard**: No test pain, clean test structure
- **Goal**: Maintainable, reliable test suite

## Testing Patterns by Package Type

### HTTP Packages
**Primary Pattern**: Request-Response Testing

HTTP packages test behavior through actual HTTP requests and responses:

```go
package http_test

func TestBookHandler_Create(t *testing.T) {
    t.Parallel()
    
    // Arrange: Create request
    body := strings.NewReader(`{"title":"Test Book","author":"Author"}`)
    req := httptest.NewRequest("POST", "/api/books", body)
    req.Header.Set("Content-Type", "application/json")
    w := httptest.NewRecorder()
    
    // Act: Execute request
    handler.ServeHTTP(w, req)
    
    // Assert: Verify response
    assert.Equal(t, http.StatusCreated, w.Code)
    assert.Equal(t, "application/json", w.Header().Get("Content-Type"))
    
    var response BookResponse
    require.NoError(t, json.NewDecoder(w.Body).Decode(&response))
    assert.Equal(t, "Test Book", response.Title)
}
```

**Key Patterns**:
- Test complete request-response cycles
- Verify HTTP status codes and headers
- Test authentication flows end-to-end
- Validate error response formats
- Test security features (CSRF, CORS, etc.)

### Domain Packages
**Primary Pattern**: Interface-Based Testing with Mocks

Domain packages focus on business logic without external dependencies:

```go
package bookscanner_test

func TestBookService_ProcessScan(t *testing.T) {
    t.Parallel()
    
    // Arrange: Setup mocks for dependencies
    mockScanner := &mock.ScannerService{
        ExtractTextFn: func(ctx context.Context, image []byte) (string, error) {
            return "extracted text", nil
        },
    }
    
    service := bookscanner.NewBookService(mockScanner)
    
    // Act: Execute business logic
    book, err := service.ProcessScan(context.Background(), imageData)
    
    // Assert: Verify business rules
    require.NoError(t, err)
    assert.Equal(t, "Expected Title", book.Title)
    assert.True(t, mockScanner.ExtractTextInvoked)
}
```

**Key Patterns**:
- Test through public interfaces only
- Mock all external dependencies
- Focus on business invariants and rules
- Test error conditions thoroughly

### Infrastructure Packages
**Primary Pattern**: Integration Testing with Test Doubles

Infrastructure packages test actual integration with external systems:

```go
//go:build integration

package postgres // Note: same package for access to test helpers

func TestBookService_Create(t *testing.T) {
    t.Parallel()
    
    // Arrange: Real database with test schema
    db, cleanup := setupTestDB(t)
    defer cleanup()
    
    service := NewBookService(db)
    
    // Act: Real database operation
    book := &bookscanner.Book{Title: "Test", Author: "Author"}
    err := service.CreateBook(context.Background(), book)
    
    // Assert: Verify persistence
    require.NoError(t, err)
    assert.NotZero(t, book.ID)
    
    // Verify in database
    var count int
    err = db.QueryRow("SELECT COUNT(*) FROM books WHERE id = $1", book.ID).Scan(&count)
    require.NoError(t, err)
    assert.Equal(t, 1, count)
}
```

**Key Patterns**:
- Use real external dependencies (database, APIs)
- Isolate tests with unique schemas/containers
- Test error conditions and edge cases
- Verify side effects (database changes, API calls)

## Core Patterns

### assert vs require

```go
// Use require for setup/preconditions that MUST succeed
require.NoError(t, err, "database connection should succeed")
require.NotNil(t, client, "client should be created")

// Use assert for test conditions that allow test to continue
assert.Equal(t, expected, actual, "values should match")
assert.True(t, condition, "condition should be true")
assert.Contains(t, slice, item, "slice should contain item")
```

### Standard Assertion Patterns

#### Error Handling
```go
// Success case
require.NoError(t, err, "operation should succeed")

// Expected error
assert.Error(t, err, "should return error")

// Specific error types
var bsErr *bookscanner.Error
require.ErrorAs(t, err, &bsErr, "should be bookscanner.Error")
assert.Equal(t, bookscanner.EINVALID, bsErr.Code, "should be invalid error")

// Error matching
assert.ErrorIs(t, err, context.Canceled, "should be context canceled")
```

#### Value Comparisons
```go
// Basic equality
assert.Equal(t, expected, actual, "values should match")
assert.NotEqual(t, forbidden, actual, "values should differ")

// Nil checks
require.NotNil(t, result, "result should not be nil")
assert.Nil(t, err, "error should be nil")

// Numeric comparisons
assert.Greater(t, value, 0, "value should be positive")
assert.GreaterOrEqual(t, len(items), 10, "should have at least 10 items")

// Float comparisons (use InDelta for precision)
assert.InDelta(t, 0.95, confidence, 0.001, "confidence should be ~0.95")
```

#### Collection Assertions
```go
// Length checks
assert.Len(t, items, 5, "should have 5 items")
assert.Empty(t, errors, "errors should be empty")
assert.NotEmpty(t, result, "result should not be empty")

// Contains checks
assert.Contains(t, haystack, needle, "should contain substring")
assert.ElementsMatch(t, expected, actual, "should have same elements")
```

## Test Types

### 1. Unit Tests
- Use mocks from `mock/` package
- No external dependencies
- Fast and focused
- Run with: `make test` or `go test ./...`

### 2. Integration Tests
- Test with real infrastructure
- Use build tags: `//go:build integration`
- Run with: `make test-integration` (requires TEST_DATABASE_URL)
- Automatically skip if dependencies unavailable

### 3. All Tests
- Run with: `make test-all`

## Table-Driven Tests

```go
package bookscanner_test

import (
    "testing"
    "github.com/fwojciec/bookscanner"
    "github.com/stretchr/testify/assert"
    "github.com/stretchr/testify/require"
)

func TestBookValidation(t *testing.T) {
    t.Parallel()
    
    tests := []struct {
        name    string
        book    *bookscanner.Book
        wantErr string
    }{
        {
            name: "valid book",
            book: &bookscanner.Book{Title: "Test", Author: "Author"},
        },
        {
            name:    "missing title",
            book:    &bookscanner.Book{Author: "Author"},
            wantErr: bookscanner.EINVALID,
        },
    }

    for _, tt := range tests {
        t.Run(tt.name, func(t *testing.T) {
            t.Parallel()
            
            err := tt.book.Validate()
            
            if tt.wantErr != "" {
                require.Error(t, err, "expected validation error")
                var bsErr *bookscanner.Error
                require.ErrorAs(t, err, &bsErr)
                assert.Equal(t, tt.wantErr, bsErr.Code)
            } else {
                assert.NoError(t, err, "validation should succeed")
            }
        })
    }
}
```

## Mock Testing Patterns

```go
package service_test

import (
    "context"
    "testing"
    "github.com/fwojciec/bookscanner"
    "github.com/fwojciec/bookscanner/mock"
    "github.com/fwojciec/bookscanner/service"
    "github.com/stretchr/testify/assert"
    "github.com/stretchr/testify/require"
)

func TestServiceWithMock(t *testing.T) {
    t.Parallel()
    
    mockStore := &mock.BookService{
        FindBookByIDFn: func(ctx context.Context, id int) (*bookscanner.Book, error) {
            return nil, &bookscanner.Error{Code: bookscanner.ENOTFOUND}
        },
    }

    service := service.NewService(mockStore)
    book, err := service.GetBook(context.Background(), 123)

    // Verify mock was called
    assert.True(t, mockStore.FindBookByIDInvoked, "FindBookByID should be called")
    
    // Verify results
    require.Error(t, err, "should return error")
    assert.Nil(t, book, "book should be nil")
}
```

## Advanced HTTP Testing Patterns

### Authentication Flow Testing

Test complete authentication workflows with real session management:

```go
package http_test

func TestAuthenticationFlow(t *testing.T) {
    t.Parallel()
    
    // Step 1: Login request
    loginBody := `{"idToken":"test-token"}`
    loginReq := httptest.NewRequest("POST", "/auth/google", strings.NewReader(loginBody))
    loginReq.Header.Set("Content-Type", "application/json")
    loginW := httptest.NewRecorder()
    
    server.ServeHTTP(loginW, loginReq)
    
    // Verify login response
    assert.Equal(t, http.StatusOK, loginW.Code)
    
    // Extract session cookie
    cookies := loginW.Result().Cookies()
    require.Len(t, cookies, 1, "should set session cookie")
    sessionCookie := cookies[0]
    
    // Step 2: Use session for protected endpoint
    protectedReq := httptest.NewRequest("GET", "/api/books", nil)
    protectedReq.AddCookie(sessionCookie)
    protectedW := httptest.NewRecorder()
    
    server.ServeHTTP(protectedW, protectedReq)
    
    // Verify authenticated access
    assert.Equal(t, http.StatusOK, protectedW.Code)
}
```

### Security Testing Patterns

```go
func TestSecurityHeaders(t *testing.T) {
    t.Parallel()
    
    tests := []struct {
        name   string
        header string
        want   string
    }{
        {"CSRF Protection", "X-CSRF-Token", "required"},
        {"Content Security Policy", "Content-Security-Policy", "default-src 'self'"},
        {"HTTPS Redirect", "Strict-Transport-Security", "max-age=31536000"},
    }
    
    for _, tt := range tests {
        t.Run(tt.name, func(t *testing.T) {
            t.Parallel()
            
            req := httptest.NewRequest("GET", "/", nil)
            w := httptest.NewRecorder()
            
            server.ServeHTTP(w, req)
            
            assert.Contains(t, w.Header().Get(tt.header), tt.want)
        })
    }
}
```

### File Upload Testing

```go
func TestImageUpload(t *testing.T) {
    t.Parallel()
    
    // Create multipart form with image
    var buf bytes.Buffer
    writer := multipart.NewWriter(&buf)
    part, err := writer.CreateFormFile("image", "test.jpg")
    require.NoError(t, err)
    
    // Add test image data
    _, err = part.Write(testImageBytes)
    require.NoError(t, err)
    require.NoError(t, writer.Close())
    
    // Create request
    req := httptest.NewRequest("POST", "/api/scan", &buf)
    req.Header.Set("Content-Type", writer.FormDataContentType())
    w := httptest.NewRecorder()
    
    // Execute and verify
    server.ServeHTTP(w, req)
    
    assert.Equal(t, http.StatusAccepted, w.Code)
    
    var response ScanResponse
    require.NoError(t, json.NewDecoder(w.Body).Decode(&response))
    assert.NotEmpty(t, response.ScanID)
}
```

## Test Pain as Design Feedback: Real Examples

### Example 1: Private Function Testing Pain

**Painful Test** (indicates design problem):
```go
// BAD: Trying to test private function
func TestParseBookData(t *testing.T) {
    // This is painful - we need reflection or test same package
    result := parseBookData("raw text") // private function
    // Pain: Can't test without exposing internals
}
```

**Design Solution** (eliminate the pain):
```go
// GOOD: Extract to public interface
type BookParser interface {
    ParseBookData(text string) (*Book, error)
}

// Test through public interface
func TestBookParser_ParseBookData(t *testing.T) {
    t.Parallel()
    
    parser := NewBookParser()
    book, err := parser.ParseBookData("Title: Test\nAuthor: Author")
    
    require.NoError(t, err)
    assert.Equal(t, "Test", book.Title)
}
```

### Example 2: Complex Setup Pain

**Painful Test** (indicates coupling problem):
```go
// BAD: Complex setup reveals too much coupling
func TestProcessBook(t *testing.T) {
    // Pain: Need to setup 5 different dependencies
    db := setupDatabase()
    visionClient := setupVisionAPI()
    openaiClient := setupOpenAI()
    googleBooks := setupGoogleBooks()
    cache := setupRedis()
    
    service := NewBookService(db, visionClient, openaiClient, googleBooks, cache)
    // This setup pain indicates design problems
}
```

**Design Solution** (dependency injection with interfaces):
```go
// GOOD: Simple interface-based testing
func TestBookService_ProcessBook(t *testing.T) {
    t.Parallel()
    
    // Simple mock setup
    mockScanner := &mock.ScannerService{
        ExtractTextFn: func(ctx context.Context, img []byte) (string, error) {
            return "extracted text", nil
        },
    }
    
    service := bookscanner.NewBookService(mockScanner)
    // Clean, focused test
}
```

### Example 3: Brittle Test Pain

**Painful Test** (testing implementation details):
```go
// BAD: Brittle test tied to implementation
func TestProcessImage(t *testing.T) {
    service := NewImageProcessor()
    
    // Pain: Test breaks when internal implementation changes
    service.processImage(image)
    
    // These assertions are tied to internal behavior
    assert.Equal(t, 3, service.internalCounter)
    assert.True(t, service.flagWasSet)
}
```

**Design Solution** (test behavior, not implementation):
```go
// GOOD: Test observable behavior
func TestImageProcessor_ProcessImage(t *testing.T) {
    t.Parallel()
    
    processor := NewImageProcessor()
    
    result, err := processor.ProcessImage(testImage)
    
    // Test what matters: the output and side effects
    require.NoError(t, err)
    assert.Equal(t, "Expected Text", result.Text)
    assert.NotZero(t, result.ProcessedAt)
}
```

## PostgreSQL Testing Strategy

We use schema-based isolation for fast, parallel tests. Note that integration tests often use the same package (without _test suffix) to access internal test helpers:

```go
//go:build integration

package postgres // NOT postgres_test - needs access to setupTestDB

func TestBookService_Create(t *testing.T) {
    t.Parallel()
    
    // Each test gets a unique schema for true isolation
    db, cleanup := setupTestDB(t) // Internal test helper
    defer cleanup()
    
    service := NewBookService(db)
    ctx := context.Background()
    
    book := &bookscanner.Book{
        Title:  "Test Book",
        Author: "Test Author",
    }
    
    err := service.CreateBook(ctx, book)
    require.NoError(t, err, "create should succeed")
    assert.NotZero(t, book.ID, "ID should be set")
    assert.False(t, book.CreatedAt.IsZero(), "CreatedAt should be set")
    
    // Verify persistence with independent query
    var savedBook bookscanner.Book
    err = db.QueryRowContext(ctx, 
        "SELECT id, title, author FROM books WHERE id = $1", 
        book.ID).Scan(&savedBook.ID, &savedBook.Title, &savedBook.Author)
    require.NoError(t, err)
    assert.Equal(t, book.Title, savedBook.Title)
}
```

## Test Helper Functions

When creating test helpers, always use `t.Helper()`:

```go
func assertValidBook(t *testing.T, book *bookscanner.Book) {
    t.Helper()
    
    assert.NotEmpty(t, book.Title, "book should have title")
    assert.NotEmpty(t, book.Author, "book should have author")
    assert.NoError(t, book.Validate(), "book should be valid")
}

func requireBookInDatabase(t *testing.T, db *sql.DB, id int) *bookscanner.Book {
    t.Helper()
    
    var book bookscanner.Book
    err := db.QueryRow("SELECT * FROM books WHERE id = $1", id).Scan(&book)
    require.NoError(t, err, "book should exist in database")
    return &book
}
```

## Context Testing

```go
func TestContextHandling(t *testing.T) {
    t.Run("respects context cancellation", func(t *testing.T) {
        ctx, cancel := context.WithCancel(context.Background())
        cancel()

        _, err := client.Process(ctx, data)
        assert.ErrorIs(t, err, context.Canceled, "should return context error")
    })
    
    t.Run("respects context timeout", func(t *testing.T) {
        ctx, cancel := context.WithTimeout(context.Background(), 1*time.Millisecond)
        defer cancel()
        
        // Simulate slow operation
        _, err := client.SlowOperation(ctx)
        assert.ErrorIs(t, err, context.DeadlineExceeded, "should timeout")
    })
}
```

## Concurrent Testing

```go
func TestConcurrentAccess(t *testing.T) {
    service := NewService()
    
    var wg sync.WaitGroup
    errors := make(chan error, 10)
    
    for i := 0; i < 10; i++ {
        wg.Add(1)
        go func(id int) {
            defer wg.Done()
            _, err := service.Process(id)
            if err != nil {
                errors <- err
            }
        }(i)
    }
    
    wg.Wait()
    close(errors)
    
    // Check for errors
    var errorCount int
    for err := range errors {
        errorCount++
        t.Logf("concurrent error: %v", err)
    }
    assert.Equal(t, 0, errorCount, "should have no concurrent errors")
}
```

## Linting Enforcement

The project uses `testifylint` and `thelper` to enforce these patterns:

```yaml
# .golangci.yml
linters:
  enable:
    - testifylint  # Enforce testify usage patterns
    - thelper      # Ensure test helpers use t.Helper()

linters-settings:
  testifylint:
    enable-all: true  # Enable all testify checks
```

## Best Practices

### 1. Test Naming
- Test files: `*_test.go`
- Integration tests: `*_integration_test.go` 
- Test functions: `Test<Type>_<Method>_<Scenario>`
- Subtests: Use descriptive names in `t.Run()`

### 2. Test Organization
- One test file per source file
- Group related tests using subtests
- Keep test data close to tests
- Use table-driven tests for multiple scenarios

### 3. Assertions
- Use `require` for setup that must succeed
- Use `assert` for test conditions
- Add descriptive messages to all assertions
- Use specific assertions (e.g., `assert.Len` over `assert.Equal` for lengths)

### 4. Error Testing
- Always test both success and error paths
- Test specific error types when relevant
- Verify error messages when they're part of the API

### 5. Test Data
- Keep test data minimal and focused
- Use builders for complex test objects
- Avoid shared mutable test data

## Debugging Tests

### Verbose Output
```bash
go test -v ./...
```

### Run Specific Test
```bash
go test -run TestBookService_Create ./postgres
```

### With Race Detection
```bash
go test -race ./...
```

## Race Detection in CI

### Local Testing
While not required for local development, race detection is strongly encouraged:
```bash
# Run all tests with race detection
make test-race

# Or manually
go test -race ./...
```

### CI/CD Pipeline
The CI pipeline runs comprehensive testing with:
- Race detection enabled (`go test -race`)
- Coverage reporting (40% minimum threshold)
- Parallel test execution with PostgreSQL schema isolation
- Google Cloud authentication for Vision API tests

Tests run in isolated PostgreSQL schemas to enable true parallel execution without conflicts. See `cmd/server/main_test.go` for the `setupTestSchema` helper.

### Writing Race-Safe Code
To ensure your code passes race detection:

1. **Always use channels or mutexes for shared state**:
   ```go
   type SafeCounter struct {
       mu    sync.Mutex
       count int
   }
   
   func (c *SafeCounter) Increment() {
       c.mu.Lock()
       defer c.mu.Unlock()
       c.count++
   }
   ```

2. **Use sync.Once for one-time initialization**:
   ```go
   var (
       instance *Service
       once     sync.Once
   )
   
   func GetService() *Service {
       once.Do(func() {
           instance = &Service{}
       })
       return instance
   }
   ```

3. **Avoid data races in tests by using t.Parallel() correctly**:
   ```go
   func TestConcurrent(t *testing.T) {
       t.Parallel()
       
       // Each test gets its own instance
       service := NewService()
       
       // Not shared across tests
   }
   ```

## Key Takeaways for Book Scanner Testing

### When Tests Are Easy (Good Design)
- **HTTP handlers**: Simple request-response testing
- **Domain services**: Clean interface mocking
- **Database operations**: Straightforward integration tests
- **File operations**: Simple setup and teardown

### When Tests Are Hard (Design Problems)
- **Complex setup required** → Too much coupling
- **Need to test private functions** → Poor encapsulation
- **Brittle tests that break frequently** → Testing implementation details
- **Mocking is complicated** → Interface design issues

### The Test-Driven Design Process

1. **Write the test first** - This reveals interface design issues early
2. **If the test is painful** - Stop and improve the design
3. **Make the test pass** - Implement the simplest solution
4. **Refactor both code and tests** - Clean up while maintaining green tests
5. **Repeat** - Each cycle improves both design and test quality

### Practical Application in Book Scanner

Our architecture naturally enables good testing because:

- **Domain interfaces** make mocking clean and simple
- **Dependency injection** eliminates complex setup
- **Package boundaries** enforce testing through public APIs
- **Schema isolation** enables fast, parallel integration tests

**Remember**: If testing hurts, the design needs work. Good tests are a side effect of good design.

## Enforcement

- All new tests MUST use testify patterns
- All tests MUST use `package *_test` for external testing
- Test pain indicates design problems that must be addressed
- `golangci-lint` will catch violations during `make validate`
- CI/CD pipeline enforces these standards
- Code review should verify proper testify usage and design quality

## Migration from Standard Library

When updating existing tests:

1. Add imports:
   ```go
   import (
       "github.com/stretchr/testify/assert"
       "github.com/stretchr/testify/require"
   )
   ```

2. Replace patterns:
   - `if err != nil { t.Fatal(err) }` → `require.NoError(t, err)`
   - `if x != y { t.Errorf(...) }` → `assert.Equal(t, y, x)`
   - `if condition { t.Error(...) }` → `assert.False(t, condition)`

3. Run tests to ensure behavior unchanged

4. Run linter to catch any missed patterns

## Testing Pattern Decision Tree

Choose the right testing pattern based on your package type and testing needs:

```
What are you testing?
│
├── HTTP Endpoints/Handlers?
│   │
│   ├── Authentication/Authorization? → Request-Response with Session Testing
│   ├── File Uploads? → Multipart Form Testing
│   ├── API Endpoints? → JSON Request-Response Testing
│   └── Security Features? → Header and Security Testing
│
├── Business Logic/Domain?
│   │
│   ├── Pure Functions? → Simple Unit Tests
│   ├── With Dependencies? → Interface Testing with Mocks
│   └── Complex Workflows? → Table-Driven Tests with Scenarios
│
├── Infrastructure/Database?
│   │
│   ├── Database Operations? → Integration Tests with Test Schemas
│   ├── External APIs? → Golden File Testing or Real API Integration
│   └── File I/O? → Temporary File Testing
│
└── Concurrent/Performance?
        │
        ├── Race Conditions? → Concurrent Testing with Goroutines
        └── Performance? → Benchmark Testing
```

### Pattern Selection Guidelines

1. **Start with the simplest pattern** that tests your behavior
2. **If test setup is painful**, your design likely needs improvement
3. **Use mocks for fast unit tests**, real dependencies for integration tests
4. **Test through public interfaces only** - avoid testing internal implementation
5. **When in doubt, prefer behavior testing** over implementation testing

## Environment Variables and Configuration in Tests

### Flag-Based Configuration (Preferred)

The project uses the `ff` package which supports both flags and environment variables. For tests and internal tools, we prefer explicit flag-based configuration over environment variables:

```go
func TestWithConfig(t *testing.T) {
    cfg := config.New()
    
    // Build explicit flags for test configuration
    args := []string{
        "--database-url", "postgres://test:test@localhost:5432/test",
        "--postgres-schema", "public",
        "--openai-api-key", "test-key",
        "--google-books-api-key", "test-key",
        "--port", "8081",
    }
    
    // ParseWithoutEnv ensures only flags are used, not environment variables
    err := cfg.ParseWithoutEnv(args)
    require.NoError(t, err)
    
    // Test with configured values...
}
```

### E2E Test Configuration

For E2E tests that need real environment values, use flags with environment variable fallbacks:

```go
func setupE2EConfig(t *testing.T) []string {
    return []string{
        "--database-url", getEnvOrDefault("DATABASE_URL", "postgres://localhost/test"),
        "--openai-api-key", getEnvOrDefault("OPENAI_API_KEY", "test-key"),
        "--google-books-api-key", getEnvOrDefault("GOOGLE_BOOKS_API_KEY", "test-key"),
        "--postgres-schema", "public",
    }
}

func getEnvOrDefault(key, defaultValue string) string {
    if value := os.Getenv(key); value != "" {
        return value
    }
    return defaultValue
}
```

### Benefits of Flag-Based Approach

1. **Explicit Configuration**: All configuration is visible in the test code
2. **No Hidden Dependencies**: No reliance on .env files or environment state
3. **Better IDE Support**: Flag names are documented and autocompleted
4. **Consistent Testing**: Tests behave the same across all environments
5. **Easier Debugging**: Configuration values are visible in test output

### Production vs Test Configuration

- **Production**: Uses `config.Parse()` which reads both flags AND environment variables via `ff.WithEnvVars()`
- **Tests**: Use `config.ParseWithoutEnv()` to ensure only explicit flags are used
- **E2E Tests**: Can use environment variables as fallbacks but should prefer explicit flags