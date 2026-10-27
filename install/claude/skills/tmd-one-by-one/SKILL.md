---
name: tmd-one-by-one
description: Use for "/tmd-one-by-one", "go through them one by one", "one at a time", "point by point", or "walk me through each" over a set of findings, review comments, problems, research points, evidence, or open questions the user needs to decide on. Works mid-task on items already in the conversation.
---

# One by one

Take a set of items and put each one to the user as its own decision, with enough context to decide without scrolling back.

## Collect

1. **Source:** the argument if given (file, URL, command output). Otherwise the most recent list of findings or questions in this conversation. If neither is clear, ask which.
2. **Check each item** against its source: read the referenced code or document. Drop items that don't hold up and say which ones.
3. **Importance:** if the source rates items (severity, priority, P1/P2, blocker/nit), map each to a meter: `▮▮▮ high`, `▮▮▯ medium`, `▮▯▯ low`. If it doesn't, show no meter.
4. **Order** by what unblocks others first, then by importance.
5. **Log:** create it once and print the path:

   ```sh
   log="$(mktemp -d "${TMPDIR:-/tmp}/one-by-one.XXXXXX")/decisions.md" ; printf '%s\n' "$log"
   ```

6. **Mode:** `decide-first` (default) or `loop` if the user asked for it.

Open with one message: the numbered index (one line per item, with its meter), the total, the mode, the log path. Then item 1 in the shape below.

## Each item

One item per message, always these sections in this order:

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
**Your call:** `1`–`<n>` · `custom` · `skip` · `later` + `absorb` (<sha>) or `new`
````

Give each section all the information that helps the decision; there is no length limit. Use as many `+` / `−` lines per option as the trade-offs need. The ★ option is always listed first.

Every file you mention, in any message, is a plain absolute path with `:line` on its own line or after a `·`, never a markdown link and never relative, so the user can click it open in their IDE.

Include the `absorb` / `new` part (in the summary line and the answer line) only when the lines to change were introduced by a commit on the current branch (`git log <base>..HEAD -L<start>,<end>:<file>` or `git blame`); otherwise the fix is a new commit and it's left out. Pick absorb when the fix corrects that commit's own change, new when it's a separate concern.

Include **Need from you** only when the choice depends on a fact you can't find.

### Ask with a picker

When the `AskUserQuestion` tool is available and the item has 2–4 options, ask through it right after the message and leave out the `---` / **Your call** lines:

- Question 1, header `<n>/<total>`: the question text stands on its own, since the picker can hide the message above it: what the code does, what goes wrong, who feels it, then "Which fix?". One option per item option, in list order. Label `<option name> (Recommended)` for ★, `<option name>` for the rest; description is its main gain and cost.
- Question 2, header `Lands as`, only when absorb applies: `Absorb into <sha> (Recommended)` / `New commit`, recommended one first.

The picker's free-text field takes `custom` answers and the commands below. With more than 4 options, or without the tool, end with the **Your call** line instead.

Stop after asking. The next item goes in the next message, after the user answers.

## After each answer

- Append `<n>. <name> → <decision> [absorb <sha> | new]` to the log.
- If the answer changes an earlier decision or makes a later item moot, say so.
- `decide-first`: show the next item.
- `loop`: implement it, run the narrowest check (type check, the related test), report the result in two lines, then show the next item. A failing check gets fixed or raised before moving on.

The user can type at any point: `back`, `list` (index with decisions so far), `switch to loop` / `switch to decide-first`, `later` (pause and keep the log), `stop`.

## Finish

Show the decision table from the log. In `decide-first`, propose an implementation order and wait for a go-ahead before changing code.

Landing follows the log and needs the user's go-ahead like any commit: commit each new one on its own first, so absorb can't fold it into history, then run `tmd-commit-absorb` on the remaining absorb fixes.

If this was started in the middle of another task, say what that task was and pick it up again with the decisions applied.
