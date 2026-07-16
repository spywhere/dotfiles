---
name: kb
description: Load this skill at the start of every session to access your long-term knowledge base — a persistent memory of workflows, tools, environment details, and patterns discovered in past sessions. Use it to look up what you have done before rather than rediscovering it. Use it to record new knowledge for future sessions.
---

# Knowledge Base

## What this is

The knowledge base (KB) is your long-term memory. It is a collection of HTML
files at `~/.config/opencode/kb/`. Each file records something learned in a
past session — a workflow, a tool behavior, an environment detail, a pattern,
a process — that would otherwise be rediscovered from scratch.

This is not documentation for the user. It is memory for you.

## On load: build your index and surface stale entries

When you load this skill, do two things:

**1. Read the KB directory listing and build your mental index:**

```
~/.config/opencode/kb/
```

For each `.html` file found, extract from its `<head>`:
- `<title>` — the entry name
- `<meta name="description">` — a one-line summary
- `<meta name="tags">` — comma-separated topics
- `<meta name="priority">` — `high`, `normal`, or `low`
- `<meta name="updated">` — last updated date

Hold this index in mind for the session. Do not load the full HTML content of
every file — only fetch specific entries when you actually need them.

**2. Surface stale entries:**

Check the `updated` date of each entry. If any entry has not been updated in
180 days or more, briefly inform the user:

> "N KB entries haven't been updated in 6+ months: [title1], [title2], ...
> Worth reviewing when you get a chance."

State this once, do not repeat it. Do not delete or alter these entries.
The user decides what to do with them.

## During work: consult before rediscovering

Before attempting something you might have done before — using a tool, running
a workflow, looking something up, interacting with a service — pause and check
the index. If a relevant entry exists, read that file first and follow the
recorded process.

When multiple entries are relevant, fetch `high` priority entries before
`normal`, and `normal` before `low`.

## Reactive cleanup: update when something is wrong

When you use a KB entry during work and observe that the recorded behavior
does not match reality — a command fails, a path is wrong, a process has
changed — do the following immediately:

1. Announce: "The KB entry '[title]' appears to be outdated. Updating it."
2. Invoke the `kb-writer` sub-agent to update the entry with the correct
   information, noting what changed and why.

Do not silently leave incorrect entries in place.

## When you learn something new: record it

When you discover something non-trivial that would be useful to remember in
future sessions, do the following:

1. Announce to the user: "I'm adding this to the knowledge base: [title]"
2. Invoke the `kb-writer` sub-agent with:
   - The title and a one-line description
   - Relevant tags (comma-separated)
   - The priority: `high` (frequently needed or critical), `normal` (default),
     or `low` (edge case or rarely needed)
   - The full content to record (steps, commands, examples, context)
   - Whether this is a new entry or an update to an existing one (include the
     existing filename if updating)

Do not write KB files directly. Always delegate to `kb-writer`.

## What qualifies as knowledge worth recording

- How to use a tool, CLI, or service that required figuring out
- Workflow steps that are non-obvious or require specific ordering
- Environment-specific details (paths, credential patterns, tool versions)
- Patterns that recurred across projects
- Mistakes made and how they were resolved
- Anything where "I wish I'd known this before" applies

## What does not qualify

- Things trivially findable in public docs with a single search
- Project-specific knowledge (those go to the project's AGENTS.md or skills)
- One-off fixes that won't recur
- Obvious conventions

## KB entry format

Each entry is a valid HTML file. Filename: `<slug>.html` where the slug is
lowercase, hyphen-separated. Examples: `gitlab-mr-diff.html`, `jira-ticket-lookup.html`.

```html
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <title>[Concise title]</title>
  <meta name="description" content="[One-line summary]">
  <meta name="tags" content="[tag1, tag2, tag3]">
  <meta name="priority" content="[high|normal|low]">
  <meta name="created" content="YYYY-MM-DD">
  <meta name="updated" content="YYYY-MM-DD">
</head>
<body>
  <h1>[Title]</h1>
  <p>[Context: why this matters, when to use it]</p>

  <h2>Steps</h2>
  <ol>
    <li>...</li>
  </ol>

  <h2>Examples</h2>
  <pre><code>[commands or code]</code></pre>

  <h2>Notes</h2>
  <ul>
    <li>[Caveats, gotchas, environment-specific details]</li>
  </ul>
</body>
</html>
```

Sections are optional — include what is relevant. Keep entries factual and
concise. These are reference notes, not tutorials.
