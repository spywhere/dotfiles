# Dotfiles

## Required Commands

- coreutils
  - `uname`

## Supported Platform

- macOS
- Linux
  - Debian
    - Raspberry OS
    - Ubuntu
  - Alpine

## Quick Installation

```sh
sh -c "$(curl -sSL bit.do/spywhere-dots-install)"
```

or

```sh
sh -c "$(curl -sSL git.io/Jt8w0)"
```

## Available Flags and Options
<!--FLAGS:START-->

    Usage: install.sh [flag ...] [package/setup ...] 
     
    Flags: 
      -h, --help          Show this help message
      -i, --info          Print out the setup environment information
      -l, --local         Run install script locally without update (use -ll for force running local script even through remote install)
      -c, --confirmation  Ask for confirmation before performing installation
      -d, --dumb          Do not attempt to install dependencies automatically
      -k, --keep          Keep downloaded dependencies
      -f, --force         Force reinstall any installed packages when possible
      -q, --quiet         Suppress output messages when possible
      -v, --verbose       Produce command output messages when possible (use -vv for more verbosity)
      -p, --packages      Print out available packages
      -s, --setup         Print out available setup
     
    To skip a specific package or setup, add a 'no-' prefix to the package or setup name itself. 
     
      Example: install.sh no-asdf no-docker 
      Skip Docker and ASDF installation 
     
    To include a specific package or setup, simply add a package or setup name after exclusions. 
     
      Example: install.sh no-package asdf docker 
      Skip package installation, but install ASDF and Docker 
     
    To skip system update/upgrade, package installation or setups, use 
      no-update           Skip system update and system upgrade
      no-upgrade          Only perform a system update but not system upgrade
      no-package          Skip package installations, including a custom and a Docker one
      no-docker           Skip Docker based installations
      no-custom           Skip custom installations
      no-setup            Skip setups
     
    Note: 
      - Package name is indicated by the file name under 'packages' or 'setup' directory 
      - If the setup require particular packages, those packages will be automatically installed. 

<!--FLAGS:END-->

## Installation with Additional Flags and Options

To use flags in remote installation, use one of these commands

```sh
sh -c "$(curl -sSL bit.do/spywhere-dots-install) - [flags...]"
```

```sh
sh -c "$(curl -sSL git.io/Jt8w0) - [flags...]"
```

## Development

To run the setup without auto updating use

```sh
sh install.sh -l
```

To simulate a remote setup use one of these commands

```sh
sh -c "$(cat install.sh)" - [flags...]
```

```sh
cat install.sh | sh -s -- [flags...]
```
