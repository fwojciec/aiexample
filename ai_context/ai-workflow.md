# AI Workflow Quick Reference

## Context Loading Strategy

When working with AI on this project:

1. **Start with CLAUDE.md** - Core rules and guidelines
2. **Load context as needed** from `ai_context/`:
   - `architecture.md` - System design decisions
   - `backend-conventions.md` - Go implementation patterns
   - `infrastructure.md` - OpenTofu/Terraform and deployment
   - `testing.md` - Testing requirements
   - `issue-management.md` - GitHub workflow

## AI Development Process

1. **Issue Creation** → Use templates with AI-ready markers
2. **Implementation** → Follow conventions in context files
3. **Validation** → Run `make validate` before EVERY commit
4. **Code Review** → Apply safety checklist from AI-DEVELOPMENT.md
5. **PR Creation** → Ensure `make validate` passes locally first

## Key Labels

- `ai-ready` - Issue has sufficient context
- `needs-human-review` - Requires human verification

For detailed workflow and safety checklists, see AI-DEVELOPMENT.md