# AI-Driven Development Guide

This guide explains the workflow and process for AI-assisted development on Go projects using this example architecture.

## Overview

This repository is optimized for AI-assisted development with structured issues, clear labeling conventions, and safety checklists to ensure high-quality AI contributions.

## Getting Started with AI Development

1. **Technical Context**: Find all technical documentation in `ai_context/`
2. **Development Rules**: Start with `CLAUDE.md` for core guidelines
3. **Issue Templates**: Use `.github/ISSUE_TEMPLATE/` for structured problems

## Writing AI-Friendly Issues

### Use Our Templates
Always use the issue templates in `.github/ISSUE_TEMPLATE/`. They include:
- Structured sections for clear problem definition
- Success criteria for measurable outcomes
- Technical considerations for implementation hints
- AI-friendly markers for tool parsing

### Example Good Issue
```markdown
## Problem Statement
The user search API returns all users when no search term is provided, 
causing performance issues with large datasets.

## Success Criteria
- [ ] Empty search returns paginated results (max 20 items)
- [ ] API includes total count in response
- [ ] Tests cover pagination edge cases
- [ ] Response time < 200ms for default page size

## Context
- Current implementation: postgres/user_service.go:45
- API endpoint: /api/users/search
- Related issue: #23 (performance improvements)
```

### AI-Ready Markers
Add these HTML comments at the bottom of issues:
- `<!-- ai-ready: yes -->` - Issue is ready for AI implementation
- `<!-- complexity: small|medium|large -->` - Estimated complexity
- `<!-- priority: low|medium|high -->` - Implementation priority

## Working with AI Assistants

### 1. Provide Context
When starting a session, point the AI to:
- The specific issue you're working on
- Relevant documentation (CLAUDE.md, architecture.md)
- Related code files or packages

### 2. Clear Instructions
- Be specific about what you want
- Reference the coding conventions
- Mention testing requirements
- Specify any constraints

### 3. Review Generated Code
AI-generated code must be reviewed for:
- **Correctness**: Does it solve the problem?
- **Conventions**: Does it follow our patterns?
- **Security**: No hardcoded secrets or vulnerabilities?
- **Testing**: Are tests included and comprehensive?
- **Documentation**: Are comments and docs updated?

## Labeling Convention

### For Issues
- `ai-ready` - Issue has enough context for AI implementation
- `ai-in-progress` - AI is currently working on this
- `needs-human-review` - AI implementation needs review

### For Pull Requests
- `ai-assisted` - Human-led with AI assistance
- `security-review-needed` - Requires security-focused review

## CI/CD for AI-Generated Code

Since all code in this repository is AI-generated, we use a unified CI workflow (`.github/workflows/ci.yml`) that automatically runs on every PR with:
- Fast-fail checks first (formatting, vetting, go mod tidy)
- Parallel execution of security, linting, and testing for speed
- Security scanning (gosec, govulncheck)
- Test coverage enforcement (40% minimum - pragmatic for current state)
- Sensitive data detection (excludes infrastructure/ to avoid false positives)
- Error handling validation (only checks changed files in PRs)

No special labeling is required - all PRs get comprehensive validation suitable for AI-generated code. Branch protection only requires the `CI / CI Status` check to pass.

## Safety Checklist for AI Code

Before merging AI-generated code:

- [ ] **Validation**
  - Run `make validate` - all checks must pass
  - No formatting changes needed
  - No linting issues
  - All tests pass
  - Dependencies are clean

- [ ] **Code Quality**
  - Follows project conventions (see CLAUDE.md)
  - Proper error handling with context
  - No code duplication
  - Clear variable and function names

- [ ] **Testing**
  - Unit tests for new functionality
  - Integration tests where appropriate
  - Edge cases covered
  - Coverage > 80%

- [ ] **Security**
  - No hardcoded credentials
  - Input validation implemented
  - SQL injection prevention (prepared statements)
  - No sensitive data in logs

- [ ] **Documentation**
  - Function comments updated
  - README updated if needed
  - Architecture docs updated for significant changes
  - API documentation current

## Workflow Example

1. **Create Issue**
   ```bash
   # Use GitHub UI or CLI to create issue with template
   gh issue create --template feature-request.md
   ```

2. **Prepare for AI**
   - Add `ai-ready` label when issue has sufficient detail
   - Include links to relevant code and documentation

3. **AI Implementation**
   - Provide issue link to AI assistant
   - Reference CLAUDE.md and relevant context files
   - Ask AI to create implementation following our patterns
   - Ensure AI runs `make validate` before committing

4. **Validate Locally**
   ```bash
   make validate  # Run before creating PR
   ```
   
5. **Create PR**
   - Ensure PR template checklist is completed
   - Link to original issue

6. **Automated Validation**
   - CI workflow runs automatically with comprehensive security and quality checks
   - Review workflow results for any failures

7. **Human Review**
   - Review for business logic correctness
   - Verify integration points
   - Check for edge cases AI might have missed

8. **Merge**
   - All checks pass
   - Human approval received
   - Squash and merge to maintain clean history

## Best Practices

### DO:
- Provide clear, unambiguous requirements
- Include examples in issues when helpful
- Review AI code as carefully as human code
- Update context files when patterns change
- Use AI for repetitive tasks and boilerplate

### DON'T:
- Accept AI code without review
- Let AI make architectural decisions alone
- Skip tests because "AI wrote them"
- Assume AI understands implicit requirements
- Use AI for security-critical code without extra scrutiny

## Getting Help

- For AI tool questions: See tool-specific documentation
- For project questions: Check CLAUDE.md first
- For process questions: Open a discussion issue

## Future Enhancements

As we gain experience with AI-driven development, we plan to:
1. Add automated issue assignment to AI agents
2. Implement MCP servers for specialized tasks
3. Create AI-specific development metrics
4. Build custom tools for AI code review

This is a living document. Please propose improvements based on your experience!