# Sync Branch with Main

Sync current branch with main/master, handling conflicts gracefully.

## Execution Steps

1. **Detect Base Branch**
   - Run `git branch -l main master` to check which exists
   - Use `main` if both exist, otherwise use whichever exists

2. **Fetch Latest**
   - Run `git fetch origin`

3. **Check Current State**
   - Run `git status --porcelain` to check for uncommitted changes
   - If dirty working tree:
     - Show changed files
     - Ask: stash changes, commit first, or abort?
     - If stash: `git stash push -m "auto-stash before sync"`

4. **Rebase on Base**
   - Run `git rebase origin/{base}`
   - If conflicts occur:
     - Show conflicting files with `git diff --name-only --diff-filter=U`
     - Ask: help resolve, abort rebase, or skip commit?
     - If abort: `git rebase --abort`

5. **Restore Stash (if applicable)**
   - If changes were stashed: `git stash pop`
   - Handle stash conflicts if any

6. **Report Result**
   - Show commits integrated: `git log HEAD@{1}..HEAD --oneline`
   - Confirm branch state

## Output Format

```markdown
Branch: feature/my-feature
Base: main

Fetching origin...
Rebasing on origin/main...

✓ Synced successfully

Commits integrated:
  abc1234 feat: add new API endpoint
  def5678 fix: resolve auth issue

Current status: Up to date with origin/main
```

## Error Handling

### Uncommitted Changes
```
⚠ Uncommitted changes detected:
  M src/api/route.ts
  A src/lib/utils.ts

Options:
1. Stash changes and continue
2. Abort sync (commit changes first)
```

### Rebase Conflicts
```
⚠ Conflicts detected during rebase:
  - src/api/route.ts

Options:
1. Show conflicts and help resolve
2. Abort rebase (restore original state)
3. Skip this commit
```
