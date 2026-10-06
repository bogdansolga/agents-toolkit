---
name: ste100-80
description: Write or rewrite text "80% of the way to ASD-STE100" (Simplified Technical English) — short sentences, active voice, one idea per sentence, simple verb tenses, consistent terms — without the full spec's strict dictionary. Use when the user asks for an explanation, summary, doc, README, runbook, handoff, or PR description "in STE", "in ASD-STE100", "80% STE", "controlled language", or "plain technical English", or invokes /ste100-80. Also use to rewrite existing text in that style.
---

# 80% of the way to ASD-STE100

ASD-STE100 (Simplified Technical English) is a controlled language from aerospace
maintenance documentation. Its full form is very strict: an approved dictionary of about
900 words, each with one meaning. This skill keeps the rules that make text easy to read
and relaxes the rules that make it stiff.

Apply it to everything you write for this request: explanations, lists, tables, headings
and code comments. Do not apply it to code, commands, quoted text or names.

## Keep (the structural rules — apply them fully)

1. **Sentence length.** Procedures (instructions): 20 words or fewer. Descriptions: 25
   words or fewer. Split longer sentences.
2. **One idea per sentence.** One instruction per sentence. Two actions in one sentence
   only when they occur at the same time.
3. **Active voice.** Say who does the action. "The server rejects the file", not "The file
   is rejected".
4. **Imperative for procedures.** "Run the build." "Open the file." Not "You should run" or
   "The build can be run".
5. **Simple tenses.** Use simple present, simple past and simple future. Avoid perfect and
   continuous forms ("has been doing", "will have been").
6. **Condition first.** Put the condition before the instruction: "If the test fails, read
   the log." Put the reason after: "Do X. This prevents Y."
7. **Short paragraphs.** One topic per paragraph. 6 sentences or fewer.
8. **No long noun clusters.** 3 nouns together at most. "Upload size limit" is fine;
   "client upload size limit check result" is not — use "the result of the check on the
   upload size".
9. **Keep articles.** Write "the", "a" and "an". Do not drop them to save words.
10. **Consistent terms.** One name for one thing. Do not change words for variety. If you
    call it "the endpoint", do not later call it "the route" or "the API".
11. **Lists for steps and sets.** Use a numbered list for a sequence, a bullet list for
    items with no order.
12. **Warnings first.** Put a warning or caution before the step it is about. Start it with
    a short command: "Do not run this on production."
13. **Positive and specific.** Say what to do, not only what not to do. Give numbers,
    names and values instead of "some", "several", "a few".

## Relax (the 20% that the full spec forbids)

- **Vocabulary.** You may use common plain-English words outside the STE dictionary. Still
  prefer the shortest common word: "use" not "utilize", "start" not "commence", "help" not
  "facilitate", "about" not "approximately".
- **One meaning per word — mostly.** Keep a word to one meaning inside one text. You do not
  need the dictionary's single fixed meaning.
- **Technical names and verbs.** Use the domain's own terms freely (commit, deploy, rebase,
  schema, token, endpoint). Define a term once if the reader may not know it.
- **Passive voice when the actor is unknown or unimportant.** "The file was deleted" is
  acceptable if nobody knows who deleted it. Otherwise use active voice.
- **-ing words** are fine as nouns and adjectives ("logging", "the running process").
  Avoid them as verb forms where a simple tense works.
- **Sentence length.** You may exceed the limit by a few words when splitting would break
  one tightly linked idea. This is the exception, not the norm.
- **Phrasal verbs.** Common ones ("set up", "log in", "roll back") are fine when they are
  the normal technical term.
- **Contractions** are acceptable in informal text. Use "do not" in warnings.

## Avoid

- Filler and hedges: "basically", "simply", "just", "it is worth noting that", "in order to"
  (use "to").
- Vague pronouns at the start of a sentence: "This", "It" with no clear noun. Repeat the
  noun.
- Idioms, metaphors and humour. Non-native readers and translation tools lose them.
- Long introductions. Start with the answer or the first step.

## Before / after

Before:
> In order to ensure that the deployment process is able to be completed successfully, it
> is recommended that the configuration file should be validated by the user prior to the
> pipeline being triggered, since otherwise failures may potentially occur.

After:
> Validate the configuration file before you start the pipeline. An invalid file stops
> the deployment.

## Self-check before you answer

1. Is any sentence longer than 25 words (20 for an instruction)? Split it.
2. Does any sentence contain two ideas? Split it.
3. Is any verb passive where the actor is known? Make it active.
4. Did you use two names for one thing? Pick one.
5. Is there a noun cluster of 4 or more words? Rewrite it.
6. Does the text start with the answer? If not, move the answer up.
