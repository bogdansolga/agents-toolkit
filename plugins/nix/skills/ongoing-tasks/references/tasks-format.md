# ongoing-tasks.md format

```markdown
# Ongoing Tasks

Updated: 2026-10-05

| # | Task | Folder | Due | Prio | Status |
|---|------|--------|-----|------|--------|
| 1 | Short title | `n-ix/Accounts/UTA` | ~2026-10-10 |  | active |
| 2 | Short title | (none) | 2026-10-14 | P1 | todo |

## 1. Short title

- **Goal:** one line, the outcome.
- **Done when:** one line, a checkable condition.
- **Links:** `VVLK-195`, https://docs.google.com/document/d/<id>/edit
- **State:** 2-4 lines: what works, what is half-done.
- **Decisions:** dated one-liners that must not be re-litigated.
- **Open:** blockers and questions for the user.
- **Next:** the single next step, concrete enough to start cold.
- **Handoffs:** latest first, last 3 kept: `docs/handoffs/2026-10-05-1430.md`, ...

## Done

- 3. Short title: one-line result (2026-10-12).
```

## Fields

| Field | Rule |
|---|---|
| `#` | Assigned once (next free number, counting Done), never reused or renumbered. |
| Folder | Relative to `/Volumes/NVMe/Development/IdeaProjects/`. `(none)` when there is no source folder. |
| Due | ISO date. `~` prefix = tentative. Every task has one. |
| Prio | Empty = computed. `P1`–`P3` = user override, always wins; its reason goes in Decisions. |
| Status | `todo`, `active`, `blocked: <reason>`, `done`. |
| Links | Optional. Jira keys, Google Docs/Sheets/Slides/Drive URLs. |
| Handoffs | Paths relative to the task folder; for `(none)` tasks, relative to the tasks file's folder. |
| Updated | Date of the last change to the file. |

Empty block fields are written as `-`, not removed, so every block has the same shape.

## Priority (computed at read time, never stored)

`days = due - today` (ignore the `~`).

| Priority | Condition |
|---|---|
| P1 | `days <= 2` (includes overdue) |
| P2 | `days <= 7` |
| P3 | later |

Sort: effective priority, then fewer days, then firm before tentative. Display: `P1 (override) · 3d`, `P2 · 5d`, overdue `P1 · -2d`.

## Done list

Triage moves a `done` task's row out of the table and its block out of the file, leaving one line under `## Done`: `- <#>. <title>: <result> (<date>)`. Its handoffs stay in the task folder.
