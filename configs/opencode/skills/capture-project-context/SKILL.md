---
name: capture-project-context
description: Use after completing non-trivial work in a project to assess whether anything learned should be persisted as project-level context. Captures project-specific conventions, workflows, architecture patterns, and tooling quirks to AGENTS.md or project skills — so future sessions don't rediscover them.
---

# Capture Project Context

## Purpose

After completing a non-trivial task, reflect on what was learned or discovered
during the work. If any of it is specific to this project and would be useful
to a future agent session working here, persist it.

This is not about documenting what you just did. It is about extracting durable
knowledge — things that will still be true and still be useful the next time
someone works in this project.

## When to apply this skill

Apply this at natural completion points:
- After finishing a feature, bug fix, or refactor
- After resolving a non-trivial investigation (build failure, test issue, etc.)
- After setting up or configuring something in the project
- After learning something surprising or non-obvious about the project

Do not apply it for:
- Trivial one-line fixes
- Changes to content (copy, data) with no structural implication
- Work where nothing was learned about the project itself

## Reflection questions

Ask yourself:
1. Did I discover how this project is structured in a way that is not obvious from filenames?
2. Did I learn a command, script, or process specific to this project?
3. Did I encounter a convention, pattern, or constraint that is not in the existing AGENTS.md?
4. Did I hit a non-obvious gotcha — a dependency, a quirk, an ordering requirement?
5. If a fresh agent started this project tomorrow, what would they waste time figuring out?

If any answer is yes, that knowledge is worth capturing.

## What goes where

### Project `AGENTS.md` (at project root)
Durable, broadly applicable project knowledge:
- Project structure and architecture that is not obvious from filenames
- Build, test, lint, and run commands
- Coding conventions and patterns specific to this codebase
- Key constraints or requirements
- Non-obvious setup steps

### `.agents/skills/<slug>/SKILL.md` (project-local skill)
Workflow-specific knowledge that is reusable but focused:
- A specific deployment or release process
- A debugging or investigation workflow for a known class of problems
- Integration patterns with a specific service or API this project uses
- Anything that warrants step-by-step guidance for a specific recurring task

Use a skill when the knowledge is a workflow with steps. Use AGENTS.md when it
is context, convention, or a fact.

## What does NOT belong here

- Knowledge that applies globally across all projects → goes to the KB instead
  (invoke the `kb-writer` sub-agent via the `kb` skill)
- Knowledge that is already in the existing AGENTS.md or an existing skill
- Ephemeral state: current ticket status, who is working on what, etc.

## How to act

1. Announce to the user what you intend to capture and why:
   > "I'm capturing [what] to [AGENTS.md / a new skill: slug] — [one sentence why]"

2. Invoke the `context-capture` sub-agent with:
   - **target**: `agents_md` or `skill`
   - **content**: the knowledge to record
   - **skill_name** (if target is `skill`): a short slug for the skill name
   - **skill_description** (if target is `skill`): one sentence describing the skill
   - **project_root**: the absolute path to the project root

3. The sub-agent handles reading existing content, merging cleanly, and writing.
   You do not write these files directly.

## Tone and style for captured content

- Write for a future agent, not a human reader
- Be precise: exact commands, paths, flags, filenames
- Be concise: no padding, no obvious things, no repetition
- Include the "why" where it prevents mistakes, not just the "what"
