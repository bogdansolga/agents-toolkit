---
name: ongoing-tasks
description: "Use to review, extend and continue the N-iX ongoing tasks in the hub IdeaProjects/active/nix (index ongoing-tasks.md, one folder per task under clients/<presales|upsales>/<active|inactive>/<Client>/ or internal/<service>/): triage the index, add tasks, archive stale docs (7-day rolling window), delegate work to per-task agents, or run a focused deep session on one task, with handoffs and Jev compaction stats. Trigger on /ongoing-tasks, 'continue the nix tasks', 'add a task', or 'work on task N'."
argument-hint: "[task number] [path to the index]"
---

# ongoing-tasks

Keeps N-iX tasks moving across clients, folders and sessions. Goals, in order: reliable high-quality results; parallel work where it is easy; low token use and elapsed time.

## The Hub

- **Hub:** `$TASKS_HUB`, set in the profile's `settings.json` `env` (work: `/Volumes/NVMe/Development/IdeaProjects/active/nix`). If it is unset, say this profile has no task hub and stop. Start Claude Code in the hub; its `CLAUDE.md` holds the standing rules.
- **Index:** `ongoing-tasks.md`. One table row per task, plus the Done list. An argument ending in `.md` overrides it.
- **Contexts:** every task is a client task (`clients/<presales|upsales>/<active|inactive>/<Client>/`, almost always active) or an internal one. Every engagement is placed on the N-iX AI Delivery Model (L1-L5) as APEX Acceleration (L1/L2 → L3) or APEX Transformation (L3 → L4), with services within both. `references/contexts.md` holds the level summaries, the domains and the services; read it before adding a task, instead of the deck.
- **Task folder:** `clients/<presales|upsales>/<active|inactive>/<Client>/0N-<slug>/` or `internal/<service>/0N-<slug>/`. It holds `task.md` (the full block), `handoffs/`, `docs/`, `docs/archive/` and `agent.md`.
- **Pilot log:** `ongoing-tasks-pilot.md`. Its Decisions table binds this skill; read it on every run.
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
   - Ask for the client (or `internal`) and the due date (tentative is fine).
   - Take the next number and create the folder.
   - Write `task.md` with every field.
   - Generate `agent.md` from `references/task-agent.md`.
   - Add the index row.
4. **Archive sweep** (rolling window, `references/archive.md`): for each active task, move unreferenced docs older than 7 days into `docs/archive/YYYY-Www/`, and update `SUMMARY.md`.
5. **Check links** (reads only): Jira status and due dates for tasks with a Jira key.
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

## Jira and Google

Always through this plugin's `jira` and `google` skills. The profile's env picks the account (`JIRA_ENV`, `GOOGLE_PROFILE`); never pass or switch a profile.

- **In scope, no extra approval:** files and issues listed in `task.md` Links, and copies made for the step. Snapshot an existing Google file before editing it, re-read before each edit, and render to check each batch.
- **Needs the user's yes:** deletes, sharing changes, comments, anything sent to a client, any write outside the task's scope.
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
