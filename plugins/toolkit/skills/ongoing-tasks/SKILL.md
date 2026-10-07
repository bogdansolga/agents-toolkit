---
name: ongoing-tasks
description: "Use to review, extend and continue the ongoing tasks in the task hub ($TASKS_HUB: index ongoing-tasks.md, one folder per task, placed by the hub's contexts.md): triage the index, add tasks, archive stale docs (7-day rolling window), delegate work to per-task agents, or run a focused deep session on one task, with handoffs and compaction stats. Works in any profile whose env sets TASKS_HUB, e.g. a work hub and a personal hub. Trigger on /ongoing-tasks, 'continue the tasks', 'add a task', or 'work on task N'."
argument-hint: "[task number] [path to the index]"
---

# ongoing-tasks

Keeps tasks moving across projects, folders and sessions, in the hub of the active profile (work or personal); the skill is the same for both. Goals, in order: reliable high-quality results; parallel work where it is easy; low token use and elapsed time.

## The Hub

- **Hub:** `$TASKS_HUB`, set in the profile's `settings.json` `env`: each profile points at its own hub (e.g. a work hub and a personal hub). If it is unset, say this profile has no task hub and stop. Start Claude Code in the hub; its `CLAUDE.md` holds the standing rules.
- **Index:** `ongoing-tasks.md`. One table row per task, plus the Done list. An argument ending in `.md` overrides it.
- **Contexts:** `$TASKS_HUB/contexts.md` (private, in the hub) defines where tasks go (e.g. client and internal folders in a work hub, area folders in a personal hub), how tasks are classified, and the Engagement field's values. Read it before adding a task. If it's missing, offer to create it from `references/contexts.md`.
- **Task folder:** `<context folder>/0N-<slug>/`, as `contexts.md` defines (e.g. `clients/<group>/<status>/<Client>/0N-<slug>/` or `tasks/<area>/0N-<slug>/`). It holds `task.md` (the full block), `handoffs/`, `docs/`, `docs/archive/` and `agent.md`.
- **Pilot log:** `ongoing-tasks-pilot.md`. Its Decisions table binds this skill; read it on every run. If the hub has none, skip the pilot-log steps.
- **Formats:** `references/tasks-format.md` (index, task.md, priority). Read it before the first edit in a session.

## Arguments → Mode

- No task number → **Triage**.
- A task number (`3`) → **Deep** on that task.

## Resume Contract

To continue a task, a session reads `task.md`, then the latest handoff, then `docs/archive/SUMMARY.md` only when the handoff points there. Whatever a cold session would need goes into one of those before the session ends.

## Triage

1. **Read** the index and the pilot log. Compute each task's priority and days left. Open a `task.md` only to check for drift.
2. **Review and refine.**
   - Flag past-due dates, a missing Done-when or Next, a status that contradicts the latest handoff, missing folders and missing due dates.
   - Apply mechanical fixes directly. Propose changes to a goal, due date, priority or scope.
3. **Add tasks** the user describes:
   - Ask for the context (per `contexts.md`: e.g. a client, an internal service or a personal area) and the due date (tentative is fine).
   - Take the next number and create the folder.
   - Write `task.md` with every field.
   - Generate `agent.md` from `references/task-agent.md`.
   - Add the index row.
4. **Archive sweep** (rolling window, `references/archive.md`): for each active task, move unreferenced docs older than 7 days into `docs/archive/YYYY-Www/`, and update `SUMMARY.md`.
5. **Check links** (reads only, and only when the profile sets `JIRA_ENV`): Jira status and due dates for tasks with a Jira key.
6. **Plan the round,** by priority. Each task's Next is either:
   - *delegable*: bounded, verifiable, no decision needed from the user;
   - *deep*: needs design, a judgement call or the user.
7. **Delegate** delegable steps to the task agents (`references/task-agent.md`): one message, at most 4 in parallel. Within a session, follow up with SendMessage to the same agent.
8. **Verify, then record.**
   - Check every claim: read the diff, re-run the check, look at the render.
   - Write the short-form handoff (`references/handoff.md`).
   - Update `task.md` and the index row, and append the pilot log row.
   - Present PROPOSED WRITES to the user; do none without a yes.
9. **Report,** sorted by priority (`| # | Task | Prio · days | Moved | Needs you |`), with the deep sessions to start.

## Deep

1. Read `task.md`, then the latest handoff, and run its state-check commands if it has any.
2. Restate State and Next in 2-4 lines, then start. Ask first only if Next is ambiguous.
3. **Design and decisions stay in this session.** Brainstorming, approvals and anything that needs the user happen here.
4. **Bounded work goes to the task's agent:** builds, adaptations, renders, research. Verify everything it returns.
5. **Wrap up** when the user says so, or before context gets heavy:
   - write the handoff, with Session stats from `bash "${CLAUDE_PLUGIN_ROOT}/scripts/compaction-stats.sh"`;
   - update `task.md`, the index row and the pilot log;
   - propose a commit; commit only on a yes, and push only on a separate yes.

## Concurrency

Several sessions may run at once.
- Re-read a file right before editing it.
- Use targeted edits, never whole-file writes.
- A deep session edits only its own `task.md`, its own index row and the Updated line.

## External Tools (Google, Jira)

Always through this plugin's `google` and `jira` skills. The profile's env picks the accounts (`GOOGLE_PROFILE`, `JIRA_ENV`); never pass or switch a profile. A tool whose variable is unset is off in this profile (e.g. no Jira in a personal hub): skip it and never fall back to another account.

- **In scope, no extra approval:** files and issues listed in `task.md` Links, and copies made for the step. Snapshot an existing Google file before editing it, re-read before each edit, and render to check each batch.
- **Needs the user's yes:** deletes, sharing changes, comments, anything sent outside (to a client, a partner or the public), any write outside the task's scope.
- **Logging:** every write and snapshot id goes into the handoff.
- **Never print tokens.**

## Red Flags

| Thought | Do instead |
|---|---|
| "I'll rewrite the whole file, it's quicker" | Targeted edits; another session may be writing. |
| "The agent said it's done" | Check the evidence: diff, render, rerun. |
| "I'll update task.md later" | Now; the next session may start cold. |
| "Old docs are clutter; delete them" | Archive (move) and summarise; never delete. |
| "The agent can decide this" | Decisions that need the user stay in the main session. |
| "One more agent in this round" | Max 4 in parallel; lower priority waits. |
