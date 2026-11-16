---
name: verify
description: Verify an implementation against its spec. Checks every acceptance criterion, runs the gates, gets a review from a fresh reviewer subagent, walks the criteria in a real browser and writes a verification report. With --pr it opens a draft PR/MR that refers to the ticket.
argument-hint: "[specs/<slug>.md] [--pr]"
disable-model-invocation: true
---

# Verify

Verify the implementation of: **$ARGUMENTS**
(In Codex, or if this line shows `$ARGUMENTS` literally, use what the user gave.)

You check, you do not build. Fix nothing here. Findings go to the report, and fixes
go back to `/code`.

## Settings

A value that still contains `<ANPASSEN` is not filled in. Take it from `AGENTS.md`,
or ask the user once.

- **Base branch:** <ANPASSEN: Branch-Schema, Basis-Branch, z. B. `main`>
- **Gates:** <ANPASSEN: Gate-Befehle (lint, typecheck, test, e2e), z. B. `npm run lint`, `npm run typecheck`, `npm test`, `PORT=3110 npm run test:e2e`>
- **Dev server and URL:** <ANPASSEN: Port und Dev-URL, z. B. `PORT=3110 npm run dev` auf `http://localhost:3110`, plus Test-Login falls nötig>
- **Open a draft PR/MR:** <ANPASSEN: Ticket-System, z. B. `gh pr create --draft --base main --title "<title>" --body-file <body>`>
  - GitLab: `glab mr create --draft --target-branch main --title "<title>" --description-file <body>`
  - Jira: the ticket lives in Jira, the review in GitHub or GitLab. Use the `gh`
    or `glab` line and put the Jira key in the title and the branch name, so
    Jira links the PR.

## 1. Load

- Read the spec. With no argument, use the spec that matches the current branch,
  or ask.
- Collect the diff: `git diff <base>...HEAD --stat` and `git log <base>..HEAD --oneline`.

## 2. Spec against implementation

For **every** acceptance criterion and every Must requirement, find the code and the
test that prove it. Record `met`, `partly met` or `not met`, with file and test name
as evidence. A criterion without a test is at most `partly met`. Flag scope creep.

## 3. Gates

Run every gate and record result, test counts and duration. A red gate is a
blocking finding. Never rerun a failing test until it passes by luck; report it.
Use a fixed, free port for the app; stop a dev server on that port first, so the
e2e run does not reuse it.

## 4. Fresh review

Start the **reviewer** subagent (Claude Code: `.claude/agents/reviewer.md`, Codex:
`.codex/agents/reviewer.toml`). It begins with an empty context, so the review is
not anchored on your view. Give it only the spec path, the branch and the base
branch, not your conclusions. Check each finding in the code yourself before it goes
into the report, and drop the ones that do not hold.

## 5. Browser walk

Skip this step only if the change has no UI, and say so in the report.

1. Start the dev server in the background and wait until `curl -sf <dev-url>` answers.
2. Drive it with the browser tool you have (e.g. `playwright-cli`, Playwright MCP).
3. For every user-facing criterion: do the steps from the verification plan, check
   the result, reload, check again, and read the console for errors.
4. Look at the affected screens at desktop (1280x800) and mobile (390x844) width.
5. Close the browser and stop the dev server.

If no browser starts, say so. Never mark a criterion as verified in the browser when
you only read the code.

## 6. Report

Write `specs/<slug>.verification.md` and show it to the user:

```markdown
# Verification: <Title>

Branch: <branch> @ <sha>  ·  Verdict: Pass | Issues found

## Acceptance criteria
| AC | Code + test | Browser | Result |

## Gates
| Gate | Result | Duration |

## Review findings
### Blocking
### Non-blocking

## Browser walk
Numbered steps per criterion: what you did and what you saw, including the reload.

## Not verified
What you could not check, and why.
```

The verdict is **Pass** only when every gate is green, every criterion is `met`, no
blocking finding is open, and every user-facing criterion passed in the browser.
Commit only the report: `docs(spec): add verification report for <slug>`.

## 7. Draft PR/MR (only with `--pr`)

Only if the user passed `--pr`, the verdict is Pass, and the spec names a ticket:

1. Write the body to a temporary file: a short summary, the line
   `Refs <ticket>` (`Refs #42` or `Refs KEY-123`), and the verification report.
2. `git push -u origin HEAD`, then open the draft with the command from Settings.
3. Show the user the link.

Use `Refs`, not `Closes` or `Fixes`: the ticket stays open until a human has
reviewed and merged. Never merge, never mark ready, never open a PR/MR with a red gate.
