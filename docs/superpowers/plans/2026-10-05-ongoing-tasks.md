# nix:ongoing-tasks Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Ship the `nix:ongoing-tasks` skill and its `compaction-stats.sh` script in the `nix` plugin, version 1.1.0.

**Architecture:** A lean `SKILL.md` with two modes (triage, deep) plus three reference templates loaded on demand. A shell + `jq` script reads Claude Code session transcripts and reports compaction savings.

**Tech Stack:** Markdown skill files; bash + jq.

**Spec:** `docs/superpowers/specs/2026-10-05-ongoing-tasks-design.md`

## Global Constraints

- Tasks file default: `/Volumes/NVMe/Development/IdeaProjects/active/nix/ongoing-tasks.md`.
- Jira and Google: `nix:jira`, `nix:google`, always the `nix` profile; writes only on the user's yes; subagents never write.
- Scripts referenced as `${CLAUDE_PLUGIN_ROOT}/scripts/...`, never hardcoded cache paths.
- Max 4 subagents per triage round.
- Priority: P1 ≤2 days or overdue, P2 ≤7 days, P3 later; user override wins.
- Plugin version `1.1.0`.

## Review Focus

- A transcript with no compactions: the script prints `Compactions: 0`, exits 0.
- A compaction with no assistant turn after it (session ended): "after" shows `?`, the row still prints.
- Transcript lines that aren't JSON objects with the expected fields: skipped, no jq crash.
- Default transcript lookup when `$CLAUDE_CONFIG_DIR` is unset: falls back to `~/.claude`.
- A folder path with spaces (e.g. `Claude Code usage assessment`): the project-dir mangling (`/` and spaces → `-`) still finds it.

---

### Task 1: compaction-stats.sh

**Files:**
- Create: `plugins/nix/scripts/compaction-stats.sh`
- Test: `plugins/nix/scripts/tests/compaction-stats.test.sh`, fixtures in `plugins/nix/scripts/tests/fixtures/`

**Interfaces:**
- Produces: `compaction-stats.sh [--json] [SESSION_ID | PATH.jsonl]`. Text mode prints the three "Session stats" lines from the spec; `--json` prints one JSON object per compaction: `{n, trigger, kind, pre, post, reduction, durationMs}`.

- [ ] Step 1: write fixtures: `builtin.jsonl` (boundary pre=100000, an `isCompactSummary` user line, an assistant with usage summing to 40000), `jev.jsonl` (boundary pre=200000, plain user/assistant lines, assistant usage summing to 70000), `none.jsonl`, `tail.jsonl` (boundary as the last line).
- [ ] Step 2: write the test script asserting the outputs; run it, see it fail.
- [ ] Step 3: implement the script; run the test, see it pass.
- [ ] Step 4: run on the two real `~/.claude` subagent transcripts; check `preTokens` against raw `jq`.
- [ ] Step 5: commit.

### Task 2: the skill

**Files:**
- Create: `plugins/nix/skills/ongoing-tasks/SKILL.md`
- Create: `plugins/nix/skills/ongoing-tasks/references/tasks-format.md`, `handoff.md`, `dispatch.md`

**Interfaces:**
- Consumes: `compaction-stats.sh` from Task 1.

- [ ] Step 1: write the three references from spec sections 1, 5 and the dispatch summary.
- [ ] Step 2: write `SKILL.md`: frontmatter, argument parsing, triage steps, deep steps, concurrency, Jira/Google rules, pointers to references.
- [ ] Step 3: check every spec section maps to a file; check `SKILL.md` stays lean (under ~150 lines).
- [ ] Step 4: commit.

### Task 3: version and docs

**Files:**
- Modify: `plugins/nix/.claude-plugin/plugin.json` (version 1.1.0, description, keywords)
- Modify: `.claude-plugin/marketplace.json` (description)
- Modify: `README.md` where it lists the nix plugin's skills, if it does

- [ ] Step 1: edit; validate JSON with `jq .`.
- [ ] Step 2: load test: `claude --plugin-dir plugins/nix -p "list your skills"`, or check via a fresh session that `nix:ongoing-tasks` shows.
- [ ] Step 3: commit.
