---
name: verify
description: Verify an implementation against its spec. Checks every acceptance criterion, runs the gates, gets a review from a fresh reviewer subagent, walks the criteria in a real browser and writes a verification report. With --pr it opens a draft PR/MR that refers to the ticket, waits for the pipeline, updates the ticket and repeats the browser walk on the dev URL.
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
  - GitLab: `glab mr create --draft -b main -t "<title>" --description-file <body> -y`
  - Jira: the ticket lives in Jira, the review in GitHub or GitLab. Use the `gh`
    or `glab` line and put the Jira key in the title and the branch name, so
    Jira links the PR.
- **Reference line:** <ANPASSEN: Verweis, z. B. GitHub `Refs #42`, GitLab `Relates to #42`, Jira `Relates to KEY-123`>
- **Wait for the pipeline:** <ANPASSEN: CI-Befehl, z. B. `gh pr checks --watch --fail-fast`>
  - GitLab: `glab ci status --wait`
- **Update the ticket:** <ANPASSEN: Ticket-Update nach grüner Pipeline und Dev-Check, leer = nichts tun, z. B. `gh issue comment <n> --body "<text>"`>
  - GitLab: `glab issue note <n> -m "<text>"`
  - Jira: `acli jira workitem transition --key <KEY> --status "<ANPASSEN: Status, z. B. In Review>" --yes`,
    then `acli jira workitem comment create --key <KEY> --body "<text>"`
- **Dev URL after deploy:** <ANPASSEN: Dev- oder Review-App-URL nach dem Auto-Deploy, leer = nur lokal>

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

1. Write the body to a temporary file: a short summary, the reference line from
   Settings, and the verification report.
2. `git push -u origin HEAD`, then open the draft with the command from Settings.
3. Wait for the pipeline with the command from Settings and read the final status.
   Red is a blocking finding: add the failing job and its log lines to the report,
   leave the ticket as it is and stop. The fix goes back to `/code`.
4. If a Dev URL is set, wait until the auto-deploy answers (`curl -sf <dev-url>`)
   and repeat the browser walk from step 5 against it instead of localhost. If the
   e2e config reads a base URL (e.g. `E2E_BASE_URL`), run the e2e gate against it
   too. Without a Dev URL the local walk stands; say so under "Not verified".
   A failure here is blocking, as in step 3.
5. Add the pipeline result and the Dev walk to the report, commit and push it:
   `docs(spec): update verification report for <slug>`.
6. Only when steps 3 and 4 are green: update the ticket with the command from
   Settings, with the PR/MR link and "Verification: Pass, see
   `specs/<slug>.verification.md`".
7. Show the user the link.

Refer, do not close: no `Closes` or `Fixes`. The ticket stays open until a human
has reviewed and merged. Never merge, never mark ready, never open a PR/MR with a
red gate.
