# Context System for AI-Driven Development

This directory contains structured context files that help AI agents understand the codebase architecture, conventions, and design decisions. These files complement the `CLAUDE.md` at the project root.

## Structure

- `ai-workflow.md` - AI development process quick reference
- `architecture.md` - High-level system design and architectural decisions
- `backend-conventions.md` - Go-specific coding patterns and conventions
- `frontend-conventions.md` - TypeScript patterns (future)
- `infrastructure.md` - OpenTofu/Terraform infrastructure patterns and conventions
- `testing.md` - Testing strategies and patterns
- `issue-management.md` - GitHub issue management workflow

## Purpose

These context files serve as:
1. **Living documentation** that evolves with the codebase
2. **AI-readable reference** for consistent code generation
3. **Onboarding material** for new developers (human or AI)

## Guidelines

- Keep files concise and focused
- Update when making significant architectural changes
- Use clear, unambiguous language
- Include examples where helpful
- Reference specific code locations when relevant

## Integration with CLAUDE.md

While `CLAUDE.md` contains project-specific instructions and guidelines, the `ai_context/` directory provides:
- Architectural context
- Language-specific patterns
- Design rationale
- Technical constraints

Together, they form a comprehensive knowledge base for AI-assisted development.