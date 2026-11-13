---
name: too-write-task
description: Use for "/too-write-task", "write a task", "write a ticket/issue for this", "turn this into a bug/feature/refactor task", or when the user wants something from the conversation captured as work for a human or a coding agent to pick up later.
---

# Task

Write one bug, feature, or refactor task from what the conversation established. The reader picks it up later with none of this context: a teammate or a coding agent.

## Gather

1. **Type.** Bug, feature, or refactor. Ask only if the conversation leaves it open.
2. **Facts.** Collect what the conversation established: symptoms, decisions, constraints, options weighed and rejected. Read the code it touches so every file reference is exact.
3. **Links.** Point at code with permalinks at a fixed commit:

   ```sh
   git rev-parse HEAD ; git remote get-url origin ; git branch -r --contains HEAD
   ```

   Turn the remote into a web URL `https://<host>/<group>/<repo>`: drop the user, port, and `.git` from `git@<host>:<group>/<repo>.git`, `ssh://git@<host>[:<port>]/<group>/<repo>.git`, or `https://<host>/<group>/<repo>.git`. Then build links by host:

   | Host                             | Permalink                                           |
   | -------------------------------- | --------------------------------------------------- |
   | `github.com`, GitHub Enterprise  | `<web-url>/blob/<full-sha>/<path>#L<start>-L<end>`  |
   | `gitlab.com`, self-hosted GitLab | `<web-url>/-/blob/<full-sha>/<path>#L<start>-<end>` |

   A host containing `github` or `gitlab` decides the format. Otherwise check which CLI knows the host, `gh auth status --hostname <host>` or `glab auth status --hostname <host>`, and ask once only if neither does. Use `HEAD` when it is on a remote branch. Otherwise use the newest pushed commit that has the same lines, or fall back to `` `path:line` `` and say the commit isn't pushed.

## Title

The only fixed pattern in the task:

| Type     | Pattern                                | Example                                                |
| -------- | -------------------------------------- | ------------------------------------------------------ |
| Bug      | `<symptom> when <condition>`           | `pnpm not found when a tab opens in a project dir`     |
| Feature  | `<Verb> <outcome>`                     | `Make too-pr-description follow the repo PR template`  |
| Refactor | `Refactor <area> to <structural goal>` | `Refactor too-* skills to share one draft-file recipe` |

## Body

Open with a **Follows up on** block when the task continues earlier work: one line per task, PR, or conversation, linked when it has a URL, saying what it left open.

Then pick the sections that carry information for this task, in this order. A section with nothing specific to say is left out, and two thin sections merge into one. Rename a heading when another word says it better. A small task can be two sections.

**Bug:** Summary · Steps to reproduce · Expected · Actual · Environment · Frequency · Last known good · Evidence · Suspected cause (unverified) · Done when · Out of scope · Open questions

**Feature:** Problem · Current behavior · Desired behavior · Options considered · Done when · Out of scope · Key interfaces · Open questions · Links

**Refactor:** Summary · Why · Target structure · Must not change · Options considered · Risks · Safety net · Sequencing · Done when · Out of scope · Open questions

What goes in them:

- **Plain language describing the outcome.** Say what must be true when the work is done and leave the how to the implementer.
- **Options considered:** only when the conversation compared approaches. Give the chosen one, then each rejected one with the reason the conversation gave. With no stated reason, write just "rejected".
- **Steps to reproduce:** exact actions and inputs, numbered. Expected says why it is expected. Actual quotes errors and output in a code block.
- **Suspected cause (unverified):** what the conversation or your reading of the code points to, with links. A diagnosis, not a fix: no fix options unless the conversation discussed them.
- **Must not change:** the observable behavior the refactor preserves (public API, output, paths, existing test assertions).
- **Done when:** a checklist where each item is a condition someone can check, with the command or steps that check it. This is where a short user-facing scenario goes, written as steps.
- **Open questions:** facts the conversation left unsettled, or that conflict with what you found while reading.
- **References:** a permalink on every file, function, or line the task names.
- **In plain words:** when the problem is hard to grasp, add a short non-technical example right after the first section, as a `> **In plain words:** …` callout written the way the `bro` skill does.
- A one-line user story ("so that…") only inside a section, where it explains a goal. Never as the task's frame.

Format it as GitHub-flavored Markdown: `##` section headings, numbered lists for steps, `- [ ]` for Done when, fenced code blocks with a language tag for commands and output, backticks for paths and identifiers. Use a table when several items share the same attributes (files × line × value, options × verdict). Write each paragraph and list item on one line, with no hard wraps. Put one blank line between blocks and none anywhere else. Leave out `---` rules, emoji, and bold anywhere except a label that opens a line (`**Follows up on:**`, `**In plain words:**`, a list item's lead word).

Every sentence carries a fact about this task. Repo-wide rules (lint, formatting, don't run `make`, commit policy) live in AGENTS.md and stay out of the task.

## Deliver

1. Apply the `unslop` skill to the text.
2. Write it to a fresh file, title as a `#` heading, then the body. Print the path on its own line:

   ```sh
   out="$(mktemp -d "${TMPDIR:-/tmp}/too-write-task.XXXXXX")/task.md" ; printf '%s\n' "$out"
   ```

   Shell state doesn't persist between calls: reuse the printed literal path on every iteration.

3. Format the file, which aligns the tables:

   ```sh
   command -v npx >/dev/null && npx --yes prettier --write --prose-wrap preserve "$out"
   ```

   Without `npx`, align the tables yourself: pad each cell to its column's widest cell, and make the separator row dashes of that width.

4. Show the formatted file's full text in the reply.
5. Offer Plannotator for inline markup. It blocks until the user submits, then prints their annotations on stdout:

   ```sh
   plannotator annotate "$out"
   ```

Apply edits from chat or Plannotator to the same file and deliver again.
