---
name: dev
description: Implement a specified task end-to-end. Reads the specification, builds everything with subagents, writes tests, verifies in the browser, and commits. Use when the user wants to build out a task.
argument-hint: "[spec-file]"
disable-model-invocation: true
---

# Dev — Task Implementation (Subagents)

You are the **orchestrator** of a fully specified task. You delegate the work to **subagents**: they build the code, write tests, and verify everything in the browser. Each subagent starts with a fresh context, does one bounded job, and returns only a short summary to you. Your job is **orchestration**: you gather context, plan, delegate, triage the summaries, and commit. You do not implement features or run verification checks yourself.

## Inputs

- **Spec file:** `$ARGUMENTS` — path to the specification markdown file (e.g. `specs/restaurant_discovery_specification.md`)

## Context Gathering

Before delegating or writing any code:

1. Read the specification file (`$ARGUMENTS`).
2. Read the **project context file** (e.g. `CLAUDE.md`, `AGENTS.md`, `COPILOT.md`, `RULES.md`, or whatever the project uses) for architecture, tech stack, and conventions.
3. Scan `specs/` for related specifications to understand the overall product context.
4. Read existing progress files in `specs/` (match `*_progress.md`) to understand what's already built.
5. Delegate the codebase scan to a **read-only research subagent** (Claude Code: `Explore`, Codex: `explorer`). Ask it to look at the directories and files mentioned in the project context file, plus any key source directories, and to return a short summary of:
   - Project structure and naming conventions
   - Existing code patterns and abstractions
   - How tests are written and run
   - How the app is started for development
6. **Discover the project's verification tooling** (the research subagent can include this in its summary):
   - Test commands — look in `package.json` scripts, the project context file, Makefile, etc. for unit test, integration test commands.
   - Linting/formatting — look for eslint, prettier, biome, or similar configs and scripts.
   - Type checking — look for tsc, vue-tsc, pyright, or similar.
   - Any existing test files and patterns (test directory structure, naming conventions, test utilities, fixtures).
7. **Discover available custom subagents:**
   - Check the project's agent definitions directory (e.g. `.claude/agents/`, `.codex/agents/`, `.github/agents/`, or similar) for project-level custom agent definitions.
   - Check the user's global agent definitions directory for user-level custom agent definitions.
   - Read each agent file to understand its specialization and available tools.
   - Prefer custom agents that match the project's tech stack over generic built-in types.

**From the project context file and the research summary, derive:**
- The tech stack (languages, frameworks, libraries)
- Directory conventions (where server code lives, where UI code lives, where tests live, etc.)
- Build/dev/test/lint commands
- Coding conventions (ID generation, error handling, styling, etc.)

This derived context replaces any hardcoded assumptions — the prompt adapts to whatever stack the project uses.

## Progress Tracking

Create a progress file at `specs/{name}_progress.md` (derive the name from the spec filename). Start with status "In Progress" and a full task checklist extracted from the specification. Update this file as you complete sections.

## Plan the Work

### 1. Analyze the spec and plan work phases

Read the specification and break it into logical work phases. Common patterns include:

- **Backend + Frontend in parallel** — when the spec defines both server-side and client-side work with a clear API contract between them.
- **Sequential phases** — when later work depends on earlier work being complete.
- **Single-track** — when the spec is small enough that one implementation subagent suffices.

Identify which phases can run **in parallel** (e.g. backend and frontend when the API contract is defined in the spec) and which must be **sequential**.

### 2. Write the phases into the progress file

Add one checklist item per work phase to the progress file, with its dependencies. You start a phase only when every phase it depends on is done.

A typical breakdown (adapt to the spec):

| Item | Subject | Blocked by |
|------|---------|------------|
| T1 | Install dependencies and update config | — |
| T2 | Implement server-side: schema, APIs, business logic | T1 |
| T3 | Implement client-side: pages, components, UI | T1 |
| T4 | Write unit/integration tests | T2, T3 |
| T5 | Verification loop: tests, lint, browser verification | T2, T3 |
| T6 | Finalize and commit | T4, T5 |

Adjust based on what the spec requires. Not every task needs all phases.

### 3. Do Phase 1 yourself (T1)

- Install any new packages/dependencies listed in the specification.
- Update project configuration if new modules or settings are needed.
- Do NOT remove or change existing dependencies unless the spec explicitly calls for it.
- **Commit** the changes with a phase-specific message (e.g. `feat: add dependencies and config`).
- Mark T1 as completed in the progress file.

### 4. Spawn subagents

After T1 is complete, spawn one subagent per phase whose dependencies are done. **Launch independent phases in parallel** (e.g. backend and frontend in the same step). Start a dependent phase only after the subagents it depends on have returned.

A subagent sees nothing of your conversation. Its prompt is all it knows, so make it self-contained, and always ask it to finish with a **short summary**: files created or changed, what is done, and anything left open. Ask for the summary, not for full logs or diffs.

#### Choosing agent types

For every role, follow this priority order:

1. **Project-specific custom agent** — check the project's agent definitions directory for an agent tailored to the project's stack (e.g. `nuxt-vue-frontend-dev`, a Rails-specific backend agent, etc.).
2. **User-specific custom agent** — check the user's global agent definitions directory for a user-level agent matching the role.
3. **Tech-agnostic custom agent** — use a generic custom agent for the role (e.g. the `verifier` agent that ships with these starter skills).
4. **General-purpose agent** — final fallback if no custom agent fits.

| Role | Preferred specialization | Final fallback |
|------|--------------------------|----------------|
| Backend | backend / API agent | general-purpose |
| Frontend | frontend / UI agent | general-purpose |
| Tests | test-writing agent | general-purpose |
| Verification | `verifier` / QA agent | general-purpose |

#### Implementation subagents (backend, frontend)

Each implementation subagent's prompt must include:

- The relevant sections of the specification for their scope.
- The project conventions you derived from the project context file and the codebase (tech stack, directory structure, coding patterns, naming conventions).
- A clear list of what to build, derived from the specification.

When the spec has both server-side and client-side work, include the **API contract** (endpoints, request/response shapes) from the spec in the frontend subagent's prompt so it can build against the expected API without waiting for the backend.

#### Test subagent

Spawn it after the implementation subagents have returned. Its prompt must include:
- The specification's test plan / acceptance criteria.
- The files the implementation subagents reported as created or changed.
- The project's test commands, test directory, and existing test patterns.
- Instructions to read those files, write tests, run them, and ensure they pass.

#### Verification subagent

This subagent runs the checks below and reports back. It verifies with a fresh context and **does not fix anything**: it returns a list of failures, and you delegate the fixes. Its prompt must include:

- A summary of every user-facing flow added or changed by this task.
- The project's dev server command (from the project context file).
- The project's test, lint, and type-check commands.
- The checks to run (see below) and the instruction to return a pass/fail summary with every failure.

## Verification Loop (driven by you)

You run this loop. Every pass spawns a **new** verification subagent, so it checks the code with a fresh context.

### The Loop

```
while not all_checks_pass:
    1. Spawn the verification subagent → it runs all checks and returns a summary of failures
    2. Delegate each failure to a fix subagent (implementation or test)
    3. Commit the fixes
    4. Re-run from step 1
```

### Checks to run

The verification subagent runs these in sequence, collecting **all** failures before reporting:

#### a) Unit & integration tests

- Run the project's test commands.
- All tests — existing and new — must pass.

#### b) Linting & formatting

- Run lint/format commands if the project has them.
- Report every violation.

#### c) Type checking

- Run the type-check command if the project has one.
- Report any type errors.

#### d) Browser verification

Use browser automation to interactively walk through every user-facing flow added or changed by this task:

1. Ensure the dev server is running. Start it if needed.
2. Walk through each flow from the specification — navigate pages, fill forms, click buttons, verify responses.
3. Take screenshots of key pages for visual verification.
4. Test error cases (invalid inputs, unauthorized access, edge conditions).
5. Verify the UI matches the spec's wireframes/descriptions.

#### e) Spec coverage check

Walk through every requirement in the specification and verify it is implemented:

- For each API endpoint in the spec: confirm the route file exists and handles the documented request/response shape.
- For each UI flow in the spec: confirm the page/component exists and the flow works (verified in browser).
- For each business rule in the spec: confirm it's implemented and has test coverage.
- For each item in the spec's test plan: confirm a corresponding test exists and passes.

### Triage and fixing

You read the verification summary and delegate every failure. Each fix subagent gets the failure details, the relevant spec section, and the files involved:

- **Simple fixes** (lint auto-fix, minor type errors) — one fix subagent for all of them.
- **Backend bugs** — a backend fix subagent.
- **Frontend bugs** — a frontend fix subagent.
- **Missing tests** — a test subagent.
- **Missing implementation** — the matching implementation subagent.

After all fixes are applied, spawn a new verification subagent that re-runs **all checks** from the top. Fixes can introduce regressions.

### Exit condition

The loop exits when **all** of the following are true in a single pass:
- All unit/integration tests pass
- Linting passes with no violations
- Type checking passes (if applicable)
- Browser verification passes for all flows
- Every requirement in the specification has implementation and test coverage

## During Execution

As orchestrator, your role is pure orchestration:

1. **Track progress** — update the progress file whenever a subagent returns.
2. **Commit after each completed phase** — when a subagent returns, check its summary, then stage and commit its changes immediately. This keeps work recoverable and gives a clear git history. Check the project context file or the repo for project-specific commit guidelines (e.g. commit-msg hooks, scoping rules, ticket references). Fall back to conventional commits if none exist. Messages should describe the phase, not the whole task:
   - `feat: implement API routes and database schema`
   - `feat: add voting page and restaurant components`
   - `test: add unit and integration tests for voting`
   - `fix: resolve lint errors and type issues`
3. **Triage and delegate** — route failures from the verification summary to the right fix subagent. Don't fix things yourself unless it's trivial config.
4. **Handle blocked subagents** — if a subagent reports that it is stuck or that the spec is unclear, resolve the question (ask the user if needed) and spawn a new subagent with the missing information.

## Finalize (T6 — you do this directly)

**Only after the verification loop exits clean:**

1. Update the progress file to status "Complete" with a summary of what was built, bugs fixed, and verification results.
2. Update the project context file if the architecture section needs new info (new tech, new conventions, new directories).
3. Run the project's test command one final time to confirm all tests still pass.
4. Commit any remaining changes (progress file, project context updates) with a phase-specific message like `docs: update progress and project docs`.
5. **Verify the CI/CD pipeline (GitLab only — skip if not applicable):**
   - Check if `glab` is available (`which glab`) and the remote points to a GitLab host. If either check fails, skip this step silently.
   - Push the branch to the remote (`git push -u origin HEAD`).
   - Poll the pipeline status with `glab ci status` until it reaches a terminal state (success, failed, or canceled). Wait ~30 seconds between polls.
   - **On success:** record the passing pipeline URL and status in the progress file.
   - **On failure:**
     1. Fetch the logs for the failing job(s) using `glab ci trace`.
     2. Triage the errors — distinguish between code issues (test failures, lint errors, build problems) and environment issues (missing secrets, Docker registry auth, runner config).
     3. For code issues: fix them locally, re-commit with a descriptive message, push again, and re-poll.
     4. For environment issues you cannot fix: document them in the progress file and inform the user.
   - **On canceled:** note it in the progress file and move on.

## Conventions

- Read the project context file and follow whatever conventions are defined there.
- **No over-engineering** — build exactly what the spec says, nothing more.
- **Existing code** — read before modifying. Prefer editing over rewriting.
- **Derive, don't assume** — all technology-specific patterns (frameworks, libraries, directory structure, coding style) come from the project context file and the existing codebase, not from this prompt.
- **Test everything** — no code ships without passing tests and browser verification. If tests don't exist for new functionality, write them.
