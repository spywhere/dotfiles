#!/bin/sh

set -e

########################
# Internal Information #
########################

REPO_NAME="spywhere/dotfiles"
CLONE_REPO="https://github.com/$REPO_NAME"
if test -z "$CLONE_REPO_BRANCH"; then
  CLONE_REPO_BRANCH="new-installer"
fi
SYSTEM_FILES="https://raw.githubusercontent.com/$REPO_NAME/$CLONE_REPO_BRANCH/systems/%s.sh"

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
HAS_LOCAL_COPY=0
if test -d "$HOME/$DOTFILES"; then
  HAS_LOCAL_COPY=1
fi

inline_support=0
esc_reset="" # reset
esc_blue="" # indicate process
esc_green="" # indicate options and information
esc_yellow="" # indicate warnings
esc_red="" # indicate errors

if test -n "$TERM" -a -n "$(command -v tput)" && test "$(tput colors)" -ge 8 && test -n "$(command -v tty)" && tty -s; then
  if test -n "$(command -v wc)"; then
    inline_support=1
  fi
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

_INLINING=0
print_inline() {
  if test "$VERBOSE" -eq 0 -o "$inline_support" -eq 0; then
    return
  fi

  printf "%s%${_INLINING}s\r" "$1" ""
  _INLINING="$(printf "%s" "$1" | wc -c)"
}

print() {
  if test "$VERBOSE" -eq 0; then
    return
  fi

  if test "$_INLINING" -gt 0; then
    printf "\r"
    _INLINING=0
  fi
  force_print "$@"
}

error() {
  if test -z "$@"; then
    >&2 printf "\n"
    return
  fi
  printf "$esc_red==> ERROR$esc_reset: %s\n" "$*" >&2
}

warn() {
  if test -z "$@"; then
    print
    return
  fi
  print "$esc_yellow==> WARN$esc_reset: $*"
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
        FORCE_INSTALL=1 # TODO: Currently no force install support
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
  print
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
  print_bool 20 "Has Local Copy" "$HAS_LOCAL_COPY" ": "
}

#################
# Main Commands #
#################

_download_system_file() {
  if test "$(curl --create-dirs -fsL "$1" -o "$2" -w "%{http_code}")" -eq 200; then
    return 0
  fi
  return 1
}

_system_loaded=0
_try_load_system() {
  if test "$_system_loaded" -eq 1; then
    return 0
  fi
  try_load_system__base_system="$HOME/$DOTFILES/systems/base.sh"
  try_load_system__target_system="$HOME/$DOTFILES/systems/$OS.sh"
  if ! test -f "$try_load_system__target_system"; then
    try_load_system__target_system="$HOME/$DOTFILES/systems/$OSKIND.sh"
  fi

  try_load_system__system_deps="$(pwd)/$DOTFILES.deps"
  if ! test -f "$try_load_system__base_system"; then
    if ! test -n "$(command -v curl)"; then
      return 1
    fi

    system_url="$(printf "$SYSTEM_FILES" "base")"

    if test "$OS" = "$OSKIND"; then
      step "Downloading system files for $OS..."
    else
      step "Downloading system files for $OS/$OSKIND..."
    fi

    try_load_system__base_system="$try_load_system__system_deps/base"
    if ! _download_system_file "$system_url" "$try_load_system__base_system"; then
      error "Failed to download system files"
      quit 1
    fi

    system_url="$(printf "$SYSTEM_FILES" "$OS")"
    try_load_system__target_system="$try_load_system__system_deps/$OS"
    if ! _download_system_file "$system_url" "$try_load_system__target_system"; then
      warn "$OS is not natively supported, trying $OSKIND..."

      system_url="$(printf "$SYSTEM_FILES" "$OSKIND")"
      try_load_system__target_system="$try_load_system__system_deps/$OSKIND"
      _download_system_file "$system_url" "$try_load_system__target_system"
    fi
  fi

  if ! test -f "$try_load_system__target_system"; then
    error "\"$OS\" is not supported"
    quit 1
  fi

  . "$try_load_system__base_system"
  . "$try_load_system__target_system"

  if test -d "$try_load_system__system_deps"; then
    rm -rf "$try_load_system__system_deps"
  fi

  _system_loaded=1
  return 0
}

_try_git() {
  if test -n "$(command -v git)"; then
    return
  fi

  if test "$DUMB" -eq 1; then
    error "command \"git\" is required"
    quit 1
  fi

  if ! _try_load_system || ! install_git; then
    warn "System does not provide a git installation method, trying a builtin method..."

    # builtin fallbacks, however these platforms will not be covered
    #   - debian might need sudo permission
    #   - macos need brew / developer tools
    if test "$OSKIND" = "alpine"; then
      step "Installing git..."
      cmd apk add git
    else
      error "command \"git\" is required"
      quit 1
    fi
  fi
}

# shellcheck disable=SC2120
_try_run_install() {
  try_run_install__skip_update=0
  if test "$HAS_LOCAL_COPY" -eq 0; then
    if test "$RUN_LOCAL" -ge 1; then
      error "local copy of dotfiles is not found at $HOME/$DOTFILES"
      quit 1
    fi

    if test "$VERBOSE" -le 1; then
      clone "$CLONE_REPO" "$HOME/$DOTFILES" "dotfiles into $HOME/$DOTFILES" --branch "$CLONE_REPO_BRANCH"
    else
      clone "$CLONE_REPO" "$HOME/$DOTFILES" "dotfiles" --branch "$CLONE_REPO_BRANCH"
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

  if ! _try_load_system; then
    error "command \"curl\" is required"
    quit 1
  fi

  step "Ready"

  # Load libs
  for try_run_install__lib_path in "$HOME/$DOTFILES/lib"/*.sh; do
    . "$try_run_install__lib_path"
  done
  # Load processes
  for try_run_install__lib_path in "$HOME/$DOTFILES/lib/process"/*.sh; do
    . "$try_run_install__lib_path"
  done

  if has_flag wsl; then
    info "Detected running on WSL..."
  fi
  if has_flag "apple-silicon"; then
    info "Detected running on Apple Silicon..."
  fi

  step "Setting up installation process..."
  setup
  step "Gathering components..."

  # run packages
  _RUNNING_TYPE="package"
  _prepare_packages

  # running setup preparation
  _RUNNING_TYPE="setup"
  _prepare_setup

  if test $_HALT -eq 1; then
    quit 1
  fi

  # if nothing is getting done
  if test -z "$_PACKAGES" -a -z "$_DOCKER" -a -z "$_CUSTOM" -a -z "$_SETUP" && _has_skip update; then
    info "Nothing to perform, exiting..."
    quit 0
  fi

  _summarize_packages
  _summarize_docker
  _summarize_custom
  _summarize_setup
  _summarize_system_update

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

  _run_system_update
  _run_packages
  _run_docker
  _run_custom
  _run_setup

  try_run_install__deps_path="$(deps)"
  if test -d "$try_run_install__deps_path" -a "$KEEP_FILES" -eq 0; then
    step "Cleaning up downloaded files..."
    cmd rm -rf "$try_run_install__deps_path"
  fi
  step "Done!"
  if test -n "$_POST_INSTALL_MSGS"; then
    print "NOTE: Don't forget to..."
    eval "set -- $_POST_INSTALL_MSGS"
    for try_run_install__message in "$@"; do
      print "  - $try_run_install__message"
    done
  fi
}

#############
# Main APIs #
#############

add_flag() {
  add_flag__flag="$1"
  _INTERNAL_STATE=$(_add_item "$_INTERNAL_STATE" " " "$add_flag__flag")
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

_main "$@"
