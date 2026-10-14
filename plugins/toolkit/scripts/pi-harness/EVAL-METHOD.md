# Local And Cheap Models On Real Repo Work: Eval Method

One method for every repo that wants a local model (Ollama) or a cheap cloud model to do work a stronger model does today. It uses the `eval-hillclimb` method (fixed held-out test set, A/A noise check, one change per round, keep or revert) on top of this folder's harness. Each consumer repo keeps its own cases, grader commands and results in `evals/<name>/`. This file holds what they share.

## Why: Move Execution Down, Thinking Up

The goal is a **division of labour**, not a cheaper copy of the strong model:

- **The local model does the execution:** bounded edits, fixes, refactors, docs and check runs, with a clear task text and a code-only "done". It costs nothing per run, so we can run it often, in parallel with other work, and retry when it fails.
- **The strong model (Claude) is freed for creative and planning work:** design, specs, choosing what to build, writing the task texts, reviewing diffs and deciding when a task isn't clear enough to hand off.
- **Productivity is measured, not assumed.** Each class of task moves down only when the eval shows the local model does it well enough, and the measured gap decides what goes next.

Every gain on the local model (a better repo guide, harness settings, case coverage) moves more execution down. That frees more of the strong model's time and budget for thinking work. That compounding is why the eval exists. Report each improvement in §9 in those terms: what share of a task class the local model now solves.

## 1. What Gets Measured

| Question | Configs compared | Typical consumer |
|---|---|---|
| Can model X do this repo's coding tasks? | one model × guides | a product repo: tasks rebuilt from its history and backlog |
| Can model X replace model Y for an agent role? | Y (today) vs X (candidate), same briefs | an agent platform: one case per reviewed task of a subagent role |

Both reduce to the same trial: **a task text + a starting tree → an agent run → a code-only grade**.

## 2. Trial Anatomy

1. **Work dir** under `$EVAL_WORK_ROOT` (see §6), never the system temp dir.
2. **Starting tree**, one of:
   - `snapshot.sh <repo> <base> <out> [drop…]`: no git history. Use it when the answer lives in a later commit (history cases).
   - A clone or worktree with real git: use it when the task itself needs git (commit by path, a scope check over the commit).
3. **Private `HOME`/`TMPDIR`** inside the work dir, holding copies of `pi-agent/` and `context-budget.ts`. The sandbox may deny this folder, so copy instead of pointing at it.
4. **Agent run**: `sandbox-exec -f sandbox.sb … env -i … pi -p --mode json --no-session --no-context-files --no-skills --no-extensions --no-mcp --no-prompt-templates --no-approve -e context-budget.ts --append-system-prompt <guide> --model <provider/id> --thinking <level> "<task>" </dev/null`.
   - **Local models run under `ollama-lock.sh`:** one trial at a time across all repos.
   - **Only the one provider key the model needs enters the sandbox.** Personal OAuth logins never do: the eval's Pi dir has no `auth.json`.
5. **Grade** in the same sandbox, after copying in the hidden tests. Grade **twice**; the two grades must agree (`grader-check`).
6. **Record** one results line plus a transcript dir (events, diff, grade logs) in the repo. **Delete the work dir** afterwards (`KEEP_TRIALS=1` keeps it while you debug).

## 3. Grader (Code Only)

- **Score = 1 only if every gate passes.** The gates: the hidden tests (fail-to-pass), the repo's whole unit suite (pass-to-pass), the type-check, and the linter on the changed files. Lint is in the score because "works but fails the repo's lint" still costs a reviewer a round.
- **Reported, not scored:** scope (deleted tests, protected files touched), i18n parity, a hidden test the agent's own file clobbered.
- **Plumbing errors are recorded and excluded from the score, never counted as 0.** That covers harness, provider, timeout, cut-off, disk and sandbox failures. A sandbox failure must throw: a broken sandbox makes every command "fail", which looks exactly like a valid failing test.
- **Case validation before Gate 1.** The hidden tests must run and fail on the base, and the reference must score 1, in the same sandbox and with today's dependencies. A case that fails this check is dropped, not patched in the grader.

## 4. Context Budget (Local Models)

Measured on a 36 GB M4 Max with a 35B-A3B Q4 model (hybrid attention). Re-measure on other hardware:

| Finding | Number |
|---|---|
| Pi fixed prompt | ~1.8k tokens |
| What fills the window | tool results: one `read` reaches 50 KB (~13k tokens); 5 parallel reads overflow 64k |
| Window memory cost | 64k = 23 GB, 128k = 24 GB, 192k = 25 GB, all on the GPU |
| Prefill | ~1,000–1,300 tokens/s; Ollama reuses the cached prefix between turns |

Defaults:
- a 128k window (the Ollama tag's `num_ctx`, matched by `contextWindow` in `models.json`)
- `context-budget.ts` at 12 KB / 300 lines per result
- compaction `reserveTokens 16384`, `keepRecentTokens 24000`

All three are hillclimb surfaces. They're shared across repos, so climb them **once** (§7) and record the result here.

## 5. Strategy: Cheapest Signal First

| Stage | Size | Purpose | Gate to the next stage |
|---|---|---|---|
| Harness smoke | 1 prompt via `try-pi.sh` | sandbox blocks the repo; the model, tools and lock work | events show tool calls; a read of the real repo gets "Operation not permitted" |
| Pilot | 3 cases × 1 run, local | wall time, context peak, the failure *kinds* | no plumbing errors; failures are attributable (per-field) |
| Guide A/B on the pilot | the same 3 cases, one guide change | is the obvious first change worth a round? | direction only. A 3-case pilot can't decide anything; it orders the rounds. |
| Gate 1 + Gate 2 | all cases, review page; graded samples | the user approves cases and grader | the user's yes |
| Baseline + A/A noise | all × 3 runs, local | score with CI; noise floor (`--min-effect 0.10`) | noise < min effect |
| Rounds | train + test, one change each | `evalkit decide` keep/revert | stall rules from `eval-hillclimb` |
| Cloud confirmation | the best guide on the cheap cloud models | does the guide transfer? | none; report only |

**Local first:** trials are free and run 1–3 minutes each, so they find the guide. Paid cloud models only confirm the winner.

## 6. Storage And Concurrency

- **`EVAL_WORK_ROOT`** (default: a scratch dir on a large data volume, e.g. `/Volumes/<data>/Temp/<eval>`). Never `$TMPDIR` or `/tmp`.
  - Each snapshot is ~25 MB plus caches; case validation makes two per case. Leftover trial dirs on the system disk once filled it, and every shell on the machine stopped.
- **Before each trial,** refuse to start if the work volume has under 5 GB free or the system disk under 15 GB. tsc, vitest and Ollama still write to the system disk, and swap can grow by 10+ GB during a run (next bullet).
- **Swap lives on the system disk.** A loaded 24 GB model on a 36 GB machine, plus dev servers and agent sessions, pushed macOS swap to 13.5 GB and filled the system disk with no files in sight (2026-10-14). So: unload the model when no trial runs (`ollama stop <tag>`, or a short `OLLAMA_KEEP_ALIVE` during evals); never run dev servers or UI walks during local trials; run `disk-guard.sh` (report, `--clean`, `--check <GB>`) before a batch.
- **Rebuilding the local model re-pulls every runner copy of the base:** about 2× the weights. Remove the base tag after each build (see the model setup script).
- **One local trial at a time across repos** (`ollama-lock.sh`, lock file `~/.ollama/eval.lock`). Take the lock for the agent run only; grading needs no GPU.

## 7. Guides: Three Surfaces, Kept Apart

| Surface | Owner | Example content | Climbed by |
|---|---|---|---|
| Repo guide | each repo | where things live; business rules; how to verify (type-check, lint with autofix, unit suite) | that repo's eval |
| Role guide | the agent-platform repo | brief format, commit by path, stop-and-report rules | that eval |
| Harness settings | this folder | context cap, window, compaction, thinking level | either eval, once; recorded in §9 |

- **One change per round, on one surface.** A round that changes two surfaces can't be attributed.
- A winning repo guide becomes a section of that repo's `AGENTS.md`/`CLAUDE.md`, with the user's yes. It then helps every harness, not only Pi.

## 8. Rules Carried Over From `eval-hillclimb`

- Cases mirror real work: history commits, the real backlog, and hand-written requests in the owner's style. Every hard case gets a `why_hard`.
- Task text states everything the hidden tests check, and never contains the diff or the test code.
- The held-out test set is fixed once and never read while proposing a change. Failure content never goes into a guide verbatim.
- The answer stays out of reach: no git history, no eval files in the tree, and the sandbox denies the real repo, `$HOME` and Claude data.

## 8a. Case Review Loop (Advise → Refine → Revalidate)

Better cases give better local results: an unfair case teaches the climb the wrong lesson (the guide drifts toward a test quirk), and a hollow case reports progress that isn't there. So every case set goes through this loop before Gate 1 and again whenever cases are added:

1. **Advise:** a reviewer agent (the strong model, not the model under test) reads each case's task text, hidden tests and reference and writes **one** advice per case, rated `fix` / `consider` / `ok`, to `review-advice.json`. It checks, in this order:
   - **Fairness:** a test asserts something the task text doesn't state.
   - **Leakage:** the text gives away the implementation.
   - **Brittleness:** a different correct solution would fail.
   - **Hollow tests:** a test that passes without the fix.
   - **Host dependence:** e.g. a timezone that isn't pinned.
   - **Realism:** would the owner phrase it this way?
2. **Show the advice on the review page,** at the top of each case. Example of a useful advice:
   > Fairness: the test only sees PropertyRow passing an onSuccess to the (mocked) dialog; a router.refresh() inside edit-description.dialog.tsx is a reasonable fix that fails. Add to the task: "do it in PropertyRow; the dialog stays generic".
3. **Refine:** apply each `fix` and `consider` item with the smallest change, to the task text or the hidden tests, never the grader. Record `applied` next to the advice.
4. **Revalidate** the touched cases: the hidden tests must fail on the base, and the reference must score 1.
5. **Rebuild the page;** the user approves at Gate 1. A case added later starts at step 1.

The loop never reads results from the model under test. It judges cases on their own merits, so it can't overfit them to one model's failures.

## 9. Results Log (Shared Findings)

Add a row whenever a finding applies beyond one repo.

| Date | Repo kind | Finding | Evidence |
|---|---|---|---|
| 2026-10-14 | Next.js/TS app | **Pilot, local 35B-A3B, repo guide = the repo's CLAUDE.md + AGENTS.md:** 1/3 solved. Both misses had the hidden tests, unit suite and tsc passing and failed **only on lint** (an unbraced `if`, a reassigned parameter): the model never ran the linter. | 3 cases × 1 run; 41–191 s, 6–20 turns, context peak 7–35k, no truncations, no compactions |
| 2026-10-14 | Next.js/TS app | **Guide A/B on the pilot: adding a "Before you finish" section (type-check, linter with autofix on changed files, unit suite) took the local model from 1/3 to 3/3** on the same cases. Cost: about 2× the turns and time (6–20 → 15–37 turns; 41–191 s → 156–352 s), context peak 23–55k; the context cap fired 3 times. Direction only (3 cases × 1 run); first round of the real climb. | 3 cases × 1 run per guide |
| 2026-10-14 | — | **Context budget didn't bind on small tasks** (1–3 files): peak ≤ 35k of 128k. Larger tasks still to measure. | same pilot |
| 2026-10-14 | — | **Local trials are faster than estimated:** 1–3 min, not 10–20, so 30 cases × 3 runs ≈ 3–5 h. | same pilot |
| 2026-10-14 | — | **Plumbing lessons:** `pi -p` hangs on an open stdin; `models.json` needs `"apiKey"` on the Ollama provider; `--thinking off` doesn't stop thinking via `openai-completions` (unverified); the base model's `presence_penalty 1.5` leaks into derived tags unless the Modelfile sets 0. | harness smoke runs |
| 2026-10-14 | agent platform (role eval) | **Haiku role baseline is saturated:** 14 cases (8 replayed tasks + 6 hard fixes), Haiku direct 24/24 and 18/18. The role eval can rank Qwen against Haiku but can't show Haiku improvements; every reviewed task becomes a new case. | 3 runs per case; ~$0.02 per trial |
| 2026-10-14 | — | **A compressing API proxy damages briefs:** subagent briefs through a token-mode compression proxy lost words and sections; long-brief cases failed 3/3 (87% overall vs 100% direct). Upgrading to a cache mode that keeps the newest user message verbatim restored 23/24. Run evals with the proxy bypassed, or verify it keeps the task text intact. | 24 trials per config |
| 2026-10-14 | — | **Swap filled the system disk:** see §6. | `sysctl vm.swapusage` 13.5 GB → 6 GB after `ollama stop` |

## 10. Next Rounds (Ordered By The Pilot)

1. **Repo guide: "before you finish" verification** (type-check, lint with autofix on the changed files, unit suite). Targets the only failure kind seen so far.
2. **Harness: compaction mode** (Pi summary vs `jev-compaction/`), once a case set compacts at all (the pilots never did): compare score, turns and context peak; key `TYPESAFE_API_KEY`.
3. **Harness: thinking level** (`low`/`medium`/`high`), checked against the transcript, not the flag.
4. **Harness: context cap** (8 / 12 / 24 KB), only once larger cases show truncations or compactions.
