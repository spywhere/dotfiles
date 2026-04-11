# System APIs

System APIs are functions that only available on a certain system.

System APIs will automatically get loaded based on the system running the
installer. A base system will always get loaded, then a specific system.

An installer will try to determine the system name primarily by running
`uname -s`. For Linux-based, the field `ID_LIKE` in `/etc/os-release` will be
used instead before fallback to `ID`. If `/etc/os-release` is not found, then
it will detect the system as followed.

- If `/etc/debian_version` is found, a system will considered `debian`
- If `/etc/alpine-release` is found, a system will considered `alpine`
- Otherwise, considered as `linux` system

During the initial self-check, if a system file for a given system is not
found, then the installer will simply bail out with a message on unsupported
system.

## Supported Systems

Currently, the installer support the following systems

- macOS
- Linux
  - Debian
    - Raspberry Pi OS
    - Ubuntu

A new system can be easily added, check out on how to add a
[support for a new system](#Support-a-new-system) below.

## Debian Interface

- `use_apt_repo <repo>`: Add a package repository to source list
  - `repo`: Repository URL to be added
- `use_apt <package>`: Install a given package using APT
  - `package`: Package name
- `use_dpkg <name> <url>`: Install a .dpkg package from the given URL
  - `name`: Display name
  - `url`: URL to .dpkg file
- `use_dpkg <name> <url> <format url> <fallback version>`: Install a .dpkg
package from the given format URL, and fetch the latest version using Git tag
from the given URL, otherwise fallback to install a fallback version
  - `name`: Display name
  - `url`: URL to a Git repository to be put into a format URL as well as for
fetching latest version
  - `format url`: URL to .dpkg file
  - `fallback version`: Fallback version to be put into a format URL

## macOS Interface

- `has_app <name>`: Check if an app is installed
  - `name`: Application name (name of directory ends with `.app`)
- `has_screensaver <name>`: Check if a screensaver is installed
  - `name`: Screensaver name
- `use_brow <kind> <name>`: Install a package using Homebrew (Intel version)
  - `name`: Package name
  - `kind`: Either `formula` or `cask`
- `use_brew <kind> <name>`: Install a package using Homebrew (Native version)
  - `name`: Package name
  - `kind`: Either `formula` or `cask`
- `use_brew_tap <name>`: Add Homebrew tap
  - `name`: Tap name
- `use_mas <package> <appid>`: Install an app from Mac AppStore using MAS
  - `package`: Package name
  - `appid`: MAS Application ID
- (Deprecated) `use_nativefier <package> <url> <flags>...`: Create an app for
the given URL
  - `package`: Package name
  - `url`: URL to turned into an app
  - `flags`: Flags to passed to nativefier

## Support a new System

A system is simply an implementation of the abstract
[base system](/systems/base.sh).

The following functions can be implement on the system and will override the
base system implementation.

### Base Interface

- (Optional) `system_usage`: Print a custom help message for this system
- (Optional) `setup`: A function that get run before gathering packages and setups
- `install_git`: A function that will install Git for this system

### Common Interface

- `update <mode>`: A function that will perform a system-wide update or upgrade
  - `mode`: Either `update` or `upgrade` will be passed
- `install_packages <packages>...`: A function that will perform a package
installation
  - `packages`: A list of packages to be installed
- (Optional) `install_bins <packages>...`: A function that will perform a
direct binary installation

### Introduce a New Interface

To introduce a new system API (such as to support a different package manager),
simply add a stub implementation (implementation that does nothing) to the base
system and implement such interface in the new system. This would make a newly
introduced API only available in this new system.
