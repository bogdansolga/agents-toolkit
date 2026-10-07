# agents-toolkit: Maintaining the Toolkit Plugin

This repo is the `bogdansolga` Claude Code marketplace, with one plugin: `plugins/toolkit`. `README.md` holds the full reference: the install and update commands, the profile env table, the Git identities, and every skill and script.

## Rules

- **One plugin, every profile.** Never add a profile name to a skill or script. Anything that differs between work and personal goes through a profile env variable (`GOOGLE_PROFILE`, `JIRA_ENV`, `GIT_SSH_HOST`, `TASKS_HUB`, `LAPTOP_*`); add new ones to the README env table.
- **An unset variable means "off in this profile".** Stop with a message that names the variable; never fall back to another identity.
- **The repo is public and shared in courses.** No tokens, no employer or client names, no hostnames, accounts, paths or document ids, no personal data. Use placeholders in examples (`PROJ-123`, `Acme`, `github-work`, `DOC_ID`). Real values go in the profile env, in `~/.config/...` files, or in the private task hub (`$TASKS_HUB/contexts.md`, `$TASKS_HUB/CLAUDE.md`). Before every push, grep the diff for anything specific to the user.
- **Edit only this repo.** The marketplace clones under `<profile>/plugins/marketplaces/` are overwritten on every update or reinstall, so uncommitted edits there are lost. If one has edits, carry them into this repo first.
- **Paths:** scripts are called as `${CLAUDE_PLUGIN_ROOT}/scripts/...`; plugins are cached, so never hardcode a cache path.
- **Names:** plugin names can't start with `claude-` (reserved). Skills resolve without the `toolkit:` prefix; commands in folders need it. So everything is a skill with a flat, hyphenated name (`git-sync`, `pr-create`); add no `commands/`. Avoid built-in command names (`/review`, `/init`, `/compact`, …).
- **Every skill needs frontmatter:** `name`, and a `description` that says when to use it.
- **Side effects mean user-only.** A skill that commits, pushes, merges, deletes, syncs or sends anything gets `disable-model-invocation: true`; Claude can't trigger it, only the user can type it. Read-only and write-a-local-doc skills stay auto. Record the choice in the README Trigger column.

## Release Checklist

1. Edit under `plugins/toolkit/`.
2. Run the tests:
   - `bash plugins/toolkit/scripts/tests/compaction-stats.test.sh`
   - `bash plugins/toolkit/scripts/tests/google-profile.test.sh`
3. Validate with `claude plugin validate .` and `claude plugin validate plugins/toolkit`.
4. Try it for one session without installing: `claude --plugin-dir plugins/toolkit`. Ask Claude to list the toolkit skills it can invoke; the user-only ones must not appear.
5. Bump `version` in `plugins/toolkit/.claude-plugin/plugin.json`, and update `README.md` when a skill, script or env variable changes.
6. Commit only on the user's yes; push only on a separate yes.
7. In both profiles, run `claude plugin marketplace update bogdansolga && claude plugin update toolkit@bogdansolga`. Prefix it with `CLAUDE_CONFIG_DIR=<dir>` for a non-default profile.
