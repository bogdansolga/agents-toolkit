---
name: pull
description: "Pull the current branch, fast-forward only, with this profile's Git identity (GIT_SSH_HOST)"
disable-model-invocation: true
---

# Pull

Fetch and integrate `origin` for the **current branch** with the active profile's Git identity. It's the companion to `/push`.

| Profile | `GIT_SSH_HOST` | Account | Key |
|---|---|---|---|
| personal | unset (`github.com`) | your personal account | `~/.ssh/id_*` |
| work | an SSH alias, e.g. `github-work` | your work account | e.g. `~/.ssh/work` |

## Steps

1. `H="${GIT_SSH_HOST:-github.com}"`.
2. **Normalize `origin`, only when needed:** read `git remote get-url origin`.
   - If `H` isn't `github.com` and the URL is `git@github.com:<org>/<repo>.git` or `https://github.com/<org>/<repo>.git`, rewrite it: `git remote set-url origin git@$H:<org>/<repo>.git`.
   - If it already uses `git@$H:`, leave it.
   - In the personal profile, never rewrite a remote that uses the work alias back; stop and tell the user that this repo belongs to the work profile.
3. **Pull, fast-forward only:** `git pull --ff-only origin "$(git branch --show-current)"`. If local and remote diverged, stop and report; let the user pick rebase or merge.
4. **Report** the commits pulled and files changed, or "already up to date".
