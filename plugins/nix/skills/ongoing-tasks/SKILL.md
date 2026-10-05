---
name: ongoing-tasks
description: "Use to review, extend and continue the N-iX ongoing-tasks list at IdeaProjects/active/nix/ongoing-tasks.md: triage it (refine, add tasks, dispatch small steps to parallel subagents) or run a focused deep session on one task, with handoff docs and Jev compaction stats. Trigger on /nix:ongoing-tasks, 'continue the nix tasks', 'add a task to ongoing tasks', or 'work on task N'."
argument-hint: "[task number] [path to tasks file]"
---

# nix:ongoing-tasks

Keeps a small set of N-iX tasks moving across folders and sessions. Goals, in order: reliable high-quality results, parallel work where it is easy, low token use and elapsed time.

- **Tasks file:** `/Volumes/NVMe/Development/IdeaProjects/active/nix/ongoing-tasks.md` (an argument ending in `.md` overrides it).
- **Pilot log:** `ongoing-tasks-pilot.md` next to it. Its Decisions table binds this skill; read it on every run.
- **Format and priority rules:** `references/tasks-format.md`. Read it before editing the file for the first time in a session.

## Arguments → mode

- No task number → **Triage**.
- A task number (`3`) → **Deep** on that task.

## Resume contract

A session needs only the task block plus its latest handoff to continue. Keep both complete enough for that: if you learned something a cold session would need, it goes into one of them before the session ends.

## Triage

1. **Read** the tasks file and the pilot log. Compute each task's priority and days left (`references/tasks-format.md`). Open handoffs only to check for drift.
2. **Review and refine.** Flag: past-due dates, missing Done when / Next, status contradicting the latest handoff, missing folders, missing due dates. Apply mechanical fixes directly (format, Updated, moving done tasks to Done). Propose changes to goal, due, priority or scope and apply them only after the user agrees.
3. **Add tasks** the user describes: ask for folder and due date if missing (tentative is fine), check the folder exists, take the next number, fill every block field.
4. **Check links** (reads only): for active tasks with a Jira key, `jira.sh get <KEY>` and flag status or due-date drift.
5. **Plan the round**, by priority. Each active task's Next is either *dispatchable* (small, independent, verifiable) or *deep* (needs design, judgement, the user, or any Jira/Google write).
6. **Dispatch** dispatchable steps per `references/dispatch.md`: one message, one subagent per task, at most 4; lower priority waits.
7. **Verify, then record.** Check every returned claim (diff, rerun the check, re-read the doc). Write a short-form handoff per moved task (`references/handoff.md`), update blocks and rows, append pilot log rows. Present PROPOSED WRITES to the user; perform none without a yes.
8. **Report**, sorted by priority:

   | # | Task | Prio · days | Moved | Needs you |
   |---|---|---|---|---|

   Then the deep sessions to start, each as a command: `/nix:ongoing-tasks 3`.

## Deep

1. Read task `<#>`'s block and its latest handoff. Older handoffs only if the latest one points to them. Run the latest handoff's state-check commands if it has any.
2. Restate State and Next in 2-4 lines, then start. Ask first only if Next is ambiguous or the handoff and the block disagree.
3. Work in the task folder. Use the matching Superpowers skills: brainstorming for new design or unclear scope, test-driven-development for code, verification-before-completion before claiming done. Parallelize independent sub-steps with subagents (`references/dispatch.md` rules apply to them).
4. **Wrap up** when the user says so, or before context gets heavy:
   - write the handoff (`references/handoff.md`) with Session stats from `bash "${CLAUDE_PLUGIN_ROOT}/scripts/compaction-stats.sh"`;
   - update the task block and its row;
   - append the pilot log row;
   - propose a commit of the handoff and work; commit only on the user's yes. Never push without a separate yes.

## Concurrency

Several deep sessions may run at once. Re-read the tasks file immediately before every edit and use targeted Edit replacements, never a whole-file Write. A deep session edits only its own block, its own table row and the Updated line. Only triage edits other tasks and the Done list.

## Jira and Google

Always through this plugin, always the `nix` profile:

- **Jira:** the `nix:jira` skill; `${CLAUDE_PLUGIN_ROOT}/scripts/jira.sh`, with `set -a; source ~/.config/nix/jira.env; set +a` in the same shell call.
- **Google:** the `nix:google` skill; `${CLAUDE_PLUGIN_ROOT}/scripts/gdocs.sh | gsheet.sh | gslides.sh | gdrive.sh`, first argument `nix`. Never `personal`.

Reads are free in any mode. Writes (Jira comments, transitions, field edits, new issues; Google copies, edits, comments) are outward-facing: propose, wait for the user's yes, then do them in the main session. Snapshot a Google file (`gdrive.sh nix copy <id> --name ...`) before a large edit. Subagents never write. Never print tokens.

## Red flags

| Thought | Do instead |
|---|---|
| "I'll rewrite the whole tasks file, it's quicker" | Targeted edits; another session may be writing. |
| "The subagent said tests pass" | Rerun or read the evidence before recording it. |
| "I'll summarize the handoff in the block later" | Update the block now; the next session may start cold. |
| "This Jira comment is obviously fine" | Propose it; wait for the yes. |
| "One more task in this round" | Max 4 subagents; lower priority waits. |
