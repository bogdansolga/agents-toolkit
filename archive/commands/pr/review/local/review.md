---
command: pr:review:local
description: Dispatch a local agent to perform code review on current branch changes
---

# Local PR Review Agent

Dispatches a background agent to perform a comprehensive code review on all changes in the current branch (committed and staged) against the base branch.

## Arguments

- `$ARGUMENTS` - Base branch to compare against (optional, defaults to main/master)

## Execution Steps

1. **Dispatch Review Agent**
   Use the Task tool to spawn a review agent with `subagent_type: "superpowers:code-reviewer"`:

   ```
   Task tool parameters:
   - subagent_type: "superpowers:code-reviewer"
   - description: "Review branch changes"
   - prompt: |
       Review all changes in the current branch against the base branch.

       ## Context Gathering
       1. Get current branch: `git rev-parse --abbrev-ref HEAD`
       2. Determine base branch (main or master)
       3. Get commit list: `git log <base>..HEAD --oneline`
       4. Get full diff: `git diff <base>...HEAD`
       5. Get staged changes: `git diff --staged`
       6. Check for CLAUDE.md project conventions

       ## Review Focus
       - Security vulnerabilities (SQL injection, XSS, auth bypass, credential exposure)
       - Logic errors and bugs (null handling, error cases, edge cases)
       - Type safety (any usage, unsafe type assertions, missing validations)
       - Performance concerns (N+1 queries, inefficient algorithms)
       - Missing tests for new/changed behavior
       - Code clarity and maintainability

       ## Anti-Patterns to Flag
       - Credentials or secrets in code
       - Disabled security features
       - Silent error swallowing (empty catch blocks)
       - Commented-out code without explanation
       - TODOs without tickets or context
       - Overly complex functions (>50 lines)

       Provide succinct, actionable feedback grouped by severity.
   ```

2. **Agent Executes Review**
   The agent autonomously:
   - Gathers branch context and diffs
   - Analyzes changes against review criteria
   - Checks project conventions if CLAUDE.md exists
   - Generates findings grouped by severity

3. **Report Results**
   Present the agent's findings to the user.

## Output Format

```markdown
## Code Review: {branch-name}

### Summary
{1-2 sentence overview of changes and general assessment}

### Findings

#### Critical Issues
- **{file}:{line}** - {issue}: {actionable fix}

#### Important Issues
- **{file}:{line}** - {issue}: {actionable fix}

#### Minor Suggestions
- **{file}:{line}** - {issue}: {actionable fix}

### Recommendation
{APPROVE | REQUEST CHANGES | COMMENT} - {brief rationale}
```

## Example Usage

```bash
# Review against default base branch (main/master)
/pr:review:local

# Review against specific base branch
/pr:review:local develop
```
