# Run Pre-PR Checks

Run local checks (lint, types, tests) before creating a pull request.

## Execution Steps

1. **Detect Project Type**
   Check for project files in order:
   - `package.json` → Node.js/TypeScript
   - `Cargo.toml` → Rust
   - `go.mod` → Go
   - `pyproject.toml` or `requirements.txt` → Python
   - `pom.xml` or `build.gradle` → Java

2. **Identify Available Scripts**
   For Node.js, read `package.json` scripts and look for:
   - Lint: `lint`, `eslint`
   - Types: `type-check`, `typecheck`, `tsc`
   - Test: `test`, `test:unit`, `vitest`, `jest`
   - Build: `build`

3. **Run Checks in Order**

   **Node.js/TypeScript:**
   ```bash
   npm run lint          # or pnpm/yarn
   npm run type-check    # if available
   npm run test          # if available
   ```

   **Rust:**
   ```bash
   cargo fmt --check
   cargo clippy -- -D warnings
   cargo test
   ```

   **Go:**
   ```bash
   go fmt ./...
   go vet ./...
   go test ./...
   ```

   **Python:**
   ```bash
   ruff check .          # or flake8
   mypy .                # if configured
   pytest                # if tests exist
   ```

4. **Report Results**
   - Show pass/fail for each check
   - On failure: display error output, suggest fixes
   - On success: confirm ready for PR

## Output Format

### Success
```markdown
Project: finances-manager (Node.js + TypeScript)
Package manager: pnpm

Checks:
  ✓ Lint (eslint) .............. passed
  ✓ Types (tsc) ................ passed
  ✓ Tests (vitest) ............. 42 passed, 0 failed

✓ All checks passed - ready for /pr:create
```

### Failure
```markdown
Project: finances-manager (Node.js + TypeScript)

Checks:
  ✓ Lint (eslint) .............. passed
  ✗ Types (tsc) ................ 2 errors

Errors:
  src/lib/api.ts:42 - Property 'userId' does not exist on type 'Request'
  src/lib/api.ts:58 - Type 'string' is not assignable to type 'number'

Fix type errors and run /pr:checks again.
```

## Notes

- Detects package manager (npm, pnpm, yarn, bun) from lock files
- Skips checks that don't exist in the project
- Runs checks sequentially, stops on first failure (fail-fast)
- Use `--continue` to run all checks even if some fail
