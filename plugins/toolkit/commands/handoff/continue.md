---
command: handoff:continue
description: Resume from a session-handoff doc — read, verify, pick up.
---

# /handoff:continue

Resume a prior session: read its handoff, verify it still reflects reality, surface where to pick up.

`$ARGUMENTS` (optional): path to a specific handoff, or a hint about which one.

## Steps

1. **Locate the handoff** (in order):
   - `$ARGUMENTS` if path-shaped
   - Most recent `<repo>/docs/handoffs/*.md` by mtime
   - `<repo>/HANDOFF.md` (rolling-snapshot pattern)
   - `<repo>/docs/**/HANDOFF.md` or `docs/**/*handoff*.md`
   - Multiple plausible candidates → list + ask. Don't guess.
   - None found → say so, suggest running `/handoff:create` at end of next session, then fall back to `/git:catchup`-style reconstruction (`git log` + `status` + `diff`).

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
