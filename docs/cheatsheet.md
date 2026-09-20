# Cheat sheet

The stuff I keep forgetting I have. Opinionated on purpose: only what's worth
reaching for, keyed by what I'm trying to do — not a full catalog. Two halves:
[shell commands](#commands) and [Claude skills](#skills).

---

# Commands

Shell / CLI. The [README](../README.md#shell) has the complete tables (git,
npm, docker, aliases, functions); this section is only the recipes that don't
stick.

## Finding files and content

`fd` searches by **name**, `rg` searches by **content**. Both respect
`.gitignore` and both take an optional path to scope the search.

| I want to…                            | Command                       |
| ------------------------------------- | ----------------------------- |
| Find a file by name, anywhere below cwd | `fd auth.controller`          |
| …only inside a folder                 | `fd auth.controller src`      |
| …including git-ignored files          | `fd -H -I auth.controller`    |
| …by extension                         | `fd -e ts` / `fd -e ts src`   |
| Search file contents, anywhere below cwd | `rg "createServer"`           |
| …only inside a folder                 | `rg "createServer" src`       |
| …in one file type                     | `rg -t ts "createServer"`     |
| …show only matching file names        | `rg -l "createServer"`        |
| …case-insensitive                     | `rg -i "todo"`                |
| …including git-ignored files          | `rg -uu "createServer"`       |
| Fuzzy-pick a file path into the command line | `Ctrl-T`                |
| Fuzzy-search shell history            | `Ctrl-R`                      |
| Jump to a recent directory            | `z <fragment>` / `zi`         |

Rule of thumb: **name → `fd`, content → `rg`, folder → append the path**.

---

# Skills

Claude Code agent skills. `/name` = invoke via slash command; some fire
automatically. Skip everything not listed here — see
[the noise list](#installed-but-probably-not-for-me).

## Worth remembering

Grouped by the moment I'd want them.

| When I'm about to…                    | Reach for                                 |
| ------------------------------------- | ----------------------------------------- |
| Build a feature (explore intent first) | `/superpowers:brainstorming`             |
| Design types/module shape before code | `/pstack:architect`                       |
| Write a plan for multi-step work      | `/superpowers:writing-plans`              |
| Debug a bug whose cause I don't know  | `/superpowers:systematic-debugging`       |
| Run two+ approaches and compare       | `/pstack:arena`                           |
| Get an adversarial multi-model review | `/pstack:interrogate`                     |
| Review my own diff before merge       | `/code-review` (built-in)                 |
| Fix failing CI on a PR                | `/pstack:fix-ci`                          |
| Drive an open PR to mergeable         | `/pstack:babysit`                         |
| Work on a Fastify server/route        | `/fastify`                                |
| Node.js + native-TS (strip types) work | `/node`                                  |
| Wrangle a hard generic / kill an `any` | `/typescript-magician`                   |
| Set up ESLint 9 flat config / neostandard | `/linting-neostandard-eslint9`        |
| Add or reorganize docs (Diátaxis)     | `/documentation`                          |

`unslop` (prose) and `deslop` (code) run automatically on every output — they're
wired into my global [CLAUDE.md](../install/claude/CLAUDE.md), no need to invoke.

## My own skills

Authored in this repo under [`install/claude/skills/`](../install/claude/skills/),
symlinked into `~/.claude/skills/`, so edits apply live:

| Skill                            | When                                                             |
| -------------------------------- | --------------------------------------------------------------- |
| `/toomuchdesign-pr-description`  | Write a PR description / markdown summary of a branch diff       |
| `/toomuchdesign-absorb`          | Fold uncommitted edits into the commits that introduced them     |
| `/toomuchdesign-relink`          | Use a local sibling package as if published (npm/yarn/pnpm)      |

## Pick one — the overlaps

Several families ship the same job. Redundant triggers are why nothing sticks.
My default per job:

| Job            | Use                                | Also installed (ignore)                          |
| -------------- | ---------------------------------- | ------------------------------------------------ |
| TDD            | `/superpowers:test-driven-development` | `pstack:tdd`, `mattpocock-skills:tdd`        |
| Debugging      | `/superpowers:systematic-debugging` | `mattpocock-skills:diagnosing-bugs`, `pstack:principle-fix-root-causes` |
| Code review    | `/code-review` + `/pstack:interrogate` | `superpowers:requesting-code-review`, `mattpocock-skills:code-review` |
| Research       | `/deep-research`                   | `mattpocock-skills:research`                      |

## pstack principles are automatic

The two dozen `pstack:principle-*` skills (e.g. `principle-fix-root-causes`,
`principle-laziness-protocol`) are **not** meant to be invoked by hand.
`poteto-mode` and the other pstack skills route to them when relevant. Don't try
to remember them; let the router do it.

## Installed but probably not for me

Candidates to leave alone or uninstall — none fit my day-to-day JS/TS work:

- `snipgrapher` — code-screenshot images
- `nodejs-core` — contributing to Node.js core / C++ addons (not my work)
- `skill-optimizer` — authoring/tuning skills
- `init` — generating AGENTS.md (rarely)
- `plannotator-*` — only if I actually use Plannotator reviews

Nearform marketplace skills that got pulled in per-project (`nearform-sql`,
`netsuite-timesheet`, `test-jira-cases`, `test-cypress/webdriverio/k6/pact`,
`nearform-blog-ideas`, …) are installed locally to specific repos, not globally.

To remove a plugin-based one:

```
claude plugin uninstall <name>@<marketplace>
```

For the plain skills copied into `~/.claude/skills/` by the Makefile, delete the
folder — but it comes back on the next `make claude-skills`, so drop it from the
[Makefile](../Makefile) target too if you want it gone for good.
