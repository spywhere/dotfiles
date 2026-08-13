# Get Started with Your Setup

To get started with your own setup, you need basically 2 things

- [Packages](/docs/package.md)
- [Setups](/docs/setup.md)

Simply create a new repository with a directory named `packages` and `setup`,
and you should be pretty much ready to start adding your 'package' and 'setup'.

There is also an optional [pre-setup](/docs/pre-setup.md) step, which works
just like a setup but runs first, before any package installation, useful for
adjusting system state that other steps may interact with.

## Installation Process

The installation process will started off with the installer self-check. The
self-check process will ensure the minimum software required for the
installation is satisfied (such as a Git command and a cURL command,
among other things).

Once self-check is done, the installer will begin evaluating pre-setups,
packages, and setups. Each will get ran and, through the proper API usage, get
collected for the summary.

After everything is collected, it will be summarized to the user and asking
for the confirmation (unless skipped) before actually performing the
installation. Pre-setups run first, ahead of the system update and package
installation, followed by the system update, packages, and lastly setups.
