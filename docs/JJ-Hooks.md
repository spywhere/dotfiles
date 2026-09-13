# JJ Hook Integration

The `binaries/jj` executable wraps the real Jujutsu executable because JJ does
not run Git hooks and aliases cannot replace built-in commands. The dotfiles
shell setup places `binaries` before package-manager directories in `PATH`.

## Hooked commands

- `jj commit` runs the pre-commit stage over the files changed in the current
  change, runs the real command with its original arguments, and then runs the
  commit-msg stage over the committed change's finalized description.
- `jj describe` runs the real command first and then runs the commit-msg stage
  for each described revision. It does not run source-file checks.
- `jj git push` determines the proposed bookmark updates with a real
  `jj git push --dry-run`, validates each pushed target with the pre-push stage,
  and only performs the original push after every check passes.
- All other commands are passed directly to the real JJ executable.

A failed post-operation commit-msg check leaves the committed change or edited
description intact. Hook formatter changes are also left intact. The wrapper
returns non-zero and does not automatically undo either kind of change.

## Hook discovery

For each stage, a colocated repository's executable Git hook takes precedence.
The wrapper uses Git's hook-path resolution, including `core.hooksPath`, and
supplies Git-compatible arguments and environment. For pre-commit it uses a
temporary index representing the JJ change; it never modifies the real Git
index.

When no installed hook exists, the wrapper looks for
`.pre-commit-config.yaml` at the JJ workspace root and invokes `pre-commit`, or
`prek` when it is available instead. A repository with neither an applicable
hook nor that configuration file is passed through without validation.

Non-colocated Git-backed JJ repositories are supported. The wrapper exposes the
bare object store reported by `jj git root` to the checker, so
`jj git colocation enable` is not required.

## Bypass

For recovery or diagnosis, place `--` immediately after `jj`. Everything after
it is passed directly to the real executable without wrapper hooks:

```sh
jj -- <raw jj arguments>
```

For example, `jj -- commit --message "emergency"` directly invokes
`jj commit --message "emergency"`. The separator itself is consumed by the
wrapper and is not forwarded.

The wrapper separately sets an internal recursion guard. Any `jj` process
started by a hook or checker goes directly to the retained real JJ executable.

## Scope

Only `commit`, `describe`, and `git push` are intercepted. JJ changes can also
be rewritten through commands such as `squash`, `split`, `rebase`, and
`restore`. The pre-push stage is therefore the primary local safety gate, and
CI remains the authoritative final enforcement layer.
