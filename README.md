# claude-config

A Claude Code marketplace (`bogdansolga`) with one plugin, `toolkit`, used in every profile. The type of work picks the identity: the active profile's `settings.json` `env` says which Google account, Jira, Git identity and task hub to use. No command or skill names a profile.

## Install and Update

```bash
claude plugin marketplace add bogdansolga/claude-config
claude plugin install toolkit@bogdansolga

# later
claude plugin marketplace update bogdansolga && claude plugin update toolkit@bogdansolga
```

For a non-default profile, prefix each command with `CLAUDE_CONFIG_DIR=~/.claude-nix`.

## Profile Env

| Variable | work (`~/.claude-nix`) | personal (`~/.claude`) | Used by |
|---|---|---|---|
| `GOOGLE_PROFILE` | `nix` | `personal` | `google` (token at `~/.config/google/<profile>/token.json`) |
| `JIRA_ENV` | `~/.config/nix/jira.env` | unset (no Jira) | `jira` |
| `GIT_SSH_HOST` | `github-nix` | unset (`github.com`) | `git:push`, `git:pull` |
| `TASKS_HUB` | `/Volumes/NVMe/Development/IdeaProjects/active/nix` | unset (no hub) | `ongoing-tasks` |

Tokens stay in their files under `~/.config`; never put them in the repo or in settings.

## Contents

- **Skills:** `ongoing-tasks`, `google`, `jira`, `ste100-80`.
- **Commands:**
  - `git`: catchup, cleanup, commit, sync, pull, push;
  - `handoff`: create, continue;
  - `pr`: create, merge, review;
  - `sync`: from-laptop, to-laptop.
- **Scripts:** `plugins/toolkit/scripts/`, with Google, Jira and `compaction-stats.sh` (tests in `scripts/tests/`).
- **`archive/`:** the previous layout and kept for reference. Nothing there is loaded.
