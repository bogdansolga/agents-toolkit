#!/bin/sh
# try-pi.sh <dir> <provider/model> <prompt>: one sandboxed, non-interactive Pi run in <dir>, with the
# context-budget extension and this folder's Pi config (pi-agent/). Prints the event log path; read it
# with show-events.py. Used for harness smoke tests; eval runners do the same plus grading.
#   PI_SANDBOX_REPO  (required) the real repo to hide from the agent
#   PI_SANDBOX_HUB   (optional) a parent workspace to hide too; default: PI_SANDBOX_REPO
#   PI_SANDBOX_CLAUDEDIR (optional) Claude data to hide; default: the resolved ~/.claude
#   PI_RESULT_MAX_BYTES / PI_RESULT_MAX_LINES  tool-result cap (context-budget.ts)
#   DEEPSEEK_API_KEY / ZAI_API_KEY  passed through when set; nothing else from the env enters.
# Ollama models run under ollama-lock.sh.
set -u
H=$(cd "$(dirname "$0")" && pwd -P)
DIR=$1; MODEL=$2; PROMPT=$3
: "${PI_SANDBOX_REPO:?set PI_SANDBOX_REPO to the repo the agent must not read}"
T=$(mktemp -d)
cp -R "$H/pi-agent" "$T/pi-agent"; cp "$H/context-budget.ts" "$T/"
LOCK=""
case "$MODEL" in ollama/*) LOCK="$H/ollama-lock.sh" ;; esac
cd "$DIR"
$LOCK sandbox-exec -f "$H/sandbox.sb" -D REPO="$PI_SANDBOX_REPO" -D HUB="${PI_SANDBOX_HUB:-$PI_SANDBOX_REPO}" \
  -D USERHOME="$HOME" -D CLAUDEDIR="${PI_SANDBOX_CLAUDEDIR:-$(realpath "$HOME/.claude")}" -D BUNDIR="$HOME/.bun" \
  /usr/bin/env -i PATH="$DIR/node_modules/.bin:$HOME/.bun/bin:$(dirname "$(command -v node)"):/usr/bin:/bin" \
  HOME="$T" TMPDIR="$T" PI_CODING_AGENT_DIR="$T/pi-agent" \
  ${PI_RESULT_MAX_BYTES:+PI_RESULT_MAX_BYTES=$PI_RESULT_MAX_BYTES} ${PI_RESULT_MAX_LINES:+PI_RESULT_MAX_LINES=$PI_RESULT_MAX_LINES} \
  ${DEEPSEEK_API_KEY:+DEEPSEEK_API_KEY=$DEEPSEEK_API_KEY} ${ZAI_API_KEY:+ZAI_API_KEY=$ZAI_API_KEY} \
  pi -p --mode json --no-session --no-context-files --no-skills --no-extensions --no-mcp --no-prompt-templates \
  --no-approve -e "$T/context-budget.ts" --model "$MODEL" "$PROMPT" </dev/null >"$T/events.jsonl" 2>"$T/stderr.txt"
echo "exit=$? events=$T/events.jsonl"
