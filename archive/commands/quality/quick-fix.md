---
command: quality:quick-fix
description: Quick implementation of small fixes without heavy workflow
---

## Description

Implements small bug fixes, typos, or simple improvements without the overhead of the full research → plan → tasks workflow. Designed for changes that affect 1-3 files and can be completed in under 30 minutes.

## Parameters

- `description` (required): Brief description of what needs to be fixed (e.g., "Fix null check in document upload")
- `--test` (optional): Run tests after implementation (default: false)
- `--commit` (optional): Create git commit after successful implementation (default: false)

## Validation Rules

1. Description must be provided or user will be prompted
2. Fix must affect 3 or fewer files (enforced during implementation)
3. If change affects >3 files, suggest using full workflow instead
4. All clarifying questions must be answered before proceeding
5. Implementation must follow KISS and YAGNI principles

## Execution Steps

1. **Accept or Request Description**
   - If description provided: proceed with clarification
   - If not provided: ask user to describe the fix needed
   - Validate that fix is "small" (if user says "refactor entire API", push back)

2. **Clarification Phase** (MANDATORY)
   - Ask questions to understand the exact issue
   - Ask which files likely need changes
   - Ask if tests should be run after
   - Ask if commit should be created
   - **IMPORTANT**: If ANY aspect is unclear, STOP and ask for clarification
   - Confirm this is truly a small fix (<30 min, ≤3 files)
   - If too large: suggest using superpowers brainstorming/planning workflow

3. **Locate Affected Files**
   - Use Glob/Grep to find relevant files mentioned in description
   - Read affected files to understand current implementation
   - Verify the issue exists as described
   - Identify exact lines that need changes
   - Count files to be modified (enforce ≤3 file limit)

4. **Implementation** (KISS/YAGNI)
   - Implement the fix using simplest approach
   - Follow existing code patterns in the file
   - No refactoring beyond the fix itself
   - No "while I'm here" improvements
   - Use environment variables or config (no hard-coding)
   - Handle errors gracefully
   - Update API specs if applicable

5. **Verification**
   - Verify the fix is complete
   - Read modified files to confirm changes
   - If `--test` flag: run relevant tests (`npm run build` minimum)
   - Report test results

6. **Create Commit** (if requested)
   - If `--commit` flag: create git commit
   - Use descriptive commit message following project conventions
   - Include Co-Authored-By: Claude
   - Run git status to verify

7. **Summary**
   - List all files modified
   - Show diff summary (lines added/removed)
   - Confirm fix is complete
   - No documentation files created (this is a feature, not a bug!)

## Output Specification

### Console Output Format

```markdown
🔧 Quick Fix: {description}

📋 Clarification:
   • Issue: {confirmed issue description}
   • Affected Files: {file count} file(s)
   • Run Tests: {yes/no}
   • Create Commit: {yes/no}

============================================================
🔍 Locating Affected Files
============================================================

Found {N} file(s) that need changes:
  • src/path/to/file1.ts:42 - Issue: {specific issue}
  • src/path/to/file2.ts:18 - Issue: {specific issue}

✓ All files found (within 3-file limit)

============================================================
🛠️  Implementing Fix
============================================================

File: src/path/to/file1.ts
  • Line 42: {description of change}
  • Line 45: {description of change}

File: src/path/to/file2.ts
  • Line 18: {description of change}

✅ Implementation complete

============================================================
✅ Verification
============================================================

Modified Files:
  ✓ src/path/to/file1.ts (+3, -2)
  ✓ src/path/to/file2.ts (+1, -1)

{If --test flag:}
Running build verification...
✅ Build passed (no errors)

{If --commit flag:}
Creating git commit...
✅ Commit created: abc1234 "Fix: {description}"

============================================================
📊 Summary
============================================================

Fix Complete: {description}

Changes:
  • Files Modified: {N}
  • Lines Added: {N}
  • Lines Removed: {N}
  • Duration: {X} seconds

✅ Quick fix successfully applied!

No documentation created (as intended for quick fixes).
```

## When NOT to Use This Command

Reject quick-fix if:

1. **Too Many Files**: Change requires >3 files
   ```markdown
   ⚠️  This change affects {N} files, which exceeds the 3-file limit for quick fixes.

   For changes affecting 4+ files, use the superpowers brainstorming and planning workflow.
   This ensures proper planning and tracking for larger changes.
   ```

2. **Complex Changes**: Requires architectural decisions
   ```markdown
   ⚠️  This change requires architectural decisions or design choices.

   Quick fixes are for simple, obvious changes only.

   Please use the brainstorming skill to properly analyze this change.
   ```

3. **New Features**: Adding new functionality
   ```markdown
   ⚠️  This appears to be a new feature, not a fix.

   Quick fixes are for:
   • Bug fixes
   • Typos
   • Simple improvements
   • Missing null checks
   • Error message updates

   For new features, use the superpowers brainstorming skill.
   ```

## Examples

### Good Quick Fix Examples

✅ **Fix typo in error message**:
```bash
/quick-fix "Fix typo 'occured' → 'occurred' in conversation error messages"
```

✅ **Add missing null check**:
```bash
/quick-fix "Add null check before accessing user.email in auth service"
```

✅ **Update environment variable**:
```bash
/quick-fix "Change hardcoded port 3000 to use PORT env var"
```

✅ **Fix off-by-one error**:
```bash
/quick-fix "Fix pagination offset calculation in conversation list endpoint"
```

### Bad Quick Fix Examples

❌ **Too broad**: "Refactor authentication system"
❌ **New feature**: "Add password reset functionality"
❌ **Multiple concerns**: "Fix error handling and add logging and update validation"
❌ **Vague**: "Make it better"

## Error Handling

### File Not Found
```markdown
❌ Error: Could not locate file mentioned in description

Searched for: {search terms}
Directories searched: {directories}

Please provide more specific file path or clarify which file needs fixing.
```

### Issue Not Found
```markdown
⚠️  Could not find the issue described in the codebase.

Description: {description}
Files searched: {files}

Options:
1. Provide more specific details (file path, function name, line number)
2. Verify the issue still exists
3. Use /research if the issue is unclear
```

### Build Fails After Fix
```markdown
❌ Build verification failed after implementing fix

Error: {build error}

The fix has been applied but introduced a build error.

Options:
1. Let me fix the build error
2. Revert the changes
3. Continue without fixing (not recommended)

How would you like to proceed?
```

### Too Complex During Implementation
```markdown
⚠️  This fix is more complex than initially assessed.

During implementation, I discovered:
• {complexity reason 1}
• {complexity reason 2}

This should use the full workflow for proper tracking.

Options:
1. Continue with quick fix (not recommended)
2. Stop and create proper research/plan/tasks
3. Break into smaller quick fixes

How would you like to proceed?
```

## Success Criteria

- Fix description is clear and specific
- Affected files located successfully (≤3 files)
- Implementation completed following KISS/YAGNI
- No unnecessary changes beyond the fix
- Build passes (if --test specified)
- Commit created (if --commit specified)
- Summary provided with file changes
- No documentation files created
- Total time < 30 minutes

## Implementation Notes

### File Count Enforcement

During Step 3 (Locate Affected Files):
```typescript
const affectedFiles = findAffectedFiles(description);

if (affectedFiles.length > 3) {
  throw new Error(
    `This change affects ${affectedFiles.length} files, exceeding the 3-file limit. ` +
    `Please use the superpowers brainstorming and planning workflow`
  );
}
```

### Commit Message Format

If `--commit` flag used:
```
Fix: {brief description from user}

{More detailed description if needed}

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>
```

### Test Execution

If `--test` flag:
- Minimum: `npm run build` (verify compilation)
- If specific test file exists: `npm test -- path/to/test.spec.ts`
- Report pass/fail, don't continue if failed

### No Documentation Created

This is intentional:
- No research.md
- No phases/index.md
- No tasks.md
- No learnings.json updates
- No task-status.json

Quick fixes are too small to warrant documentation overhead. Use git history for tracking.

## Best Practices

1. **Be Specific**: "Fix null check in parseDocument() line 42" beats "Fix bug"
2. **One Thing**: Don't bundle multiple unrelated fixes
3. **Test Locally**: Use `--test` flag to catch issues before commit
4. **Descriptive Commits**: Use `--commit` with good description
5. **Know Your Limits**: If it feels complex, use full workflow

## Integration with Existing Workflow

Quick fixes complement, not replace, the standard workflow:

**Use Quick Fix For**:
- Typos and simple bugs
- Missing null checks
- Hardcoded values → env vars
- Error message improvements
- Simple logic errors

**Use Standard Workflow For**:
- New features
- Refactoring
- Multi-file changes (>3 files)
- Architectural changes
- Database schema changes

## Time Savings

**Full Workflow** (features, complex changes):
- Brainstorming, planning, implementation phases
- Proper tracking and documentation

**Quick Fix**:
- `/quality:quick-fix`: 5-10 min (just the fix)
- No documentation overhead
