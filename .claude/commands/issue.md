You are helping to start work on issue #$ARGUMENTS in the bookscanner repository. Follow these steps systematically to set up the development environment and create a comprehensive implementation plan.

## Step 1: Verify Git Status
First, check for any uncommitted changes that might interfere with branch operations:
- Use `git status --porcelain` to check for uncommitted changes
- If changes exist, stop and inform the user they need to commit or stash changes first
- Only proceed if the working directory is clean

## Step 2: Update Default Branch
Ensure you're working from the latest default branch:
- Execute `git checkout main` to switch to the default branch
- Execute `git pull origin main` to fetch the latest changes
- Handle any errors (e.g., merge conflicts) by informing the user

## Step 3: Fetch Issue Details
Retrieve comprehensive issue information from GitHub:
- Use `mcp__github__get_issue` with owner="fwojciec", repo="bookscanner", issue_number=$ARGUMENTS
- Extract: title, description, labels, and any linked issues
- Pay special attention to:
  - Problem Statement section
  - Success Criteria checklist
  - Technical Requirements
  - Context and references
  - AI-ready markers and complexity indicators
  - Any comments on the issue that provide additional context

## Step 4: Create Feature Branch
Create a branch following the repository's simplified naming convention:
- Use format: `issue-$ARGUMENTS`
- Example: for issue #17, create `issue-17`
- Execute `git checkout -b issue-$ARGUMENTS`

## Step 5: Analyze Relevant Code
Based on issue context, investigate the codebase:
- Use Grep/Glob to find files mentioned in the issue
- Read key files to understand current implementation
- Check CLAUDE.md and ai_context/ files for relevant patterns
- Look for similar implementations to maintain consistency
- If the issue mentions specific files/packages, read them thoroughly

## Step 6: Create Implementation Plan
Generate a detailed plan including:

1. **Problem Summary**: Concise restatement of what needs to be solved
2. **Affected Components**: List all files/packages that need modification
3. **Implementation Strategy**:
   - Step-by-step approach following TDD principles
   - Start with failing tests
   - Implement to pass tests
   - Follow Ben Johnson's architecture patterns
4. **Test Plan**: Specific test cases to implement
5. **Validation Steps**: How to verify the implementation works
6. **Potential Challenges**: Any complexities or edge cases to consider

## Step 7: Set Up Task Tracking
Use TodoWrite to create a task list:
- Break down the implementation into concrete, actionable tasks
- Include test writing as the first task (TDD approach)
- Add tasks for code formatting and validation checks
- Structure tasks to enable incremental progress

## Important Guidelines:
- Always follow the TDD approach mandated by CLAUDE.md
- Respect the architecture patterns in ai_context/architecture.md
- If any step fails, provide clear error messages and stop
- After presenting the plan, wait for user approval before implementation
- Include relevant code references using the format: `file_path:line_number`

Begin by checking the current git status.
