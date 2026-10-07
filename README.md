# agents-toolkit

A Claude Code marketplace, `bogdansolga`, with one plugin, `toolkit`, installed in every profile. The type of work picks the identity: the active profile's `settings.json` `env` decides which Google account, Jira instance, Git identity and task hub are used. No command or skill names a profile.

| Profile | Config dir | Used for |
|---|---|---|
| work | e.g. `~/.claude-work` (`CLAUDE_CONFIG_DIR=~/.claude-work`) | work: clients, internal tasks, Jira |
| personal | `~/.claude` (the default) | personal projects |

## Install

In each profile (prefix with `CLAUDE_CONFIG_DIR=<dir>` for a non-default profile):

```bash
claude plugin marketplace add bogdansolga/agents-toolkit
claude plugin install toolkit@bogdansolga
```

Then set the profile env (below) in that profile's `settings.json` and restart Claude Code.

## Update

After a push to `main`, in each profile:

```bash
claude plugin marketplace update bogdansolga
claude plugin update toolkit@bogdansolga
```

Restart running sessions to load the new version. Bump `version` in `plugins/toolkit/.claude-plugin/plugin.json` with every release; `update` compares versions, so it never downgrades. To go back to a lower version, uninstall and reinstall.

## Profile Env

Set these under `env` in each profile's `settings.json`:

| Variable | work (example) | personal (example) | Used by |
|---|---|---|---|
| `GOOGLE_PROFILE` | `work` | `personal` | `google` skill and scripts: the OAuth token is `~/.config/google/<profile>/token.json` |
| `JIRA_ENV` | `~/.config/jira/work.env` | unset: no Jira | `jira` skill: the file holds `JIRA_BASE_URL`, `JIRA_EMAIL`, `JIRA_API_TOKEN` (`chmod 600`) |
| `GIT_SSH_HOST` | `github-work` | unset: `github.com` | `push`, `pull`: the SSH alias for the identity |
| `TASKS_HUB` | `~/work/hub` | `~/personal/hub` | `ongoing-tasks`: the hub folder, with `ongoing-tasks.md`, `contexts.md` and `CLAUDE.md` |
| `LAPTOP_HOSTNAME`, `LAPTOP_SSH_USER` | `my-laptop`, `me` | same | `sync-to-laptop`, `sync-from-laptop` (or `LAPTOP_HOST=user@host` to skip mDNS) |

**Rules:**
- Tokens stay in their files under `~/.config`; never put them in settings or in this repo.
- An unset variable means the feature is off in that profile. The skill or script says so and stops; it never falls back to the other identity.

**Git identities:** the work identity is a `~/.ssh/config` alias, for example:

```
Host github-work
  HostName github.com
  IdentityFile ~/.ssh/work
  IdentitiesOnly yes
```

Check it with `ssh -T git@github-work`. `push` and `pull` rewrite `origin` to the alias in the work profile.

## Contents

### Skills

Every skill has a flat name: type `/<name>` (the `toolkit:` prefix is optional). **Auto** skills are also triggered by Claude when the task matches their description. **User-only** skills have side effects (`disable-model-invocation: true`), so they run only when you type them.

| Skill | Trigger | What it does |
|---|---|---|
| `ongoing-tasks` | auto | Tracks and continues tasks in `$TASKS_HUB`: triage, add tasks, the 7-day rolling-window archive, per-task agents, deep sessions, handoffs, compaction stats. Each hub's private model (e.g. client and internal folders at work, areas at home) lives in it as `$TASKS_HUB/contexts.md`; `references/contexts.md` is its template. |
| `google` | auto | Google Docs, Sheets, Slides and Drive through the bundled scripts, with the `GOOGLE_PROFILE` account |
| `jira` | auto | Jira Cloud issues, links, labels and comments through `jira.sh`, with the `JIRA_ENV` credentials |
| `ste100-80` | auto | Writes or rewrites text "80% of the way" to ASD-STE100 Simplified Technical English |
| `catchup` | auto | Summarises what was worked on in previous sessions; read-only |
| `handoff` | auto | Keeps one rolling `docs/handoffs/HANDOFF.md` per project, rewritten in place as the current snapshot. It migrates old timestamped handoffs (asking before deleting) and reports what changed. |
| `handoff-continue` | auto | Resumes from `HANDOFF.md` (falling back to the newest timestamped handoff): read, verify, pick up |
| `pr-review` | auto | Runs a local agent code review of the current branch; read-only |
| `commit` | user-only | Writes a succinct commit message and commits the current changes |
| `push` | user-only | Pushes the current branch with the profile's Git identity |
| `pull` | user-only | Pulls the current branch, fast-forward only, with the profile's Git identity |
| `git-sync` | user-only | Syncs the current branch with main/master, handling conflicts |
| `git-cleanup` | user-only | Deletes local branches already merged to main/master |
| `pr-create` | user-only | Writes a PR summary and creates the pull request |
| `pr-merge` | user-only | Squash-merges a PR, combining the commit messages |
| `sync-to-laptop` | user-only | Mirrors the current project to the laptop dev box (code, .git, .env) |
| `sync-from-laptop` | user-only | Pulls the current project back from the laptop dev box |

The plugin has no commands; the 1.0 conversion turned them all into skills.

### Scripts

These live in `plugins/toolkit/scripts/`; skills call them through `${CLAUDE_PLUGIN_ROOT}/scripts/`.

| Script | Purpose |
|---|---|
| `gdocs.sh`, `gslides.sh`, `gsheet.sh`, `gdrive.sh`, `gdoc2md.py` | Google APIs with curl and jq. The account is `GOOGLE_PROFILE`. A legacy first argument (`gdocs.sh work read …`) still works when it matches; a different one exits 2. |
| `jira.sh` | Jira Cloud REST |
| `compaction-stats.sh` | Session duration and compaction numbers (built-in vs Jev) from a transcript |

Tests: `bash plugins/toolkit/scripts/tests/compaction-stats.test.sh` and `bash plugins/toolkit/scripts/tests/google-profile.test.sh` (offline).

## Repository Layout

```
.claude-plugin/marketplace.json   the bogdansolga marketplace
plugins/toolkit/                  the plugin
  .claude-plugin/plugin.json      name, version
  skills/  scripts/
CLAUDE.md                         rules for maintaining the plugin
```

## Privacy

The plugin holds no personal or employer details. Everything specific to you stays outside the repo:
- identities and paths in each profile's `settings.json` env;
- tokens in `~/.config/...`;
- each hub's model in `$TASKS_HUB/contexts.md`.
