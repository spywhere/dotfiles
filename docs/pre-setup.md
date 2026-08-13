# Pre-setup

Pre-setup works exactly the same as [setup](/docs/setup.md), the only
difference is when it get run.

While a setup will perform after all package installation has successfully
installed, a pre-setup will perform first, before the system update and any
package installation. This makes pre-setup the right place to adjust system
state that other steps (system update, packages, custom installations) may
read from or interact with, such as OS-level preferences.

## Create a new pre-setup

To create a pre-setup, create a new shell file with `.sh` extension under
`pre_setup` directory. The file name will be the pre-setup name and should be
named in a kebab-case with no spacing and special characters (to prevent a
conflict with shell escaping), exactly the same as setup.

The main different apart from a setup is on the `add_pre_setup` line.

```sh
add_pre_setup 'setup_trackpad'
```

For all other detail (skipping using `has_profile`/`depends`/`require`, the
`force_print` self-check guard, available APIs, and so on), check out
[setup](/docs/setup.md) documentation.
