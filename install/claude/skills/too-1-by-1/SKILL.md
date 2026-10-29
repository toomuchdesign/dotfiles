---
name: too-1-by-1
description: Use for "/too-1-by-1", "go through them one by one", "one at a time", "point by point", or "walk me through each" over a set of findings, review comments, problems, research points, evidence, or open questions the user needs to decide on. Works mid-task on items already in the conversation.
---

# One by one

Take a set of items and put each one to the user as its own decision, with enough context to decide without scrolling back.

## Collect

1. **Source:** the argument if given: a file (such as `findings.md` from `too-review-all`), a URL, command output, or a reference to earlier output ("the review above"). Otherwise the most recent list of findings, review comments or questions in this conversation, whatever produced it. If neither is clear, ask which. Numbers after the source (`1,3,5`) pick items and keep the source's numbering; without them take the source's `default:` list if it has one, else everything.
2. **Check each item** against its source: read the referenced code or document, and everything its card will quote, so later items don't wait on reads. Drop items that don't hold up and say which ones.
3. **Importance:** if the source rates items (severity, priority, P1/P2, blocker/nit), map each to a meter: `▮▮▮ high`, `▮▮▯ medium`, `▮▯▯ low`. If it doesn't, show no meter.
4. **Order** by what unblocks others first, then by importance.
5. **Log:** create it once and print the path:

   ```sh
   log="$(mktemp -d "${TMPDIR:-/tmp}/1-by-1.XXXXXX")/decisions.md" ; printf '%s\n' "$log"
   ```

6. **Mode:** `decide-first` (default) or `loop` if the user asked for it.
7. **Contract:** when the source's header names a `contract:` file, or a skill hands over the items and defines what a decision is, read and follow it: its options replace the fix options, its finish step replaces **Finish**, and in `loop` its action replaces implementing. Without one, the default below applies. `absorb` / `new` apply only to code changes on the current branch.

Open with one message: the numbered index (one line per item, with its meter), the total, the mode, the log path. Then item 1 in the shape below.

## Each item

One item per message, always these sections in this order. The card is visible output text, never only reasoning: drafting it while thinking doesn't show it to the user.

````markdown
### <n>/<total> · <short name> · <meter, if any>

> <the problem and its consequence in one line> **Pick: <option number>[, absorb | new].**

**Where**
/absolute/path/file.ts:42
<who calls it or where the point came from> · /absolute/path/caller.ts:10

```ts
<the code, quote, or data that shows it>
```

**In plain words:** <what goes wrong and who feels it, jargon-free, the way the `bro` skill talks>

**Options**
1. ★ **<option name>**
   \+ <gain>
   − <cost>
2. **<option name>**
   \+ <gain>
   − <cost>

**Why ★:** <the reasoning behind the pick>

**Need from you:** <a fact you can't find that changes the pick>

---
**Your call:** `1`–`<n>` · `custom` · `rephrase` · `skip` · `defer` + `absorb` (<sha>) or `new`
````

Give each section all the information that helps the decision; there is no length limit. Use as many `+` / `−` lines per option as the trade-offs need. The ★ option is always listed first.

Every file you mention, in any message, is a plain absolute path with `:line` on its own line or after a `·`, never a markdown link and never relative, so the user can click it open in their IDE.

Include the `absorb` / `new` part (in the summary line and the answer line) only when the lines to change were introduced by a commit on the current branch (`git log <base>..HEAD -L<start>,<end>:<file>` or `git blame`); otherwise the fix is a new commit and it's left out. Pick absorb when the fix corrects that commit's own change, new when it's a separate concern.

Include **Need from you** only when the choice depends on a fact you can't find.

### Ask with a picker

End every item with `AskUserQuestion`: write the full card as text first, then call the tool in the same message, leaving out the `---` / **Your call** lines. Never put the choice only as a typed list when the tool is available. A picker with no card above it is a failed item.

- Question 1, header `<n>/<total>`: the question text stands on its own, since the picker can hide the message above it: what the code does, what goes wrong, who feels it, then "Which fix?". Options, in list order: up to 3 item options, then `Rephrase` (description: "Explain this point again in different words"). Label `<option name> (Recommended)` for ★, `<option name>` for the rest; description is its main gain and cost. With more than 3 item options, the picker carries the first 3 and the card says the rest are picked by typing their number.
- Question 2, header `Lands as`, only when absorb applies: `Absorb into <sha> (Recommended)` / `New commit`, recommended one first.

The picker's free-text field takes an option number, `custom <text>`, `rephrase <hint>` and the commands below. Only without the tool, end with the **Your call** line instead.

Stop after asking. The next item goes in the next message, after the user answers.

## After each answer

- `Rephrase`: rewrite the whole card for the same item from scratch, with new wording, a different angle or example, and a simpler **In plain words**. Keep the facts, the number, and the options with their numbering. A hint (`rephrase focus on who's affected`) steers it. Ask again; nothing is logged.
- Append `<n>. <name> → <decision> [absorb <sha> | new] [after #<m>]` to the log. Add `after #<m>` when the decision only holds if item m lands. Don't spend a round trip on it: write the next card right away and make the append a `Bash` call in the same message, next to its `AskUserQuestion`. After the last item, append on its own before **Finish**.
- `defer`: log it as deferred; it goes to `open.md` to be decided once the other fixes have landed.
- If the answer changes an earlier decision or makes a later item moot, say so.
- `decide-first`: show the next item.
- `loop`: implement it, run the narrowest check (type check, the related test), report the result in two lines, then show the next item. A failing check gets fixed or raised before moving on.

The user can type at any point: `defer` (this item), `back`, `list` (index with decisions so far), `switch to loop` / `switch to decide-first`, `stop`.

## Finish

Show the decision table from the log. In `decide-first`, propose an implementation order and ask for one go-ahead that covers implementing and landing everything in the log.

On the go-ahead, hand the log to a background `general-purpose` agent and give control back; say the working tree is in use until it reports. The agent works through the decisions in order without asking anything:

1. Re-read the code. If an earlier fix already resolved the item, record it as resolved by that fix. If the item's `after #<m>` didn't land, or an earlier fix made the decision wrong, record it as open with the reason. Either way, move on.
2. Implement it and run the narrowest check (type check, the related test). If the check fails and the fix isn't obvious, revert that change and record it as open with the output.
3. Commit each `new` fix on its own as it lands. After the last item, run `too-commit-absorb` on the `absorb` fixes, so absorb can't fold a new fix into history.

Open items go in `open.md` next to the log, each with its location and why it's open. When the agent finishes, report what landed, with the commits and check results, what earlier fixes resolved, and what's open. If anything is open, run this skill again on `open.md`.

If this was started in the middle of another task, say what that task was and pick it up again with the decisions applied.
