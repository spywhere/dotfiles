# Packages

Package is simply a software package that would be installed through either
a package manager or simply direct download an executable and put in the binary
directory.

Package is somewhat declarative, you simply need to specified how the package
can be installed. Along with some optional conditions.

## Create a new package

To create a package, create a new shell file with `.sh` extension under
`packages` directory. The file name will be the package name and should be
named in a kebab-case with no spacing and special characters (to prevent a
conflict with shell escaping).

An example package to install Tmux would look something like this.

```sh
#!/bin/sh

set -e

if
  ! (command -v force_print >/dev/null 2>&1) ||
  ! (force_print 3 a b >/dev/null 2>&1) ||
  test "$(force_print 3 a b)" != "a  b";
then
  printf "Please run this script through \"install.sh\" instead"
  exit 1
fi

has_executable 'tmux'

use_apt 'tmux'
use_brew formula 'tmux'
use_custom 'make_tmux'

make_tmux() {
  # TODO: to be implemented
  return
}
```

Let's break it down.

```sh
#!/bin/sh

set -e
```

This simply set the default binary to run this script to `/bin/sh` and set the
`-e` flag to always error out should their be any issue with the command in
this script.

```sh
if
  ! (command -v force_print >/dev/null 2>&1) ||
  ! (force_print 3 a b >/dev/null 2>&1) ||
  test "$(force_print 3 a b)" != "a  b";
then
  printf "Please run this script through \"install.sh\" instead"
  exit 1
fi
```

This lines are optional, though used as a safe guard against running the
package directly. It simply validate the expected behaviour of certain
function calls to check itself whether it ran from a correct environment or
not.

```sh
has_executable 'tmux'
```

This line is using the available [built-in API](/lib) to check if the command
`tmux` is exists. If it is exists, the script will halt and nothing will get
installed. This basically means skip the installation if it was installed
already.

```sh
use_apt 'tmux'
use_brew formula 'tmux'
use_custom 'make_tmux'
```

These lines are specified how the package get installed. For the system with
APT, it would install a package named `tmux`. And for the system with Homebrew,
it would install a formula named `tmux`. And lastly, should nothing worked, run
a function named `make_tmux` in an attempt to install Tmux manually.

Notice that the package will only get installed if the defined package manager
is installed. So if we remove the line for `use_custom` on a system without
APT nor Homebrew, the package would not get installed.

```sh
make_tmux() {
  # TODO: to be implemented
  return
}
```

This last section is basically defined the function `make_tmux` to install
the mentioned package.

## Supported Package Managers

Check out [system APIs](/systems) for all available command on each supported
systems.

## Conditions

### Skip if certain condition is met

To not install a package if it was already exists, there are a few caveats to
noted. For certain systems, installing a software would means install a
software package (with its assets and resources) while others would means
install an executable to the binary directory.

In order to skip the installation, each package could use the function to check
if various kind of software is exists or not. To name a few, you could use

- `has_executable '<binary name>'`
- `has_app '<app name>'`
- `has_string '<string>' command args...`

Check out [built-in API references](/lib) for a function prefixed with `has_`.

As certain systems might also implemented a similar function, be sure to check
out [system APIs](/systems) as well.

### Skip installation for a specific system

To not install a package on any particular system, simply NOT call a function
of the package manager installed.

For example, to only install Tmux for Linux with APT package manager and
nothing on macOS, simply call APT function and nothing else.

```sh
# ...

use_apt 'tmux'
# do not add use_brew or use_custom to skip Homebrew and custom installation
```

### Manually skipped

Since the package is a shell script, you could also use an if statement to
check and either call or not call the function based on the condition.

For example, only install Tmux using Homebrew on machine with Arm64 architecture.

```sh
if test "$(uname -m)" = "arm64"; then
  use_brew formula 'tmux'
fi
```

## Custom Installation

As explain above, simply call `use_custom` and pass a function name that would
perform a package installation.

```sh
# ...

use_custom 'make_tmux'

make_tmux() {
  # the process of installation goes here
  return
}
```
