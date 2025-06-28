# Go Style Guide

This guide documents the Go patterns and idioms we follow for building maintainable Go applications. We strictly adhere to Ben Johnson's Standard Package Layout philosophy and enforce specific practices for consistency, testability, and maintainability.

## Core Architecture Principles

### Package Organization (Ben Johnson's Standard Package Layout)
- **Root package contains domain types only**: Pure business entities and interfaces
- **Subpackages implement interfaces**: Each external dependency gets its own package
- **Dependencies flow inward**: Infrastructure depends on domain, never the reverse
- **Shared mock package**: Manual mocks in `mock/` to avoid circular dependencies

```go
myapp/
├── *.go                    # Domain types and interfaces only
├── mock/                   # Manual mocks (separate package)
├── postgres/               # PostgreSQL implementations
├── http/                   # HTTP handlers
└── cmd/server/             # Application entry point (wiring)
```

## Testing Requirements

### 1. Always Use `t.Parallel()`
**Every test must start with `t.Parallel()`** - no exceptions. This provides natural protection against data races and ensures tests can run concurrently.

```go
func TestPostgresUserService_CreateUser(t *testing.T) {
    t.Parallel()  // REQUIRED - first line of every test
    // test implementation...
}
```

### 2. Test Package Naming with `_test` Suffix
**All test files must use external test packages** (e.g., `package postgres_test`). This enforces testing through public APIs only and prevents accessing private implementation details.

```go
//go:build integration
package postgres_test  // NOT package postgres

import (
    "github.com/yourusername/myapp/postgres"
    // ...
)
```

### 3. Schema-Based Test Isolation for PostgreSQL
Each test creates a unique schema with timestamp and random ID for true parallel testing:

```go
func setupTestDB(t *testing.T) (*sql.DB, func()) {
    schemaName := fmt.Sprintf("test_%s_%d", randomID(), time.Now().UnixNano())
    // Create isolated schema and return cleanup function
}
```

### 4. Build Tags for Test Categories
```go
//go:build integration  // For integration tests
//go:build e2e         // For end-to-end tests
```

### 5. Table-Driven Tests with testify
Use table-driven tests with descriptive names and the testify library:

```go
tests := []struct {
    name    string
    input   string
    want    string
    wantErr bool
}{
    {
        name:  "valid input returns expected result",
        input: "test input",
        want:  "expected output",
    },
}

for _, tt := range tests {
    t.Run(tt.name, func(t *testing.T) {
        t.Parallel()  // Even subtests should be parallel
        // Use require for setup that must succeed
        require.NoError(t, err, "setup failed")
        // Use assert for test conditions
        assert.Equal(t, tt.want, got)
    })
}
```

## Dependency Injection Patterns

### 1. Interface-Based Dependencies
Define interfaces in the domain, implement in subpackages:

```go
// In root package (domain layer)
type DataProcessor interface {
    Process(ctx context.Context, input string) (string, error)
    Validate(ctx context.Context, data string) error
}

// In implementation package
type Client struct {
    httpClient *http.Client
}
```

### 2. Compile-Time Interface Compliance Checks
**Always include interface compliance checks** after implementations:

```go
// Ensure Client implements myapp.DataProcessor
var _ myapp.DataProcessor = (*Client)(nil)
```

Benefits:
- Compile-time verification (not runtime)
- Clear documentation of implemented interfaces
- Immediate compilation errors on interface changes
- Better IDE support

### 3. Manual Dependency Wiring
No DI frameworks - explicit wiring in `main`:

```go
func main() {
    // Initialize dependencies
    db, err := sql.Open("postgres", databaseURL)
    // ...
    
    // Create services with explicit dependencies
    userService := postgres.NewUserService(db)
    dataProcessor := external.New(ctx, config)
    
    // Wire into server
    server := &http.Server{
        UserService:    userService,
        DataProcessor: dataProcessor,
    }
}
```

### 4. Functional Options Pattern (When Needed)
For optional configuration, use functional options:

```go
type Option func(*Client)

func WithTimeout(timeout time.Duration) Option {
    return func(c *Client) {
        c.timeout = timeout
    }
}

func New(required string, opts ...Option) *Client {
    c := &Client{required: required}
    for _, opt := range opts {
        opt(c)
    }
    return c
}
```

## Error Handling

### 1. Domain-Specific Error Types
Use domain errors with codes and messages:

```go
return &myapp.Error{
    Code:    myapp.EINVALID,
    Message: "required field is missing",
}
```

### 2. Error Constants
Define error codes as constants:

```go
const (
    ECONFLICT     = "conflict"
    EINTERNAL     = "internal"
    EINVALID      = "invalid"
    ENOTFOUND     = "not_found"
    EUNAUTHORIZED = "unauthorized"
)
```

### 3. Infrastructure Error Translation
Convert infrastructure errors to domain errors at boundaries:

```go
if err == sql.ErrNoRows {
    return nil, &myapp.Error{
        Code:    myapp.ENOTFOUND,
        Message: "resource not found",
    }
}
```

## Context and Resource Management

### 1. Context Cancellation Checks
Always check context at operation start:

```go
func (c *Client) Process(ctx context.Context, input string) (string, error) {
    select {
    case <-ctx.Done():
        return "", ctx.Err()
    default:
    }
    // Proceed with operation...
}
```

### 2. Defer Cleanup Immediately
Place defer statements immediately after resource creation:

```go
client, err := someapi.NewClient()
if err != nil {
    return err
}
defer client.Close()  // Immediately after successful creation
```

### 3. Constructor Validation
Validate required parameters early:

```go
func New(ctx context.Context, config Config) (*Client, error) {
    if config.APIKey == "" {
        return nil, &myapp.Error{
            Code:    myapp.EINVALID,
            Message: "API key is required",
        }
    }
    // Continue initialization...
}
```

## Mock Patterns

### 1. Manual Mocks in Separate Package
Create mocks in `mock/` package with function fields:

```go
package mock

type DataProcessor struct {
    mu sync.Mutex  // Thread-safe
    
    ProcessFunc func(ctx context.Context, input string) (string, error)
    processInvoked bool
}

func (m *DataProcessor) Process(ctx context.Context, input string) (string, error) {
    m.mu.Lock()
    defer m.mu.Unlock()
    
    m.processInvoked = true
    if m.ProcessFunc != nil {
        return m.ProcessFunc(ctx, input)
    }
    return "", errors.New("mock: ProcessFunc not implemented")
}
```

### 2. Mock Usage in Tests
```go
mockProcessor := &mock.DataProcessor{
    ProcessFunc: func(ctx context.Context, input string) (string, error) {
        return "test output", nil
    },
}
```

## Integration Test Patterns

### 1. Environment-Based Skip
Allow graceful skipping when dependencies unavailable:

```go
apiKey := os.Getenv("API_KEY")
if apiKey == "" {
    t.Skip("Skipping integration test, API_KEY not set")
}
```

### 2. Golden File Testing
For complex outputs, use golden files:

```go
golden := filepath.Join("testdata", "golden", testName+".json")
if *update {
    err := os.WriteFile(golden, got, 0644)
    require.NoError(t, err)
}
want, err := os.ReadFile(golden)
require.NoError(t, err)
assert.JSONEq(t, string(want), string(got))
```

## Code Organization Best Practices

### 1. Package Comments
Document package purpose clearly:

```go
// Package external implements the DataProcessor interface using an external API.
// It handles authentication and request/response transformation.
package external
```

### 2. Consistent Naming
- **Acronyms**: Maintain consistent case (e.g., `HTTPClient`, not `HttpClient`)
- **Getters**: No "Get" prefix (e.g., `User()` not `GetUser()`)
- **Interfaces**: Use "-er" suffix when possible (e.g., `Reader`, `Writer`, `Processor`)

### 3. Zero Values
Leverage Go's zero values:

```go
type Result struct {
    Text       string    // Zero value "" is sensible default
    Confidence float64   // Zero value 0.0 indicates no confidence
}
```

### 4. Behavioral Tests Over Implementation
Test the contract, not the implementation:

```go
// Good: Tests behavior
func TestClient_Process_ValidatesInput(t *testing.T) {
    // Test that invalid input is rejected
}

// Avoid: Tests implementation details
func TestClient_Process_CallsExternalAPI(t *testing.T) {
    // Too coupled to implementation
}
```

## Security Patterns

### 1. CSRF Protection
Use CSRF tokens for state-changing operations:

```go
csrfToken := r.Header.Get("X-CSRF-Token")
if csrfToken == "" {
    return &myapp.Error{Code: myapp.EINVALID}
}
```

### 2. Security Headers
Apply security headers middleware to all HTTP handlers.

### 3. Input Validation
Validate and sanitize all user inputs at entry points.

## Why These Patterns?

1. **`t.Parallel()` everywhere**: Catches race conditions early and speeds up test suite
2. **`_test` packages**: Forces proper API design and prevents testing internals
3. **Schema isolation**: Enables true parallel database tests without conflicts
4. **Manual mocks**: Simple, debuggable, no magic or code generation
5. **Interface compliance checks**: Catches breaking changes at compile time
6. **Domain-driven errors**: Clear error handling across layers
7. **Explicit wiring**: No hidden dependencies or reflection magic

These patterns have proven effective through real-world usage, where proper interface boundaries allow swapping implementations with minimal code changes.