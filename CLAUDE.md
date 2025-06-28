# Claude Development Guidelines for Go Projects

## Quick Reference
- **Architecture**: Ben Johnson's Standard Package Layout - see ai_context/architecture.md
- **Language**: Go 1.24+ 
- **Database**: PostgreSQL with schema-based test isolation
- **Required**: TDD approach for all features

## Essential Development Rules

1. **Test-Driven Development is MANDATORY**
   - Write failing tests first using **testify** library (assert/require)
   - Implement to pass tests
   - If unclear on correctness criteria, ASK
   - Use `require` for setup that must succeed, `assert` for test conditions
   - **Test Package Naming**: Use `_test` package suffix (e.g., `package mypackage_test`) to enforce testing through public APIs only

2. **Before EVERY Commit**
   ```bash
   make validate
   ```
   This runs: formatting, vetting, tests, module tidying, linting, and workflow linting.

3. **Working with Docker Environment**
   Ensure PostgreSQL is running before running tests:
   ```bash
   make dev-up                # Start PostgreSQL
   go test ./...              # Run tests directly
   make validate              # Run all validation
   ```
   All commands can be run directly without any wrapper.

4. **Essential Make Commands**
   ```bash
   make dev-up                # Start Docker PostgreSQL
   make dev-down              # Stop Docker PostgreSQL
   make validate              # Run all checks before committing
   make lint-workflows        # Lint GitHub Actions workflow files
   make test TAGS=integration RACE=1  # Run ALL integration tests with race detector
   make server-start          # Start server in background
   make server-stop           # Stop background server
   make server-logs           # Tail server logs
   ```

5. **Branch Naming Convention**
   Use this pattern for all development:
   ```bash
   git checkout -b issue-123  # For issue #123
   ```
   - **Current pattern**: `issue-{number}` (e.g., `issue-119`)
   - **Claude commands**: `/issue`, `/pr`, `/comments`, `/ci-investigate` all expect this pattern

6. **Domain Purity**
   - Root package: domain types only
   - No infrastructure imports in domain
   - Dependencies flow inward

## Context Files

For detailed information, these files will be loaded as needed:

- **Go Conventions**: ai_context/backend-conventions.md
- **Go Style Guide**: @ai_context/go-style-guide.md
- **Architecture Details**: ai_context/architecture.md
- **Testing Standards**: ai_context/testing.md
- **AI Development**: AI-DEVELOPMENT.md
- **Issue Management**: ai_context/issue-management.md
- **Database Setup**: ai_context/database-setup.md
- **CI/CD Workflows**: ai_context/cicd-workflows.md

## Task-Specific References

When working on:
- **New features**: Include ai_context/backend-conventions.md and ai_context/go-style-guide.md
- **Bug fixes**: Include relevant package docs
- **Infrastructure**: Include ai_context/infrastructure.md
- **Tests**: Include ai_context/testing.md and ai_context/database-setup.md
- **GitHub issues**: Include ai_context/issue-management.md
- **Database/PostgreSQL**: Include ai_context/database-setup.md
- **CI/CD and deployments**: Include ai_context/cicd-workflows.md
- **Go code style**: Include ai_context/go-style-guide.md

## Example Package Layout (Ben Johnson's Standard Pattern)
```
myproject/
├── *.go                    # Domain types and interfaces only
├── mock/                   # Manual mocks for testing
├── postgres/               # PostgreSQL implementations
├── http/                   # HTTP handlers and middleware
├── cmd/                    # Application entry points
│   └── server/             # Main server application
├── internal/               # Private application code
└── config/                 # Configuration management
```

This follows Ben Johnson's Standard Package Layout where:
- Root package contains pure domain types
- Subpackages implement interfaces
- Dependencies flow inward (infrastructure depends on domain)

For full architectural details, see ai_context/architecture.md
