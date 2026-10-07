# The Rolling Window: Archive and Summary

Keep each task folder small. A new session should load only what still matters.

## What Stays Live

- The latest 3 handoffs.
- Every file that `task.md` (Links, State, Decisions, Next) or the latest handoff names.
- Files marked as living in `task.md` (for example `Living: docs/changelog.md`). These are change logs that keep growing; they are never archived.

## The Sweep (Triage Step 4, or on Request)

For each task folder:

1. **Find the candidates:** files in `docs/` and `handoffs/` older than 7 days (by date in the name, else by modification time) and not in the live set.
2. **Move them,** never delete. Move each to `docs/archive/YYYY-Www/` (the ISO week of the file's date), keeping its name. Use `git mv` when the file is tracked, `mv` otherwise.
3. **Update `docs/archive/SUMMARY.md`:** add or extend the section for that week:

   ```markdown
   ## 2026-W40 (archived 2026-10-13)

   **Still applies:**
   - <a fact or decision from these files that still holds>, from `<file>`

   **Superseded:**
   - `<old file>` → replaced by `<live file>` (reason)

   **Files:**
   | File | One line |
   |---|---|
   | `2026-W40/2026-09-30-1706.md` | Handoff: pricing options, history |
   ```

4. **Fix the links:** if `task.md` or a live handoff still names a moved file, the file was live; move it back. Never leave a broken link.
5. **Record:** the triage handoff lists what moved, file by file.

## Rules

- **Summarise only what still applies.** If a week's files hold nothing that still matters, the section is just the file index.
- **Google files** stay where they are. List Google ids that are no longer current under "Superseded".
- **Nothing is deleted.** Old content is always one path away in `docs/archive/`.
- **Read `SUMMARY.md` only when the latest handoff points there,** or when the user asks about history.
