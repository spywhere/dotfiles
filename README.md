# Dotfiles

A cross-platform, modular dotfiles for my personal setup

![Screen Shot](https://user-images.githubusercontent.com/1087399/163681933-45116a93-57a3-4a2d-8f34-244362a303f5.png)

## Required Commands

- coreutils
  - `uname`

## Supported Platform

[![Installation Test (native)](https://github.com/spywhere/dotfiles/actions/workflows/macos-test.yml/badge.svg)](https://github.com/spywhere/dotfiles/actions/workflows/macos-test.yml)
[![Installation Test (via Docker)](https://github.com/spywhere/dotfiles/actions/workflows/os-test.yml/badge.svg)](https://github.com/spywhere/dotfiles/actions/workflows/os-test.yml)

- macOS
- Linux
  - Debian
    - Raspberry Pi OS
    - Ubuntu
  - Alpine
  - Arch Linux -- including on ARM!

## Quick Installation

```sh
sh -c "$(curl -sSL dots.spywhere.me)"
```

## Available Flags and Options
<!--FLAGS:START-->

    Usage: install.sh [flag ...] [package/setup ...] 
     
    A cross-platform, modular dotfiles installer 
     
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
     
      Example: install.sh no-asdf no-zsh 
      Skip ZSH and ASDF installation 
     
    To include a specific package or setup, simply add a package or setup name after exclusions. 
     
      Example: install.sh no-package asdf zsh 
      Skip package installation, but install ASDF and ZSH 
     
    To skip system update/upgrade, package installation or setups, use 
      no-update           Skip system update and system upgrade
      no-upgrade          Only perform a system update but not system upgrade
      no-package          Skip package installations, including a custom one
      no-custom           Skip custom installations
      no-setup            Skip setups
     
    Note: 
      - Package name is indicated by the file name under 'packages' or 'setup' directory 
      - Packages in the inclusion list will be installed regardless of existing installation 
      - If the setup require particular packages, those packages will be automatically installed 
     
    Some systems might have additional installation flags, try running with 
      -hh                 Show this help message with additional flags for this system

<!--FLAGS:END-->

## Installation with Additional Flags and Options

To use flags in remote installation, use this command

```sh
sh -c "$(curl -sSL dots.spywhere.me)" - [flags...]
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
