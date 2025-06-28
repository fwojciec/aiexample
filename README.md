# AI Example - Building Go Applications with AI-Assisted Development

This repository demonstrates a modern approach to building Go applications with AI-assisted development, featuring Ben Johnson's Standard Package Layout, Test-Driven Development (TDD), and comprehensive AI development guidelines.

## What This Example Demonstrates

### 1. **Ben Johnson's Standard Package Layout**
A battle-tested architecture pattern where:
- Domain logic lives in the root package
- Infrastructure implementations in subpackages
- Dependencies flow inward
- No circular dependencies

### 2. **AI-First Development Workflow**
- Comprehensive `CLAUDE.md` file for AI context
- Structured `ai_context/` directory with domain knowledge
- Clear conventions that AI assistants can follow
- TDD approach that works seamlessly with AI pair programming

### 3. **Production-Ready Practices**
- Schema-based PostgreSQL test isolation
- Parallel test execution with `t.Parallel()`
- Manual mocks for predictable testing
- Comprehensive validation with `make validate`

## Quick Start

```bash
# Start PostgreSQL
make dev-up

# Run all validations (format, vet, test, lint)
make validate

# Run tests with race detection
make test RACE=1

# Run integration tests
make test TAGS=integration
```

## Project Structure

```
myproject/
├── *.go                    # Domain types and interfaces only
├── mock/                   # Manual mocks for testing
├── postgres/               # PostgreSQL implementations
├── http/                   # HTTP handlers and middleware
├── cmd/                    # Application entry points
│   └── server/             # Main server application
├── ai_context/             # AI development context
├── CLAUDE.md               # AI assistant instructions
└── Makefile                # Development automation
```

## Key Features for AI Development

### 1. **CLAUDE.md - Your AI's Instruction Manual**
The `CLAUDE.md` file serves as the primary instruction set for AI assistants. It includes:
- Quick reference for architecture patterns
- Essential development rules
- Make commands and workflows
- Context file references

### 2. **Context-Aware Development**
The `ai_context/` directory contains:
- `architecture.md` - System design and patterns
- `go-style-guide.md` - Go idioms and conventions
- `testing.md` - Testing strategies and patterns
- `backend-conventions.md` - Backend-specific rules
- And more...

### 3. **TDD with AI**
- Write tests first, even when working with AI
- Use table-driven tests for clarity
- Leverage `testify` for readable assertions
- AI can help generate comprehensive test cases

## Development Workflow

### Working with AI Assistants

1. **Start with Intent**
   ```
   "I need to add a new user authentication feature"
   ```

2. **AI References Context**
   - Reads `CLAUDE.md` for project rules
   - Checks relevant `ai_context/` files
   - Follows established patterns

3. **TDD Approach**
   - AI writes failing tests first
   - Implements to pass tests
   - Validates with `make validate`

4. **Consistent Patterns**
   - Interface in root package
   - Implementation in subpackage
   - Mock in `mock/` package
   - Wire in `cmd/server/main.go`

## Example: Adding a New Feature

Let's say you want to add a new data processing feature:

1. **Define the Interface** (root package)
   ```go
   type DataProcessor interface {
       Process(ctx context.Context, data []byte) (*Result, error)
   }
   ```

2. **Create Implementation** (subpackage)
   ```go
   // In processor/processor.go
   type Processor struct {
       db *sql.DB
   }
   
   var _ myapp.DataProcessor = (*Processor)(nil)
   ```

3. **Add Mock** (mock package)
   ```go
   // In mock/data_processor.go
   type DataProcessor struct {
       ProcessFunc func(ctx context.Context, data []byte) (*myapp.Result, error)
   }
   ```

4. **Write Tests First**
   ```go
   func TestProcessor_Process(t *testing.T) {
       t.Parallel()
       // Test implementation
   }
   ```

## Best Practices

### For Developers
1. Always run `make validate` before committing
2. Use `t.Parallel()` in every test
3. Keep domain logic pure (no external dependencies)
4. Write integration tests with `//go:build integration`

### For AI Assistants
1. Read `CLAUDE.md` first
2. Check relevant `ai_context/` files for the task
3. Follow TDD approach strictly
4. Use existing patterns from the codebase
5. Run validation before suggesting commits

## Advanced Features

### Database Testing
- Automatic schema isolation per test
- True parallel test execution
- No test data conflicts
- Fast cleanup with schema drops

### Error Handling
- Domain-specific error types
- Consistent error codes
- Error wrapping with context
- Infrastructure errors translated at boundaries

### Dependency Injection
- Manual wiring in `main()`
- No magic or reflection
- Clear, debuggable initialization
- Easy to test with mocks

## Why This Approach?

1. **AI-Friendly**: Clear patterns that AI can learn and follow
2. **Testable**: Everything can be mocked and tested
3. **Maintainable**: Clear separation of concerns
4. **Scalable**: Patterns work from small to large applications
5. **Debuggable**: No hidden magic or framework complexity

## Contributing

When contributing to this example:
1. Follow the patterns established in the codebase
2. Update relevant `ai_context/` documentation
3. Ensure all tests pass with `make validate`
4. Add examples that demonstrate the patterns

## Learn More

- [Ben Johnson's Standard Package Layout](https://medium.com/@benbjohnson/standard-package-layout-7cdbc8391fc1)
- [Effective Go](https://golang.org/doc/effective_go.html)
- [Go Code Review Comments](https://github.com/golang/go/wiki/CodeReviewComments)

## License

This example is provided as-is for educational purposes. Feel free to use these patterns in your own projects.