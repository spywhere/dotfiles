---
name: recreate-branch
description: Rebuild a branch's intended final changes as reviewed, cohesive commits in an isolated worktree without replaying its history.
---

# Recreate Branch

Use this skill when a branch's final result is wanted but its commit history is
not. Recreate only the approved net changes; do not rewrite the source branch.

## 1. Inspect before planning

Before making any change, inspect and report:

- the source branch, source commit, and working-tree status;
- staged and unstaged diffs, including untracked files;
- relevant history, merge bases, and reverted or superseded work; and
- repository conventions for commit messages, authorship, and checks.

Define and get confirmation for all of the following:

- **source** — the read-only branch, worktree, and commit to inspect;
- **authoritative final state** — the exact final files/content/modes to keep;
- **base ref** — an explicit destination starting point, often the merge-base
  with the target branch; never silently use source `HEAD` as the base;
- **destination branch** and **isolated destination worktree path**; and
- **scope** — included paths and explicit exclusions.

Exclude ignored files by default. Include untracked, generated, binary,
submodule, symlink, or file-mode changes only with explicit opt-in. Do not make
unrelated changes.

## 2. Create the destination safely

Only after the definition above is confirmed, create an isolated worktree for
the destination branch at the confirmed base ref. Leave the source read-only:
do not modify it, stage there, or create commits there.

Record the source status and commit before work. Recheck them before each
material step; abort if the source branch, commit, or working tree changes.

## 3. Reconstruct the final state

Compare the authoritative final state with the explicit base and apply only the
net intended changes in the destination worktree. Do not replay, cherry-pick,
or preserve source commits merely because they exist.

Explicitly exclude bad, reverted, experimental, superseded, and intermediate
decisions. Preserve approved final file contents and modes. Recreate sensible
commit messages and authorship under repository conventions, but do not carry
over historical metadata such as commit IDs, timestamps, parents, signatures,
or notes.

## 4. Plan and create commits

Derive small, cohesive commits from the reconstructed final diff. Show the
commit plan — each commit's purpose and included paths — and get confirmation
before staging or committing.

After confirmation, stage only the planned paths and create the approved
commits. Recheck that the source remains unchanged throughout; abort on any
source change.

## 5. Validate and report

Validate the destination against the authoritative final state, including:

- file contents and scoped diff;
- executable bits and other approved file modes;
- relevant metadata (for example symlink targets, submodule revisions, and
  binary identity) when explicitly included; and
- all available relevant project checks.

Report the destination branch/worktree, created commits, files changed,
validation performed and results, explicit exclusions, and any unresolved
destination diffs. Do not claim completion if validation or source-stability
checks cannot be completed.
