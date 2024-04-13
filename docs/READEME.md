# Get Started with Your Setup

To get started with your own setup, you need basically 2 things

- [Packages](/docs/package.md)
- [Setups](/docs/setup.md)

Simply create a new repository with a directory named `packages` and `setup`,
and you should be pretty much ready to start adding your 'package' and 'setup'.

## Installation Process

The installation process will started off with the installer self-check. The
self-check process will ensure the minimum software required for the
installation is satisfied (such as a Git command and a cURL command,
among other things).

Once self-check is done, the installer will begin evaluating all the packages.
Each package will get ran and, through the proper API usage, get collected for
the summary. Same will be done for the setup step.

After all packages and setups are collected, it will be summarized to the user
and asking for the confirmation (unless skipped) before actually performing
the installation.
