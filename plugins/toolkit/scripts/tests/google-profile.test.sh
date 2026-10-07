#!/usr/bin/env bash
# Offline tests for the Google scripts' account resolution (no network: every case exits before an API call).
# Run: bash plugins/toolkit/scripts/tests/google-profile.test.sh
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
fail=0
check() { # name, expected substring, actual
  if [[ "$3" == *"$2"* ]]; then echo "ok   $1"; else echo "FAIL $1"; echo "  expected: $2"; echo "  actual:   $3"; fail=1; fi
}
# A fake HOME with two profile folders, so the tests never touch real tokens.
H=$(mktemp -d); mkdir -p "$H/.config/google/work" "$H/.config/google/personal"
trap 'rm -rf "$H"' EXIT

for s in gdocs gslides gsheet gdrive; do
  S="$HERE/../$s.sh"
  out=$(env -u GOOGLE_PROFILE -u TOKEN_PATH HOME="$H" bash "$S" read X 2>&1)
  check "$s unset names the variable" "GOOGLE_PROFILE is not set" "$out"
  out=$(env -u TOKEN_PATH HOME="$H" GOOGLE_PROFILE=personal bash "$S" work read X 2>&1)
  check "$s legacy arg conflict"      "conflicts with GOOGLE_PROFILE=personal" "$out"
done
exit $fail
