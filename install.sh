#!/bin/sh

set -e

########################
# Internal Information #
########################

CLONE_REPO="https://github.com/spywhere/dotfiles"

CURRENT_DIR=$(pwd)
FLAGS="$@"

# Set a dot files directory if one is not found
if test -z "$DOTFILES"; then
  DOTFILES=".dots"
fi

# Try to set home variable if one is not found
if test -z "$HOME"; then
  HOME="$(printf "%s" ~)"
fi

# Figure out if we run through local file or not
#   $0 will produced a shell command if we piped the file
#   $0 will produced "-" when being evaluated as a script
REMOTE_INSTALL=0
if test "$0" = "sh" -o "$0" = "bash" -o "$(echo $0 | sed 's/^--*$/-/g')" = "-"; then
  REMOTE_INSTALL=1
fi

# Figure out if we already have a local copy
LOCAL_COPY=0
if test -d "$HOME/$DOTFILES"; then
  LOCAL_COPY=1
fi

esc_reset="" # reset
esc_blue="" # indicate process
esc_green="" # indicate options and information
esc_yellow="" # indicate warnings
esc_red="" # indicate errors

if test -n "$TERM" -a -n "$(command -v tput)" && test "$(tput colors)" -ge 8 && test -n "$(command -v tty)" && tty -s; then
  esc_reset="$(tput sgr0)"
  if test "$(tput colors)" -gt 8; then
    esc_blue="$(tput setaf 12)"
    esc_green="$(tput setaf 10)"
    esc_yellow="$(tput setaf 11)"
    esc_red="$(tput setaf 9)"
  else
    esc_blue="$(tput setaf 4)"
    esc_green="$(tput setaf 2)"
    esc_yellow="$(tput setaf 3)"
    esc_red="$(tput setaf 1)"
  fi
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
  if test -z "$@"; then
    >&2 printf "\n"
    return
  fi
  printf "$esc_red ==> ERROR$esc_reset: %s\n" "$@" >&2
}

warn() {
  if test -z "$@"; then
    print
    return
  fi
  print "$esc_yellow==> WARN$esc_reset: $@"
}

# Print a padded string
#   print [string] [string]
#   print <pad size> <padded string> <string>
force_print() {
  if test -z "$#"; then
    printf "\n"
    return
  fi
  if test "$#" -le 2; then
    printf "$1 $2\n"
    return
  fi
  printf "%-$1s%s\n" "$2" "$3"
}

print() {
  if test "$VERBOSE" -eq 0; then
    return
  fi

  force_print "$@"
}

info() {
  print "$esc_green==> INFO:$esc_reset $@"
}

step() {
  print "$esc_blue==>$esc_reset $@"
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
  OSARCH=" ($(uname -m))"
  case "$(uname -s)" in
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
      OSARCH=""
      ;;
  esac
}

_add_item() {
  local target="$1"
  local separator="$2"
  local value="$3"

  if test -z "$target"; then
    printf "%s" "$value"
  else
    printf "%s%s%s" "$target" "$separator" "$value"
  fi
}

_has_item() {
  local list="$1"
  local item="$2"

  local found_item
  for found_item  in $list; do
    if test "$found_item" = "$item"; then
      return 0
    fi
  done
  return 1
}

# All options turned on
RUN_LOCAL=0
DUMB=0
KEEP_FILES=0
CONFIRMATION=0
FORCE_INSTALL=0
# Verbosity
#   0: Quiet
#   1: Quiet for commands, but not output (default)
#   2: Default command verbosity (no verbose flags)
#   3: More command verbosity (explicit verbose flags)
VERBOSE=1
PRINT_MODE=""

PKGMGR=""
OS="unsupported"
OSNAME="Unsupported"
OSARCH=""

_HALT=0 # flag to indicate if the installation should be stopped
_FULFILLED="" # a flag indicate if the task has been fulfilled
_SKIP_OPTIONAL="" # a flag to indicate if the current task is optional
_RUNNING_TYPE="package" # a string indicate the type of running script
_RUNNING="" # keep the currently running sub-script
_SKIPPED="" # keep a list of skipped components (scripts)
_INDICATED="" # keep a list of specified components (scripts)
_LOADED="" # keep a list of install components (scripts)
_PACKAGES="" # keep a list of install packages
_CUSTOM="" # keep a list of custom function for installing packages
_DOCKER="" # keep a list of docker build for installing packages
_SETUP="" # keep a list of custom function for setups
_INTERNAL_STATE="" # keep a list of internal flags and states

_QUIET_CMD="" # an alternative command for suppressing output
_QUIET_FLAGS="" # an alternative flag for suppressing output
_VERBOSE_CMD="" # an alternative command for producing more output
_VERBOSE_FLAGS="" # an alternative flag for producing more output
_POST_INSTALL_MSGS="" # keep a list of post installation messages

_main() {
  _detect_os

  # Read flags
  while test "$1" != ""; do
    PARAM="$(printf "%s" "$1" | sed 's/=.*//g')"
    VALUE="$(printf "%s" "$1" | sed 's/^[^=]*=//g')"
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
      -ll)
        RUN_LOCAL=2
        ;;
      -c | --confirmation)
        CONFIRMATION=1
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
        VERBOSE=0
        ;;
      -v | --verbose)
        VERBOSE=2
        ;;
      -vv)
        VERBOSE=3
        ;;
      -p | --packages)
        PRINT_MODE="packages"
        ;;
      -s | --setup)
        PRINT_MODE="setup"
        ;;
      -*)
        error "unknown flag \"$1\""
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
      no-*)
        # Add package to the skipped list
        local name=$(printf "%s" "$1" | cut -c4-)
        _SKIPPED=$(_add_item "$_SKIPPED" " " "$name")
        ;;
      *)
        # Add package to the indicated list
        local name="$1"
        _INDICATED=$(_add_item "$_INDICATED" " " "$name")
        ;;
    esac

    shift
  done

  _try_run_install
  quit
}

_usage() {
  VERBOSE=1
  print "Usage: $0 [flag ...] [package/setup ...]"
  print
  print "Flags:"
  print 22 "  -h, --help" "Show this help message"
  print 22 "  -i, --info" "Print out the setup environment information"
  print 22 "  -l, --local" "Run install script locally without update (use -ll for force running local script even through remote install)"
  print 22 "  -c, --confirmation" "Ask for confirmation before performing installation"
  print 22 "  -d, --dumb" "Do not attempt to install dependencies automatically"
  print 22 "  -k, --keep" "Keep downloaded dependencies"
  print 22 "  -f, --force" "Force reinstall any installed packages when possible"
  print 22 "  -q, --quiet" "Suppress output messages when possible"
  print 22 "  -v, --verbose" "Produce command output messages when possible (use -vv for more verbosity)"
  print 22 "  -p, --packages" "Print out available packages"
  print 22 "  -s, --setup" "Print out available setup"
  print
  print "To skip a specific package or setup, add a 'no-' prefix to the package or setup name itself."
  print
  print "  Example: $0 no-asdf no-docker"
  print "  Skip Docker and ASDF installation"
  print
  print "To include a specific package or setup, simply add a package or setup name after exclusions."
  print
  print "  Example: $0 no-packages asdf docker"
  print "  Skip package installation, but install ASDF and Docker"
  print
  print "To skip system update/upgrade, package installation or setups, use"
  print 22 "  no-update" "Skip system update and system upgrade"
  print 22 "  no-upgrade" "Only perform a system update but not system upgrade"
  print 22 "  no-packages" "Skip package installation, including a custom one"
  print 22 "  no-setup" "Skip setups"
  print "Note:"
  print "  - Package name is indicated by the file name under 'packages' or 'setup' directory"
  print "  - If the setup require particular packages, those packages will be automatically installed."
}

_info() {
  VERBOSE=1
  print      20 "Execution" ": $0"
  print      20 "Operating System" ": $OSNAME$OSARCH$PKGMGR"
  print      20 "Home Directory" ": $HOME"
  print      20 "Working Directory" ": $CURRENT_DIR"
  print      20 ".dots Target" ": $DOTFILES -> $HOME/$DOTFILES"
  print_bool 20 "Remote Install" "$REMOTE_INSTALL" ": "
  print_bool 20 "Has Local Copy" "$LOCAL_COPY" ": "
}

#################
# Main Commands #
#################

_has_skip() {
  local component="$1"
  _has_item "$_SKIPPED" "$component"
}

_has_indicate() {
  local component="$1"
  _has_item "$_INDICATED" "$component"
}

_check_sudo() {
  if test "$(command -v sudo)"; then
    return
  fi

  error "insufficient permission, no 'sudo' available"
}

_try_git() {
  if test "$(command -v git)"; then
    return
  fi
  if test "$DUMB" -eq 1; then
    error "command \"git\" is required"
    quit 1
  fi

  if test "$OS" = "alpine"; then
    step "Installing git..."
    cmd apk add git
  elif test "$OS" = "debian"; then
    step "Installing git..."
    sudo_cmd apt install -y git
  elif test "$OS" = "macos" -a "$(command -v "brew")"; then
    step "Installing git..."
    cmd brew install git
  else
    error "command \"git\" is required"
    quit 1
  fi
}

_try_run_install() {
  local skip_update=0
  if test "$LOCAL_COPY" -eq 0; then
    if test "$RUN_LOCAL" -ge 1; then
      error "local copy of dotfiles is not found at $HOME/$DOTFILES"
      quit 1
    fi

    local clone_flags=""
    if test -n "$CLONE_REPO_BRANCH"; then
      clone_flags="--branch $CLONE_REPO_BRANCH"
    fi
    if test "$VERBOSE" -le 1; then
      clone "$CLONE_REPO" "$HOME/$DOTFILES" "dotfiles into $HOME/$DOTFILES" "$clone_flags"
    else
      clone "$CLONE_REPO" "$HOME/$DOTFILES" "dotfiles" "$clone_flags"
    fi
    skip_update=1
  fi

  cd $HOME/$DOTFILES

  # Try to update when install remotely, but not the first clone
  if test "$skip_update" -eq 0 -a "$REMOTE_INSTALL" -eq 1 -a "$RUN_LOCAL" -lt 2; then
    _try_git
    step "Updating dotfiles to latest version..."
    cmd git reset --hard
    cmd git fetch
    cmd git pull --rebase
  fi

  # Run local script when install remotely
  if test "$REMOTE_INSTALL" -eq 1; then
    step "Executing local script..."
    sh $HOME/$DOTFILES/install.sh $FLAGS
    quit
  fi

  if test -n "$PRINT_MODE"; then
    if ! test -d "$HOME/$DOTFILES/$PRINT_MODE"; then
      print "No $PRINT_MODE available"
      quit
    fi
    print "Available $PRINT_MODE:"
    local file_path
    for file_path in $HOME/$DOTFILES/$PRINT_MODE/*.sh; do
      name=$(basename $file_path)
      name=${name%.sh}
      print "  - $name"
    done
    quit
  fi

  # testing basic requirements
  local commands="awk basename sed"
  local command
  for command in $commands; do
    if ! test "$(command -v "$command")"; then
      error "'$command' is required, but not found"
      _HALT=1
    fi
  done

  if test $_HALT -eq 1; then
    quit 1
  fi

  step "Ready"
  if ! test -f "$HOME/$DOTFILES/systems/$OS.sh"; then
    error "\"$OS\" is not supported"
    quit 1
  fi
  . $HOME/$DOTFILES/systems/$OS.sh
  step "Setting up installation process..."
  setup
  step "Gathering components..."

  # run packages
  _RUNNING_TYPE="package"
  if ! _has_skip packages || test -n "$_INDICATED"; then
    local package_path
    for package_path in $HOME/$DOTFILES/packages/*.sh; do
      local package=$(basename "$package_path")
      package=${package%.sh}

      # Skip requested packages
      if (_has_skip packages || _has_skip "$package") && ! _has_indicate "$package"; then
        continue
      fi

      # Package could be loaded from the dependency list
      if has_package "$package"; then
        continue
      fi

      _RUNNING="$package"
      _FULFILLED=""
      # Add package to the loaded list (prevent dependency cycle)
      _LOADED=$(_add_item "$_LOADED" " " "$_RUNNING")
      . $package_path

      # Remove optional packages from the loaded list
      if test "$_FULFILLED" = "optional"; then
        local new_loaded=""
        local loaded_package
        for loaded_package in $(_split "$_LOADED"); do
          if test "$loaded_package" = "$_RUNNING"; then
            continue
          fi
          new_loaded=$(_add_item "$new_loaded" " " "$loaded_package")
        done
        _LOADED="$new_loaded"
      fi
    done
  fi

  # running setup preparation
  _RUNNING_TYPE="setup"
  if ! _has_skip setup || test -n "$_INDICATED"; then
    local setup_path
    for setup_path in $HOME/$DOTFILES/setup/*.sh; do
      local setup=$(basename "$setup_path")
      setup=${setup%.sh}

      # Skip requested setups
      if (_has_skip setup || _has_skip "$setup") && ! _has_indicate "$setup"; then
        continue
      fi

      _RUNNING="$setup"
      _FULFILLED=""
      . $setup_path
    done
  fi

  if test $_HALT -eq 1; then
    quit 1
  fi

  if test -n "$_PACKAGES"; then
    print "$esc_green==>$esc_reset The following packages will be installed:"
    local package
    for package in $(_split "$_PACKAGES"); do
      print "  $esc_blue-$esc_reset $(printf "$package" | sed 's/|/ - /g')"
    done
  fi
  if test -n "$_DOCKER"; then
    print "$esc_green==>$esc_reset The following Docker buildings will be run:"
    local package
    for package in $(_split "$_DOCKER"); do
      print "  $esc_blue-$esc_reset $(printf "$package" | sed 's/|/ - /g')"
    done
  fi
  if test -n "$_CUSTOM"; then
    print "$esc_green==>$esc_reset The following installations will be run:"
    local fn
    for fn in $(_split "$_CUSTOM"); do
      print "  $esc_blue-$esc_reset $fn"
    done
  fi
  if test -n "$_SETUP"; then
    print "$esc_green==>$esc_reset The following setups will be run:"
    local fn
    for fn in $(_split "$_SETUP"); do
      print "  $esc_blue-$esc_reset $fn"
    done
  fi

  if ! _has_skip update; then
    if _has_skip upgrade; then
      print "$esc_green==>$esc_reset System update will be performed"
    else
      print "$esc_green==>$esc_reset System update and upgrade will be performed"
    fi
  fi

  if test "$CONFIRMATION" -eq 1; then
    printf "$esc_yellow==>$esc_reset Perform the installation? [y/N] "
    while test !; do
      local choice
      if ! read -n1 -s choice; then
        quit 1
      fi
      if test "$choice" = "y" -o "$choice" = "Y"; then
        force_print
        break
      fi
      force_print
      quit
    done
  fi

  # update/upgrade system
  if ! _has_skip update; then
    if _has_skip upgrade; then
      step "Updating system..."
      update "update"
    else
      step "Updating and upgrading system..."
      update "upgrade"
    fi
  fi

  # install packages
  if test -n "$_PACKAGES"; then
    install_packages $(_split "$_PACKAGES")
  fi

  # run custom installations
  if test -n "$_CUSTOM"; then
    step "Performing custom installations..."
    local fn
    for fn in $(_split "$_CUSTOM"); do
      "$fn"
    done
  fi

  # run setups
  if test -n "$_SETUP"; then
    step "Running setups..."
    local fn
    for fn in $(_split "$_SETUP"); do
      "$fn"
    done
  fi

  step "Done!"
  if test -n "$_POST_INSTALL_MSGS"; then
    print "NOTE: Don't forget to..."
    print "  - $_POST_INSTALL_MSGS"
  fi
}

#############
# Main APIs #
#############

add_flag() {
  local flag="$1"
  _INTERNAL_STATE=$(_add_item "$_INTERNAL_STATE" " " "$flag")
}

has_flag() {
  local flag="$1"
  _has_item "$_INTERNAL_STATE" "$flag"
}

deps() {
  if ! test -d "$HOME/$DOTFILES/.deps"; then
    mkdir -p $HOME/$DOTFILES/.deps
  fi

  if test -n "$1"; then
    printf "$HOME/$DOTFILES/.deps/$1"
  else
    printf "$HOME/$DOTFILES/.deps"
  fi
}

quiet_cmd() {
  _QUIET_CMD="$@"
}

quiet_flags() {
  _QUIET_FLAGS="$@"
}

verbose_cmd() {
  _VERBOSE_CMD="$@"
}

verbose_flags() {
  _VERBOSE_FLAGS="$@"
}

sudo_cmd() {
  if test "$(whoami)" = "root"; then
    cmd $@
  else
    _check_sudo
    if test -n "$_VERBOSE_CMD"; then
      _VERBOSE_CMD="sudo $_VERBOSE_CMD"
    fi
    if test -n "$_QUIET_FLAGS"; then
      _QUIET_FLAGS="sudo $_QUIET_FLAGS"
    fi
    cmd sudo $@
  fi
}

cmd() {
  if test "$VERBOSE" -le 1 -a "$_QUIET_CMD"; then
    "$_QUIET_CMD"
  elif test "$VERBOSE" -le 1 -a "$_QUIET_FLAGS"; then
    "$@" "$_QUIET_FLAGS"
  elif test "$VERBOSE" -le 1; then
    "$@" >/dev/null 2>&1
  elif test "$VERBOSE" -ge 3 -a "$_VERBOSE_CMD"; then
    "$_VERBOSE_CMD"
  elif test "$VERBOSE" -ge 3 -a "$_VERBOSE_FLAGS"; then
    "$@" "$_VERBOSE_FLAGS"
  else
    "$@"
  fi
  _QUIET_CMD=""
  _QUIET_FLAGS=""
  _VERBOSE_CMD=""
  _VERBOSE_FLAGS=""
}

full_clone() {
  local repo="$1"
  local dir_name="$2"
  local name="$3"
  shift
  if test -n "$dir_name"; then
    shift
  fi
  _try_git
  if test -n "$name"; then
    shift
    step "Cloning $name..."
  fi

  cmd git clone $@ "$repo" "$dir_name"
}

clone() {
  local repo="$1"
  local dir_name="$2"
  local name="$3"
  shift
  if test -n "$dir_name"; then
    shift
  fi
  _try_git
  if test -n "$name"; then
    shift
    step "Cloning $name..."
  fi

  cmd git clone --shallow-submodules --depth 1 $@ "$repo" "$dir_name"
}

# has_cmd <command>
has_cmd() {
  local cmd="$1"
  test "$(command -v $cmd)"
}

# has_package <package>
has_package() {
  local package="$1"
  _has_item "$_LOADED" "$package"
}

add_post_install_message() {
  local message="$1"
  _POST_INSTALL_MSGS=$(_add_item "$_POST_INSTALL_MSGS" "\n  - " "$message")
}

# Mark current script as optional
optional() {
  if test -n "$_SKIP_OPTIONAL"; then
    return
  fi
  _FULFILLED="optional"
}

# Skip installation if the package is not being installed
# depends <package>
depends() {
  if test -n "$_FULFILLED"; then
    return
  fi

  local package="$1"
  if has_package "$package"; then
    return
  fi

  _FULFILLED="fulfilled"
}

# Install package regardless of skipped components
# require <package>
require() {
  if test "$_FULFILLED" = "optional"; then
    return
  fi

  local package="$1"

  # Depends on itself
  if test "$_RUNNING" = "$package"; then
    return
  fi

  if has_package "$package"; then
    return
  fi

  # Dependency not found
  if ! test -f "$HOME/$DOTFILES/packages/$package.sh"; then
    error "$_RUNNING_TYPE \"$_RUNNING\" is depends on \"$package\""
    _HALT=1
    return
  fi

  local old_running_type="$_RUNNING_TYPE"
  local old_running="$_RUNNING"
  local old_fulfilled="$_FULFILLED"
  _RUNNING_TYPE="package"
  _RUNNING="$package"
  _SKIP_OPTIONAL="1"
  _FULFILLED=""
  # Add package to the loaded list (prevent dependency cycle)
  _LOADED=$(_add_item "$_LOADED" " " "$_RUNNING")

  . $HOME/$DOTFILES/packages/$package.sh

  _RUNNING_TYPE="$old_running_type"
  _RUNNING="$old_running"
  _SKIP_OPTIONAL=""
  _FULFILLED="$old_fulfilled"
}

_add_package() {
  local target="$1"
  local manager="$2"
  shift
  shift
  local package="$manager"
  local component
  for component in $@; do
    package=$(printf "%s|%s" "$package" "$component")
  done

  target=$(_add_item "$target" ";" "$package")
  printf "$target"
}

# Add package into installation list
# add_package <manager> <package>...
add_package() {
  if test "$_FULFILLED" = "optional"; then
    return
  fi
  _PACKAGES=$(_add_package "$_PACKAGES" "$@")
  _FULFILLED="fulfilled"
}

# Add custom function into installation list
# add_custom <function>
add_custom() {
  if test "$_FULFILLED" = "optional"; then
    return
  fi
  local fn="$1"
  _CUSTOM=$(_add_item "$_CUSTOM" ";" "$fn")
}

# Add custom function into installation list if no valid setup available
# use_custom <function>
use_custom() {
  if test -n "$_FULFILLED"; then
    return
  fi

  add_custom "$@"
  _FULFILLED="fulfilled"
}

# Add docker build into installation list if no valid setup available
# use_docker <package>
use_docker_build() {
  if _has_skip docker; then
    return
  fi
  local package="$1"
  if test -n "$_FULFILLED"; then
    return
  fi

  if ! test -f "$HOME/$DOTFILES/docker/$package/Dockerfile.$OS"; then
    warn "Docker build for package \"$package\" is not available on $OS"
    return
  fi

  if test -z "$_DOCKER"; then
    require 'docker'
  fi
  _DOCKER=$(_add_package "$_DOCKER" "$package")
  _FULFILLED="fulfilled"
}

# Add custom function into setup list if no valid setup available
# add_setup <function>
add_setup() {
  if test -n "$_FULFILLED"; then
    return
  fi

  local fn="$1"
  _SETUP=$(_add_item "$_SETUP" ";" "$fn")
}

_main "$@"
