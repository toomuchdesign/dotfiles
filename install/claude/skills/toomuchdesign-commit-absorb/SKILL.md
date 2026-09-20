---
name: toomuchdesign-commit-absorb
description: Use for "/toomuchdesign-commit-absorb", "reconcile these changes", "fold this into the right commits", or after addressing review feedback — reconciles uncommitted edits into the commits that introduced those lines, leaves genuinely-new work for its own commit, so branch history reads as a clean logical sequence. Wraps the deterministic git-absorb tool; the caller supplies the judgment.
---

# absorb

Take the uncommitted changes in the working tree and reconcile them into a clean,
logically-sequential history: edits to existing code fold back into the commit that
introduced that code; genuinely new work becomes its own commit.

Deterministic attribution is done by **git-absorb** (a static, no-AI tool). The
judgment it can't do — deciding whether leftover is a new concern, writing its commit
message, keeping the order logical — is yours.

## When to use

- After a `plannotator` (or any) review pass: implement the feedback **without
  committing**, then `/toomuchdesign-commit-absorb` to fold the fixes back into the commits under review.
- Any time follow-up tweaks/refactors should land in the commits that introduced the
  code, not pile up as "address review" commits at the tip.
- Runs safely and idempotently in a tight review→fix→absorb→review loop.

## Requires

`git-absorb` on PATH (`brew install git-absorb`). The script errors clearly if absent.

## Flow

Run `absorb.sh` from anywhere in the repo.

1. **`absorb.sh preview`** *(optional)* — `git-absorb --dry-run`; shows which edits would
   fold into which commits. Side-effect-free. Skip it in the fast post-review pass.
2. **`absorb.sh`** — stages tracked edits, runs git-absorb to create `fixup!` commits, then:
   - **No leftover** → folds them in (non-interactive autosquash rebase) and verifies. Done in one shot.
   - **Leftover remains** (untracked/new or hunks git-absorb couldn't pin) → it stops and lists them.
3. **Your judgment on leftover** — for each item decide: genuinely new concern → commit it
   as its own logical commit (unslop'd message); belongs in history but git-absorb couldn't
   place it → handle manually. Then:
4. **`absorb.sh finish`** — folds the fixups in and verifies.

`--base REF` overrides the base (defaults to this branch's fork point from upstream/main).
Only commits **after** base are touched — shared history below the fork point is never rewritten.

## The guarantee

After folding, the script asserts the final tree is **byte-identical** to the pre-run
working state — only history was reorganized, zero content drift. If it isn't, it says so
and points at `git reset --hard ORIG_HEAD` to recover.

## Notes for the agent

- This rewrites history (force-push territory). The user decides when that's appropriate —
  don't add safety gates, but never force-push without explicit OK.
- Pure additions / brand-new files have no origin commit; git-absorb leaves them — that's the
  signal they're a new concern. Don't try to force them into an unrelated commit.
- Don't wire this into the plannotator skills; the uncommitted working tree is the hand-off.
- Verify the branch still builds/types after a fold before reporting success.
