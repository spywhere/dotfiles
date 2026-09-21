# Global Agent Rules

## Agent ownership

Each agent owns its task from understanding through verification and documentation.
These rules apply across agent harnesses.
The workflow does not depend on subagents, named roles, or delegation tools.

Treat development aspects as responsibilities, not a mandatory sequence of agent handoffs.
Apply each relevant aspect within the task scope and available permissions.
Optional specialist profiles do not replace these responsibilities.

## Knowledge Base

At session start, load the `kb` skill.
If no skill loader exists, read `~/.agents/skills/kb/SKILL.md` directly.
Build the metadata index for `~/.agents/kb/` and read relevant entries before repeating work.

Record useful knowledge as soon as you verify it.
Small facts count when they prevent repeated work, such as a local `jj` wrapper that runs Git hooks.
Do not wait for task completion, a large discovery, or a handoff.
Write your own findings directly instead of delegating the write.

Choose the destination by where the knowledge applies:
1. Project facts and conventions belong in that project's `AGENTS.md`.
   Repeatable project workflows belong in project skills.
   Follow `~/.agents/skills/capture-project-context/SKILL.md`.
2. Knowledge that applies across projects, including local tool behavior, belongs in `~/.agents/kb/`.
3. Do not record temporary state, unsupported guesses, secrets, or duplicate notes.

Read the destination first and update an existing note when it covers the same topic.
Keep each KB entry focused on one topic and link related entries.
Keep the note concise, with its scope, useful action, evidence, and limits.
Correct verified errors directly and refresh the session index after KB changes.
Before the final response, check for missed knowledge.
This final check does not replace recording during work.

## Working style

State your understanding and intended approach before changes.
Ask for confirmation when scope, risk, or a design decision needs agreement.
Use the user's stated goal, and ask when missing information affects correctness or safety.

Challenge weak assumptions and explain simpler alternatives.
When valid approaches differ in behavior, cost, or risk, compare them briefly before choosing one.
Explain key decisions, risks, and tradeoffs.
Share concise progress and evidence.
State uncertainty instead of guessing.

Prefer the smallest complete solution.
Preserve unrelated user changes.
Do not add features or cleanup outside the agreed scope.

## Development aspects

### Understanding

Read relevant instructions, code, configuration, and KB entries yourself.
Define the expected behavior, scope, and testable acceptance criteria.
Identify missing information, dependencies, and failure cases before implementation.

### Design

Prefer existing architecture, interfaces, components, and conventions.
Consider compatibility, data changes, security, and operational risks.
Ask before large refactors, breaking changes, or public interface changes outside the agreed scope.
Ask before architecture decisions that the agreed requirements do not cover.

For UI work, use the existing design system.
Define new and changed components, their hierarchy, and each input's name, type, and purpose.
Specify user actions, system responses, state changes, and interaction edge cases.
Include loading, empty, and error states.

Use design tokens for spacing, sizing, and alignment when available.
Describe responsive behavior and existing visual constraints.
Check tab order, keyboard shortcuts, focus management, labels, ARIA roles, live regions, contrast, and visual indicators.
Do not add UI design work to tasks without a UI change.

### Implementation

Make small, focused changes that satisfy the acceptance criteria.
Handle errors, resource cleanup, and relevant edge cases.
Inspect local command wrappers and recorded workflows before duplicating their checks.
Do not bypass hooks or safety checks to make a command succeed.
When commits are in scope, follow repository conventions and keep each commit focused.

### Review

Review every change, including documentation, before completion.
Check these dimensions:
- **Correctness:** Compare behavior with acceptance criteria, including boundaries, conditionals, and silent failures.
- **Security:** Check injection risks, input validation, access control, secrets, and sensitive data.
- **Errors:** Check recovery, failure handling levels, and cleanup of files, connections, and locks.
- **Edge cases:** Check empty or null inputs, zero and maximum values, slow dependencies, unavailable services, and concurrency.
- **Maintainability:** Check consistency, readability, unnecessary abstractions, dead code, and leftover debug output.
- **Tests:** Confirm that tests cover the requested behavior and important failure cases.

Error messages must explain failures without exposing secrets or sensitive internals.
For each finding, record its severity, affected location, impact, and proposed correction.

Stop and inform the user about critical risks, such as data loss or a security flaw.
Fix major findings before completion, or report them as blockers.
Report minor findings without unrelated cleanup.
Review fixes again, focusing on the changed code and affected behavior.
Distinguish your own review from an independent review.

Limit a major-finding correction cycle to three review rounds, including the first review.
Keep the count when another agent continues the same review.
If major findings remain after the third round, stop and report them to the user.
Include the unresolved findings and corrections already tried.

### Validation

Run the relevant project checks and tests.
Add focused regression tests when changed behavior lacks coverage.
Check the acceptance criteria against test results, inspection, or explicit manual checks.
Report the commands, results, and any checks you could not run.
Separate existing failures from failures caused by your changes.
Do not claim success without evidence.

### Documentation and memory

Update documentation when behavior, interfaces, setup, or workflows change.
Use comments to explain non-obvious reasons, not to repeat the code.
Record verified, reusable knowledge during the task through the direct-write rules above.
Avoid duplicate documentation and task transcripts.

## Completion

Summarize changed behavior, affected paths, validation results, and remaining issues.
Mention any project context or KB notes you wrote.
Report blocked writes or checks clearly.
