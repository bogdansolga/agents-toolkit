---
description: Pull the current branch, fast-forward only, with this profile's Git identity (GIT_SSH_HOST)
---

# Pull

Fetch and integrate `origin` for the **current branch** with the active profile's Git identity. It's the companion to `git:push`, with the same identity table and the same `origin` normalization (its steps 1-2).

## Steps

1. Normalize `origin` as `git:push` does (`H="${GIT_SSH_HOST:-github.com}"`).
2. **Pull, fast-forward only:** `git pull --ff-only origin "$(git branch --show-current)"`. If local and remote diverged, stop and report; let the user pick rebase or merge.
3. **Report** the commits pulled and files changed, or "already up to date".
