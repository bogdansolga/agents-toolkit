# Per-Task Agents

Each task folder has an `agent.md`: a thin brief the main session passes to a subagent working on that task. The agent's knowledge lives in files: `task.md`, the latest handoff and `docs/archive/SUMMARY.md`. That way it survives sessions and compactions.

## agent.md Template (Generated When a Task Is Added; the User Can Edit It)

```markdown
# Agent: task <#> - <title>

## Read First
1. <task folder>/task.md
2. the latest file in <task folder>/handoffs/
3. <task folder>/docs/archive/SUMMARY.md, only if the handoff points there

## Standing Rules for This Task
- <rules learned on this task, e.g. "the agenda line is exactly: <the agreed wording>">
- <e.g. "a product fact, in its verified wording">
- Hub rules: $TASKS_HUB/CLAUDE.md

## Write Scope
- Allowed: <Google file ids, repos, folders>; snapshot existing Google files first.
- Never: delete, share, comment, send anything outside (clients, partners, public), push, commit (unless the step says so).

## Return (≤15 lines)
CHANGED · WRITES DONE (ids, snapshots) · VERIFIED (command or render → result) · PROPOSED WRITES · NEXT · BLOCKERS
```

## How the Main Session Uses It

1. **Delegate:** run the `Agent` tool (general-purpose) with the prompt: the contents of `agent.md`, then `STEP: <the exact request>` and `VERIFY BY: <the check>`. Run it in the background when other work can go on in parallel.
2. **Follow up in the same session:** send the next request with `SendMessage` to the same agent. It keeps its context, so there's no re-reading. Use this for "change X", "redirect to Y", "fix the render".
3. **Verify** every claim before recording it, then write the handoff and update `task.md`.
4. **Learn:** when an agent repeats a mistake that the main session had to correct (for example a wording rule), add the rule to that task's `agent.md` under Standing Rules.

## What Stays in the Main Session

- Brainstorming, design choices, priorities, anything that needs the user.
- Decisions about Google, Jira (when the profile has it) or Git actions that need a yes.
- Writing `task.md`, the index and the handoff. The agent proposes; the main session records.
