---
name: too-voice
description: Use for "/too-voice", "polish my English", "make this sound like me", "write this in my voice", or when the user, a non-native English speaker, asks to write or fix a message (Slack, PR comment, email) so it reads as their own. Accepts drafts in English and intents in Italian.
---

# Write in my voice

Make English read as the writer's own message: their vocabulary level,
phrasing and tone. The goal is a message nobody would flag as AI-written or
as written by someone else.

## The voice

Drawn from ~330 of the writer's public GitHub comments (2021–2026).

- **Openers:** almost always `Hi @name!` or `Hi @name,` with the message on
  the next line. `Hey @name` for people they already know, `Hi all!` for a
  group. Thanks come early: "thanks for your contribution", "Thank you for
  your quick reply!".
- **Closers:** usually "Greetings!" or "Cheers!" on their own line; also
  "Thank you!" or an offer: "Happy to review/rework/support…".
- **Hedging:** claims are tentative: "seems", "I believe", "I seem to
  understand", "I assume", "Not sure whether…". Opinions come as
  suggestions: "I'd suggest to…", "I'd consider…", "I'm inclined to…".
- **Checking questions:** "…, right?", "Am I missing anything?", "Did I get
  it right?", "Makes sense?", "Would it make sense…?", "Shall we…?", "Would
  you mind…?".
- **Softeners:** self-deprecating asides with `:)`: "(my bad :))", "I might
  be missing some obvious element :)". `👍` to confirm something is done,
  `✌️` as a friendly sign-off; `❤`, `🙌`, `🙇` rarely.
- **Length:** one line when it's enough ("Branch rebased :)", "PR ready for
  another review 👍", "Superseded by #…"). Longer posts get structure:
  `###` headings, bullets, numbered points, links to the exact lines.
- **Connectives:** "BTW", "That said,", "In the meanwhile", "In other
  words:", "As for…", "Back to…", "Eg:".
- **Contractions:** mostly (I'm, I'll, don't, can't), with "cannot" now and
  then.
- **The writer's own non-native phrasing, to keep:** "if the case" (if
  needed), "from my side", "Happy to…", "I'd suggest to try and…", "at" +
  -ing ("hesitant at pushing", "struggling at spending time"), "Beside X"
  (apart from X), "OS" for open source, digits for small numbers ("the 2
  options"). Idioms are Italian sayings in English ("the remedy might look
  worse than the disease"), never native ones.

If the user pastes a Slack thread, use the writer's lines as extra samples:

- The writer is `git config user.name`, matched against sender headers
  (`Name  [10:05 AM]`). If no header matches, ask which lines are theirs.
- A bare timestamp (`[10:06 AM]`) continues the previous sender.
- Strip `(edited)`, URLs and link-preview text.
- Drop any text that repeats another participant's message: it's a quote.
- Other participants' lines are context, never style samples.

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
  ("circle back", "touch base", "ballpark").
- Keep non-native phrasing that reads fine ("I cannot see", "from my
  side"), including uncontracted forms. Don't add typos or mistakes on
  purpose.
- Match the channel: Slack short and informal, PR comment direct, email
  fuller.
- Finish with the `pstack:unslop` pass. Its rules win over the voice only for
  AI tells, never for the writer's own phrasing.
