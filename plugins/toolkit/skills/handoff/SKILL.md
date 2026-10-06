---
name: handoff
description: "Use when ending a session, before a compaction, or when asked to write a handoff: writes a session-handoff doc so a fresh session can pick up cold."
---

# /handoff

Write a self-contained handoff. A fresh session (or human) should be able to resume from this file alone.

`$ARGUMENTS` (optional): focus hint — area to emphasise, caveat, or target path.

## Steps

1. **Gather state** (parallel): `git status -s`, `git log --oneline -15`, `git diff --stat HEAD`, `git log --oneline @{u}.. 2>/dev/null`. Detect stack (`package.json`/`Cargo.toml`/`go.mod`/etc.) → note verify/test/build command. Skim project `CLAUDE.md` for conventions worth surfacing.

2. **Reconstruct from conversation**: goal · what was done · what's half-done / deferred · non-obvious decisions and *why* (highest-value, rots if unwritten) · gotchas (failed approaches, env quirks, hidden constraints) · in-flight background state (processes, tunnels, temp state) — cleaned up or not?

3. **Pick output path** (inside the project repo):
   - `$ARGUMENTS` if path-shaped
   - **In-place mode**: if the repo has a rolling `HANDOFF.md` at root, or a `docs/**/HANDOFF.md` referenced by `CLAUDE.md`/README as *the* state-snapshot → update that in place
   - **Default**: `<repo>/docs/handoffs/<YYYY-MM-DD-HHMM>.md` (timestamped, never overwrites). `mkdir -p` as needed.
   - State which mode you picked.

4. **Write the doc** (drop sections that don't apply; facts > prose):

   ```markdown
   # Session handoff — <project> — <YYYY-MM-DD>

   **Branch:** <branch> · **Updated:** <time> · **Last commit:** <sha> <subject>
   Read fully before acting.

   ## 1. Where we are
   1–3 paragraphs: what this work is, current state, deployed/live status.

   ## 2. What this session did
   Commits (newest last), one-line each. Then uncommitted/in-progress + state.

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

5. **Verify**: re-read what you wrote. A stranger should be able to resume cold. Report path + 3-line summary.

## Notes
- **No secrets** in the file (passwords, tokens, full connection strings) — reference paths only.
- **Don't commit** unless asked. If asked, detect commit-message convention from recent `git log` (e.g. bracket prefix `[doc] …` vs Conventional `docs: …`) and match it. Don't impose `docs(handoff):` on a `[improve]`/`[fix]`/`[doc]` project.
- Thin session → short handoff. Don't pad.
- `docs/handoffs/` tracked by default (history is valuable); suggest gitignore only if user wants it ephemeral.
