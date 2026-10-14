# pi-harness: Pi As A Scripted, Sandboxed Agent For Evals

**Why:** the better the local model gets at execution (edits, fixes, docs, checks), the more of the strong model's time goes to creative and planning work (`EVAL-METHOD.md`, "Why").

**Overview:** `docs/local-model-overview.html` at the repo root (one self-contained page: the stack, Jev, the loop, quality by round). **Local model:** [Ollama](https://ollama.com/), [Qwen3.6](https://ollama.com/library/qwen3.6).

**Method:** `EVAL-METHOD.md` (trial anatomy, grader, context budget, staged strategy, storage, guide surfaces, shared results log).

Run the Pi coding agent non-interactively on local or cheap models, with nothing from the caller's machine in reach. Built for eval runners (fixed task in, graded diff out); also usable by hand through `try-pi.sh`.

| File | What |
|---|---|
| `context-budget.ts` | Pi extension (`pi -e`): caps each `read`/`bash` result (default 12 KB / 300 lines). `read` keeps the head and points to `offset`/`limit`; `bash` keeps head + tail and saves the full output to a temp file. Pi's own cap is 50 KB, which lets a few reads fill a 64–128k local window. |
| `pi-agent/` | A self-contained Pi config dir (`PI_CODING_AGENT_DIR`): `models.json` (local `ollama/qwen3.6-coder-128k`), `settings.json` (compaction override for it: reserve 16384, keep 24000). No `auth.json`: keys come from env only, so a personal OAuth login is never used. |
| `sandbox.sb` | macOS `sandbox-exec` profile: denies reads/writes of the real repo, a parent workspace, `$HOME` and the Claude data dir; allows `~/.bun` read-only. A snapshot outside the repo isn't enough on its own: the agent's bash tool can read any path. |
| `ollama-lock.sh` | Runs a command under an exclusive lock (`$OLLAMA_EVAL_LOCK`, default `~/.ollama/eval.lock`) so evals from different repos never share the local GPU. macOS has no `flock(1)`; this uses Python's `fcntl.flock`. |
| `snapshot.sh` | `snapshot.sh <repo> <base-ref> <out-dir> [drop ...]`: the repo at a ref as a fresh one-commit repo (no history to mine), with listed paths and `.env*` dropped and `node_modules` re-linked to realpaths. For tasks whose answers live in later commits. |
| `disk-guard.sh` | System-disk watch: free space, swap, Ollama models in memory, largest temp folders. `--clean` unloads models and empties `$EVAL_WORK_ROOT` when no trial holds the lock; `--check <GB>` exits 1 below a floor. |
| `jev-compaction/` | Pi extension (`pi -e jev-compaction`, after `npm install` there): at `session_before_compact` it hands the messages Pi would summarize to `fast-jev-compaction` (TypeSafe's Jev). Stale tool calls are removed and stale results truncated; everything kept stays verbatim and becomes the summary. Falls back to Pi's summary when `TYPESAFE_API_KEY` is unset, Jev fails, or it saves under 25%. **Sends the conversation state to api.typesafe.ai.** |
| `try-pi.sh` | One sandboxed Pi run in a directory: `PI_SANDBOX_REPO=<repo> try-pi.sh <dir> <provider/model> "<prompt>"`. |
| `show-events.py` | Prints a Pi `--mode json` event log as one line per turn: tool calls, token use, result sizes, compactions. |

## Gotchas

- **Close stdin.** `pi -p` waits for piped input on an open stdin; without `</dev/null` a scripted run hangs.
- **Copy, don't point.** Copy `pi-agent/` and `context-budget.ts` into the trial's temp `HOME` before sandboxing: the sandbox may deny the folder they live in.
- **`node_modules` with relative symlinks** (bun/pnpm workspaces) breaks in a snapshot outside the repo; re-link each entry to its `realpath`.
- **Ollama `num_ctx`** comes from the model's Modelfile, not the OpenAI-compatible request; `contextWindow` in `models.json` must match it.
- **Prompt-prefix cache:** Ollama reuses the cached prefix between turns, so a turn costs only its new tokens; compaction forces a full re-prefill.
