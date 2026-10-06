---
name: google
description: "Use when reading or editing Google Docs, Sheets, Slides, or Drive files — read a doc as text/JSON, batch-format or edit a doc, read/write sheets, read/replace/export slides, list/search Drive. Driven by the bundled gdocs.sh / gsheet.sh / gslides.sh / gdrive.sh; the account comes from the profile's GOOGLE_PROFILE env. Shell + curl + jq, no MCP. Trigger on any docs.google.com / drive.google.com Google file request."
---

# google: Google Docs/Sheets/Slides/Drive CLI

Drive Google Workspace via bundled shell/`curl`/`jq` CLIs. No install.

## Scripts

Bundled with this plugin under `${CLAUDE_PLUGIN_ROOT}/scripts/` — always reference via `${CLAUDE_PLUGIN_ROOT}` (plugins get cached; hardcoded paths break):
- `gdocs.sh` — Google Docs (read, batch edit/format, comments)
- `gsheet.sh` — Google Sheets
- `gslides.sh` — Google Slides (read text/structure, find-replace, export)
- `gdrive.sh` — Google Drive (list/search/download)
- `gdoc2md.py` — Doc → Markdown helper

## Auth: The Profile Picks the Account

The active Claude profile sets `GOOGLE_PROFILE` in its `settings.json` `env`: `nix` in the work profile, `personal` in the personal one. The scripts read it and use `~/.config/google/$GOOGLE_PROFILE/token.json`, refreshing the short-lived access token. Never pass a profile argument and never switch accounts inside a session; the type of work decides the account.

- If `GOOGLE_PROFILE` is unset, the scripts stop with an error that names it. Tell the user to set it in this profile's settings; don't guess an account.
- Old docs call the scripts with a profile first (`gdocs.sh nix read …`). That still works when the argument matches `GOOGLE_PROFILE`; a different profile stops with exit 2. Write new calls without it.
- `TOKEN_PATH` overrides everything, for one-off use.

## Commands (gdocs.sh)

```bash
G="${CLAUDE_PLUGIN_ROOT}/scripts/gdocs.sh"
"$G" get       DOC_ID          # title + revisionId
"$G" read      DOC_ID          # full document as plain text
"$G" read-json DOC_ID          # body.content array (structural elements → char indices)
"$G" replace   DOC_ID "FIND" "REPLACE"
"$G" append    DOC_ID "text"
"$G" insert    DOC_ID INDEX "text"
"$G" batch     DOC_ID '<json-array-of-batchUpdate-requests>'   # raw edits/formatting
"$G" comments  DOC_ID [--include-resolved]
```

The DOC_ID is the long string in the URL: `docs.google.com/document/d/<DOC_ID>/edit`.

## Commands (gslides.sh)

```bash
S="${CLAUDE_PLUGIN_ROOT}/scripts/gslides.sh"
"$S" info    PRESENTATION_ID              # presentationId, page size, slide objectIds
"$S" text    PRESENTATION_ID [SLIDE_IDX]  # all slides' text (or one slide, 0-indexed)
"$S" slides  PRESENTATION_ID              # list slide objectIds (p1, p2, …)
"$S" slide   PRESENTATION_ID SLIDE_IDX    # one slide's elements/structure
"$S" replace PRESENTATION_ID "OLD" "NEW"  # find/replace text across the deck
"$S" export  PRESENTATION_ID              # export (PDF via Drive)
# also: shapes · set-text · set-font · duplicate · delete · batch (raw batchUpdate)
```

The PRESENTATION_ID is the long string in the URL: `docs.google.com/presentation/d/<PRESENTATION_ID>/edit`.
The `#slide=id.pN` fragment is the slide's objectId — `pN` is the N-th slide (`text PRESENTATION_ID N-1` reads it 0-indexed).

## Sheets / Drive

`gsheet.sh` and `gdrive.sh` use the same `GOOGLE_PROFILE` resolution (`gsheet.sh read …`). Run the script with no args for its usage.

## Recipes

- **Read a shared doc:** `"$G" read DOC_ID`.
- **Read a deck (or one slide):** `"$S" text PRESENTATION_ID` for the whole deck; append the 0-indexed slide number for just one (`#slide=id.p3` → `text PRESENTATION_ID 2`).
- **Fit a doc to one page (formatting, not text cuts):** get indices with `read-json` (returns the `body.content` array — last `endIndex` + heading ranges), then `batch` with: `updateDocumentStyle` margins 36pt top/bottom, 54pt left/right; `updateParagraphStyle` over `{startIndex:1, endIndex:<last-1>}` → `lineSpacing:100`, `spaceAbove/Below:0`; `updateTextStyle` on heading ranges → smaller `fontSize`.
- **Targeted wording change:** `replace DOC_ID "old" "new"` (exact match, keeps formatting).

## Gotchas

- `read-json` returns the **`body.content` array**, not the whole document object — index it directly; `documentStyle`/margins are **not** in that output (set them blind via `batch`; the request still succeeds).
- `batch` expects a **JSON array of request objects**; the script wraps it as `{requests: [...]}`. Style updates return empty `{}` replies on success.
- Markdown pasted into Google Docs brings Heading styles with large space-above — that (not word count) is usually why a short doc spills to 2 pages; fix with the formatting `batch` above.
- Confidentiality: work content stays in work contexts; don't copy N-iX docs into personal repos.
