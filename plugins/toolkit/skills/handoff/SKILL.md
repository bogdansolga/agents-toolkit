---
name: handoff
description: "Use when ending a session, before a compaction, or when asked to write a handoff: updates the project's rolling HANDOFF.md snapshot in place so a fresh session can pick up cold."
---

# /handoff

Keep one rolling handoff per project: a self-contained snapshot of the current state. A fresh session (or a human) should be able to resume from this file alone. Each run rewrites the snapshot; it never appends per-session sections.

`$ARGUMENTS` (optional): focus hint — area to emphasise, caveat, or target path.

## Steps

1. **Gather state** (parallel): `git status -s`, `git log --oneline -15`, `git diff --stat HEAD`, `git log --oneline @{u}.. 2>/dev/null`. Detect stack (`package.json`/`Cargo.toml`/`go.mod`/etc.) → note verify/test/build command. Skim project `CLAUDE.md` for conventions worth surfacing.

2. **Reconstruct from conversation**: goal · what was done · what's half-done / deferred · non-obvious decisions and *why* (highest-value, rots if unwritten) · gotchas (failed approaches, env quirks, hidden constraints) · in-flight background state (processes, tunnels, temp state) — cleaned up or not?

3. **Pick the file** (inside the project repo; `<repo>` is the git root, else cwd):
   - `$ARGUMENTS`, if it's a path.
   - An existing rolling handoff: a `HANDOFF.md` at the repo root, or a `docs/**/HANDOFF.md` (prefer the one `CLAUDE.md` or the README names).
   - **Default:** `<repo>/docs/handoffs/HANDOFF.md` (`mkdir -p` as needed).
   - Never create a new timestamped file.

   **Migration:** if the repo has only old timestamped handoffs (`docs/handoffs/YYYY-MM-DD-HHMM.md`) and no `HANDOFF.md`:
   - read the newest one and fold what still applies into the new `HANDOFF.md`;
   - then list the old files and ask the user before deleting any. Never delete without a yes.

4. **Update in place:** if the file exists, read it first, then rewrite it as the current snapshot.
   - **Keep** open items, conventions and gotchas that still apply.
   - **Drop** finished or outdated items. They live on in git history and in the commits listed.
   - **Never** add per-session sections; the doc describes now, not a diary.
   - Note what changed since the previous snapshot, for the summary in step 6.

5. **Write the doc** (drop sections that don't apply; facts > prose):

   ```markdown
   # Handoff — <project>

   **Branch:** <branch> · **Updated:** <time> · **Last commit:** <sha> <subject>
   Read fully before acting.

   ## 1. Where we are
   1–3 paragraphs: what this work is, current state, deployed/live status.

   ## 2. Recent work
   The latest commits that matter (newest last), one line each. Then uncommitted / in-progress work and its state.

   ## 3. Open / next — ranked
   Numbered, highest-value first. Mark [easy]/[medium]/[hard]; flag blockers.

   ## 4. Decisions & rationale
   Non-obvious calls and *why*.

   ## 5. Conventions — DO NOT VIOLATE
   Durable rules established or reaffirmed. One line per rule + one-line why. User directives, library/test/commit policy, naming patterns. The next session must honour these.

   ## 6. Gotchas
   Failed approaches, env quirks, "don't do X because Y".

   ## 7. State-check on entry
   Exact commands a resumer runs first to verify this snapshot is still accurate (git log, build/test, service health) + healthy signals to expect.

   ## 8. Pointers
   Key files (`path:line` where useful), other docs, external resources (dashboards, tickets, repos), credential locations (paths, not values).

   ## 9. Memory pointers (ECC auto-loaded)
   Relevant `~/.claude/projects/.../memory/` files that influence behaviour. Skip if none.

   ## 10. Session metadata
   Date · branch · working-tree-clean? · DB/service access notes · running dev servers/tunnels/jobs.
   ```

6. **Verify:** re-read what you wrote; a stranger should be able to resume cold. Report the path, a 3-line summary, and **what changed since the previous snapshot** (added, closed and dropped items). On the first run or a migration, say so.

## Notes
- **No secrets** in the file (passwords, tokens, full connection strings) — reference paths only.
- **Don't commit** unless asked. If asked, detect commit-message convention from recent `git log` (e.g. bracket prefix `[doc] …` vs Conventional `docs: …`) and match it. Don't impose `docs(handoff):` on a `[improve]`/`[fix]`/`[doc]` project.
- Thin session → short handoff. Don't pad.
- `HANDOFF.md` is tracked by default; git history keeps the earlier snapshots. Suggest gitignoring it only if the user wants it ephemeral.
