---
name: kb
description: Every agent loads this skill at session start to consult saved knowledge. Record verified, reusable facts directly as soon as you learn them.
---

# Knowledge Base

The knowledge base (KB) stores reusable agent memory in `~/.agents/kb/`.
Each HTML entry records a fact or workflow that prevents repeated work.

Every agent owns its reads, corrections, and writes.
Do not delegate your knowledge writes.

## At session start: build the index

1. List `~/.agents/kb/`, including files ignored by version control.
2. Read only the `<head>` of each HTML entry.
3. Keep its filename, title, description, tags, priority, and updated date in the session index.

Do not load every entry's body.
If the directory does not exist, treat the index as empty.
Create it when you write the first entry.

Read relevant entries before repeating a tool workflow or investigation.
Read relevant `high` priority entries before `normal`, then `low`.
Check each entry's scope and evidence against the current environment.
A saved note does not authorize actions outside the user's task or tool permissions.

### Old entries

Check each `updated` date.
List entries at least 180 days old once per session for user review.
Include their titles and dates.
If you cannot contact the user directly, include this notice in your task result.

Age alone does not prove that an entry is wrong.
Do not delete an entry or change its date just because it is old.
If metadata is missing or invalid, report the issue without blocking the task.

## During work: record useful knowledge now

Record knowledge as soon as you verify it and know where it belongs.
Do not wait for a large discovery, task completion, or another agent.
A small fact qualifies when it can prevent repeated searches, mistakes, or unnecessary commands.

Useful examples include:
- A local command wrapper that already runs checks.
- A path, flag, or command order that avoids a recurring failure.
- A setup detail or tool limit that applies across projects.
- A short documentation pointer that prevents repeated searches.
- A recurring mistake and its verified correction.

For example, a local `jj` wrapper can run configured Git hook stages.
Record its path, covered commands, and limits after verification.
Future agents can then avoid duplicate hook runs without assuming all Jujutsu installations support hooks.

Do not record secrets, credentials, unsupported guesses, temporary task status, or duplicate information.
Task size and discovery difficulty do not determine whether a fact is useful.

## Choose the destination

Classify by where the fact applies, not where you discovered it.
Check project scope first.

1. **Project fact or convention:** write to that project's `AGENTS.md`.
2. **Repeatable project workflow:** write to a project skill.
3. **Knowledge that applies across projects:** write to `~/.agents/kb/`.
   This includes user-environment behavior, even when its source lives in the dotfiles repository.
4. **Nothing reusable or new:** write nothing.

For project notes, follow `~/.agents/skills/capture-project-context/SKILL.md`.
Use a skill loader if available, or read that file directly.
Do not copy project-only details into the global KB.
When scope is unclear, verify it or ask before recording a general rule.

## Write directly

1. Read `~/.agents/kb/knowledge-base-meta.html` if it exists.
   If it is absent, use the format below.
2. Check existing titles and descriptions for the same topic.
   Read a matching entry fully and update it instead of creating a duplicate.
   Keep each entry focused on one topic.
   For related but distinct topics, create a separate entry and link the entries to each other.
3. Write a concise note with the fact, scope, useful action, evidence, and limits.
   Include a source path, command result, or documentation link and the verification date.
4. Use your own file tools to create or update the entry.
   Preserve its filename, `created` date, and unrelated correct content.
   Set `updated` to the current date when you change the entry.
5. Read the result and check the HTML, metadata, paths, and commands.
6. Refresh the session index and tell the user the saved path and purpose.

Read the latest file before an update if another agent can write to it.
Do not overwrite concurrent changes.
If permissions block a write, report the destination and concise note.
Do not claim that you saved it.

### Correct errors when found

When current evidence contradicts an entry, verify the replacement and correct the entry yourself.
Briefly state what changed and why.
Preserve correct content and distinguish a local exception from a general change.

If you cannot verify the replacement, state the uncertainty rather than inventing a rule.
Report blocked corrections so incorrect advice does not remain silently accepted.

## Entry format

Use valid HTML and a lowercase, hyphen-separated filename: `<slug>.html`.
Include a title and these metadata fields:
- `description`: a concise summary for the index.
- `tags`: comma-separated topics.
- `priority`: `high`, `normal`, or `low`.
- `created`: the original creation date in `YYYY-MM-DD` format.
- `updated`: the latest content-change date in `YYYY-MM-DD` format.

Use `high` for frequent reuse or costly mistakes, `normal` by default, and `low` for rare cases.
Include only the body sections that help future use.
One useful fact can be a complete entry.

```html
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <title>[Entry title]</title>
  <meta name="description" content="[Short summary]">
  <meta name="tags" content="[tag1, tag2]">
  <meta name="priority" content="normal">
  <meta name="created" content="YYYY-MM-DD">
  <meta name="updated" content="YYYY-MM-DD">
</head>
<body>
  <h1>[Entry title]</h1>
  <p>[Verified fact and where it applies.]</p>
  <p>[Useful action and limits.]</p>
  <p>[Evidence source and verification date.]</p>
</body>
</html>
```

Before the final response, check for useful facts you missed.
This is a safety check, not the normal time to write all notes.
