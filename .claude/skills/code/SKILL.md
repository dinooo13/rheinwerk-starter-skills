---
name: code
description: Implement an approved specification from specs/ task by task, test first, with small Conventional Commits. Lint, typecheck and tests must be green at the end.
argument-hint: "[specs/<slug>.md]"
disable-model-invocation: true
---

# Code

Implement the approved spec: **$ARGUMENTS**
(In Codex, or if this line shows `$ARGUMENTS` literally, use the path the user gave.)

## Settings

A value that still contains `<ANPASSEN` is not filled in. Take it from `AGENTS.md`,
or ask the user once.

- **Base branch and branch scheme:** <ANPASSEN: Branch-Schema, z. B. Basis `main`, Feature-Branch `feat/<ticket>-<slug>`; bei Jira den Key in den Namen: `feat/KEY-123-<slug>`>
- **Fast gates:** <ANPASSEN: Gate-Befehle (lint, typecheck, test), z. B. `npm run lint`, `npm run typecheck`, `npm test`>
- **E2E gate:** <ANPASSEN: e2e-Befehl mit festem Port, z. B. `PORT=3110 npm run test:e2e`>
- **Test folders:** <ANPASSEN: wo Unit- und e2e-Tests liegen, z. B. `tests/` und `e2e/`>

## 1. Load the spec

- With no argument, list `specs/*.md` and ask which spec to implement.
- Read the whole spec. It is the source of truth for scope: build what it asks
  for, no more and no less.
- Check the approval. If the header still says `Status: draft` and the user did
  not approve it in this conversation, ask before you write code.
- Read `AGENTS.md`, the files listed under Research and the ADRs the spec names.
  If the spec asks for a new ADR, write it as one of the tasks: next free number
  in the ADR folder, and add it to the index.

## 2. Prepare the branch

- Never work on the base branch. Create a feature branch with the branch scheme.
- Start from a clean working tree. Run the unit tests once so you know the
  baseline is green before you change anything.

## 3. Work the tasks in a TDD cycle

For each task in the spec, in order:

1. **Red.** Write or extend a test that describes the task's behavior and run it.
   It must fail for the right reason. **Hard rule: no production code for a task
   before you have seen its test fail.** Show the command and the failing
   assertion in your reply before you implement. If a task has no testable
   behavior (an ADR, docs, config), say so explicitly: `No test: <reason>`.
2. **Green.** Write the smallest change that makes the test pass. Follow the
   patterns and hard rules in `AGENTS.md`.
3. **Refactor.** Clean up while the tests stay green.
4. **Commit.** One small Conventional Commit per task, e.g.
   `feat(orders): add status filter`, `test(e2e): cover filter after reload`.
   The message says what and why. Add a body line `Red: <test name>` for the
   test you saw fail first (or `Red: none - <reason>`). Never commit a red state.

Tick the task in the spec as you go (`- [x]`) so a new session can resume.

If a task turns out wrong or impossible, stop and tell the user. Do not change the
scope on your own. Small details the spec left open are fine to decide; note them
in the report.

## 4. Gates

When all tasks are done, run the fast gates and make them green. Run the e2e gate
as well when you touched UI or flows. Fix failures at the cause. Never weaken,
skip or delete a test to get green.

## 5. Report

Tell the user the branch, the commits, the tasks done, the decisions you made, the
gate results, and anything open or risky. Then suggest `/verify specs/<slug>.md`.
Do not push, open a PR/MR or merge; that happens after verification.
