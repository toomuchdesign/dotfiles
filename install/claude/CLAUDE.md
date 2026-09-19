# Global instructions

Applies to every project on this machine. Managed in dotfiles
(`install/claude/CLAUDE.md`), symlinked to `~/.claude/CLAUDE.md`.

## Never push to master/main on your own

Two hard rules for the default branch (`master` or `main`):

1. **Never force-push to it.** No `--force`, `-f`, or `--force-with-lease`
   targeting `master`/`main`, ever — no exception, no matter what you think
   the history needs.
2. **Never plain-push to it unless the prompter told you to in this
   conversation.** A general "keep things moving" is not permission. If the
   work is on the default branch, branch first and push the branch.

When you believe a push to the default branch is warranted, stop and ask.
If the human wants it done, they run it themselves (`! git push …`) — you do
not run it for them. Pushing to a feature branch is fine.

## Always unslop written output

Before returning any prose you generated, apply the `unslop` skill
(`pstack:unslop` — cut AI tells) as a final pass. This covers:

- code comments and inline comments
- documentation and READMEs
- commit messages and PR descriptions
- issue and ticket text
- any prose deliverable you're asked to produce (e.g. "give me a PR
  description for this")

For a substantial deliverable, invoke the skill. For a short comment or
sentence, apply its patterns inline: plain words over AI vocabulary, no
"not just X but Y", no forced rule-of-three, no filler. Then self-audit —
"what makes this obviously AI-generated?" — and fix what's left.

Skip verbatim content: direct quotes, code identifiers, and anything the
user asks to leave unchanged.

## Always deslop code output

`deslop` is the code counterpart to `unslop` (prose). Before finalizing any
code you wrote or edited, apply the `deslop` skill (`pstack:deslop`) — strip
needless comments, defensive noise, `any` casts, and other AI code slop.
Match the surrounding file's style.

## Keep it minimal

Make the output as short as it can be without losing clarity. Cut filler,
redundant restatement, and hedging; keep only what carries meaning. Fewer
words for the same information is always better. Never trade away
correctness or clarity to hit a smaller size.
