---
name: spec
description: Brainstorm and specify a task through iterative Q&A. Use when the user wants to refine a task, feature idea, or work item into a full specification.
argument: <task-description-or-file>
---

# Spec — Task Brainstorming & Specification

You are running an interactive brainstorming session to turn a task into a detailed specification.

## Inputs

- **Task:** `$ARGUMENTS` — a short task description, a feature idea, a ticket/issue number, or a filename from `specs/`.

## Setup

1. Read the **project context file** (e.g. `CLAUDE.md`, `AGENTS.md`, `COPILOT.md`, `RULES.md`, or whatever the project uses) for architecture, tech stack, and conventions. This tells you what technology decisions are already made and what patterns to follow.
2. Identify the task: if `$ARGUMENTS` points to a file or an existing item in `specs/`, read it. Otherwise treat `$ARGUMENTS` as a free-form task description and work from that.
3. Derive a short snake_case name from the task title (e.g. "First Vote" → `first_vote`).
4. Create the brainstorming file: `specs/{name}_brainstorming.md`
5. The final specification will go in: `specs/{name}_specification.md`

## Brainstorming Rules

**Questions are asked interactively, then persisted to the brainstorming file.** Only append to the brainstorming file — never overwrite or rewrite earlier rounds.

### Question Design

Design multiple questions per round (3–7 questions). For each question:

- Prepare 2–4 options.
- Mark the recommended option by placing it first and adding "(Recommended)" to its label.
- Include a short rationale for each option in a description.
- When ASCII diagrams, wireframes, or flow charts help clarify a question, include them as a preview alongside the option.

**Technology awareness:** Your recommendations should be informed by what the project context file says about the project's stack. Don't propose technologies or patterns that conflict with established conventions. When the project already has a clear pattern for something (e.g. auth, database, UI framework), treat that as decided and focus questions on the task-specific decisions instead.

### Iteration Loop

1. **Ask the user** with up to 4 questions at a time. If the round has more than 4 questions, split into multiple interactive prompts within the same round.
2. **Persist the round** — after receiving all answers, append the full round to the brainstorming file:
   - Write each question with all options as `[ ]`/`[x]` checkboxes (mark the user's chosen option with `[x]`).
   - Include any ASCII diagrams or wireframes inline — these are part of the permanent record.
   - Append a summary table of the round's answers.
3. **Repeat** — design the next round based on the decisions so far, and go back to step 1.
4. Continue until all major decisions are covered.

### File Format

Each round has a heading, numbered questions with checkbox options, and an answers summary table. Choices are filled in programmatically from user responses.

Example of what gets appended after a round:

```markdown
## Round 1: Topic Area

### Q1. Question Title

Context or framing sentence.

- [x] **Option A** — Recommended. Rationale here.
- [ ] **Option B** — Rationale here.
- [ ] **Option C** — Rationale here.

### Round 1 — Answers

| Q | Choice |
|---|--------|
| Q1 | Option A |
```

### Topics to Cover

Derive relevant topics from the task's scope and the project's tech stack (from the project context file). Common areas to consider — skip any that don't apply to this task:

- **Data model** — new entities, relationships, schema changes
- **Auth & permissions** — who can do what
- **UI/UX** — layout, navigation flow, wireframes (ASCII), component choices
- **API design** — endpoints, request/response shapes, protocols
- **Business logic** — rules, edge cases, state machines, error handling
- **Integration points** — external services, APIs, data sources
- **Realtime / async** — if applicable
- **Architecture** — any decisions not already settled by the project's existing stack

Don't ask about topics that are already decided by the project's conventions (e.g. don't ask "which database?" if the project context file already specifies one).

### Respect Prior Decisions

Read any existing specification files in `specs/` to understand decisions already made in earlier tasks. Don't re-ask questions that were already settled.

## Writing the Specification

After the final brainstorming round:

1. Append a "Brainstorming Complete" note to the brainstorming file.
2. Write the full specification to `specs/{name}_specification.md`.

### Specification Structure

```markdown
# {Title} — Specification

> One-line summary.

---

## 1. Overview
Summary table of all key decisions.

## 2–N. Feature Sections
Detailed description of each feature area, including:
- Requirements and behavior
- ASCII wireframes where useful
- API routes (method, path, auth, description)
- Data schema additions or changes (with table definitions)
- State machines or flow diagrams if applicable

## N+1. Dependencies
New packages or services needed.

## N+2. Test Plan
Table of numbered test cases:
| # | Test Case | Type | Steps | Expected |

## N+3. Out of Scope
What is explicitly deferred.
```
