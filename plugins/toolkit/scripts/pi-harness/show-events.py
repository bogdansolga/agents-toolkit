# show-events.py <events.jsonl>: one line per model turn (calls, text, usage) and per tool result size.
import json, sys
for line in open(sys.argv[1]):
    e = json.loads(line)
    if e.get("type") in ("compaction_start", "compaction_end"):
        print(e["type"])
    if e.get("type") != "turn_end":
        continue
    m = e["message"]; u = m.get("usage", {})
    for c in m.get("content", []):
        if c.get("type") == "toolCall":
            print("CALL", c["name"], json.dumps(c.get("arguments"))[:120])
        if c.get("type") == "text":
            print("TEXT", c["text"][:400])
    print("  usage in=%s cacheRead=%s out=%s stop=%s" % (u.get("input"), u.get("cacheRead"), u.get("output"), m.get("stopReason")))
    for r in e.get("toolResults", []):
        t = "".join(x.get("text", "") for x in r.get("content", []) if x.get("type") == "text")
        print("  RESULT", r.get("toolName"), len(t), "chars |", t[-170:].replace("\n", " "))
