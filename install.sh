#!/bin/sh

set -e

########################
# Internal Information #
########################

CLONE_REPO="https://github.com/spywhere/dotfiles"

CURRENT_DIR=$(pwd)
RUN_DIRNAME=$(dirname $0)
RUN_DIR=$(realpath $(pwd)/$RUN_DIRNAME)
FLAGS=$@

# Set a dot files directory if one is not found
if test -z "$DOTFILES"; then
  DOTFILES=.dots
fi

# Try to set home variable if one is not found
if test -z "$HOME"; then
  HOME="$(printf "%s" ~)"
fi

# Figure out if we run through local file or not
# $0 will produced a shell command if we piped the file
REMOTE_INSTALL=0
if test "$0" = "sh" -o "$0" = "bash"; then
  REMOTE_INSTALL=1
fi

# Figure out if we already have a local copy
LOCAL_COPY=0
if test -d "$HOME/$DOTFILES"; then
  LOCAL_COPY=1
fi

#######################
# Utilities Functions #
#######################

quit() {
  cd "$CURRENT_DIR"
  if test -z "$1"; then
    exit
  else
    exit "$1"
  fi
}

error() {
  if test -z "$#"; then
    >&2 echo
    return
  fi
  printf "%s\n" "$*" >&2
}

# Print a padded string
#   print [string] [string]
#   print <pad size> <padded string> <string>
force_print() {
  if test -z "$#"; then
    echo
    return
  fi
  if test "$#" -le 2; then
    printf "$1 $2\n"
    return
  fi
  printf "%-$1s%s\n" "$2" "$3"
}

print() {
  if test "$SILENT" -eq 1; then
    return
  fi

  force_print "$@"
}

# Print a boolean value as string
#   print_bool <pad size> <padded string> <bool variable> [prefix] [suffix]
print_bool() {
  if test "$3" -eq 0; then
    print "$1" "$2" "$4No$5"
  else
    print "$1" "$2" "$4Yes$5"
  fi
}

_split() {
  printf "%s" "$1" | awk 'BEGIN{RS=";"}{print $0}'
}

_detect_os() {
  case `uname -s` in
    Linux*)
      OS="Linux"
      if test -f /etc/debian_version; then
        PKGMGR=" - Advanced Packaging Tool (apt)"
        OSNAME="Debian"
        OS="debian"
      elif test -f /etc/alpine-release; then
        PKGMGR=" - Alpine Linux Package Manager (apk)"
        OSNAME="Alpine"
        OS="alpine"
      else
        OSNAME="Linux"
        OS="linux"
      fi
      ;;
    Darwin*)
      PKGMGR=" - Homebrew (brew)"
      OSNAME="Mac"
      OS="macos"
      ;;
    *)
      OSNAME="Unsupported"
      OS="unsupported"
      ;;
  esac
}

# All options turned on
RUN_LOCAL=0
DUMB=0
KEEP_FILES=0
FORCE_INSTALL=0
SILENT=0
VERBOSE=0
PRINT_MODE=""

PKGMGR=""
OS="unsupported"
OSNAME="Unsupported"

_HALT=0
_ADDED=""
_RUNNING=""
_LOADED=""
_PACKAGES=""
_CUSTOM=""

_main() {
  _detect_os

  # Read flags
  while test "$1" != ""; do
    PARAM=`echo $1 | sed 's/=.*//g'`
    VALUE=`echo $1 | sed 's/^[^=]*=//g'`
    case $PARAM in
      -h | --help)
        _usage
        quit
        ;;
      -i | --info)
        _info
        quit
        ;;
      -l | --local)
        RUN_LOCAL=1
        ;;
      -d | --dumb)
        DUMB=1
        ;;
      -k | --keep)
        KEEP_FILES=1
        ;;
      -f | --force)
        FORCE_INSTALL=1
        ;;
      -q | --quiet)
        SILENT=1
        ;;
      -v | --verbose)
        VERBOSE=1
        ;;
      -p | --packages)
        PRINT_MODE="packages"
        ;;
      -s | --setup)
        PRINT_MODE="setup"
        ;;
      -*)
        error "ERROR: unknown flag \"$1\""
        quit 1
        ;;
      *)
        break
        ;;
    esac

    shift
  done

  # Read skip packages
  while test "$1" != ""; do
    case $1 in
      no*)
        # Add package to the loaded list (to skip loading)
        if test -z "$_LOADED"; then
          _LOADED="${1:2}"
        else
          _LOADED=$(printf "%s %s" "$_LOADED" "${1:2}")
        fi
        ;;
      *)
        break
        ;;
    esac

    shift
  done

  _try_run_install
  quit
}

_usage() {
  SILENT=0
  print "Usage: $0 [flag ...] [package/setup ...]"
  print
  print "Flags:"
  print 20 "  -h, --help" "Show this help message"
  print 20 "  -i, --info" "Print out the setup environment information"
  print 20 "  -l, --local" "Run install script locally without update"
  print 20 "  -d, --dumb" "Do not attempt to install dependencies automatically"
  print 20 "  -k, --keep" "Keep downloaded dependencies"
  print 20 "  -f, --force" "Force reinstall any installed packages when possible"
  print 20 "  -q, --quiet" "Suppress output messages when possible"
  print 20 "  -v, --verbose" "Produce command output messages when possible"
  print 20 "  -p, --packages" "Print out available packages"
  print 20 "  -s, --setup" "Print out available setup"
  print
  print "To skip specific package or setup, add a 'no' prefix to the package or setup name itself."
  print
  print "  Example: $0 noasdf nodocker"
  print "  Skip Docker and ASDF installation"
}

_info() {
  SILENT=0
  print      20 "Execution" ": $0"
  print      20 "Operating System" ": $OSNAME$PKGMGR"
  print      20 "Home Directory" ": $HOME"
  print      20 "Working Directory" ": $CURRENT_DIR"
  print      20 ".dots Target" ": $DOTFILES -> $HOME/$DOTFILES"
  print_bool 20 "Remote Install" "$REMOTE_INSTALL" ": "
  print_bool 20 "Has Local Copy" "$LOCAL_COPY" ": "
}

#################
# Main Commands #
#################

_check_sudo() {
  if test "$(command -v "sudo")"; then
    return
  fi

  error "Failed: insufficient permission, no 'sudo' available"
}

_try_git() {
  if test "$(command -v git)"; then
    return
  fi
  if test "$DUMB" -eq 1; then
    error "Failed: command \"git\" is required"
    quit 1
  fi

  if test "$OS" = "alpine"; then
    print "Installing git..."
    cmd apk add git
  elif test "$OS" = "debian"; then
    print "Installing git..."
    sudo_cmd apt install -y git
  elif test "$OS" = "macos" -a "$(command -v "brew")"; then
    print "Installing git..."
    cmd brew install git
  else
    error "Failed: command \"git\" is required"
    quit 1
  fi
}

_try_run_install() {
  local SKIP_UPDATE=0
  if test "$LOCAL_COPY" -eq 0; then
    if test "$RUN_LOCAL" -eq 1; then
      error "Failed: local copy of dotfiles is not found at $HOME/$DOTFILES"
      quit 1
    fi

    if test "$VERBOSE" -eq 0; then
      clone "$CLONE_REPO" "$HOME/$DOTFILES" "dotfiles into $HOME/$DOTFILES"
    else
      clone "$CLONE_REPO" "$HOME/$DOTFILES" "dotfiles"
    fi
    SKIP_UPDATE=1
  fi

  cd $HOME/$DOTFILES

  # Try to update when install remotely, but not the first clone
  if test "$SKIP_UPDATE" -eq 0 && test "$REMOTE_INSTALL" -eq 1; then
    _try_git
    print "Updating dotfiles to latest version..."
    cmd git reset --hard
    cmd git fetch
    cmd git pull
  fi

  # Run local script when install remotely
  if test "$REMOTE_INSTALL" -eq 1; then
    print "Executing local script..."
    sh $HOME/$DOTFILES/install.sh $FLAGS
    quit
  fi

  if test -n "$PRINT_MODE"; then
    if ! test -d "$HOME/$DOTFILES/$PRINT_MODE"; then
      print "No $PRINT_MODE available"
      quit
    fi
    print "Available $PRINT_MODE:"
    for file_path in $HOME/$DOTFILES/$PRINT_MODE/*.sh; do
      name=$(basename $file_path)
      name=${name%.sh}
      print "  - $name"
    done
    quit
  fi

  print "Ready"
  if ! test -f "$HOME/$DOTFILES/systems/$OS.sh"; then
    error "Failed: \"$OS\" is not supported"
    quit 1
  fi
  . $HOME/$DOTFILES/systems/$OS.sh
  print "Preparing installation..."
  setup

  for PACKAGE_PATH in $HOME/$DOTFILES/packages/*.sh; do
    local PACKAGE=$(basename "$PACKAGE_PATH")
    PACKAGE=${PACKAGE%.sh}

    # Package could be loaded from the dependency list
    local skip=0
    for loaded_package in $_LOADED; do
      if test "$loaded_package" = "$PACKAGE"; then
        skip=1
      fi
    done

    if test $skip -eq 1; then
      continue
    fi

    _RUNNING="$PACKAGE"
    _ADDED=""
    # Add package to the loaded list (prevent dependency cycle)
    if test -z "$_LOADED"; then
      _LOADED="$_RUNNING"
    else
      _LOADED=$(printf "%s %s" "$_LOADED" "$_RUNNING")
    fi
    . $PACKAGE_PATH
  done

  if test $_HALT -eq 1; then
    quit 1
  fi

  if test -n "$_PACKAGES"; then
    print "The following packages will be installed:"
    for package in $(_split "$_PACKAGES"); do
      print "  - $(printf "$package" | sed 's/|/ - /g')"
    done
  fi
  if test -n "$_CUSTOM"; then
    print "The following functions will be run:"
    for fn in $(_split "$_CUSTOM"); do
      print "  - $fn"
    done
  fi
}

#############
# Main APIs #
#############

deps() {
  if ! test -d "$HOME/$DOTFILES/.deps"; then
    mkdir -p $HOME/$DOTFILES/.deps
  fi

  if test "$1"; then
    printf "$HOME/$DOTFILES/.deps/$1"
  else
    printf "$HOME/$DOTFILES/.deps"
  fi
}

sudo_cmd() {
  if test "$(whoami)" = "root"; then
    cmd $@
  else
    _check_sudo
    cmd sudo $@
  fi
}

cmd() {
  if test "$VERBOSE" -eq 0; then
    "$@" >/dev/null 2>&1
  else
    echo "Running $@"
    "$@"
  fi
}

clone() {
  _try_git
  if test -n "$3"; then
    print "Cloning $3..."
  fi

  cmd git clone --shallow-submodules --depth 1 "$1" "$2"
}

depends() {
  local package="$1"

  # Depends on itself
  if test "$_RUNNING" = "$package"; then
    return
  fi

  # Depends on loaded packages
  for loaded_package in $_LOADED; do
    if test "$loaded_package" = "$package"; then
      return
    fi
  done

  # Dependency not found
  if ! test -f "$HOME/$DOTFILES/packages/$package.sh"; then
    error "Failed: Package \"$_RUNNING\" is depends on \"$package\""
    _HALT=1
    return
  fi

  local old_running="$_RUNNING"
  local old_added="$_ADDED"
  _RUNNING="$package"
  _ADDED=""
  # Add package to the loaded list (prevent dependency cycle)
  if test -z "$_LOADED"; then
    _LOADED="$_RUNNING"
  else
    _LOADED=$(printf "%s %s" "$_LOADED" "$_RUNNING")
  fi

  . $HOME/$DOTFILES/packages/$package.sh

  _RUNNING="$old_running"
  _ADDED="$old_added"
}

add_package() {
  local manager="$1"
  shift
  local package="$manager"
  for component in $@; do
    package=$(printf "%s|%s" "$package" "$component")
  done

  if test -z "$_PACKAGES"; then
    _PACKAGES="$package"
  else
    _PACKAGES=$(printf "%s;%s" "$_PACKAGES" "$package")
  fi
  _ADDED="1"
}

add_custom() {
  local fn="$1"
  if test -z "$_CUSTOM"; then
    _CUSTOM="$fn"
  else
    _CUSTOM=$(printf "%s;%s" "$_CUSTOM" "$fn")
  fi
}

use_custom() {
  if test -n "$_ADDED"; then
    return
  fi

  add_custom "$@"
}

# use_docker <package>
use_docker_build() {
  if test -n "$_ADDED"; then
    return
  fi

  local package="$1"
  add_package docker "$package"
}

_main "$@"
