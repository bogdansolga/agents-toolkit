# nix:ongoing-tasks: Design

Date: 2026-10-05 · Status: draft for review · Pilot log: `IdeaProjects/active/nix/ongoing-tasks-pilot.md`

## Purpose

One skill that keeps a small set of N-iX work tasks moving across many folders and sessions. It reads `IdeaProjects/active/nix/ongoing-tasks.md`, refines it, adds tasks, and continues the work: in parallel where that is easy, reliably, to a high quality bar, while keeping token use and elapsed time low. Each task gets handoff docs. Jev compaction savings are measured as we go, to judge whether Jev pays off.

## Decisions (from brainstorming)

- Interactive only: the user invokes the skill. No scheduled or unattended runs for now.
- Tasks are independent and may live in different repos.
- Hybrid modes: no argument = triage; a task number = focused deep session.
- The tasks file stays minimal, but each task block carries enough state to resume in a new session from the block plus the latest handoff.
- The skill lives in the `nix` plugin of `claude-config`, so both profiles (`~/.claude`, `~/.claude-nix`) load it.
- Jev is measured from session transcripts by a script; no extra hook.
- Jira and Google access always uses the `nix` profile, through the plugin's `nix:jira` and `nix:google` skills.

## 1. The tasks file

Path: `/Volumes/NVMe/Development/IdeaProjects/active/nix/ongoing-tasks.md`. A skill argument that is a path overrides it.

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

Field rules:

- **#**: assigned once, never reused or renumbered.
- **Folder**: relative to `/Volumes/NVMe/Development/IdeaProjects/`; `(none)` when there is no source folder.
- **Due**: ISO date; a `~` prefix marks it tentative. Every task has one.
- **Prio**: empty = computed; `P1`–`P3` = user override, which always wins. A reason for an override goes in Decisions.
- **Status**: `todo`, `active`, `blocked: <reason>`, `done`. Triage moves `done` tasks from the table and their blocks to `## Done`.
- **Links**: optional; Jira keys and Google Docs/Sheets/Slides/Drive URLs.
- **Updated**: date of the last change to the file.

### Priority

Computed at read time from days remaining (`due - today`), never stored:

- **P1**: overdue, or 2 days or less.
- **P2**: 7 days or less.
- **P3**: later.

Sort order: priority, then fewer days remaining, then firm before tentative due dates. Reports show it as `P1 (override) · 3d` or `P2 · 5d`; overdue shows as `-2d`.

### Resume contract

A new session reads the task block and the latest handoff, and nothing else, before starting. Whatever a session must know to continue belongs in one of those two places.

## 2. Triage mode: `/nix:ongoing-tasks`

1. **Read** the tasks file and the pilot log's Decisions. Open handoffs only to check for drift.
2. **Review and refine.** Flag past-due dates, a missing Done-when or Next, a status that contradicts the latest handoff, folders that no longer exist, and tasks with no due date. Apply mechanical fixes directly (formatting, the Updated date, moving done tasks). Propose changes to goal, due date, priority or scope; apply them only after the user agrees.
3. **Add tasks** the user describes: ask for the folder and due date if missing (a tentative date is fine), check that the folder exists, assign the next number, fill every field of the block.
4. **Check links** (cheap reads only): for each active task with a Jira key, `jira.sh get` its status and due date and flag drift against the block.
5. **Plan the round.** Sort by priority. Classify each active task's Next step:
   - *dispatchable*: small, independent, verifiable (a fix, a doc, research, a data pull);
   - *deep*: needs design, a judgement call, or the user.
6. **Dispatch** dispatchable steps in a single message, one subagent per task, at most 4 per round; the lowest-priority steps wait. Code-changing steps use `isolation: "worktree"` when the folder is a git repo. Each subagent gets the prompt in `references/dispatch.md`.
7. **Verify, then record.** Check each subagent claim against the diff, test output or fetched data. Update the task blocks, write a short-form handoff for each task that moved, append the stats rows to the pilot log.
8. **Report** a table sorted by priority: task, priority · days, what moved, what needs the user, and for deep tasks the exact command to run (`/nix:ongoing-tasks 3`).

## 3. Deep mode: `/nix:ongoing-tasks <#>`

1. Read the task block and its latest handoff. Read older handoffs only when the latest one points to them.
2. Restate state and next step in a few lines, then start. Ask first only if the next step is ambiguous.
3. Work in the task's folder with the matching Superpowers skills: brainstorming for new design, test-driven-development for code, verification-before-completion before claiming anything is done.
4. Wrap up when the user says so, or before context gets heavy:
   - write the handoff (`references/handoff.md`);
   - run `compaction-stats.sh` on the current session and paste its lines into the handoff;
   - update the task block (State, Decisions, Open, Next, Handoffs) and its table row;
   - append a stats row to the pilot log;
   - propose a commit of the handoff and work; commit only on the user's yes.

### Concurrency rule

Several deep sessions may run at once. A session re-reads the tasks file immediately before editing it and edits with targeted replacements, never a whole-file rewrite. A deep session edits only its own block, its own table row, and the Updated line. Only triage edits other tasks and the Done list.

## 4. Jira and Google access

Both come from this plugin and always use the `nix` profile:

- **Jira**: the `nix:jira` skill and `${CLAUDE_PLUGIN_ROOT}/scripts/jira.sh`, with `~/.config/nix/jira.env` sourced in the same shell call.
- **Google**: the `nix:google` skill and `${CLAUDE_PLUGIN_ROOT}/scripts/gdocs.sh`, `gsheet.sh`, `gslides.sh`, `gdrive.sh`, always with `nix` as the first argument. Never `personal`.

Rules:

- Reads (issue status, comments, document text) are allowed in both modes and in subagents.
- Writes (Jira comments, transitions, field changes, new issues; Google doc edits) are outward-facing: propose them and wait for the user's yes. A subagent never writes to Jira or Google; it returns the proposed write for the orchestrator to present.
- Tokens are never printed.
- The dispatch prompt names the two skills and the `nix` profile so subagents use them without rediscovering auth.

## 5. Handoffs

Location: `<folder>/docs/handoffs/YYYY-MM-DD-HHMM.md`; for `(none)` tasks, `IdeaProjects/active/nix/handoffs/<#>/YYYY-MM-DD-HHMM.md`.

```markdown
# Task 3: Short title (handoff 2026-10-05 14:30)

## Done this session
- What changed, with paths, commits, Jira keys, doc links.

## Verified
- Commands run and their results.

## State and next
- Where things stand; the single next step (copied to the task block).

## Decisions and gotchas
- What a new session must know but could not guess from the code.

## Session stats
- Mode: deep | triage-dispatch · Duration: 1h40m · Session: <id>
- Compactions: 2 · Jev: 2, fallback: 0
- Tokens: 168.9k → 61.2k (-64%), 151.0k → 58.4k (-61%) · compaction time 3.1m
```

Each handoff stands alone. The triage short form has the first three sections plus one stats line (`Mode: triage-dispatch · subagent, no compaction`).

## 6. Jev measurement: `scripts/compaction-stats.sh`

- Shell and `jq`, like the plugin's other scripts.
- Input: a session id or a `.jsonl` path. Default: the newest transcript for the current folder under the active profile (`$CLAUDE_CONFIG_DIR`, else `~/.claude`) `projects/` directory.
- For each `compact_boundary` entry: `preTokens` and `durationMs` from `compactMetadata`; "after" = input + cache-read + cache-creation tokens of the next assistant message's usage.
- Classifies each compaction as `jev` or `builtin`. Working hypothesis: Jev keeps the original messages after the boundary, built-in leaves a single summary message. Confirm on a real Jev compaction before relying on it; until confirmed, print `unverified`.
- Output: the three Session stats lines above. `--json` prints one row per compaction.

Pilot log rollup: one row per handoff in an Observations table: date, task, mode, compactions, average reduction, fallbacks.

## 7. Files

In `claude-config/plugins/nix/`:

```
skills/ongoing-tasks/
  SKILL.md              # lean: rules, both modes, priority, concurrency, Jira/Google rules
  references/
    tasks-format.md     # table, block, Done list, priority computation
    handoff.md          # handoff template and short form
    dispatch.md         # subagent prompt template and return format
scripts/
  compaction-stats.sh
```

`SKILL.md` loads on every call, so it holds steps and rules only; templates live in `references/` and are read at the step that needs them. Also: bump the plugin to `1.1.0`; update the descriptions in `plugins/nix/.claude-plugin/plugin.json` and `.claude-plugin/marketplace.json`; update the README where it lists the plugin's skills.

### Dispatch prompt (summary)

Given to each subagent: the task block, the latest handoff path, the exact step, how to verify it, the folder, the worktree note, and the Jira/Google rules from section 4. Required return, at most about 15 lines: what changed (paths, commits), verification command and result, proposed Jira/Google writes if any, suggested next step, blockers.

## 8. Install and testing

- During the pilot: `claude --plugin-dir /Volumes/NVMe/Development/IdeaProjects/active/personal/claude-config/plugins/nix`.
- Release: commit and push (user's yes for each), then in both profiles `claude plugin marketplace update nix-config` and `claude plugin update nix@nix-config`.
- Stats script: run on the two existing `~/.claude` transcripts with compactions and check by hand against the raw `compactMetadata`.
- Triage: the first real run is on the empty file, adding the user's 5 tasks.
- Deep mode: tested on the first task taken deep, ending with a handoff.
- Findings (slow steps, token-heavy steps) go to the pilot log's Observations.

## Out of scope

- Scheduled or unattended runs.
- A logging hook for Jev's per-decision detail.
- Updating `claude-config/claude-home/settings.json` (stale; tracked separately in the pilot log).
