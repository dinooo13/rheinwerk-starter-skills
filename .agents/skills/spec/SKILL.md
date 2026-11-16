---
name: spec
description: Turn a task or a ticket into a reviewed specification in specs/<slug>.md. Reads AGENTS.md and the ADRs, researches the code with a read-only subagent, asks the human about open points, then stops for approval. Use when the user wants to plan or specify a feature before coding.
argument-hint: "[ticket | task description]"
---

# Spec

Write a build-ready specification for: **$ARGUMENTS**
(In Codex, or if this line shows `$ARGUMENTS` literally, use the text the user gave.)

You plan, you do not build. Write no code, and change no file except the spec.

## Settings

A value that still contains `<ANPASSEN` is not filled in. Take it from `AGENTS.md`,
or ask the user once.

- **Read a ticket:** <ANPASSEN: Ticket-System, z. B. `gh issue view <n> --json number,title,body,comments`>
  - GitLab: `glab issue view <n> --comments`
  - Jira: `acli jira workitem view <KEY-123> --fields summary,description,comment`
- **Gates:** <ANPASSEN: Gate-Befehle (lint, typecheck, test, e2e), z. B. `npm run lint`, `npm run typecheck`, `npm test`, `npm run test:e2e`>
- **Dev URL:** <ANPASSEN: Port und Dev-URL, z. B. `http://localhost:3110`, plus Test-Login falls nötig>
- **Approval:** <ANPASSEN: Freigabe-Modus, Standard: Kopfzeile in der Spec + Commit `docs(spec): approve <slug>`>

## 1. Read the task

- If the argument is a ticket (`42`, `#42`, `KEY-123`), read it with the ticket command
  above: title, body and all comments. Its acceptance criteria are the starting
  point, not the limit.
- Otherwise the argument is the task itself. With no argument, ask and stop.

## 2. Research

Ground every statement in real code. Name real paths, types and functions.

- Read `AGENTS.md` first: gates, architecture map, hard rules.
- Read the ADR index (folder named in `AGENTS.md`, usually `docs/adr/`) and every
  accepted ADR the task touches. Accepted ADRs are settled. If the task needs a
  structural change (data schema, persistence, a core dependency, a cross-cutting
  pattern), the spec must call for a **new ADR**, not quietly contradict an old one.
- Delegate the code search to a read-only subagent (Claude Code: **Explore**,
  Codex: **explorer**) so your context stays on the spec. Ask for a compact map, at
  most about 40 lines, of every affected file as `path:line – why`, guided by the
  architecture map, plus the existing tests. Ask it to check the side effects that
  are easy to miss: schemas and migrations, import/export, caches, seed data.
- Open the files the map names before you rely on them. The subagent can be wrong.

## 3. Clarify with the human

Collect the open questions that change scope, data or UX. Ask them in one round,
3 to 7 questions (AskUserQuestion when available), each with 2 to 4 options, a
one-line trade-off, and your recommendation first. Do not ask what the code or an
ADR already answers. Record every decision for the spec.

## 4. Write the spec

Pick a short kebab-case slug and write `specs/<slug>.md` with exactly these sections:

```markdown
# <Title>

Ticket: <#n | KEY-123 | none>  ·  Status: draft  ·  Approved-by: –

## Context
Why we build this and for whom, in 2 to 4 sentences.

## Research
| File | Why it matters |
Relevant ADRs and what they constrain. Decisions from the clarification round.

## Requirements
### Must
### Should
### Won't (this time)

## Non-goals

## Tasks
1. Small, ordered, each testable on its own (test first, then code). Name the files.

## Acceptance criteria
- [ ] AC1: observable behavior a user or a test can check.

## Verification plan
| AC | How we prove it | Type (unit / e2e / browser) |
Gates: the gate commands from Settings.
Browser walk: the exact steps for each user-facing AC, including a reload.
```

- Every acceptance criterion is testable and appears in the verification plan.
- Cover the hard states: empty lists, errors, reload, old data, mobile width.
- Data changes say how old data migrates.
- Keep it short. A reviewer reads it in five minutes.

## 5. Stop for approval

Show the spec path, a five-line summary and your decisions. Then **stop**.
Implementation starts only after a human approves, with `/code specs/<slug>.md`.

Only a human approves. With the default approval mode, set the header to
`Status: approved  ·  Approved-by: <name>, <YYYY-MM-DD>` and commit only the spec:
`docs(spec): approve <slug>`. Never set `approved` on your own.
