# Global instructions

Applies to every project on this machine. Managed in dotfiles
(`install/claude/CLAUDE.md`), symlinked to `~/.claude/CLAUDE.md`.

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

When a code change adds or edits comments, also apply `deslop` to strip AI
code slop (needless comments, defensive noise, `any` casts).

Skip verbatim content: direct quotes, code identifiers, and anything the
user asks to leave unchanged.

## Keep it minimal

Make the output as short as it can be without losing clarity. Cut filler,
redundant restatement, and hedging; keep only what carries meaning. Fewer
words for the same information is always better. Never trade away
correctness or clarity to hit a smaller size.
