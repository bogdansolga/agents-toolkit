---
command: workflow:task-declarative
description: Define success criteria and constraints for a task, then let the agent loop until done
---

## Description

Shifts from imperative ("do X, then Y, then Z") to declarative ("achieve state S given constraints C") task definition. This enables longer, more autonomous agent loops by providing clear success criteria rather than step-by-step instructions.

Based on the insight: **"Don't tell it what to do, give it success criteria and watch it go."**

## Parameters

- `goal` (required): What should be true when the task is complete
- `--test-first` (optional): Write tests before implementation
- `--max-files N` (optional): Limit files that can be modified (default: 10)
- `--no-deps` (optional): Don't add new dependencies

## Execution Steps

### 1. Gather Requirements

Ask user for:

```markdown
## Goal
What should be true when this task is complete?
(e.g., "Users can reset their password via email")

## Success Criteria
How will we know it's done? (checkboxes)
- [ ] Test X passes
- [ ] File Y exists with Z
- [ ] `bun run build` succeeds
- [ ] Manual verification: {description}

## Constraints
What are the boundaries?
- Max files to modify: {N}
- No new dependencies: {yes/no}
- Must work with: {existing systems}
- Must NOT break: {critical paths}

## Out of Scope
What should NOT be done?
- {thing 1}
- {thing 2}
```

### 2. Create Verification Script

Before any implementation, create a script that checks success criteria:

```bash
#!/bin/bash
# .claude-task-verify.sh

echo "Checking success criteria..."

# Criterion 1: Tests pass
if bun test src/auth/password-reset.test.ts; then
  echo "✓ Password reset tests pass"
else
  echo "✗ Password reset tests failing"
  exit 1
fi

# Criterion 2: Build succeeds
if bun run build; then
  echo "✓ Build passes"
else
  echo "✗ Build failing"
  exit 1
fi

# Criterion 3: File exists
if [ -f "src/auth/password-reset.ts" ]; then
  echo "✓ Password reset module exists"
else
  echo "✗ Password reset module missing"
  exit 1
fi

echo ""
echo "All criteria met!"
```

### 3. Implementation Loop

Execute this loop:

```
while verification_script fails:
    1. Run verification script
    2. Identify which criterion is failing
    3. Make targeted changes to address it
    4. Run verification again

    if stuck_count > 3 on same criterion:
        Ask user for guidance
```

### 4. Progress Tracking

After each iteration, report:

```markdown
## Iteration {N}

**Status:** {N}/{total} criteria passing

| Criterion | Status | Notes |
|-----------|--------|-------|
| Tests pass | ✓ | 5/5 tests |
| Build succeeds | ✗ | Type error line 42 |
| Module exists | ✓ | Created |

**Next action:** Fix type error in password-reset.ts:42
```

### 5. Completion

When all criteria pass:

```markdown
## Task Complete

All success criteria verified:
- ✓ Tests pass (5/5)
- ✓ Build succeeds
- ✓ Module exists

**Files modified:**
- src/auth/password-reset.ts (new)
- src/auth/password-reset.test.ts (new)
- src/auth/index.ts (export added)

**Verification command:**
```bash
./claude-task-verify.sh
```

Ready for manual verification: {any manual steps}
```

## Templates

### Feature Implementation

```markdown
## Goal
{Feature description}

## Success Criteria
- [ ] Unit tests pass for new code
- [ ] Integration test demonstrates feature works
- [ ] `bun run build` succeeds
- [ ] No type errors
- [ ] Feature accessible via {entry point}

## Constraints
- Max 5 new files
- Use existing {patterns/libraries}
- Don't modify {protected files}
```

### Bug Fix

```markdown
## Goal
{Bug no longer occurs}

## Success Criteria
- [ ] Regression test added that would have caught bug
- [ ] Regression test passes
- [ ] Original functionality preserved (existing tests pass)
- [ ] `bun run build` succeeds

## Constraints
- Minimal change to fix issue
- Don't refactor surrounding code
- Max 3 files modified
```

### Refactor

```markdown
## Goal
{Code improved without behavior change}

## Success Criteria
- [ ] All existing tests still pass
- [ ] No new test failures
- [ ] `bun run build` succeeds
- [ ] {Specific metric improved: lines reduced, complexity down, etc.}

## Constraints
- Zero behavior changes
- Preserve all public APIs
- Max {N} files in single PR
```

## Example Usage

```bash
# Start declarative task flow
/workflow:task-declarative "Users can export their data as CSV"

# With test-first approach
/workflow:task-declarative "API rate limiting" --test-first

# With constraints
/workflow:task-declarative "Add dark mode" --max-files 5 --no-deps
```

## Philosophy

**Imperative:** "Create a file, add a function, call it from here, add a test..."
- Micromanages every step
- Agent stops when instructions run out
- Easy to miss edge cases

**Declarative:** "When done, tests pass, build works, feature accessible"
- Agent figures out the how
- Loops until success criteria met
- Self-correcting through verification

The key insight: **Verification is cheap, planning is expensive.** Let the agent try things and verify, rather than trying to plan perfectly upfront.

## Integration with Other Workflows

- Use with `superpowers:test-driven-development` for test-first approach
- Use with `superpowers:verification-before-completion` to ensure criteria met
- Use after `superpowers:brainstorming` to execute on decided approach
- Combine with `/quality:simplify` after completion to clean up
