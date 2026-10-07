# Index and task.md Formats

## The Index: `ongoing-tasks.md` (in the Hub)

```markdown
# Ongoing Tasks

Updated: 2026-10-06

| # | Task | Folder | Due | Prio | Status |
|---|------|--------|-----|------|--------|
| 1 | Short title | `clients/presales/active/Acme/01-discovery` | ~2026-10-10 |  | active |
| 4 | Short title | `tasks/apps/04-budget-export` | 2026-10-14 | P1 | todo |

## Done

- 5. Short title: one-line result (2026-10-12).
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
| Status | `todo`, `active`, `blocked: <reason>` or `done`. |

## Priority (Computed When Read, Never Stored)

`days = due - today` (ignore the `~`).

| Priority | Condition |
|---|---|
| P1 | `days <= 2`, including overdue |
| P2 | `days <= 7` |
| P3 | later |

**Sort order:** priority, then fewer days left, then firm dates before tentative ones. Display it as `P1 (override) · 3d`, `P2 · 5d`, or for overdue `P1 · -2d`.

## Done

Triage moves a done task's row to the Done list: `- <#>. <title>: <result> (<date>)`. Its folder stays where it is.
