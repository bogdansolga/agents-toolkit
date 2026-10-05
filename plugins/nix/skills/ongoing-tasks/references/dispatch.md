# Subagent dispatch

Send all of a round's dispatches in ONE message (parallel), at most 4. Use `subagent_type: "general-purpose"`. Add `isolation: "worktree"` when the step changes code in a git repo; plain docs and data pulls run in place.

## Prompt template

Fill every `<...>`; paste the task block verbatim, don't summarize it.

```text
You are working on one task from an ongoing-tasks list. Do only the step below.

TASK BLOCK:
<the task's block from ongoing-tasks.md>

FOLDER: /Volumes/NVMe/Development/IdeaProjects/<folder>
LATEST HANDOFF: <path, or "none">. Read it first if it exists.

STEP: <the exact step, one deliverable>
VERIFY BY: <the command or check that proves it worked>

RULES:
- Stay inside FOLDER. Do not edit ongoing-tasks.md or write handoffs; the orchestrator does that.
- Jira: use the nix:jira skill (jira.sh, source ~/.config/nix/jira.env in the same shell call).
  Google: use the nix:google skill (gdocs.sh / gsheet.sh / gslides.sh / gdrive.sh), first arg always `nix`.
  READ ONLY. Never comment, transition, edit or create in Jira or Google: put the write you would make under PROPOSED WRITES.
- Never print tokens. Do not commit or push unless STEP says so.
- If the step turns out bigger or unclear, stop and report it under BLOCKERS instead of guessing.

RETURN (at most ~15 lines, no preamble):
CHANGED: paths, commits, doc ids
VERIFIED: command → result
PROPOSED WRITES: Jira/Google writes for the user to approve, or "none"
NEXT: the suggested next step
BLOCKERS: or "none"
```

## On return

Verify each claim before recording it: read the diff (`git -C <folder> diff --stat`, or the worktree branch), rerun VERIFY BY if cheap, re-read the doc for Google work. A claim you could not verify is recorded as unverified in the handoff.
