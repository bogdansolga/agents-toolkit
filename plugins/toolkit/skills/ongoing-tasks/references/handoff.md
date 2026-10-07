# Handoff template

Path: `<task folder>/handoffs/YYYY-MM-DD-HHMM.md` (local time). The latest 3 stay live; older ones are archived by the rolling-window sweep (`references/archive.md`).

Each handoff stands alone: a new session reads only this file and the task block. Write facts a cold reader needs, not a diary.

```markdown
# Task <#>: <title> (handoff YYYY-MM-DD HH:MM)

## Done this session
- What changed, with paths, commits, Jira keys (if the profile has Jira), doc links.

## Verified
- Commands run and their results (tests, builds, rendered checks, re-read docs).

## State and next
- Where things stand.
- Next: the single next step (copy it to the task block's Next).

## Decisions and gotchas
- What a new session must know but could not guess from the code or docs.

## Session stats
- Mode: deep · <script line 1>
- <script line 2>
- <script line 3>
```

Fill Session stats from `bash "${CLAUDE_PLUGIN_ROOT}/scripts/compaction-stats.sh"`, run from the folder the session started in (it finds the newest transcript for that folder in the active profile). If it picks the wrong session, pass the session id.

## Triage short form

Written by the orchestrator for each task a subagent moved:

```markdown
# Task <#>: <title> (handoff YYYY-MM-DD HH:MM, triage)

## Done this session
## Verified
## State and next

- Mode: triage-dispatch · subagent
```

## After writing

1. Add the path to the front of the Handoffs line in `task.md` (keep 3).
2. Update State, Decisions, Open and Next in `task.md`, and the Status in the index row.
3. Append a row to the pilot log Observations table (the hub's `ongoing-tasks-pilot.md`):
   `| date | #<n> | mode | compactions | avg reduction | fallbacks | note |`
