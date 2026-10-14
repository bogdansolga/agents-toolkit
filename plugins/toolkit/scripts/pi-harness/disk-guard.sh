#!/bin/sh
# disk-guard.sh: watch the system disk (swap, staged OS update, temp folders) and free what is safe.
#   disk-guard.sh            report only
#   disk-guard.sh --clean    also unload Ollama models and delete leftover trial folders under
#                            $EVAL_WORK_ROOT (only when no local trial holds the GPU lock)
#   disk-guard.sh --check N  exit 1 when free space on the system disk is below N GB (use before evals)
# Why: a local model that takes most of RAM, plus dev servers, pushes macOS into swap, and swap files live
# on the system disk. Swap of 13+ GB once filled a small system disk with no files in sight (EVAL-METHOD.md §6).
#   DISK_GUARD_HIDE_VOLUMES  egrep pattern of APFS volume names to leave out of the report (optional)
set -u
DATA=/System/Volumes/Data
free_gb() { df -g "$DATA" | awk 'NR==2 {print $4}'; }

if [ "${1:-}" = "--check" ]; then
  need=${2:-15}
  have=$(free_gb)
  if [ "$have" -lt "$need" ]; then
    echo "disk-guard: only ${have} GB free on the system disk (need ${need}); run disk-guard.sh --clean" >&2
    exit 1
  fi
  exit 0
fi

echo "== system disk"
df -h "$DATA" | awk 'NR==2 {print "free " $4 " of " $2}'
echo "== swap (lives on the system disk)"
sysctl -n vm.swapusage
echo "== APFS volumes on the internal disk"
diskutil apfs list 2>/dev/null | awk '/Name:/ {n=$0} /Capacity Consumed/ {sub(/.*Name: /,"",n); sub(/ \(Case.*/,"",n); print "  " n ": " $(NF-1) " " $NF}' \
  | grep -vE "${DISK_GUARD_HIDE_VOLUMES:-^$}" | tr -d ')('
tmutil listlocalsnapshots / 2>/dev/null | grep -q MSUPrepareUpdate && echo "  note: a macOS update is staged (Preboot holds it); install or cancel it in System Settings to free space"
echo "== Ollama models in memory"
ollama ps 2>/dev/null | awk 'NR>1 {print "  " $1 " " $3 " " $4}'
echo "== largest temp folders"
du -xsh /private/tmp/* "${TMPDIR:-/tmp}"/* 2>/dev/null | sort -h | tail -5 | sed 's/^/  /'

[ "${1:-}" = "--clean" ] || exit 0
echo "== cleaning"
for m in $(ollama ps 2>/dev/null | awk 'NR>1 {print $1}'); do
  ollama stop "$m" >/dev/null 2>&1 && echo "  unloaded $m (reloads on its next request)"
done
LOCK=${OLLAMA_EVAL_LOCK:-$HOME/.ollama/eval.lock}
if [ -n "${EVAL_WORK_ROOT:-}" ] && [ -d "$EVAL_WORK_ROOT" ]; then
  # A held lock means a local trial is running right now; its folder must stay.
  if python3 -I -c 'import fcntl,os,sys; fd=os.open(sys.argv[1], os.O_CREAT|os.O_RDWR, 0o644); fcntl.flock(fd, fcntl.LOCK_EX|fcntl.LOCK_NB)' "$LOCK" 2>/dev/null; then
    find "$EVAL_WORK_ROOT" -mindepth 1 -maxdepth 1 -exec rm -rf {} + && echo "  emptied $EVAL_WORK_ROOT"
  else
    echo "  skipped $EVAL_WORK_ROOT: a local trial holds $LOCK"
  fi
fi
sleep 15
echo "  free now: $(free_gb) GB; swap: $(sysctl -n vm.swapusage | awk '{print $6}')"
