---
name: handoff-continue
description: "Use when resuming work or asked to continue from a handoff: reads the project's rolling HANDOFF.md (or, as a fallback, the newest timestamped handoff), verifies it against the repo, and picks up."
---

# /handoff-continue

Resume a prior session: read its handoff, verify it still reflects reality, surface where to pick up.

`$ARGUMENTS` (optional): path to a specific handoff, or a hint about which one.

## Steps

1. **Locate the handoff** (in order):
   - `$ARGUMENTS`, if it's a path.
   - **The rolling `HANDOFF.md` first:** `<repo>/docs/handoffs/HANDOFF.md`, `<repo>/HANDOFF.md`, or a `docs/**/HANDOFF.md` that `CLAUDE.md` or the README names. If one exists, use it, even when timestamped files are newer.
   - **Fallback, for repos not migrated yet:** the newest `<repo>/docs/handoffs/YYYY-MM-DD-HHMM.md`, then `docs/**/*handoff*.md`. Mention that the next `/handoff` will migrate it to `HANDOFF.md`.
   - Several plausible candidates → list them and ask. Don't guess.
   - None found → say so, suggest running `/handoff` at the end of the next session, then fall back to `/catchup`-style reconstruction (`git log` + `status` + `diff`).

2. **Read it fully.** Then run its §"State-check on entry" commands. If absent: `git log --oneline -15`, `git status -s`, plus an obvious build/test/health command for the stack.

3. **Reconcile handoff vs reality**:
   - Does the doc's "last commit" match HEAD? If HEAD moved past it, more happened after the handoff — flag.
   - Working tree state as described?
   - Healthy signals still hold? Probe any service/health check it names.
   - Stale claims (renamed files, merged work, changed deploy state)? Trust what you observe now over the doc — note discrepancies.

4. **Honour conventions.** If the handoff has §"Conventions — DO NOT VIOLATE", treat each item as a hard constraint for the rest of this session. Also honour any §"Memory pointers" listed.

5. **Brief the user** — concise:
   - One paragraph: where things stand right now
   - Top 1–3 open items (re-ranked if reality changed)
   - Discrepancies between handoff and current state
   - Ask what to work on — *or*, if the handoff has a clear single next step and the user said "just continue", state what you'll do and start.

6. **Do not** make changes before step 5 unless the user explicitly said "continue / pick up where you left off". Even then, state intent first.

## Notes
- Handoff = point-in-time snapshot, not gospel. Verify load-bearing claims (files/functions named there may have been renamed or removed) before acting.
- Thin handoff or cold trail → say so plainly and propose how to re-establish context. Don't improvise.
