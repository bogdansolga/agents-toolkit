---
name: catchup
description: "Use when starting a session or asked what was worked on recently: summarises previous sessions' work from git history and the working tree. Read-only."
---

# Catchup

Inspect with one bash call:

```
git status -sb && echo --- && git log -10 --oneline && echo --- && git log -3 --stat
```

If status shows uncommitted changes, follow with `git diff --stat HEAD`
(filenames + line counts). Only request full `git diff` when the user wants
specific change details — full diffs can be huge.

Summarize: what was being worked on, anything in-flight, apparent blockers.
Ask only if the changes don't form a coherent story.
