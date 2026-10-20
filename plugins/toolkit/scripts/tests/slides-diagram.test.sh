#!/usr/bin/env bash
# Offline tests for slides_diagram.py: runs the example spec and checks the generated
# Slides API requests (no network; nothing is sent to Google).
# Run: bash plugins/toolkit/scripts/tests/slides-diagram.test.sh
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
fail=0
check() { # name, expected substring, actual
  if [[ "$3" == *"$2"* ]]; then echo "ok   $1"; else echo "FAIL $1"; echo "  expected: $2"; echo "  actual:   $3"; fail=1; fi
}

out=$(python3 "$HERE/../slides_diagram_example.py" 2>&1)
check "example without args prints usage" "usage: slides_diagram_example.py" "$out"

json=$(python3 "$HERE/../slides_diagram_example.py" ex SLIDE_ID 2>&1)
# Every request must be valid JSON, target the given slide and use the key prefix.
summary=$(printf '%s' "$json" | python3 -c '
import json, sys
reqs = json.load(sys.stdin)
creates = [r[k] for r in reqs for k in ("createShape", "createLine") if k in r]
print("pages", sorted({c["elementProperties"]["pageObjectId"] for c in creates}))
print("prefix", all(c["objectId"].startswith("ex_n") for c in creates))
print("ids unique", len({c["objectId"] for c in creates}) == len(creates))
print("arrowheads", sum(1 for r in reqs if r.get("updateLineProperties", {}).get("lineProperties", {}).get("endArrow") == "FILL_ARROW"))
print("dashed lines", sum(1 for r in reqs if r.get("updateLineProperties", {}).get("lineProperties", {}).get("dashStyle") == "DASH"))
' 2>&1)
check "requests target the given slide"   "pages ['SLIDE_ID']" "$summary"
check "object ids use the key prefix"     "prefix True"        "$summary"
check "object ids are unique"             "ids unique True"    "$summary"
check "one arrowhead per path"            "arrowheads 3"       "$summary"
check "dashed path draws dashed segments" "dashed lines 3"     "$summary"

# clear_requests deletes only this key's elements.
cleared=$(python3 -c '
import sys
sys.path.insert(0, sys.argv[1])
from slides_diagram import clear_requests
els = [{"objectId": "ex_n001"}, {"objectId": "ex_n002"}, {"objectId": "title"}, {"objectId": "other_n001"}]
print([r["deleteObject"]["objectId"] for r in clear_requests(els, "ex")])
' "$HERE/.." 2>&1)
check "clear_requests keeps other elements" "['ex_n001', 'ex_n002']" "$cleared"
exit $fail
