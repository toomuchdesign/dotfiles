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
"not just X but Y", no forced rule-of-three, no bolding every proper noun,
no filler. Then self-audit — "what makes this obviously AI-generated?" —
and fix what's left.

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

Don't leave gratuitous blank lines in prose or code.

## Verification

Never claim done / fixed / passing without showing the command output that
proves it. If you didn't run it, say so plainly. Prefer the real fix over a
mask — address the cause, not the symptom.

## Diffs & scope

Keep diffs minimal and reviewable. Touch only what the task needs. If you
spot adjacent work, mention it — don't do it. For legacy code that needs
team approval, keep changes small enough to be approved.

## Git & commits

Never commit without explicit approval. Default to amending the fix into the
commit that introduced the line; keep refactors in their own commit. One
concern per commit, each independently revertable. When a branch can't be
amended, make an additive commit instead.

Git worktrees are mine to manage for my own branch work — don't create or
switch them as a substitute for me changing branches; just work in the
directory I'm in. Exceptions: (1) I explicitly ask, or (2) your own process
needs isolation (e.g. parallel agents each on a different approach). In
those cases go ahead, but say what you created and where, and clean it up
when done.

## Planning

For non-trivial or legacy changes, present options with pros/cons before
implementing; let me choose.

## Reuse my skills

When a task wants multi-agent review or parallel candidates, suggest
`/interrogate` or `/arena` instead of hand-typing reviewer/candidate
prompts.

## Long-running & background work

Run slow work (installs, full test suites, builds, benchmarks) in the
background and hand control back — don't block on it. When I only need to
know it finished, use something that exits and notifies once on completion;
don't sit watching an unbounded tail. On long unattended runs, emit a short
heartbeat (elapsed + current step) rather than going silent. Never report a
background job as "fine" or "still going" without actually checking its
state.
