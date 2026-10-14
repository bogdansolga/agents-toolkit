# Implementing A Plan With Pi

How to shape an implementation plan so the local model executes it through this harness, with Claude reviewing each task.

**Status: untested for real implementation.** Everything below comes from evals (fixed tasks, hidden tests, a graded diff). The first real plan is the first trial: Claude reviews every task, and the lessons go back into this file.

## What The Evals Showed

From the first local runs (Qwen3.6 35B-A3B, 128k context, one TypeScript repo, 26 cases × 3 runs, first batches):

- **The model's code usually worked; it stopped too early.** Without a guide it never ran the linter, and ran the unit suite in 1 of 13 tuning-set trials. "Type-check passes" was its signal to stop. 13 of 23 failures failed on lint alone.
- **A "Before You Finish" section (below) took the same 13 trials from 2 solved to 12.** Lint passed in all 13. The cost: about 3× the input tokens and a longer tail (slowest run 20 minutes, 100 turns).
- **The remaining hidden-test failures were contract misses:** a placeholder `0` left where the task asked for a computed value, a key set to `undefined` where the task said "no key at all", a different response shape than the one the task spelled out.
- **Context was not the limit:** the peak was 71k of 128k tokens; no run needed compaction.

## 1. Runner And Work Dir

- **There is no implementation runner.** An eval runner snapshots, grades and discards. For implementation, call `try-pi.sh` once per task, or a small loop around it.
- **The work dir must sit outside everything the sandbox denies:** the real repo (`PI_SANDBOX_REPO`), the parent workspace (`PI_SANDBOX_HUB`), `$HOME` and the Claude data dir. Use a copy under a work root on a data disk, e.g. `<work-root>/<repo>-pi`:
  - `snapshot.sh <repo> <ref> <out>` gives a one-commit copy with no history and `node_modules` re-linked;
  - or a plain clone or worktree there, when hiding history doesn't matter.
- **Loop per task:** Pi edits the copy → Claude reviews `git diff` there → Claude applies the patch to the real branch (`git apply`), runs the checks Pi can't (see 5), and commits outside the sandbox. Reset the copy to the new commit before the next task.

## 2. Model

- `ollama/qwen3.6-coder-128k`, thinking `medium` (the eval default; not tuned yet).
- Cloud models (DeepSeek, GLM) only confirm a winning guide in evals. Sending a repo's code to a cloud provider is the repo owner's decision; keep private or client code local.

## 3. Task Size

- **One plan task = one Pi run:** one testable behaviour, at most about 3 files, with its tests. That's the range the evals measured (1–3 files, about 20–150 changed lines; median 2–3 minutes and 19–23 turns).
- **Don't split a task's steps into separate runs.** Each run starts with no memory of the last one.
- **Split anything bigger into more tasks,** each leaving the repo green.

## 4. Task Text

State the contract literally; every hidden-test failure in the evals was a contract miss.

- Exact file paths to create or change.
- Function signatures with types.
- The exact output: shapes, keys, literal values; say when a key must be absent.
- The input forms and error paths that must keep working (existing callers and tests).
- The tests to pass. For implementation, giving the full test code is fine.
- "Call each function the task names with the task's own example inputs before finishing."

Pass the repo's `CLAUDE.md` / `AGENTS.md` with `--append-system-prompt`, and add this section verbatim. Adapt the commands to the repo; with Claude-written tests, step 3 becomes "the task's tests plus the unit suite".

```markdown
## Before You Finish (Every Task)

The work is done only when all of these pass; run them yourself and fix what they report:

1. `bun run type-check`
2. `bunx biome check --write <the files you changed>`, then `bunx biome check <the files you changed>` must report no errors. Biome enforces rules that tsc does not, for example: braces on every `if`, no reassigning a function parameter (use a new `const`), sorted object keys, no `console`.
3. `bun run test` (the whole unit suite; about 5 s). Add or update unit tests under `tests/unit/` for the behaviour you changed.
```

## 5. What Works Inside The Sandbox

| | Inside | Notes |
|---|---|---|
| Network | yes | The profile allows everything except the denied paths. |
| Local Postgres over TCP | yes | Pass the connection string in the task's env; `try-pi.sh` runs `env -i`, so no `.env` reaches Pi. |
| Docker | no | Its socket lives under `$HOME`, which is denied. |
| `bun install` | untested | `~/.bun` is read-only inside; it would need `BUN_INSTALL_CACHE_DIR` in the run's HOME. Run it outside before the task instead, and forbid dependency changes in the task text. |
| Dev server, browser | avoid | Memory: see 6. |

**Split for DB-dependent work:** Pi writes the code and the unit tests (no DB). Claude runs the integration tests on real Postgres outside the sandbox during review, and turns failures into a follow-up task.

## 6. Keep Out Of Pi's Loop

- **Git hooks and commit gates:** Pi doesn't commit; Claude does, outside the sandbox.
- **Smoke crawls, page checks, anything that needs a dev server.**
- **Slow or broad checks** (UI doctors, file-size ratchets, coverage): run them in Claude's review.
- **Pi-side checks stay fast:** type-check, lint on the changed files, unit tests.

## 7. Machine

- **Memory:** the model loads at 24 GB, and on long tasks the process grows to about 34 GB (context plus cache). On a 36 GB Mac, run nothing heavy beside it: no dev servers, no browser walks, few Chrome tabs.
- **Disk:** macOS keeps swap on the system disk; it reached 15 GB during long runs. Run `disk-guard.sh --check 15` before a batch, keep the work dir and `TMPDIR` on a data disk, and take the GPU lock (`ollama-lock.sh`) so runs from different repos never overlap.
- **Batches:** one task at a time. A stopped batch loses at most the task in progress, so stop between tasks when swap grows.
