---
description: Investigate and resolve CI failures with structured analysis and actionable fixes
---

You are helping to investigate CI failures in the bookscanner repository. This command guides you through systematic diagnosis and resolution of CI issues, leveraging enhanced structured output for efficient problem-solving.

## Core Principles

When investigating CI failures:

1. **Systematic Approach**: Follow a structured investigation process
2. **Root Cause Analysis**: Identify the real issue, not just symptoms
3. **Actionable Solutions**: Provide specific, testable fixes
4. **Local Validation**: Always verify fixes work before pushing

## Step 1: Identify the Context

First, determine which PR we're investigating:

```bash
# Check current branch
current_branch=$(git branch --show-current)
echo "Current branch: $current_branch"

# Extract issue/PR number from branch name
if [[ "$current_branch" =~ ^issue-([0-9]+)$ ]]; then
    issue_number="${BASH_REMATCH[1]}"
    echo "Detected issue #$issue_number"
    # Find PR associated with this issue branch
    pr_number=$(gh pr list --head "$current_branch" --json number -q ".[0].number" 2>/dev/null)
elif [[ "$current_branch" =~ ^feature/issue-([0-9]+) ]]; then
    # Backwards compatibility for old pattern
    issue_number="${BASH_REMATCH[1]}"
    echo "Detected issue #$issue_number (legacy branch pattern)"
    pr_number=$(gh pr list --head "$current_branch" --json number -q ".[0].number" 2>/dev/null)
else
    # Try to get PR number directly
    pr_number=$(gh pr status --json number,headRefName -q ".currentBranch.number" 2>/dev/null)
fi

if [[ -z "$pr_number" ]]; then
    echo "ERROR: Cannot determine PR number"
    echo "Please ensure you have an open PR for the current branch"
    exit 1
fi

echo "Investigating CI failures for PR #$pr_number"
```

## Step 2: Get PR and CI Status Overview

Retrieve comprehensive PR information:

```bash
# Get PR details
gh pr view $pr_number --json title,author,headRefName,commits

# Check CI status
gh pr checks $pr_number --repo fwojciec/bookscanner

# Get detailed check runs
gh api /repos/fwojciec/bookscanner/commits/HEAD/check-runs \
  --jq '.check_runs[] | {name: .name, status: .status, conclusion: .conclusion}'
```

Key jobs to monitor:
- **Quick Check**: formatting, go vet, go mod tidy
- **Security**: gosec, govulncheck
- **Lint**: golangci-lint, error handling
- **Test**: unit tests, coverage
- **CI Status**: overall summary

## Step 3: Analyze Enhanced CI Output

The CI provides LLM-friendly structured output. Look for:

### GitHub Actions Annotations
```bash
# Extract structured errors from logs
gh run view <RUN_ID> --repo fwojciec/bookscanner --log | \
  grep -E "::error|::warning|::notice"
```

Annotation patterns:
- `::error title=<category>::<message>` - Critical failures
- `::error file=<path>,line=<num>::<message>` - File-specific issues
- `::warning title=<category>::<message>` - Non-blocking issues

### Error Categories
Common categories and their fixes:
- **FORMAT_ERROR**: Run `go fmt ./...`
- **MODULE_ERROR**: Run `go mod tidy`
- **COVERAGE_LOW**: Add tests for uncovered code
- **ERROR_HANDLING**: Wrap errors with context
- **SECURITY_ALERT**: Review and fix vulnerabilities
- **LINT_ERROR**: Address code quality issues
- **TEST_FAILURE**: Fix failing tests

## Step 4: Deep Dive into Failures

For each failed job:

### 4.1 Get Detailed Logs
```bash
# View specific job logs
gh run view <RUN_ID> --job <JOB_ID> --log

# Look for CI Pipeline Summary
gh run view <RUN_ID> --log | grep -A20 "CI Pipeline Summary"
```

### 4.2 Download Test Artifacts
```bash
# List available artifacts
gh api /repos/fwojciec/bookscanner/actions/runs/<RUN_ID>/artifacts

# Download test results
gh run download <RUN_ID> --name test-results
```

Artifacts include:
- `test-results.json` - Machine-readable test output
- `junit-report.xml` - JUnit format results
- `coverage.out` - Coverage data

### 4.3 Parse Structured Output
Look for:
- Job summary tables with metrics
- Test result counts and failures
- Coverage percentages
- Specific file:line error locations

## Step 5: Correlate with Code Changes

Understand what changed and how it relates to failures:

```bash
# Get changed files in PR
gh pr diff $pr_number --name-only

# View specific file changes
gh pr diff $pr_number -- <file_path>
```

Match failures to changes:
- Formatting errors → Modified Go files
- Coverage drop → New untested code
- Lint errors → Changed code patterns
- Test failures → Implementation or test changes

## Step 6: Generate Fix Strategy

Based on the analysis, create a fix plan:

### Quick Fixes (Automated)
```bash
# 1. Fix formatting
go fmt ./...

# 2. Tidy modules
go mod tidy

# 3. Auto-fix some lint issues
golangci-lint run --fix

# 4. Validate all fixes locally
make validate
```

### Code Changes Required
For issues requiring manual intervention:

1. **Test Coverage**:
   - Identify specific uncovered lines
   - Write tests following TDD principles
   - Reference patterns in CLAUDE.md

2. **Error Handling**:
   - Wrap errors with context
   - Follow patterns in ai_context/backend-conventions.md

3. **Security Issues**:
   - Understand the vulnerability
   - Implement secure alternative
   - Add tests for security scenarios

## Step 7: Implement and Validate Fixes

Execute the fix strategy:

```bash
# Apply automated fixes
go fmt ./...
go mod tidy

# Commit formatting/module fixes separately
git add -u
git commit -m "fix: address formatting and module tidiness"

# Make code changes for other issues
# ... implement fixes ...

# Validate everything locally
make validate

# If validation passes, push changes
git push
```

## Step 8: Document the Resolution

Create a comment on the PR explaining what was fixed:

```markdown
## CI Fixes Applied

Resolved the following CI failures:

### Automated Fixes
- ✅ Fixed formatting issues in 3 files
- ✅ Updated go.mod with `go mod tidy`

### Code Changes
- ✅ Added error wrapping in scanner/ocr.go:45-47
- ✅ Increased test coverage from 75% to 82%:
  - Added test for Vision API error case
  - Added test for timeout scenario
- ✅ Fixed lint warning about unused variable

All fixes validated locally with `make validate` passing.
```

## Investigation Patterns

### Pattern: Multiple Small Issues
Often CI fails due to several minor issues:
1. Run all automated fixes first
2. Commit those separately
3. Address remaining issues one by one
4. Validate after each fix

### Pattern: Cascading Failures
One issue causing multiple job failures:
1. Identify the root cause (often in Quick Check)
2. Fix that first
3. Re-run CI to see what remains

### Pattern: Environment-Specific Failures
CI passes locally but fails in GitHub:
1. Check for missing environment variables
2. Verify all dependencies are committed
3. Look for platform-specific code

## Quick Reference Commands

```bash
# View PR checks status
gh pr checks $pr_number

# Get failed job details
gh run list --workflow=ci.yml --limit 1 --json databaseId,status,conclusion

# Extract errors from logs
gh run view <RUN_ID> --log | grep -E "::error"

# Download all artifacts
gh run download <RUN_ID>

# Re-run failed jobs
gh run rerun <RUN_ID> --failed
```

## Important Notes

- Always run `make validate` locally before pushing fixes
- Group related fixes in logical commits
- If CI is still failing after fixes, investigate deeper - don't just retry
- For complex failures, consider breaking into smaller PRs
- Document any non-obvious fixes for future reference

Remember: CI failures are often simple issues with simple fixes. Start with the automated solutions before diving into complex debugging.
