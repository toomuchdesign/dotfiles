---
name: too-voice
description: Use for "/too-voice", "polish my English", "make this sound like me", "write this in my voice", or when the user, a non-native English speaker, asks to write or fix a message (Slack, PR comment, email) so it reads as their own. Accepts drafts in English and intents in Italian.
---

# Write in my voice

Make English read as the writer's own message: their vocabulary level,
phrasing and tone. The goal is a message nobody would flag as AI-written or
as written by someone else.

## Learn the voice

Do this on every run. Keep samples and observations in context only; never
write them to a file.

1. Fetch the writer's recent public GitHub comments and read the output
   directly; don't redirect it to a file:

   ````sh
   gh api graphql -f query='{viewer{issueComments(last:100){nodes{body repository{isPrivate}}}}}' --jq '.data.viewer.issueComments.nodes[] | select(.repository.isPrivate | not) | .body | select(test("🤖") | not) | select(test("^\\s*@(dependabot|copilot)\\b") | not) | gsub("```[\\s\\S]*?```"; "") | split("\n") | map(select(test("^\\s*>") | not)) | join("\n") | gsub("^\\s+|\\s+$"; "") | select(length > 0) | . + "\n---"'
   ````

   Each comment ends with a `---` line. `🤖` marks AI-drafted comments, and
   `@dependabot`/`@copilot` lines are bot commands. Neither is the writer's
   voice.

2. If the user pasted a Slack thread, keep only the writer's lines:
   - The writer is `git config user.name`, matched against sender headers
     (`Name  [10:05 AM]`). If no header matches, ask which lines are theirs.
   - A bare timestamp (`[10:06 AM]`) continues the previous sender.
   - Strip `(edited)`, URLs and link-preview text.
   - Drop any text that repeats another participant's message: it's a quote.
   - Other participants' lines are context, never style samples.

3. Note sentence length, formality, recurring phrases, openers and closers,
   emoji, and which native idioms the writer never uses.

4. If `gh` fails, say so in one line and keep any Slack samples. If fewer
   than 5 samples remain in total, say so and continue with the rules below
   only.

## Modes

- **Polish** (default, when the user gives a draft): fix only grammar and
  spelling errors and phrasing a native reader would misread. Keep the
  writer's words, order and structure; "I've a doubt" stays, it doesn't
  become "I have a concern". If a calque may confuse a native reader, keep
  it and list an alternative as a suggestion. Return the text, then a short
  list of changes and suggestions.
- **Compose** (when the user gives an intent, in Italian or English): write
  the message in the writer's voice for the channel they name. Say only
  what the intent says; add no promises or follow-ups. Ask for the channel
  only if it's unclear.

## Rules

- Never raise vocabulary above the writer's level. Add no native idiom
  ("circle back", "touch base", "ballpark") the samples don't show.
- Keep non-native phrasing that reads fine ("I cannot see", "from my
  side"), including uncontracted forms. Don't add typos or mistakes on
  purpose.
- Match the channel: Slack short and informal, PR comment direct, email
  fuller.
- Finish with the `pstack:unslop` pass. Its rules win over the samples only
  for AI tells, never for the writer's own phrasing.
