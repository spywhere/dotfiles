#!/bin/sh

set -e

########################
# Internal Information #
########################

CLONE_REPO="https://github.com/spywhere/dotfiles"

CURRENT_DIR=$(pwd)
FLAGS="$*"

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
if test "$0" = "sh" -o "$0" = "bash" -o "$(printf "%s" "$0" | sed 's/^--*$/-/g')" = "-"; then
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
  printf "$esc_red ==> ERROR$esc_reset: %s\n" "$*" >&2
}

warn() {
  if test -z "$@"; then
    print
    return
  fi
  print "$esc_yellow==> WARN$esc_reset: $*"
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
    printf "%s %s\n" "$1" "$2"
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
  print "$esc_green==> INFO:$esc_reset $*"
}

step() {
  print "$esc_blue==>$esc_reset $*"
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
  WSL_SUFFIX=""
  if test -n "$(command -v wsl.exe)"; then
    WSL_SUFFIX=" (through WSL)"
    add_flag "wsl"
  fi

  SYSTEM_NAME="$(uname -s)"
  case "$SYSTEM_NAME" in
    Linux*)
      OS="Linux"
      if test -f /etc/os-release; then
        OSNAME="$(awk 'BEGIN{FS="="} /^NAME=/ { print $2 }' /etc/os-release | sed 's/^"//g' | sed 's/"$//g')"
        OS="$(awk 'BEGIN{FS="="} /^ID=/ { print $2 }' /etc/os-release)"
        OSKIND="$(awk 'BEGIN{FS="="} /^ID_LIKE=/ { print $2 }' /etc/os-release)"
      elif test -f /etc/debian_version; then
        OSNAME="Debian"
        OS="debian"
      elif test -f /etc/alpine-release; then
        OSNAME="Alpine"
        OS="alpine"
      else
        OSNAME="Linux"
        OS="linux"
      fi

      if test -n "$(command -v apt)"; then
        PKGMGR=" - Advanced Packaging Tool (apt)"
      elif test -n "$(command -v apk)"; then
        PKGMGR=" - Alpine Linux Package Manager (apk)"
      fi
      ;;
    Darwin*)
      PKGMGR=" - Homebrew (brew)"
      OSNAME="Mac"
      OS="macos"

      if test "$(arch)" = "arm64"; then
        add_flag "apple-silicon"
      fi
      ;;
    *)
      OSNAME="$SYSTEM_NAME"
      OS="$SYSTEM_NAME"
      ;;
  esac
  if test -z "$OSKIND"; then
    OSKIND="$OS"
  fi
  OSARCH=" ($OSKIND/$(uname -m))"
  OSNAME="$OSNAME$WSL_SUFFIX"
}

_add_to_list() {
  add_to_list__target="$(printf "%s" "$1" | sed 's/^ $//g')"
  shift

  if test -n "$add_to_list__target"; then
    printf "%s\n" "$add_to_list__target"
  fi
  for i in "$@"; do
    printf '%s\n' "$i" | sed "s/'/'\\\\''/g" | sed "1s/^/'/" | sed "\$s/\$/' \\\\/"
  done
  printf ' '
}

_make_list() {
  _add_to_list "" "$@"
}

_add_item() {
  add_item__target="$1"
  add_item__separator="$2"
  add_item__value="$3"

  if test -z "$add_item__target"; then
    printf "%s" "$add_item__value"
  else
    printf "%s%s%s" "$add_item__target" "$add_item__separator" "$add_item__value"
  fi
}

_has_item() {
  has_item__list="$1"
  has_item__item="$2"

  for has_item__found_item  in $has_item__list; do
    if test "$has_item__found_item" = "$has_item__item"; then
      return 0
    fi
  done
  return 1
}

_escape_special() {
  printf "%s" "$@" |
    sed 's/%/%25/g' |
    sed 's/\\/%5C/g' |
    sed 's/:/%3A/g' |
    sed 's/;/%3B/g' |
    sed 's/|/%7C/g' |
    sed "s/'/%27/g" |
    sed 's/"/%22/g' |
    sed 's/ /%20/g' |
    awk 'ORS="%0A"' |
    sed 's/%0A$//g'
}

_unescape_special() {
  printf "%s" "$@" |
    sed 's/%0A/\n/g' |
    sed 's/%20/ /g' |
    sed 's/%22/"/g' |
    sed "s/%27/'/g" |
    sed 's/%7C/|/g' |
    sed 's/%3B/;/g' |
    sed 's/%3A/:/g' |
    sed 's/%5C/\\/g' |
    sed 's/%25/%/g'
}

_FIELDS=""
field () {
  field__name="$1"
	shift
  if test "$#" -eq 0; then
    printf ""
    return
  fi
  field__output="$field__name"
	for field__value in "$@"
	do
    field__output="$field__output:$(_escape_special "$field__value")"
	done

  _FIELDS="$(_add_item "$_FIELDS" ";" "$field__output")"
}

reset_object() {
  _FIELDS=""
}

make_object() {
  printf "%s" "$_FIELDS"
}

_map_field() {
	map_field__object="$1"
  map_field__callback="$2"
	for map_field__field in $(printf "%s" "$map_field__object" | awk 'BEGIN{RS=";"}{print $0}')
	do
    map_field__field_name="$(printf "%s" "$map_field__field" | cut -d':' -f1)"
    map_field__field_value="$(printf "%s" "$map_field__field" | cut -d':' -f2-)"
    if ! "$map_field__callback" "$map_field__field_name" "$map_field__field_value"; then
      return 1
    fi
	done
}

has_field() {
	has_field__object="$1"
	has_field__name="$2"

  _has_field() {
    if test "$1" = "$has_field__name"; then
      return 1
    fi
  }
  if ! _map_field "$has_field__object" "_has_field"; then
    return 0
  else
    return 1
  fi
}

parse_field() {
	parse_field__object="$1"
	parse_field__name="$2"

  _parse_field() {
    if test "$1" = "$parse_field__name"; then
      printf "%s" "$2"
      return 1
    fi
  }
  _unescape_special "$(_map_field "$parse_field__object" "_parse_field")"
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
OSKIND=""
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
        # shellcheck disable=SC2034
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
        main__name=$(printf "%s" "$1" | cut -c4-)
        _SKIPPED=$(_add_item "$_SKIPPED" " " "$main__name")
        ;;
      *)
        # Add package to the indicated list
        main__name="$1"
        _INDICATED=$(_add_item "$_INDICATED" " " "$main__name")
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
  print 22 "  no-packages" "Skip package installations, including a custom and a Docker one"
  print 22 "  no-docker" "Skip Docker based installations"
  print 22 "  no-custom" "Skip custom installations"
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
  has_skip__component="$1"
  _has_item "$_SKIPPED" "$has_skip__component"
}

_has_indicate() {
  has_indicate__component="$1"
  _has_item "$_INDICATED" "$has_indicate__component"
}

_check_sudo() {
  if test -n "$(command -v sudo)"; then
    return
  fi

  error "insufficient permission, no 'sudo' available"
}

_try_git() {
  if test -n "$(command -v git)"; then
    return
  fi
  if test "$DUMB" -eq 1; then
    error "command \"git\" is required"
    quit 1
  fi

  if test "$OSKIND" = "alpine"; then
    step "Installing git..."
    cmd apk add git
  elif test "$OSKIND" = "debian"; then
    step "Installing git..."
    sudo_cmd apt install -y git
  elif test "$OSKIND" = "macos" -a -n "$(command -v "brew")"; then
    step "Installing git..."
    cmd brew install git
  else
    error "command \"git\" is required"
    quit 1
  fi
}

# shellcheck disable=SC2120
_try_run_install() {
  try_run_install__skip_update=0
  if test "$LOCAL_COPY" -eq 0; then
    if test "$RUN_LOCAL" -ge 1; then
      error "local copy of dotfiles is not found at $HOME/$DOTFILES"
      quit 1
    fi

    try_run_install__clone_flags=""
    if test -n "$CLONE_REPO_BRANCH"; then
      try_run_install__clone_flags="--branch $CLONE_REPO_BRANCH"
    fi
    if test "$VERBOSE" -le 1; then
      clone "$CLONE_REPO" "$HOME/$DOTFILES" "dotfiles into $HOME/$DOTFILES" "$try_run_install__clone_flags"
    else
      clone "$CLONE_REPO" "$HOME/$DOTFILES" "dotfiles" "$try_run_install__clone_flags"
    fi
    try_run_install__skip_update=1
  fi

  cd "$HOME/$DOTFILES"

  # Try to update when install remotely, but not the first clone
  if test "$try_run_install__skip_update" -eq 0 -a "$REMOTE_INSTALL" -eq 1 -a "$RUN_LOCAL" -lt 2; then
    _try_git
    step "Updating dotfiles to latest version..."
    cmd git reset --hard
    cmd git fetch
    cmd git pull --rebase
  fi

  # Run local script when install remotely
  if test "$REMOTE_INSTALL" -eq 1; then
    step "Executing local script..."
    # shellcheck disable=SC2086
    sh "$HOME/$DOTFILES/install.sh" $FLAGS
    quit
  fi

  if test -n "$PRINT_MODE"; then
    if ! test -d "$HOME/$DOTFILES/$PRINT_MODE"; then
      print "No $PRINT_MODE available"
      quit
    fi
    print "Available $PRINT_MODE:"
    for try_run_install__file_path in "$HOME/$DOTFILES/$PRINT_MODE"/*.sh; do
      name=$(basename "$try_run_install__file_path")
      name=${name%.sh}
      print "  - $name"
    done
    quit
  fi

  # testing basic requirements
  try_run_install__commands="awk basename sed"
  for try_run_install__command in $try_run_install__commands; do
    if ! test -n "$(command -v "$try_run_install__command")"; then
      error "'$try_run_install__command' is required, but not found"
      _HALT=1
    fi
  done

  if test $_HALT -eq 1; then
    quit 1
  fi

  step "Ready"
  try_run_install__system_script="$HOME/$DOTFILES/sytems/$OS.sh"
  if ! test -f "$try_run_install__system_script"; then
    try_run_install__system_script="$HOME/$DOTFILES/systems/$OSKIND.sh"
  fi
  if ! test -f "$try_run_install__system_script"; then
    error "\"$OS\" is not supported"
    quit 1
  fi

  if has_flag wsl; then
    info "Detected running on WSL..."
  fi
  if has_flag "apple-silicon"; then
    info "Detected running on Apple Silicon..."
  fi

  # shellcheck disable=SC1090
  . "$try_run_install__system_script"
  step "Setting up installation process..."
  setup
  step "Gathering components..."

  # run packages
  _RUNNING_TYPE="package"
  if ! _has_skip packages || test -n "$_INDICATED"; then
    for try_run_install__package_path in "$HOME/$DOTFILES/packages"/*.sh; do
      try_run_install__package=$(basename "$try_run_install__package_path")
      try_run_install__package=${try_run_install__package%.sh}

      # Skip requested packages
      if (_has_skip packages || _has_skip "$try_run_install__package") && ! _has_indicate "$try_run_install__package"; then
        continue
      fi

      # Package could be loaded from the dependency list
      if has_package "$try_run_install__package"; then
        continue
      fi

      _RUNNING="$try_run_install__package"
      _FULFILLED=""
      # Add package to the loaded list (prevent dependency cycle)
      _LOADED=$(_add_item "$_LOADED" " " "$_RUNNING")
      # shellcheck disable=SC1090
      . "$try_run_install__package_path"

      # Remove optional packages from the loaded list
      if test "$_FULFILLED" = "optional"; then
        try_run_install__new_loaded=""
        for try_run_install__loaded_package in $(_split "$_LOADED"); do
          if test "$try_run_install__loaded_package" = "$_RUNNING"; then
            continue
          fi
          try_run_install__new_loaded=$(_add_item "$try_run_install__new_loaded" " " "$try_run_install__loaded_package")
        done
        _LOADED="$try_run_install__new_loaded"
      fi
    done
  fi

  # running setup preparation
  _RUNNING_TYPE="setup"
  if ! _has_skip setup || test -n "$_INDICATED"; then
    for try_run_install__setup_path in "$HOME/$DOTFILES/setup"/*.sh; do
      try_run_install__setup=$(basename "$try_run_install__setup_path")
      try_run_install__setup=${try_run_install__setup%.sh}

      # Skip requested setups
      if (_has_skip setup || _has_skip "$try_run_install__setup") && ! _has_indicate "$try_run_install__setup"; then
        continue
      fi

      _RUNNING="$try_run_install__setup"
      _FULFILLED=""
      # shellcheck disable=SC1090
      . "$try_run_install__setup_path"
    done
  fi

  if test $_HALT -eq 1; then
    quit 1
  fi

  # if nothing is getting done
  if test -z "$_PACKAGES" -a -z "$_DOCKER" -a -z "$_CUSTOM" -a -z "$_SETUP" && _has_skip update; then
    info "Nothing to perform, exiting..."
    quit 0
  fi

  if test -n "$_PACKAGES"; then
    print "$esc_green==>$esc_reset The following packages will be installed:"
    eval "set -- $_PACKAGES"
    for try_run_install__package in "$@"; do
      try_run_install__manager_name="$(parse_field "$try_run_install__package" manager_name)"
      try_run_install__package_name="$(parse_field "$try_run_install__package" package_name)"
      if test -z "$try_run_install__manager_name"; then
        try_run_install__manager_name="$(parse_field "$try_run_install__package" manager)"
      fi

      if test -z "$try_run_install__package_name"; then
        try_run_install__package_name="$(parse_field "$try_run_install__package" package)"
      fi

      if test -n "$try_run_install__manager_name"; then
        try_run_install__manager_name=" ${esc_blue}via$esc_reset $try_run_install__manager_name"
      fi

      print "  $esc_blue-$esc_reset $try_run_install__package_name$try_run_install__manager_name"
    done
  fi
  if test -n "$_DOCKER"; then
    print "$esc_green==>$esc_reset The following Docker buildings will be run:"
    eval "set -- $_DOCKER"
    for try_run_install__package in "$@"; do
      try_run_install__package_name="$(parse_field "$try_run_install__package" package_name)"

      if test -z "$try_run_install__package_name"; then
        try_run_install__package_name="$(parse_field "$try_run_install__package" package)"
      fi

      print "  $esc_blue-$esc_reset $try_run_install__package_name"
    done
  fi
  if test -n "$_CUSTOM"; then
    print "$esc_green==>$esc_reset The following installations will be run:"
    eval "set -- $_CUSTOM"
    for try_run_install__fn in "$@"; do
      try_run_install__package_name="$(parse_field "$try_run_install__fn" package_name)"

      if test -z "$try_run_install__package_name"; then
        try_run_install__package_name="$(parse_field "$try_run_install__fn" fn)"
      fi

      print "  $esc_blue-$esc_reset $try_run_install__package_name"
    done
  fi
  if test -n "$_SETUP"; then
    print "$esc_green==>$esc_reset The following setups will be run:"
    eval "set -- $_SETUP"
    for try_run_install__fn in "$@"; do
      try_run_install__setup_name="$(parse_field "$try_run_install__fn" display_name)"

      if test -z "$try_run_install__setup_name"; then
        try_run_install__setup_name="$(parse_field "$try_run_install__fn" fn)"
      fi

      print "  $esc_blue-$esc_reset $try_run_install__setup_name"
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
    printf "%s==>%s Perform the installation? [y/N] " "$esc_yellow" "$esc_reset"
    while test !; do
      if ! read -r try_run_install__choice; then
        quit 1
      fi
      if test "$try_run_install__choice" = "y" -o "$try_run_install__choice" = "Y"; then
        break
      fi
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
    eval "set -- $_PACKAGES"
    install_packages "$@"
  fi

  # run custom installations
  if test -n "$_CUSTOM"; then
    step "Performing custom installations..."
    eval "set -- $_CUSTOM"
    for try_run_install__custom in "$@"; do
      try_run_install__fn="$(parse_field "$try_run_install__custom" fn)"
      "$try_run_install__fn"
    done
  fi

  # run setups
  if test -n "$_SETUP"; then
    step "Running setups..."
    eval "set -- $_SETUP"
    for try_run_install__setup in "$@"; do
      try_run_install__fn="$(parse_field "$try_run_install__setup" fn)"
      "$try_run_install__fn"
    done
  fi

  try_run_install__deps_path="$(deps)"
  if test -d "$try_run_install__deps_path" -a "$KEEP_FILES" -eq 0; then
    step "Cleaning up downloaded files..."
    cmd rm -rf "$try_run_install__deps_path"
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
  add_flag__flag="$1"
  _INTERNAL_STATE=$(_add_item "$_INTERNAL_STATE" " " "$add_flag__flag")
}

has_flag() {
  has_flag__flag="$1"
  _has_item "$_INTERNAL_STATE" "$has_flag__flag"
}

# shellcheck disable=SC2120
deps() {
  if test -n "$1"; then
    if ! test -d "$HOME/$DOTFILES/.deps"; then
      mkdir -p "$HOME/$DOTFILES/.deps"
    fi

    printf "%s/%s/.deps/%s" "$HOME" "$DOTFILES" "$1"
  else
    printf "%s/%s/.deps" "$HOME" "$DOTFILES"
  fi
}

quiet_cmd() {
  _QUIET_CMD="$*"
}

quiet_flags() {
  _QUIET_FLAGS="$*"
}

verbose_cmd() {
  _VERBOSE_CMD="$*"
}

verbose_flags() {
  _VERBOSE_FLAGS="$*"
}

sudo_cmd() {
  if test "$(whoami)" = "root"; then
    # shellcheck disable=SC2068
    cmd $@
  else
    _check_sudo
    if test -n "$_VERBOSE_CMD"; then
      _VERBOSE_CMD="sudo $_VERBOSE_CMD"
    fi
    if test -n "$_QUIET_FLAGS"; then
      _QUIET_FLAGS="sudo $_QUIET_FLAGS"
    fi
    # shellcheck disable=SC2068
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
  full_clone__repo="$1"
  full_clone__dir_name="$2"
  full_clone__name="$3"
  shift
  if test -n "$full_clone__dir_name"; then
    shift
  fi
  _try_git
  if test -n "$full_clone__name"; then
    shift
    step "Cloning $full_clone__name..."
  fi

  # shellcheck disable=SC2068
  cmd git clone $@ "$full_clone__repo" "$full_clone__dir_name"
}

clone() {
  clone__repo="$1"
  clone__dir_name="$2"
  clone__name="$3"
  shift
  if test -n "$clone__dir_name"; then
    shift
  fi
  _try_git
  if test -n "$clone__name"; then
    shift
    step "Cloning $clone__name..."
  fi

  # shellcheck disable=SC2068
  cmd git clone --shallow-submodules --depth 1 $@ "$clone__repo" "$clone__dir_name"
}

# has_cmd <command>
has_cmd() {
  has_cmd__cmd="$1"
  test -n "$(command -v "$has_cmd__cmd")"
}

# has_package <package>
has_package() {
  has_package__package="$1"
  _has_item "$_LOADED" "$has_package__package"
}

add_post_install_message() {
  add_post_install_message__message="$1"
  _POST_INSTALL_MSGS=$(_add_item "$_POST_INSTALL_MSGS" "\n  - " "$add_post_install_message__message")
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

  depends__package="$1"
  if has_package "$depends__package"; then
    return
  fi

  _FULFILLED="fulfilled"
}

# Install package regardless of skipped components
# require <package>
require() {
  if test -n "$_FULFILLED"; then
    return
  fi

  require__package="$1"

  # Depends on itself
  if test "$_RUNNING" = "$require__package"; then
    return
  fi

  if has_package "$require__package"; then
    return
  fi

  # Dependency not found
  if ! test -f "$HOME/$DOTFILES/packages/$require__package.sh"; then
    error "$_RUNNING_TYPE \"$_RUNNING\" is depends on \"$require__package\""
    _HALT=1
    return
  fi

  require__old_running_type="$_RUNNING_TYPE"
  require__old_running="$_RUNNING"
  require__old_fulfilled="$_FULFILLED"
  _RUNNING_TYPE="package"
  _RUNNING="$require__package"
  _SKIP_OPTIONAL="1"
  _FULFILLED=""
  # Add package to the loaded list (prevent dependency cycle)
  _LOADED=$(_add_item "$_LOADED" " " "$_RUNNING")

  # shellcheck disable=SC1090
  . "$HOME/$DOTFILES/packages/$require__package.sh"

  _RUNNING_TYPE="$require__old_running_type"
  _RUNNING="$require__old_running"
  _SKIP_OPTIONAL=""
  _FULFILLED="$require__old_fulfilled"
}

# Add package into installation list
# add_package [display name]
# Fields:
#   + manager      : string
#   - manager_name : string
#   + package      : string
#   - package_name : string
add_package() {
  if test "$_FULFILLED" = "optional"; then
    reset_object
    return
  fi

  field package_name "$1"
  _PACKAGES="$(_add_to_list "$_PACKAGES" "$(make_object)")"
  reset_object

  _FULFILLED="fulfilled"
}

# Add custom function into installation list if no valid setup available
# use_custom <function> [display name]
# Fields:
#   + fn           : function
#   - package_name : string
use_custom() {
  if _has_skip custom; then
    return
  fi
  if test -n "$_FULFILLED"; then
    reset_object
    return
  fi

  if test "$_FULFILLED" = "optional"; then
    reset_object
    return
  fi

  field fn "$1"
  if test -n "$2"; then
    field package_name "$2"
  else
    field package_name "$_RUNNING"
  fi
  _CUSTOM="$(_add_to_list "$_CUSTOM" "$(make_object)")"
  reset_object
  _FULFILLED="fulfilled"
}

# Add docker build into installation list if no valid setup available
# use_docker_build [display name]
# Fields:
#   - package_name : string
use_docker_build() {
  if _has_skip docker; then
    return
  fi
  use_docker_build__package="$_RUNNING"
  if test -n "$_FULFILLED"; then
    reset_object
    return
  fi

  use_docker_build__dockerfile="$HOME/$DOTFILES/docker/$use_docker_build__package/Dockerfile.$OS"
  if ! test -f "$use_docker_build__dockerfile"; then
    use_docker_build__dockerfile="$HOME/$DOTFILES/docker/$use_docker_build__package/Dockerfile.$OSKIND"
  fi
  if ! test -f "$use_docker_build__dockerfile"; then
    warn "Docker build for package \"$use_docker_build__package\" is not available on $OS"
    reset_object
    return
  fi

  if test -z "$_DOCKER"; then
    require 'docker'
  fi

  field package "$use_docker_build__package"
  field package_name "$1"
  _DOCKER="$(_add_to_list "$_DOCKER" "$(make_object)")"
  reset_object

  _FULFILLED="fulfilled"
}

# Add custom function into setup list if no valid setup available
# add_setup <function> [display name]
# Fields:
#   + fn           : function
#   - display_name : string
add_setup() {
  if test -n "$_FULFILLED"; then
    reset_object
    return
  fi

  field fn "$1"
  if test -n "$2"; then
    field display_name "$2"
  else
    field display_name "$_RUNNING"
  fi
  _SETUP="$(_add_to_list "$_SETUP" "$(make_object)")"
  reset_object
}

_main "$@"
