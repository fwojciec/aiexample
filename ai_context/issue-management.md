# Issue Management for Solo Dev + LLM Workflow

## Overview

This document defines a minimal, efficient issue management system optimized for a solo developer using LLM agents (like Claude Code) to write all code. The system prioritizes clarity, context, and automation over complex workflows.

## Label System

### Stage Labels (Required)
Track where each issue is in your workflow:

- `stage:idea` - Rough thoughts, needs refinement before LLM can work on it
- `stage:ready` - Clear requirements, LLM can start implementation
- `stage:active` - LLM currently working on this issue
- `stage:done` - Completed, may need human review

### Context Labels (As Needed)
Indicate how much information is available:

- `context:minimal` - LLM can figure out requirements from issue title/description
- `context:detailed` - Needs specific requirements spelled out
- `context:blocked` - Missing critical info or has unresolved dependencies

### Size Labels (Optional)
Estimate LLM session length:

- `size:quick` - Can be done in a single LLM response
- `size:session` - Requires one full conversation
- `size:multi` - Needs multiple sessions or complex coordination
- `size:epic` - Large feature requiring multiple sub-tasks

## Issue Templates

### Standard Issue Format
```markdown
## What needs to be done
[Clear, specific description of the desired outcome]

## Context
- Related files: [List specific files if relevant]
- Dependencies: [Other issues or external factors]
- Constraints: [Technical or business constraints]

## Success criteria
- [ ] Specific, testable outcome 1
- [ ] Specific, testable outcome 2
- [ ] Tests pass
- [ ] No linting errors

<!-- llm:ready -->
```

### Quick Idea Capture
For `stage:idea` issues, just write a title. You'll add details later when moving to `stage:ready`.

## Workflow

### 1. Capture Ideas
Create issues with minimal info and `stage:idea` label. Don't overthink it.

### 2. Refine for LLM
When ready to implement:
- Add context and success criteria
- Move from `stage:idea` to `stage:ready`
- Remove `context:blocked` if previously blocked

### 3. LLM Implementation
When Claude Code starts work:
- Auto-label as `stage:active`
- Create feature branch
- Implement solution
- Run tests
- Create PR

### 4. Completion
When PR is created:
- Auto-label as `stage:done`
- Human reviews and merges
- Close issue after merge

## LLM Agent Commands

### Daily Planning
```
"What should I work on?"
```
Lists all `stage:ready` issues, oldest first, excluding any with `context:blocked`.

### Start Work
```
"Work on issue #42"
```
1. Validates issue has `stage:ready` label
2. Updates to `stage:active`
3. Reads all context and related files
4. Implements solution
5. Creates PR with implementation

### Check Blockers
```
"What's blocking progress?"
```
Shows all issues with `context:blocked` label with their descriptions.

### Add Context
```
"This issue needs more context"
```
Adds `context:detailed` label and comments asking for specific missing information.

### Weekly Cleanup
```
"Clean up completed work"
```
Lists `stage:done` issues older than 7 days for review and closure.

## Best Practices

### For the Human (You)

1. **Brain dump freely** - Create `stage:idea` issues whenever you think of something
2. **Batch refinement** - Set aside time to move ideas to ready state
3. **Clear success criteria** - LLMs work best with specific, testable goals
4. **Reference files** - Always mention specific files when relevant

### For the LLM

1. **Check labels first** - Ensure issue is `stage:ready` before starting
2. **Update labels immediately** - Mark as `stage:active` when beginning work
3. **Create atomic PRs** - One issue = one PR
4. **Run all checks** - Always run tests and linting before creating PR
5. **Reference issue** - Always link PR to issue with "Fixes #X"

## Label Colors (GitHub)

When creating these labels in GitHub, use these colors for visual clarity:

- Stage labels: Blue (#0052CC)
- Context labels: Yellow (#FFA500)
- Size labels: Green (#00875A)

## Epic Issue Management

When creating multiple related issues tracked by an epic:

### Epic Issue Requirements
1. **Title format**: `[EPIC] <descriptive title>`
2. **Labels**: `size:epic`, `stage:idea` (epics are never "ready")
3. **Body must include**:
   - Overview section explaining the epic's goal
   - Migration Tasks section with checkboxes linking to ALL sub-issues
   - Success criteria for the entire epic
   - Format: `- [ ] #123 - Brief description of task`

### Creating Epic with Sub-tasks
1. **Create the epic issue first** with placeholder tasks
2. **Create individual task issues** with:
   - Reference to epic: "Part of epic #XXX"
   - Clear dependencies on other tasks
   - Appropriate stage labels (`stage:ready` if actionable)
3. **Update the epic** with direct links to all created issues
4. **Important**: Epic body MUST contain direct links to all sub-issues for easy tracking

### Example Epic Structure
```markdown
## Epic Overview
Brief description of the overall goal

## Migration Tasks
- [ ] #206 - Set up authentication
- [ ] #207 - Implement core feature
- [ ] #208 - Add configuration options
- [ ] #209 - Deploy and monitor
- [ ] #210 - Complete migration

## Success Criteria
- [ ] All sub-tasks completed
- [ ] Integration tests pass
- [ ] Documentation updated
```

## Migration from Current System

To adopt this system:

1. Create the new labels in your repository
2. Archive or delete unused labels
3. Bulk update existing issues:
   - Open issues → `stage:ready` or `stage:idea`
   - Closed issues → can be ignored
4. Update CLAUDE.md to reference this guide

## Example Issue Lifecycle

```
1. Human: "Need to add pagination to book search"
   → Creates issue #45 with `stage:idea`

2. Human (later): "Let me add details to #45"
   → Adds context, success criteria
   → Changes label to `stage:ready`

3. LLM: "Work on issue #45"
   → Changes label to `stage:active`
   → Implements pagination
   → Creates PR #46
   → Changes label to `stage:done`

4. Human: Reviews PR, merges, closes issue
```

## Automation Opportunities

Future enhancements could include:

1. GitHub Actions to auto-label based on issue content
2. Scheduled jobs to remind about stale `stage:idea` issues
3. Auto-close `stage:done` issues after PR merge
4. Weekly digest of completed work

Keep the system simple. The goal is to reduce friction between your ideas and LLM implementation, not to create process overhead.