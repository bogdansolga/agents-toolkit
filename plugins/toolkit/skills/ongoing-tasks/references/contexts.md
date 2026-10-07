# Work Contexts: The Hub's `contexts.md`

The work model is private, so it lives in the hub, not in this plugin. Its file is `$TASKS_HUB/contexts.md`, which says where tasks go and how they are classified. Read it before adding a task. If it's missing, offer to create it from the template below, filled in with the user's answers.

## Template

```markdown
# Work Contexts

## Contexts
Every task belongs to one (or more) of these. Each line gives the folder pattern and when to use it.

Work hub, for example:
- **Clients:** `clients/<group>/<status>/<Client>/0N-<slug>/`: work for a client. Groups, e.g. presales (new clients) and upsales (existing ones); status `active` or `inactive`. `<Client>` is the real name, no spaces.
- **Internal:** `internal/<service>/0N-<slug>/`: building your own assets, one folder per service.

Personal hub, for example:
- **Projects:** `tasks/<area>/0N-<slug>/`: one folder per area (e.g. apps, training, infra); the repos stay where they are and `task.md` links to them.

## Engagement Model
Optional: how engagements are classified, e.g. maturity levels and the type of work each move implies.
| Domain | Move | The work |
|---|---|---|

## Areas (Services)
| Slug | Covers |
|---|---|

## Recording It
Each `task.md` carries an **Engagement** line built from the model above, e.g. `<domain> (<move>) · service: <slug>`; `-` where a part doesn't apply.
```

## Rules

- The skill never moves client or project folders; the user does that.
- Keep names and examples from `contexts.md` out of this plugin; they belong only to the hub.
- When the user changes the model, update `$TASKS_HUB/contexts.md`, not this file.
