# Cleanup Merged Branches

Delete local branches that have been merged to main/master.

## Execution Steps

1. **Detect Base Branch**
   - Run `git branch -l main master` to check which exists
   - Use `main` if both exist

2. **Ensure Base is Current**
   - Run `git checkout {base}` if not already on base
   - Run `git pull` to get latest

3. **Find Merged Branches**
   - Run `git branch --merged {base}` to list merged branches
   - Filter out:
     - `main`, `master` (base branches)
     - Current branch (if different)
     - Any branch starting with `*`

4. **Find Stale Remote-Tracking Branches**
   - Run `git remote prune origin --dry-run` to find stale refs

5. **Confirm Deletion**
   - List branches to delete with last commit date
   - Ask for confirmation

6. **Delete Branches**
   - Run `git branch -d {branch}` for each local branch
   - Run `git remote prune origin` to clean remote refs

7. **Report Results**
   - Show deleted branches
   - Show any branches that couldn't be deleted

## Output Format

```markdown
Base: main

Merged local branches:
  - feature/auth-improvements (merged 3 days ago)
  - fix/null-check (merged 1 week ago)
  - chore/deps-update (merged 2 weeks ago)

Stale remote refs:
  - origin/feature/old-feature

Delete these branches? [y/N] y

✓ Deleted 3 local branches
✓ Pruned 1 remote ref
```

## Options

- Default: ask for confirmation
- `--dry-run`: show what would be deleted without deleting
- `--force`: delete without confirmation

## Notes

- Uses `git branch -d` (safe delete) - won't delete unmerged branches
- If a branch fails to delete, shows error and continues with others
- Does not delete remote branches, only local and stale refs
