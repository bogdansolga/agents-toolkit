#!/usr/bin/env bash
# compaction-stats.sh — report the context compactions in a Claude Code session transcript.
#
# Usage: compaction-stats.sh [--json] [SESSION_ID | PATH.jsonl]
#   No argument: the newest transcript for the current folder in the active profile
#   ($CLAUDE_CONFIG_DIR, else ~/.claude). A SESSION_ID is searched under that profile's projects/.
#
# Text output (for handoffs):
#   - Duration: 1h40m · Session: <id>
#   - Compactions: 2 · jev: 2 (unverified), builtin: 0
#   - Tokens: 168.9k → 61.2k (-64%), 151.0k → 58.4k (-61%) · compaction time 3.1m
# --json: one object per compaction: {n, trigger, kind, pre, post, reduction, durationMs}
#
# "post" is the context size of the first assistant turn after the boundary
# (input + cache read + cache creation tokens). A built-in compaction leaves an
# isCompactSummary message; anything else is reported as jev, unverified until
# confirmed on a real Jev compaction.
set -euo pipefail

JSON=0
if [[ "${1:-}" == "--json" ]]; then JSON=1; shift; fi
ARG="${1:-}"
BASE="${CLAUDE_CONFIG_DIR:-$HOME/.claude}/projects"

F=""
if [[ -z "$ARG" ]]; then
  DIR="$BASE/$(pwd | sed 's/[^A-Za-z0-9]/-/g')"
  F=$(ls -t "$DIR"/*.jsonl 2>/dev/null | head -1 || true)
elif [[ -f "$ARG" ]]; then
  F="$ARG"
elif [[ "$ARG" != *.jsonl && "$ARG" != */* ]]; then
  F=$(find "$BASE" -name "$ARG.jsonl" -print -quit 2>/dev/null || true)
fi
if [[ -z "$F" || ! -f "$F" ]]; then
  echo "compaction-stats: transcript not found (${ARG:-newest in $BASE for $(pwd)})" >&2
  exit 1
fi

SESSION=$(basename "$F" .jsonl)

jq -n -R -r --argjson json "$JSON" --arg session "$SESSION" '
  def ts: (.timestamp? // empty) | sub("\\.[0-9]+Z$"; "Z") | try fromdateiso8601 catch empty;
  def one: round as $t | "\($t / 10 | floor).\($t % 10)";   # tenths → "12.3"
  def k: if . == null then "?" else (. / 100 | one) + "k" end;
  def dur: (. / 60 | floor) as $m | if $m >= 60 then "\($m / 60 | floor)h\($m % 60)m" else "\($m)m" end;

  [inputs | fromjson? | objects] as $l
  | ($l | map(ts)) as $times
  | (reduce $l[] as $e ({rows: [], cur: null};
      if $e.type == "system" and $e.subtype == "compact_boundary" then
        (if .cur then .rows += [.cur] else . end)
        | .cur = {trigger: ($e.compactMetadata.trigger // "?"), kind: "jev",
                  pre: $e.compactMetadata.preTokens, post: null,
                  durationMs: ($e.compactMetadata.durationMs // 0)}
      elif .cur != null and .cur.post == null and $e.isCompactSummary == true then
        .cur.kind = "builtin"
      elif .cur != null and .cur.post == null and $e.type == "assistant"
           and ($e.message.usage? | type) == "object" then
        .cur.post = (($e.message.usage.input_tokens // 0)
                   + ($e.message.usage.cache_read_input_tokens // 0)
                   + ($e.message.usage.cache_creation_input_tokens // 0))
      else . end)
    | if .cur then .rows + [.cur] else .rows end)
  | to_entries
  | map({n: (.key + 1)} + .value
        | .reduction = (if .post != null and (.pre // 0) > 0
                        then ((1 - .post / .pre) * 100 | round) else null end)
        | {n, trigger, kind, pre, post, reduction, durationMs}) as $rows

  | if $json == 1 then $rows[] | tojson
    else
      (if ($times | length) > 1 then ($times | max - min | dur) else "?" end) as $d
      | ($rows | map(select(.kind == "jev")) | length) as $jev
      | "- Duration: \($d) · Session: \($session)",
        "- Compactions: \($rows | length)"
          + (if ($rows | length) > 0
             then " · jev: \($jev)\(if $jev > 0 then " (unverified)" else "" end), builtin: \(($rows | length) - $jev)"
             else "" end),
        (if ($rows | length) > 0 then
          "- Tokens: "
          + ($rows | map("\(.pre | k) → \(.post | k) (\(if .reduction == null then "?" else "-\(.reduction)%" end))") | join(", "))
          + " · compaction time \(($rows | map(.durationMs) | add) / 6000 | one)m"
         else empty end)
    end
' < "$F"
