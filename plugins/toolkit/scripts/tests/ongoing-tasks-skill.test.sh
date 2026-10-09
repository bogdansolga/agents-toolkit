#!/usr/bin/env bash
# Structural tests for the ongoing-tasks skill text: every rule the spec requires is present.
# Run: bash plugins/toolkit/scripts/tests/ongoing-tasks-skill.test.sh
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
S="$HERE/../../skills/ongoing-tasks"
fail=0
has() { # name, file, fixed string
  if grep -qF -- "$3" "$S/$2"; then echo "ok   $1"; else echo "FAIL $1"; echo "  missing in $2: $3"; fail=1; fi
}

# Step 0
has "step 0 section"            SKILL.md "## Step 0: Status Updates"
has "step 0 first in every run" SKILL.md "Every run starts with Step 0"
has "step 0 question"           SKILL.md "What changed since"
has "no changes reply"          SKILL.md "'no changes'"
has "unknown task number"       SKILL.md "not in the index"
has "no status-synced yet"      SKILL.md "else the \`Updated:\` date"
has "deep keeps sync date"      SKILL.md "Deep never changes \`status-synced\`"
has "planned online sources"    SKILL.md "Online sources (planned"
has "web app note"              SKILL.md "web app"
# Formats
has "waiting status"            references/tasks-format.md "waiting: <who> (nudge YYYY-MM-DD)"
has "nudge default"             references/tasks-format.md "3 working days"
has "who without parentheses"  references/tasks-format.md "no parentheses in \`<who>\`"
has "missing nudge"             references/tasks-format.md "without \`(nudge"
has "priority from nudge"       references/tasks-format.md "from the nudge date"
has "status-synced line"        references/tasks-format.md "status-synced YYYY-MM-DD"
has "done line with link"       references/tasks-format.md "<result>, <key link or id> (<date>)"
has "parseable formats"         references/tasks-format.md "machine-parseable"
# Close-out
has "close-out form"            references/handoff.md "## Close-out"
has "close-out next"            references/handoff.md "none; done <date>: <result>"
# Dispatch
has "dispatch gate"             SKILL.md "confirmed in this run"
has "deep skips other tasks"    SKILL.md "In Deep, a line for another task"
has "deep stops when closed"    SKILL.md "If Step 0 closes the task, stop after the close-out"
has "deep may close out"        SKILL.md "including moving it to Done"
has "conflict checks exempt"    SKILL.md "exempt from the status rule"
has "who runs conflict check"   SKILL.md "with read access to both tasks' Links"
has "highest priority launch"   SKILL.md "the 4 highest-priority choices"
has "eligibility"               SKILL.md "Dispatch candidates"
has "choose-then-launch"        SKILL.md "Choose, then launch"
has "reply by numbers"          SKILL.md "\`1,3,4\`"
has "out of range"              SKILL.md "out of range"
has "nothing to delegate"       SKILL.md "Nothing to delegate; all Nexts wait on you or others"
has "red flag dispatch"         SKILL.md "Everything waits on the user"
# Conflicts
has "conflicts step"            SKILL.md "**Check conflicts**"
has "hub-wide files"            SKILL.md "Hub-wide files"
has "conflict line"             SKILL.md "#a ↔ #b"
has "report sections"           SKILL.md "Waiting, Conflicts"
# Public repo hygiene (names are checked on the diff at release, Task 4 Step 5; never list them here)
if grep -rqE '1[A-Za-z0-9_-]{40,}' "$S"; then echo "FAIL document ids in the skill"; fail=1; else echo "ok   no document ids"; fi
exit $fail
