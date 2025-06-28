# Go Backend Conventions

## Package Structure

Follow Ben Johnson's Standard Package Layout:
- Root package contains ONLY domain types and interfaces
- Each external dependency gets its own subpackage
- No circular dependencies between packages
- Dependencies flow inward toward the domain

## Naming Conventions

### Files
- One primary type per file
- File named after the primary type (e.g., `user.go` for `User` type)
- Test files follow `*_test.go` pattern
- Integration tests use `//go:build integration` tag

### Types and Functions
- Exported types use PascalCase
- Unexported types use camelCase
- Interfaces end with "-er" suffix when possible (e.g., `UserStorer`, `DataProcessor`)
- Constructors named `New` or `NewXxx`

## Error Handling

### Domain Errors
```go
type Error struct {
    Code    string
    Message string
    Op      string
    Err     error
}
```

### Error Codes
- `ENOTFOUND` - Resource not found
- `EINVALID` - Invalid input
- `EINTERNAL` - Internal error
- `ECONFLICT` - Resource conflict

### Error Wrapping
Always preserve error context:
```go
if err != nil {
    return &myapp.Error{
        Code: myapp.EINTERNAL,
        Message: "failed to query database",
        Op: "postgres.UserService.GetByID",
        Err: err,
    }
}
```

## Testing Patterns

### Unit Tests
- Use manual mocks from `mock/` package
- Table-driven tests for multiple scenarios
- Test one behavior per test function

### Integration Tests
```go
//go:build integration

func TestUserService_Create_Integration(t *testing.T) {
    // Setup with real database
    // Test with actual infrastructure
}
```

### Test Naming
- `Test<Type>_<Method>` for method tests
- `Test<Type>_<Method>_<Scenario>` for specific cases

## Database Conventions

### SQL Queries
- Use prepared statements
- Named parameters with sqlx
- Explicit column lists (no SELECT *)

### Migrations
- Sequential version numbers
- Up and down migrations
- Idempotent operations

## Code Quality Requirements

Before ANY commit, run:
```bash
make validate
```

This single command runs all required checks:
1. `go fmt ./...` - Format code
2. `go vet ./...` - Run static analysis
3. `go test ./...` - Run unit tests
4. `go mod tidy` - Clean up dependencies
5. `golangci-lint run ./...` - Run comprehensive linting
6. `actionlint` - Lint GitHub Actions workflow files

For CI environments, use:
```bash
make validate-ci
```
This fails fast on any formatting or module changes.

### CI Pipeline

The project uses a consolidated CI workflow (`.github/workflows/ci.yml`) that:
- Runs on all pushes to main and pull requests
- Performs fast-fail checks first (formatting, vet, go mod tidy)
- Runs security, linting, and testing in parallel for speed
- Security: gosec, govulncheck, sensitive data detection (excludes infrastructure/)
- Testing: Requires 40% code coverage with race detection enabled
- Error handling: For PRs, only checks changed files for unwrapped errors

Branch protection requires only the `CI / CI Status` check, which depends on all other checks.

### Linting

The project uses golangci-lint with a configuration optimized for LLM-friendly feedback:
- Run `make lint` to check for issues
- Run `make lint-fix` to auto-fix some issues
- All code (including tests) must pass linting checks
- Configuration is in `.golangci.yml`

Key linters enabled:
- `errcheck` - Ensures all errors are handled
- `staticcheck` - Comprehensive correctness checks
- `bodyclose` - Ensures HTTP response bodies are closed
- `gochecknoglobals` - Enforces no global state (Ben Johnson principle)
- See `.golangci.yml` for the complete list

## Documentation

### Package Comments
```go
// Package postgres implements the BookService interface
// using PostgreSQL as the backing store.
package postgres
```

### Function Comments
- Start with function name
- Describe what, not how
- Document error conditions

## Dependency Management

- Minimal external dependencies
- Justify each dependency in comments
- Use standard library when possible
- Mock external services in tests

## Concurrency Patterns

- Use channels for communication
- Mutexes for shared state protection
- Context for cancellation
- Goroutines with clear ownership

## Performance Guidelines

- Profile before optimizing
- Benchmark critical paths
- Pool database connections
- Reuse allocated memory when beneficial