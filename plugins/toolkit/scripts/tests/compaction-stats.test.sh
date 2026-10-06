#!/usr/bin/env bash
# Tests for compaction-stats.sh. Run: bash plugins/toolkit/scripts/tests/compaction-stats.test.sh
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
S="$HERE/../compaction-stats.sh"
F="$HERE/fixtures"
fail=0
check() { # name, expected substring, actual
  if [[ "$3" == *"$2"* ]]; then echo "ok   $1"; else echo "FAIL $1"; echo "  expected: $2"; echo "  actual:   $3"; fail=1; fi
}

out=$(bash "$S" "$F/builtin.jsonl")
check "builtin count"     "Compactions: 1 · jev: 0, builtin: 1" "$out"
check "builtin tokens"    "100.0k → 40.0k (-60%)" "$out"
check "builtin duration"  "Duration: 1h40m · Session: builtin" "$out"
check "builtin time"      "compaction time 1.0m" "$out"

out=$(bash "$S" "$F/jev.jsonl")
check "jev count"         "Compactions: 2 · jev: 2 (unverified), builtin: 0" "$out"
check "jev tokens + tail" "200.0k → 70.0k (-65%), 150.0k → ? (?)" "$out"

out=$(bash "$S" "$F/none.jsonl")
check "none"              "Compactions: 0" "$out"

out=$(bash "$S" --json "$F/builtin.jsonl")
check "json row" '{"n":1,"trigger":"auto","kind":"builtin","pre":100000,"post":40000,"reduction":60,"durationMs":60000}' "$out"

out=$(bash "$S" "$F/missing.jsonl" 2>&1); rc=$?
check "missing exits 1"   "1" "$rc"

exit $fail
