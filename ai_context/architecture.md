# Go Project Architecture - Ben Johnson's Standard Package Layout

## Overview

This project demonstrates Ben Johnson's Standard Package Layout philosophy - a battle-tested approach to organizing Go applications that promotes clean architecture, testability, and maintainability.

## Core Design Principles

We follow Ben Johnson's Standard Package Layout. For the complete philosophy and detailed patterns, see @ai_docs/ben-johnson-standard-package-layout.md

Key principles:
1. **Domain-Centric Design**: Business logic lives in the root package, free from external dependencies
2. **Dependency Injection**: Infrastructure implementations are injected, not imported
3. **Interface-Driven**: All external dependencies are accessed through interfaces
4. **Test-First Development**: TDD is mandatory for all features

## Package Organization

### Domain Layer (Root Package)
The root package contains only:
- Domain types (entities, value objects)
- Business interfaces
- Domain errors
- Pure business logic

Example structure:
```go
// user.go - Domain entity
type User struct {
    ID        string
    Email     string
    Name      string
    CreatedAt time.Time
}

// interfaces.go - Service interfaces
type UserService interface {
    CreateUser(ctx context.Context, user *User) error
    GetUser(ctx context.Context, id string) (*User, error)
}

// errors.go - Domain errors
const (
    ENOTFOUND = "not_found"
    EINVALID  = "invalid"
    EINTERNAL = "internal"
)
```

### Infrastructure Layer (Subpackages)
Each external dependency gets its own package:
- `postgres/` - PostgreSQL implementations
- `http/` - HTTP handlers and middleware
- `redis/` - Redis cache implementations
- `email/` - Email service implementations
- `config/` - Configuration management

### Cross-Cutting Concerns
- `mock/` - Manual behavioral mocks for testing
- `cmd/` - Application entry points

## Dependency Flow

```
cmd/server/main.go
    ↓ imports
http/ package
    ↓ imports
domain types & interfaces (root)
    ↑ implements
postgres/ package
```

Dependencies always flow inward - infrastructure depends on domain, never the reverse.

## Key Architectural Decisions

### Interface Segregation
- Small, focused interfaces
- Clients depend only on methods they use
- Easy to mock and test

### Manual Dependency Injection
- No DI frameworks or magic
- Explicit wiring in main()
- Clear, debuggable initialization

### Database Strategy
- Direct SQL queries, no ORM
- Schema-based test isolation
- Migrations managed separately

### Error Handling
- Domain errors at the root
- Infrastructure errors translated at boundaries
- Consistent error codes across layers

### Testing Strategy
- Unit tests with mocks
- Integration tests with real infrastructure
- Parallel tests with proper isolation
- Build tags for test categories

## Example Implementation Pattern

### 1. Define Domain Interface
```go
// In root package
type UserService interface {
    CreateUser(ctx context.Context, user *User) error
    GetUser(ctx context.Context, id string) (*User, error)
}
```

### 2. Implement in Infrastructure
```go
// In postgres/user_service.go
type UserService struct {
    db *sql.DB
}

// Compile-time check
var _ myapp.UserService = (*UserService)(nil)

func (s *UserService) CreateUser(ctx context.Context, user *myapp.User) error {
    // Implementation
}
```

### 3. Wire in Main
```go
// In cmd/server/main.go
func main() {
    db, _ := sql.Open("postgres", dsn)
    
    userService := &postgres.UserService{DB: db}
    
    server := &http.Server{
        UserService: userService,
    }
    
    server.Start()
}
```

### 4. Test with Mocks
```go
// In tests
mockUserService := &mock.UserService{
    CreateUserFunc: func(ctx context.Context, user *myapp.User) error {
        return nil
    },
}
```

## Benefits of This Architecture

1. **Testability**: Easy to mock dependencies
2. **Flexibility**: Swap implementations without changing business logic
3. **Clarity**: Clear separation of concerns
4. **Maintainability**: Changes isolated to specific layers
5. **Onboarding**: New developers understand structure quickly

## Common Patterns

### Repository Pattern
- One repository per aggregate root
- Methods return domain types, not database rows
- Transaction support through context

### Service Pattern
- Orchestrate multiple repositories
- Implement business workflows
- Handle cross-cutting concerns

### Factory Pattern
- Create complex domain objects
- Validate business rules
- Ensure invariants

## Anti-Patterns to Avoid

1. **Import Cycles**: Domain importing infrastructure
2. **Leaky Abstractions**: Database details in interfaces
3. **God Objects**: Overly large interfaces
4. **Anemic Domain**: Logic in wrong layer
5. **Framework Lock-in**: Business logic coupled to frameworks

## Migration Guide

When adopting this pattern in existing projects:
1. Start with new features
2. Extract interfaces gradually
3. Move implementations to subpackages
4. Update tests incrementally
5. Refactor main() last

This architecture has proven effective across various domains and scales well from small services to large applications.