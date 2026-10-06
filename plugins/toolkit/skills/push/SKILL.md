---
name: push
description: "Push the current branch with this profile's Git identity (GIT_SSH_HOST)"
disable-model-invocation: true
---

# Push

Push the **current branch** to `origin` with the Git identity of the active profile.

## The Identity Comes from the Profile

| Profile | `GIT_SSH_HOST` | Account | Key |
|---|---|---|---|
| personal | unset (`github.com`) | `bogdansolga` | `~/.ssh/id_*` |
| work | `github-nix` | `bsolga` | `~/.ssh/nix` |

`github-nix` is an SSH alias (`HostName github.com`, `IdentityFile ~/.ssh/nix`, `IdentitiesOnly yes`). A "Repository not found" error on a work repo means the personal key answered.

## Steps

1. `H="${GIT_SSH_HOST:-github.com}"`.
2. **Normalize `origin`, only when needed:** read `git remote get-url origin`.
   - If `H` isn't `github.com` and the URL is `git@github.com:<org>/<repo>.git` or `https://github.com/<org>/<repo>.git`, rewrite it: `git remote set-url origin git@$H:<org>/<repo>.git`.
   - If it already uses `git@$H:`, leave it.
   - In the personal profile, never rewrite a `github-nix` remote back; stop and tell the user that this repo belongs to the work profile.
3. **Push:** `git push --set-upstream origin "$(git branch --show-current)"`.
4. **Report** the pushed branch, the ahead/behind result and the PR-create URL GitHub prints.

## Notes

- The rewrite is durable (per-repo git config) and idempotent. Only touch `origin`.
- The push identity is not the commit author. A work email on commits needs `git config user.email`; this command doesn't change it.
