# claude-config: Maintaining the Toolkit Plugin

This repo is the `bogdansolga` Claude Code marketplace, with one plugin: `plugins/toolkit`. `README.md` holds the full reference: the install and update commands, the profile env table, the Git identities, and every skill, command and script.

## Rules

- **One plugin, every profile.** Never add a profile name to a skill, command or script. Anything that differs between work and personal goes through a profile env variable (`GOOGLE_PROFILE`, `JIRA_ENV`, `GIT_SSH_HOST`, `TASKS_HUB`); add new ones to the README env table.
- **An unset variable means "off in this profile".** Stop with a message that names the variable; never fall back to another identity.
- **The repo is public.** No tokens, no client content, no N-iX documents, no personal data (CVs, exam progress). Tokens live in `~/.config/...` files that settings point to.
- **Paths:** scripts are called as `${CLAUDE_PLUGIN_ROOT}/scripts/...`; plugins are cached, so never hardcode a cache path.
- **Names:** plugin names can't start with `claude-` (reserved). Skills resolve without the `toolkit:` prefix; commands in folders need it (`/toolkit:git:commit`).
- **Every command and skill needs frontmatter** with a `description`.
- `archive/` is reference only; don't edit it or load from it.

## Release Checklist

1. Edit under `plugins/toolkit/`.
2. Run the tests:
   - `bash plugins/toolkit/scripts/tests/compaction-stats.test.sh`
   - `bash plugins/toolkit/scripts/tests/google-profile.test.sh`
3. Validate with `claude plugin validate .` and `claude plugin validate plugins/toolkit`.
4. Optionally, try it for one session without installing: `claude --plugin-dir plugins/toolkit`.
5. Bump `version` in `plugins/toolkit/.claude-plugin/plugin.json`, and update `README.md` when a skill, command, script or env variable changes.
6. Commit only on the user's yes; push only on a separate yes.
7. In both profiles, run `claude plugin marketplace update bogdansolga && claude plugin update toolkit@bogdansolga`. Prefix it with `CLAUDE_CONFIG_DIR=~/.claude-nix` for the work profile.
