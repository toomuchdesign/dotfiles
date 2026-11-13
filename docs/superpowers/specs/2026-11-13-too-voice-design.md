# too-voice design

## Goal

Write or polish English for a non-native writer so it reads as the writer's
own message: their vocabulary level, phrasing and tone, with no AI tells.

## Constraints

- Public repo. Nothing committed may describe the writer's voice or contain
  their messages: a distilled style profile is an impersonation recipe.
- No setup beyond `make install` (the `claude-skills-local` target symlinks
  the skill) and `gh auth login`.
- No stored profile, no extra folders, no MCP connectors.

## Files

- `install/claude/skills/too-voice/SKILL.md`, the only new file.
- `docs/cheatsheet.md`: one row in the "My own skills" table.

## Learning step

Runs fresh on every invocation. Samples and derived patterns live in the
session context only and are never written to disk.

1. GitHub: fetch the authenticated user's last 100 issue and PR comments.

   ```sh
   gh api graphql -f query='{viewer{issueComments(last:100){nodes{body repository{isPrivate}}}}}'
   ```

   Keep public repos only. Drop comments containing `🤖` (AI-drafted), bot
   commands (`@dependabot …`, `@copilot …`), quoted lines (`>`) and code
   blocks.

2. Slack (optional): if the user pasted a conversation, keep only the
   writer's messages, matched by `git config user.name` against the sender
   header (`Name  [11:20 AM]`). If no name matches, ask which lines are
   theirs.
   - A bare timestamp line (`[11:22 AM]`) continues the previous sender.
   - Strip `(edited)`, URLs and link-preview text.
   - Drop text that repeats another participant's message (inline quotes).

3. From the remaining samples, note sentence length, formality, recurring
   phrases, openers and closers, and the native idioms the writer never
   uses.

4. If `gh` fails or fewer than 5 samples remain, say so once and continue
   with the generic rules only.

## Modes

Picked from the request.

- **Polish** (default): the user pastes a draft. Fix only errors that hurt
  clarity; keep their words and structure. Flag calques a native reader may
  not understand as suggestions instead of rewriting them. Return the text
  and a short list of changes.
- **Compose**: the user gives the intent (Italian or English) and the
  channel. Draft it in the writer's voice.

## Generic rules

Always on, with or without samples.

- Never raise vocabulary above the writer's level; add no native idioms the
  samples don't show.
- Keep harmless non-native phrasing. No deliberate typos or fake mistakes.
- Match the channel: Slack short and informal, PR comment direct, email
  fuller.
- Apply `pstack:unslop` as the last pass.

## Testing

Per `superpowers:writing-skills`:

- Blind check: mix a few of the writer's real messages with skill output on
  the same topics; the writer tries to tell them apart.
- Over-correction check: polish one real draft and confirm only errors and
  unclear calques changed.
- Fallback check: run with `gh` logged out and confirm the warning and the
  generic-rules output.

## Out of scope

Stored profiles, Slack or email access through connectors, auto-applying
the skill to all output, translating whole documents.
