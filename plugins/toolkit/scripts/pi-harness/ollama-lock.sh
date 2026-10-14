#!/bin/sh
# ollama-lock.sh <command> [args...]: run a command while holding the local-model lock, so evals
# from different repos never share the GPU (Ollama serves one request at a time; a second trial
# would skew both latency numbers). Waits for the lock; prints a note while waiting.
# Lock file: $OLLAMA_EVAL_LOCK, default ~/.ollama/eval.lock. macOS has no flock(1), hence Python.
LOCK=${OLLAMA_EVAL_LOCK:-$HOME/.ollama/eval.lock}
exec python3 -I -c '
import fcntl, os, sys
fd = os.open(sys.argv[1], os.O_CREAT | os.O_RDWR, 0o644)
try:
    fcntl.flock(fd, fcntl.LOCK_EX | fcntl.LOCK_NB)
except BlockingIOError:
    print(f"ollama-lock: waiting for {sys.argv[1]}", file=sys.stderr, flush=True)
    fcntl.flock(fd, fcntl.LOCK_EX)
os.set_inheritable(fd, True)
os.execvp(sys.argv[2], sys.argv[2:])
' "$LOCK" "$@"
