# Index and task.md Formats

## The Index: `ongoing-tasks.md` (in the Hub)

```markdown
# Ongoing Tasks

Updated: 2026-10-06 · status-synced 2026-10-06

| # | Task | Folder | Due | Prio | Status |
|---|------|--------|-----|------|--------|
| 1 | Short title | `clients/presales/active/Acme/01-discovery` | ~2026-10-10 |  | active |
| 2 | Short title | `clients/presales/active/Acme/02-review` | 2026-10-20 |  | waiting: Acme CTO (nudge 2026-10-09) |
| 4 | Short title | `tasks/apps/04-budget-export` | 2026-10-14 | P1 | todo |

## Done

- 5. Short title: one-line result, DOC_ID (2026-10-12).
```

## The Task Folder

`<context folder>/0N-<slug>/`, with the folder patterns from `$TASKS_HUB/contexts.md`, e.g. in a work hub `clients/<group>/<status>/<Client>/0N-<slug>/` (the client's real name, no spaces) or `internal/<service>/0N-<slug>/`; in a personal hub `tasks/<area>/0N-<slug>/`:

```
task.md          the full block (below)
agent.md         the per-task agent brief (references/task-agent.md)
handoffs/        YYYY-MM-DD-HHMM.md; the latest 3 stay live
docs/            working docs
docs/archive/    YYYY-Www/ folders plus SUMMARY.md (references/archive.md)
```

Deliverables (code, repos, decks) stay where they live: in their repos, under `projects/`, or in Google. `task.md` links to them.

## task.md

```markdown
# <#>. Short title

<!-- Paths are relative to this task folder; paths starting with a top-level hub folder (e.g. clients/, internal/, projects/, tasks/) are relative to the hub. -->

- **Goal:** one line, the outcome.
- **Engagement:** the classification from `$TASKS_HUB/contexts.md`, e.g. `<domain> (<move>) · service: <slug>`.
- **Done when:** one line, a checkable condition.
- **Links:** Google ids or URLs, repos, Jira keys (work), `docs/...`.
- **Living:** change logs that are never archived (optional).
- **State:** 2-4 lines: what works, what is half-done.
- **Decisions:** dated one-liners that must not be re-litigated.
- **Open:** blockers and questions for the user.
- **Next:** the single next step, concrete enough to start cold.
- **Handoffs:** latest first, last 3: `handoffs/2026-10-05-1430.md`, ...
```

## Field Rules

| Field | Rule |
|---|---|
| `#` | Assigned once and never reused. It is also the folder prefix (`0N-`). |
| Folder | Hub-relative. |
| Due | ISO date. A `~` prefix means tentative. Every task has one. |
| Prio | Empty means computed. `P1`-`P3` is a user override that always wins; record its reason in Decisions. |
| Status | `todo`, `active`, `waiting: <who> (nudge YYYY-MM-DD)`, `blocked: <reason>` or `done`. See § Status. |

## Status

| Status | Meaning | Priority from |
|---|---|---|
| `todo` | not started | due date |
| `active` | in progress | due date |
| `waiting: <who> (nudge YYYY-MM-DD)` | the next move is someone else's | the nudge date |
| `blocked: <reason>` | cannot move, and not waiting on a person | due date |
| `done` | finished; the row moves to Done | - |

- **Nudge default:** 3 working days from today, unless the user gives a date.
- `<who>` is a name or a short role, with no parentheses in `<who>` (write `Acme, CTO`, not `Acme (CTO)`), so the `(nudge …)` part stays the only parenthesis.
- A `waiting:` row without `(nudge …)` (old or hand-edited): treat the nudge as today + 3 working days and propose the fix.
- A waiting task never gets an overdue flag. On or after its nudge date, triage proposes a follow-up: who to ping and a one-line draft. It never sends.

## The Updated Line

`Updated: YYYY-MM-DD · status-synced YYYY-MM-DD`. `Updated` changes on every write to the index; `status-synced` changes only when a triage Step 0 is confirmed. An index without `status-synced` has never been synced.

## Machine-Parseable

The index and `task.md` stay machine-parseable: one row per task, the column order above, the status prefixes above, the field labels above. A minimal web app for the Step 0 sync is under evaluation and would read and write these same files; do not add free-form variants.

## Priority (Computed When Read, Never Stored)

`days = due - today` (ignore the `~`).

| Priority | Condition |
|---|---|
| P1 | `days <= 2`, including overdue |
| P2 | `days <= 7` |
| P3 | later |

For a waiting task, priority comes from the nudge date: apply the same table to it instead of the due date.

**Sort order:** priority, then fewer days left, then firm dates before tentative ones. Display it as `P1 (override) · 3d`, `P2 · 5d`, or for overdue `P1 · -2d`.

## Done

Close-out (`references/handoff.md` § Close-out) moves a done task's row to the Done list: `- <#>. <Title>: <result>, <key link or id> (<date>)`. Its folder stays where it is.
