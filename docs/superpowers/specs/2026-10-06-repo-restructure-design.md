# claude-config Restructure: One Plugin, Profile by Type of Work

Date: 2026-10-06 · Status: approved, implemented on branch `restructure`

## Goal

Turn `claude-config` into a clean Claude Code marketplace with one plugin, installed and updated with `claude plugin` in both profiles. The type of work picks the identity, not the command name:

| Profile | Config dir | Google | Git SSH key | Jira | Task hub |
|---|---|---|---|---|---|
| work | `~/.claude-nix` | `nix` | `~/.ssh/nix` | the N-iX Atlassian instance | `IdeaProjects/active/nix` |
| personal | `~/.claude` | `personal` | default key | none | none for now |

## Profile Resolution

Each profile's `settings.json` `env` sets the identity once:

- `GOOGLE_PROFILE`: `nix` or `personal`. The Google scripts already honour it; the profile argument disappears from the skills.
- `GIT_SSH_HOST`: `github-nix` (the SSH alias for `~/.ssh/nix`) in work; unset (`github.com`) in personal. `git:pull` and `git:push` use it; the separate `nix.md` variants go.
- `JIRA_ENV`: the path to the token file (`~/.config/nix/jira.env`), work only. The token stays in that file, never in settings or the repo.
- `TASKS_HUB`: the hub path for `ongoing-tasks`; unset means the skill says there's no hub for this profile.

Skills and commands never name a profile. A missing variable produces one clear error ("GOOGLE_PROFILE is not set in this profile's settings").

## Naming

The plugin is named `toolkit`, in the marketplace `bogdansolga` (install: `toolkit@bogdansolga`). `claude-config` was the first choice; Claude Code reserves plugin names starting with `claude-`. Claude Code accepts a plugin command without its prefix when no other plugin uses the same name, so the usage is flat: `/ongoing-tasks`, `/git:commit`, `/handoff:create`. Verify this in testing; if the prefix turns out to be required, revisit the name.

## Layout

```
.claude-plugin/marketplace.json     marketplace "bogdansolga", one plugin "toolkit"
plugins/toolkit/
  .claude-plugin/plugin.json
  skills/
    ongoing-tasks/                   from nix; uses TASKS_HUB
    google/                          from nix; uses GOOGLE_PROFILE
    jira/                            from nix
    ste100-80/                       from ~/.claude/skills
  commands/                          from ~/.claude/commands (the source of truth)
    git/  catchup cleanup commit sync pull push
    handoff/  create continue
    pr/  create merge review
    sync/  from-laptop to-laptop
  scripts/                           gdocs gslides gsheet gdrive gdoc2md jira compaction-stats (+ tests)
archive/                             everything else, moved in one commit
README.md                            install, update, profile env table
```

**Archived:**
- The repo's `next-docs/`, `commands/`, `skills/`, `agents/`, `claude-home/`, `scripts/`, `output-styles/`, `git-hooks/`, `sync-to-home.*`, `biome.jsonc`, `plugins/config.json` and `plugins/nix/`.
- Retired from `~/.claude`: `bid-response`, `cv-work-refine`, `cv-work-summary`, `pptx-self-paced`, `anthropic-cert-mentor` and the `cert-tutor` agent. They hold personal content and the repo is public, so they are kept only in the local tgz backup, not in `archive/`.

## Migration

1. Work on branch `restructure`. Test through a local marketplace (`claude plugin marketplace add <repo path>`) in a scratch profile.
2. Remove the profile argument from the google skill, the ongoing-tasks skill and the hub `CLAUDE.md`. Rename `nix:ongoing-tasks`, `nix:google` and `nix:jira` to their flat names.
3. **Verify:** the script tests pass; in each profile, `/ongoing-tasks`, a Google read, `/git:pull` and `/git:commit` (dry run) resolve and use the right identity.
4. **On the user's yes:**
   - merge and push;
   - in both profiles, remove `nix@nix-config` and the `nix-config` marketplace, add the `bogdansolga` marketplace and install `toolkit`;
   - set the env variables;
   - back up (tgz) and remove the loose `~/.claude/commands`, `~/.claude/skills/{ste100-80,humanizer,…}` and `~/.claude-nix/skills`.
5. The marketplace is now hosted at the repo itself, so one marketplace name serves both profiles.

## Open

- Is `skills/synced` (in both profiles) still used? Check before removing it.
- `~/.claude/skills/humanizer` duplicates the installed humanizer plugin; remove it with the other loose copies.
- **Tested 2026-10-06 (`--plugin-dir`, work profile):**
  - Skills resolve without the prefix: `/ste100-80` ran.
  - Nested plugin commands need it: `/git:catchup` isn't found, `/toolkit:git:catchup` is.
  - To be fully flat, the commands could become skills with flat names (`/commit`, `/push`, `/pull`, `/handoff-create`, `/pr-create`). Decide when refining.
- With `GOOGLE_PROFILE` unset, the Google scripts take the first argument as the profile and print usage, instead of naming the missing variable. Tighten this when refining.
