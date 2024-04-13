# Dotfiles Installer

A cross-platform, modular dotfiles installer

## Required Commands

- coreutils
  - `uname`

## Supported Platforms

[![Installation Test (native)](https://github.com/spywhere/dotfiles/actions/workflows/macos-test.yml/badge.svg?branch=installer)](https://github.com/spywhere/dotfiles/actions/workflows/macos-test.yml)
[![Installation Test (via Docker)](https://github.com/spywhere/dotfiles/actions/workflows/os-test.yml/badge.svg?branch=installer)](https://github.com/spywhere/dotfiles/actions/workflows/os-test.yml)

[![Build Stats](https://buildstats.info/github/chart/spywhere/dotfiles?branch=installer)](https://github.com/spywhere/dotfiles/actions)

- macOS
- Linux
  - Debian
    - Raspberry Pi OS
    - Ubuntu

## Quick Installation

```sh
sh -c "$(curl -sSL dots.spywhere.me)" - user/repo@branch
```

## Available Flags and Options
<!--FLAGS:START-->

    Usage: install.sh [user/repo@branch] [flag ...] [package/setup ...] 
     
    A cross-platform, modular dotfiles installer 
     
    Environment Variables: 
      DOTFILES               Target directory to stored the setup (default to '.dots')
     
      REPO_URL               Git URL to pull the setup from
      REPO_BRANCH            Git branch to pull the setup from (default to default branch)
      REPO_NAME              Repository short hand for using GitHub URL as a Git URL
     
      ** Do not change the following variables unless you know what you are doing ** 
      INSTALLER_REPO_URL     Git URL to pull the installer from (default to 'https://github.com/spywhere/dotfiles')
      INSTALLER_REPO_BRANCH  Git branch to pull the installer from (default to 'installer')
      INSTALLER_DIR          Target directory to stored the installer (default to unique temporary directory)
      SYSTEM_FILES           Template string to direct URL to requested system files
     
    Flags: 
      -h, --help             Show this help message
      -i, --info             Print out the setup environment information
      -l, --local            Use the setup from the local copy
      -y, --yes              Do not ask for confirmation before performing installation
      -d, --dumb             Do not attempt to install dependencies automatically
      -k, --keep             Keep downloaded artifacts
      -f, --force            Force reinstall any installed packages when possible
      -q, --quiet            Suppress output messages when possible
      -v, --verbose          Produce command output messages when possible (use -vv for more verbosity)
      -p, --packages         Print out available packages
      -s, --setup            Print out available setup
      --profile=<profile>    Specify the setup profile
     
    To skip a specific package or setup, add a 'no-' prefix to the package or setup name itself. 
     
      Example: install.sh no-asdf no-zsh 
      Skip ZSH and ASDF installation 
     
    To include a specific package or setup, simply add a package or setup name after exclusions. 
     
      Example: install.sh no-package asdf zsh 
      Skip package installation, but install ASDF and ZSH 
     
    To skip system update/upgrade, package installation or setups, use 
      no-update              Skip system update and system upgrade
      no-upgrade             Only perform a system update but not system upgrade
      no-package             Skip package installations, including a custom one
      no-custom              Skip custom installations
      no-setup               Skip setups
     
    Note: 
      - Package name is indicated by the file name under 'packages' or 'setup' directory 
      - Packages in the inclusion list will be installed regardless of existing installation 
      - If the setup require particular packages, those packages will be automatically installed 
     
    Some systems might have additional installation flags, try running with 
      -hh                  Show this help message with additional flags for this system

<!--FLAGS:END-->

## Installation with Additional Flags and Options

To use flags in remote installation, use this command

```sh
sh -c "$(curl -sSL dots.spywhere.me)" - user/repo@branch [flags...]
```

## Development

To run the setup without auto updating use

```sh
sh install.sh user/repo@branch -l
```

To simulate a remote setup use one of these commands

```sh
sh -c "$(cat install.sh)" - user/repo@branch [flags...]
```

```sh
cat install.sh | sh -s -- user/repo@branch [flags...]
```
