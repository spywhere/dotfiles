---
name: capture-project-context
description: Record verified project facts and workflows directly when they can help future work. Small, repeatedly useful details qualify.
---

# Capture Project Context

## Purpose

Save project knowledge that can help a future agent avoid repeated work.
Write it yourself as soon as you verify it.
Do not wait for task completion or delegate the write.

A small fact can qualify, even during a one-line fix or a short investigation.
Record reusable knowledge, not a transcript of the task.

## When to record

Consider a note when you learn:
- A project-specific build, test, lint, or run command.
- A convention or constraint absent from current instructions.
- A setup detail, dependency, or command order that prevents a recurring failure.
- An architecture decision that affects future changes.
- A repeatable workflow for this project.

Ask whether a future agent can use the note to avoid a search, mistake, or unnecessary command.
If the answer is yes, task size does not matter.

Do not record duplicate facts, unsupported guesses, secrets, or temporary task status.
If the knowledge applies across projects, follow `~/.agents/skills/kb/SKILL.md` and write to the global KB directly.

## Choose the destination

### Project `AGENTS.md`

Use the project's instructions for broadly useful facts:
- Project structure and architecture.
- Exact build, test, lint, and run commands.
- Coding conventions and interface constraints.
- Setup details and tool limits.

### Project skill

Use a skill for a focused workflow with repeatable steps.
Follow the project's existing skill layout.
Otherwise, use `<project_root>/.agents/skills/<slug>/SKILL.md`.

Keep facts in `AGENTS.md` and detailed workflows in skills.
Link to existing guidance instead of duplicating it.

## Direct-write process

1. Confirm the absolute project root and the fact's scope.
2. Read the existing `AGENTS.md` and relevant project skills.
3. Choose the existing section or skill that best matches the topic.
   Create a section or file only when needed.
4. Use your own file tools to merge the note into that destination.
   Preserve unrelated instructions and correct content.
   Remove duplicate guidance that your edit introduces.
5. Include exact commands, paths, conditions, and evidence when they help future use.
   Explain the reason when it prevents a mistake.
6. Read the result and check its accuracy, scope, and brevity.
7. Tell the user what you saved and where.

Read the latest content before an update if another agent can write to the same file.
Do not overwrite concurrent changes.
Respect read-only task limits and tool permissions.
If permissions block a write, report the destination and note instead of claiming success.

## New skill format

```markdown
---
name: <slug>
description: <When to use this workflow.>
---

# [Workflow title]

## When to use

[Conditions and scope.]

## Steps

1. [Action with exact commands or paths.]
2. [Next action and verification.]

## Notes

[Limits, evidence, and recurring mistakes.]
```

Before the final response, check for missed project knowledge.
Do not use this final check to delay notes that were useful earlier.
