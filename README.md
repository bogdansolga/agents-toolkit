# claude-config

A Claude Code marketplace, `bogdansolga`, with one plugin, `toolkit`, installed in every profile. The type of work picks the identity: the active profile's `settings.json` `env` decides which Google account, Jira instance, Git identity and task hub are used. No command or skill names a profile.

| Profile | Config dir | Used for |
|---|---|---|
| work | `~/.claude-nix` (`CLAUDE_CONFIG_DIR=~/.claude-nix`) | N-iX work: clients, internal tasks, Jira |
| personal | `~/.claude` (the default) | personal projects |

## Install

In each profile (prefix with `CLAUDE_CONFIG_DIR=~/.claude-nix` for the work profile):

```bash
claude plugin marketplace add bogdansolga/claude-config
claude plugin install toolkit@bogdansolga
```

Then set the profile env (below) in that profile's `settings.json` and restart Claude Code.

## Update

After a push to `main`, in each profile:

```bash
claude plugin marketplace update bogdansolga
claude plugin update toolkit@bogdansolga
```

Restart running sessions to load the new version. Bump `version` in `plugins/toolkit/.claude-plugin/plugin.json` with every release; `update` compares versions.

## Profile Env

Set these under `env` in each profile's `settings.json`:

| Variable | work (`~/.claude-nix`) | personal (`~/.claude`) | Used by |
|---|---|---|---|
| `GOOGLE_PROFILE` | `nix` | `personal` | `google` skill and scripts: the OAuth token is `~/.config/google/<profile>/token.json` |
| `JIRA_ENV` | `/Users/bogdan/.config/nix/jira.env` | unset: no Jira | `jira` skill: the file holds `JIRA_BASE_URL`, `JIRA_EMAIL`, `JIRA_API_TOKEN` (`chmod 600`) |
| `GIT_SSH_HOST` | `github-nix` | unset: `github.com` | `git:push`, `git:pull`: the SSH alias for the identity |
| `TASKS_HUB` | `/Volumes/NVMe/Development/IdeaProjects/active/nix` | unset: no hub | `ongoing-tasks` skill |

**Rules:**
- Tokens stay in their files under `~/.config`; never put them in settings or in this repo.
- An unset variable means the feature is off in that profile. The skill or script says so and stops; it never falls back to the other identity.

**Git identities:**

| Identity | `GIT_SSH_HOST` | GitHub account | Key |
|---|---|---|---|
| personal | `github.com` | `bogdansolga` | `~/.ssh/id_*` |
| work | `github-nix` | `bsolga` | `~/.ssh/nix` |

`github-nix` is a `~/.ssh/config` alias: `HostName github.com`, `IdentityFile ~/.ssh/nix`, `IdentitiesOnly yes`. Check it with `ssh -T git@github-nix`; it should answer "Hi bsolga!".

## Contents

### Skills

Invoke a skill as `/<name>` (the `toolkit:` prefix is optional), or let Claude trigger it from the task.

| Skill | What it does |
|---|---|
| `ongoing-tasks` | Tracks and continues tasks in `$TASKS_HUB`: triage, add tasks, the 7-day rolling-window archive, per-task agents, deep sessions, handoffs, compaction stats. `references/contexts.md` holds the work model: clients (presales/upsales), internal services, and the AI Delivery Model levels (Acceleration L1/L2 → L3, Transformation L3 → L4). |
| `google` | Google Docs, Sheets, Slides and Drive through the bundled scripts, with the `GOOGLE_PROFILE` account. |
| `jira` | Jira Cloud issues, links, labels and comments through `jira.sh`, with the `JIRA_ENV` credentials. |
| `ste100-80` | Writes or rewrites text "80% of the way" to ASD-STE100 Simplified Technical English. |

### Commands

Commands keep their folder in the name and need the prefix: `/toolkit:git:commit`.

| Command | What it does |
|---|---|
| `git:catchup` | Summarises what was worked on in previous sessions |
| `git:cleanup` | Deletes local branches already merged to main/master |
| `git:commit` | Writes a succinct commit message and commits the current changes |
| `git:pull` | Pulls the current branch, fast-forward only, with the profile's Git identity |
| `git:push` | Pushes the current branch with the profile's Git identity |
| `git:sync` | Syncs the current branch with main/master, handling conflicts |
| `handoff:create` | Writes a session handoff so a fresh session can pick up cold |
| `handoff:continue` | Resumes from a handoff: read, verify, pick up |
| `pr:create` | Writes a PR summary and creates the pull request |
| `pr:merge` | Squash-merges a PR, combining the commit messages |
| `pr:review` | Runs a local agent code review of the current branch |
| `sync:to-laptop` | Mirrors the current project to the laptop dev box (code, .git, .env) |
| `sync:from-laptop` | Pulls the current project back from the laptop dev box |

### Scripts

These live in `plugins/toolkit/scripts/`; skills call them through `${CLAUDE_PLUGIN_ROOT}/scripts/`.

| Script | Purpose |
|---|---|
| `gdocs.sh`, `gslides.sh`, `gsheet.sh`, `gdrive.sh`, `gdoc2md.py` | Google APIs with curl and jq. The account is `GOOGLE_PROFILE`. A legacy first argument (`gdocs.sh nix read …`) still works when it matches; a different one exits 2. |
| `jira.sh` | Jira Cloud REST |
| `compaction-stats.sh` | Session duration and compaction numbers (built-in vs Jev) from a transcript |

Tests: `bash plugins/toolkit/scripts/tests/compaction-stats.test.sh` and `bash plugins/toolkit/scripts/tests/google-profile.test.sh` (offline).

## Repository Layout

```
.claude-plugin/marketplace.json   the bogdansolga marketplace
plugins/toolkit/                  the plugin
  .claude-plugin/plugin.json      name, version
  skills/  commands/  scripts/
docs/superpowers/                 specs and plans
archive/                          the pre-2.0 layout, for reference; nothing there is loaded
CLAUDE.md                         rules for maintaining the plugin
```

## History

`toolkit` 2.0 replaces the `nix` plugin of the `nix-config` marketplace (`nix:ongoing-tasks` is now `ongoing-tasks`). It also replaces the loose `~/.claude/commands` and `~/.claude/skills` copies.

The retired skills (bid-response, cv-work-*, pptx-self-paced, anthropic-cert-mentor and the cert-tutor agent) hold personal content. They are kept only in the local backup, `~/.claude-config-backups/2026-10-06-restructure/`.
