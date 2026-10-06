---
command: pr:review:ci
description: Request Claude GitHub Action review on PR and summarize results (for CI pipelines)
---

# Review PR with Claude (CI Pipeline)

Requests a comprehensive PR review from Claude via GitHub Actions and summarizes the results. Designed for use in CI pipelines.

## Arguments

- `$ARGUMENTS` - PR number (optional, defaults to current branch's PR)

## Execution Steps

1. **Determine PR Number**
   - If argument provided, use it
   - Otherwise, get PR number from current branch: `gh pr view --json number -q '.number'`

2. **Add Review Request Comment**
   ```bash
   gh pr comment <PR_NUMBER> --body "@claude review the entire PR, propose cleanups and improvements"
   ```

3. **Wait for Claude's Response**
   - Wait 3 minutes for Claude GitHub Action to process
   - Poll for new comments

4. **Retrieve and Summarize Results**
   - Get the latest comment from the PR
   - Extract cleanups and improvements
   - Summarize by priority (P1 = critical, P2 = nice-to-have, P3 = future)

## Output Format

```markdown
## PR Review Summary

**PR:** #<number> - <title>
**Review Status:** Complete/Pending

### Cleanups & Improvements (by priority)

| Priority | Issue | Location |
|----------|-------|----------|
| P1 | ... | ... |
| P2 | ... | ... |
| P3 | ... | ... |

### Recommendation
- [ ] Address P1 items before merge
- [ ] P2 items are optional
```

## Example Usage

```bash
# Review current branch's PR
/pr:review:ci

# Review specific PR
/pr:review:ci 42
```
