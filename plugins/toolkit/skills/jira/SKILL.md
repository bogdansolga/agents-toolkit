---
name: jira
description: "Use when reading, creating, linking, labeling, attaching to, commenting on, or updating Jira issues in the Jira Cloud instance named by this profile's JIRA_ENV — epics/stories/tasks, dependency links, web links, due dates, adapt/net-new tags. Driven by the bundled jira.sh CLI (shell + curl + jq, no MCP). Trigger on issue-key ticket work (e.g. PROJ-123), an *.atlassian.net URL, or a Jira request."
---

# jira: Jira Cloud CLI

Drive Jira via the bundled `jira.sh` (shell/`curl`/`jq`, no install). The instance is the `JIRA_BASE_URL` in the profile's `JIRA_ENV` file.

## Script

Bundled with this plugin at `${CLAUDE_PLUGIN_ROOT}/scripts/jira.sh`. Always reference it via the `${CLAUDE_PLUGIN_ROOT}` variable (the plugin is copied to a cache on install — hardcoded paths break).

## Auth

The work profile sets `JIRA_ENV` in its `settings.json` `env` to a token file, e.g. `~/.config/jira/work.env` (`chmod 600`, git-ignored), which holds `JIRA_BASE_URL`, `JIRA_EMAIL`, `JIRA_API_TOKEN`. **Source it in the SAME shell as the `jira.sh` call** (env doesn't persist across shell invocations):

```bash
: "${JIRA_ENV:?no Jira in this profile: set JIRA_ENV in its settings}"; set -a; source "$JIRA_ENV"; set +a
J="${CLAUDE_PLUGIN_ROOT}/scripts/jira.sh"
"$J" get PROJ-123
```

`jira.sh` reads these as env vars (`JIRA_BASE_URL`→base URL, `JIRA_EMAIL`→user, `JIRA_API_TOKEN`→token; `CONFLUENCE_*` also accepted), so it works from any directory. It also falls back to any `.env` it finds by searching upward from the script dir / CWD. Never print the token.

> If `JIRA_ENV` is unset, this profile has no Jira; say so and stop. If the file is missing (fresh machine), create it with the three `JIRA_*` vars (Atlassian API token from id.atlassian.com), `chmod 600`. Keep it out of git.

## Commands

```bash
"$J" get KEY                         # key/type/status/summary/parent/labels/duedate/links (human-readable)
"$J" get-text KEY                    # summary + description as plain text
"$J" search "JQL"                    # e.g. "project=PROJ AND labels=net-new ORDER BY key"
"$J" create PROJ TYPE "summary" DESCFILE [--parent KEY] [--due YYYY-MM-DD] [--label L]...
"$J" link BLOCKER BLOCKED [TYPE]     # default "Blocks": link A B → "A blocks B" (B depends on A)
"$J" unlink A B                      # remove the link between two issues
"$J" set-desc KEY DESCFILE  ·  set-due KEY YYYY-MM-DD  ·  label-add KEY lbl  ·  attach KEY file
"$J" weblink KEY URL "title"  ·  comment KEY "text"  ·  children EPIC  ·  types PROJ  ·  link-types
```

## Gotchas

- **Jira Cloud removed the v2 `/search`** (HTTP 410) → `jira.sh` uses **v3 `/search/jql`**.
- **Labels cannot contain spaces** — use hyphens (`Agentic-Kit`, `net-new`, `adapt`).
- **Link direction:** `link BLOCKER BLOCKED` stores "BLOCKER blocks BLOCKED"; `get` renders `blocks X` / `is blocked by X`.
- Descriptions/comments are plain text (REST v2), not ADF — write to a temp file, pass its path.
- After bulk label/link ops, verify via `get` (authoritative) not `search` — the index lags a few seconds.
- **Confidentiality:** work ticket content stays in work repos; never commit it to personal repos. The token lives only in the `JIRA_ENV` file.
