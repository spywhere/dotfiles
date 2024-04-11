#!/bin/sh

set -e

########################
# Internal Information #
########################

INSTALLER_REPO_NAME="spywhere/dotfiles"
if test -z "$INSTALLER_REPO_URL"; then
  INSTALLER_REPO_URL="https://github.com/$INSTALLER_REPO_NAME"
fi
if test -z "$INSTALLER_REPO_BRANCH"; then
  INSTALLER_REPO_BRANCH="installer"
fi

if test -z "$REPO_URL" -a -n "$REPO_NAME"; then
  REPO_URL="https://github.com/$REPO_NAME"
fi

if test -z "$SYSTEM_FILES"; then
  SYSTEM_FILES="https://raw.githubusercontent.com/$INSTALLER_REPO_NAME/$INSTALLER_REPO_BRANCH/systems/%s.sh"
fi
TEMP_DIR="$(mktemp -d)"

CURRENT_DIR="$(pwd)"
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

# Figure out if we already have a local installer
HAS_INSTALLER=0
if test -d "$INSTALLER_DIR"; then
  HAS_INSTALLER=1
elif test -z "$INSTALLER_DIR"; then
  INSTALLER_DIR="$(mktemp -d)"
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

if test -t 1 && test -n "$TERM" -a -n "$(command -v tput)" && test "$(tput colors)" -ge 8 && test -n "$(command -v tty)"; then
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

      if test -n "$(command -v raspi-config)"; then
        # Raspberry Pi OS 64bit would not update its /etc/os-release
        #   so we have to resort another way to detect Raspberry Pi OS
        # Ref: https://github.com/raspberrypi/Raspberry-Pi-OS-64bit/issues/6
        OSNAME="Raspberry Pi OS"
        OS="raspios"
        # OS kind need to be hard coded
        #   - 32 bit: OSKIND would be 'debian', OS would be 'raspbian'
        #   - 64 bit: OSKIND would not set, as OS would be 'debian'
        OSKIND="debian"
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
CONFIRMATION=1
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
PROFILE=""

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
_SETUP="" # keep a list of custom function for setups
_INTERNAL_STATE="" # keep a list of internal flags and states

_QUIET_CMD="" # an alternative command for suppressing output
_QUIET_FLAGS="" # an alternative flag for suppressing output
_VERBOSE_CMD="" # an alternative command for producing more output
_VERBOSE_FLAGS="" # an alternative flag for producing more output
_POST_INSTALL_MSGS="" # keep a list of post installation messages

_main() {
  _detect_os

  # Config flags
  while test "$1" != ""; do
    PARAM="$(printf "%s" "$1" | sed 's/=.*//g')"
    VALUE="$(printf "%s" "$1" | sed 's/^[^=]*=//g')"
    EQUAL_SIGN="$(printf "%s" "$1" | sed 's/[^=]//g')"
    case $PARAM in
      -h | --help)
        _usage
        quit
        ;;
      -hh)
        _usage all
        quit
        ;;
      -i | --info)
        _info
        quit
        ;;
      -l | --local)
        RUN_LOCAL=1
        ;;
      -y | --yes)
        CONFIRMATION=0
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
      --profile)
        if test -z "$EQUAL_SIGN" || test -z "$VALUE"; then
          error "missing profile name"
          quit 1
        fi
        PROFILE="$VALUE"
        ;;
      -*)
        error "unknown flag \"$1\""
        quit 1
        ;;
      *)
        if test -n "$REPO_URL"; then
          break
        else
          GIT_REPO_URL="$(printf "%s" "$1" | cut -d'@' -f1)"
          GIT_REPO_BRANCH="$(printf "%s" "$1" | cut -d'@' -f2-)"
          if test "$GIT_REPO_BRANCH" = "$1"; then
            GIT_REPO_BRANCH=""
          fi
          GIT_REPO_URL_PROTO="$(printf "%s" "$GIT_REPO_URL" | cut -d'/' -f1)"

          if test "$GIT_REPO_URL_PROTO" != "http:" -a "$GIT_REPO_URL_PROTO" != "https:" -a "$GIT_REPO_URL_PROTO" != "ssh:"; then
            GIT_REPO_URL_THIRD="$(printf "%s" "$GIT_REPO_URL" | cut -d'/' -f3)"
            if test "$GIT_REPO_URL_THIRD" = "$GIT_REPO_URL" -o -n "$GIT_REPO_URL_THIRD"; then
              error "repository format is not in a 'user/repo' format, got  '$GIT_REPO_URL' instead"
              quit 1
            fi

            GIT_REPO_URL="https://github.com/$GIT_REPO_URL"
          fi

          REPO_URL="$GIT_REPO_URL"
          if test -n "$GIT_REPO_BRANCH"; then
            REPO_BRANCH="$GIT_REPO_BRANCH"
          fi
        fi
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
      -*)
        error "unexpected flag \"$1\""
        quit 1
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
  print "Usage: $0 [user/repo] [flag ...] [package/setup ...]"
  print
  print "A cross-platform, modular dotfiles installer"
  print
  print "Environment Variables:"
  print 25 "  DOTFILES" "Target directory to stored the setup (default to '$DOTFILES')"
  print
  print 25 "  REPO_URL" "Git URL to pull the setup from"
  print 25 "  REPO_BRANCH" "Git branch to pull the setup from (default to default branch)"
  print 25 "  REPO_NAME" "Repository short hand for using GitHub URL as a Git URL"
  print
  print "  ** Do not change the following variables unless you know what you are doing **"
  print 25 "  INSTALLER_REPO_URL" "Git URL to pull the installer from (default to '$INSTALLER_REPO_URL')"
  print 25 "  INSTALLER_REPO_BRANCH" "Git branch to pull the installer from (default to '$INSTALLER_REPO_BRANCH')"
  print 25 "  INSTALLER_DIR" "Target directory to stored the installer (default to unique temporary directory)"
  print 25 "  SYSTEM_FILES" "Template string to direct URL to requested system files"
  print
  print "Flags:"
  print 25 "  -h, --help" "Show this help message"
  print 25 "  -i, --info" "Print out the setup environment information"
  print 25 "  -l, --local" "Use the setup from the local copy"
  print 25 "  -y, --yes" "Do not ask for confirmation before performing installation"
  print 25 "  -d, --dumb" "Do not attempt to install dependencies automatically"
  print 25 "  -k, --keep" "Keep downloaded artifacts"
  print 25 "  -f, --force" "Force reinstall any installed packages when possible"
  print 25 "  -q, --quiet" "Suppress output messages when possible"
  print 25 "  -v, --verbose" "Produce command output messages when possible (use -vv for more verbosity)"
  print 25 "  -p, --packages" "Print out available packages"
  print 25 "  -s, --setup" "Print out available setup"
  print 25 "  --profile=<profile>" "Specify the setup profile"
  print
  print "To skip a specific package or setup, add a 'no-' prefix to the package or setup name itself."
  print
  print "  Example: $0 no-asdf no-zsh"
  print "  Skip ZSH and ASDF installation"
  print
  print "To include a specific package or setup, simply add a package or setup name after exclusions."
  print
  print "  Example: $0 no-package asdf zsh"
  print "  Skip package installation, but install ASDF and ZSH"
  print
  print "To skip system update/upgrade, package installation or setups, use"
  print 25 "  no-update" "Skip system update and system upgrade"
  print 25 "  no-upgrade" "Only perform a system update but not system upgrade"
  print 25 "  no-package" "Skip package installations, including a custom one"
  print 25 "  no-custom" "Skip custom installations"
  print 25 "  no-setup" "Skip setups"
  print
  print "Note:"
  print "  - Package name is indicated by the file name under 'packages' or 'setup' directory"
  print "  - Packages in the inclusion list will be installed regardless of existing installation"
  print "  - If the setup require particular packages, those packages will be automatically installed"
  print

  if test -z "$1"; then
    print "Some systems might have additional installation flags, try running with"
    print 23 "  -hh" "Show this help message with additional flags for this system"
  elif test "$1" = "all"; then
    if _try_load_system; then
      system_usage
    else
      warn "System files cannot be downloaded, some options might be available"
    fi
  fi
}

_info() {
  VERBOSE=1
  print      20 "Execution" ": $0"
  print      20 "Operating System" ": $OSNAME$OSARCH$PKGMGR"
  print_bool 20 "Has Installer" "$HAS_INSTALLER" ": "
  print      20 "Home Directory" ": $HOME"
  print      20 "Working Directory" ": $CURRENT_DIR"
  print      20 "Installer Target" ": $INSTALLER_DIR"
  if test -n "$REPO_NAME"; then
    if test -n "$REPO_BRANCH"; then
      print      20 ".dots Target" ": $DOTFILES -> $HOME/$DOTFILES ($REPO_NAME@$REPO_BRANCH)"
    else
      print      20 ".dots Target" ": $DOTFILES -> $HOME/$DOTFILES ($REPO_NAME)"
    fi
  else
    print      20 ".dots Target" ": $DOTFILES -> $HOME/$DOTFILES (no repository defined)"
  fi
  print_bool 20 "Remote Install" "$REMOTE_INSTALL" ": "
  print_bool 20 "Has Local Copy" "$HAS_LOCAL_COPY" ": "
}

#################
# Main Commands #
#################

_get_system_file() {
  # shellcheck disable=SC2059
  get_system_file__system_file="$(printf "$1" "$OS")"

  if test -f "$get_system_file__system_file" -o "$OS" = "$OSKIND"; then
    printf "%s" "$get_system_file__system_file";
    return 0
  fi

  # shellcheck disable=SC2059
  printf "$1" "$OSKIND"
}

_system_loaded=0
_try_load_system() {
  if test "$_system_loaded" -eq 1; then
    return 0
  fi
  try_load_system__base_system="$INSTALLER_DIR/systems/base.sh"
  try_load_system__target_system="$(_get_system_file "$INSTALLER_DIR/systems/%s.sh")"

  if test "$REMOTE_INSTALL" -eq 0 -a -f "$0" && test -f "$(dirname "$0")/systems/base.sh"; then
    try_load_system__base_system="$(dirname "$0")/systems/base.sh"
    try_load_system__target_system="$(_get_system_file "$(dirname "$0")/systems/%s.sh")"
  fi

  try_load_system__system_deps="$TEMP_DIR"
  if ! test -f "$try_load_system__base_system"; then
    if ! test -n "$(command -v curl)"; then
      return 1
    fi

    # shellcheck disable=SC2059
    system_url="$(printf "$SYSTEM_FILES" "base")"

    if test "$OS" = "$OSKIND"; then
      step "Downloading system files for $OS..."
    else
      step "Downloading system files for $OS/$OSKIND..."
    fi

    try_load_system__base_system="$try_load_system__system_deps/base"
    if ! download_file "$system_url" "$try_load_system__base_system"; then
      error "failed to download system files"
      quit 1
    fi

    # shellcheck disable=SC2059
    system_url="$(printf "$SYSTEM_FILES" "$OS")"
    try_load_system__target_system="$try_load_system__system_deps/$OS"
    if ! download_file "$system_url" "$try_load_system__target_system"; then
      warn "$OS is not natively supported, trying $OSKIND..."

      # shellcheck disable=SC2059
      system_url="$(printf "$SYSTEM_FILES" "$OSKIND")"
      try_load_system__target_system="$try_load_system__system_deps/$OSKIND"
      download_file "$system_url" "$try_load_system__target_system"
    fi
  fi

  if ! test -f "$try_load_system__target_system"; then
    error "\"$OS\" is not supported"
    quit 1
  fi

  . "$try_load_system__base_system"
  . "$try_load_system__target_system"

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

  step "Installing git..."
  if ! _try_load_system || ! install_git; then
    warn "System does not provide a git installation method, trying a builtin method..."

    if test "$OSKIND" = "debian"; then
      DEBIAN_FRONTEND=noninteractive sudo_cmd apt update -y
      DEBIAN_FRONTEND=noninteractive sudo_cmd apt install -y git
    elif test "$OSKIND" = "macos" -a -n "$(command -v "brew")"; then
      cmd brew install git
    else
      if test "$_system_loaded" -eq 0; then
        error "command \"git\" or \"curl\" is required"
      else
        error "command \"git\" is required"
      fi
      quit 1
    fi
  fi
}

# shellcheck disable=SC2120
_try_run_install() {
  if test "$HAS_INSTALLER" -eq 0; then
    clone "$INSTALLER_REPO_URL" "$INSTALLER_DIR" "installer into $INSTALLER_DIR" --branch "$INSTALLER_REPO_BRANCH"
  fi

  # Run local script when install remotely
  if test "$REMOTE_INSTALL" -eq 1; then
    step "Executing local script..."

    # shellcheck disable=SC2086,SC2097,SC2098
    INSTALLER_DIR="$INSTALLER_DIR" sh "$INSTALLER_DIR/install.sh" $FLAGS
    quit
  fi

  if test "$HAS_LOCAL_COPY" -eq 0; then
    if test "$RUN_LOCAL" -ge 1; then
      error "local copy of dotfiles is not found at $HOME/$DOTFILES"
      quit 1
    fi

    if test -z "$REPO_URL"; then
      error "no repository defined"
      exit 1
    fi

    if test -n "$REPO_BRANCH"; then
      clone "$REPO_URL" "$HOME/$DOTFILES" "dotfiles into $HOME/$DOTFILES" --branch "$REPO_BRANCH"
    else
      clone "$REPO_URL" "$HOME/$DOTFILES" "dotfiles into $HOME/$DOTFILES"
    fi
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
  for try_run_install__lib_path in "$INSTALLER_DIR/lib"/*.sh; do
    . "$try_run_install__lib_path"
  done
  # Load processes
  for try_run_install__lib_path in "$INSTALLER_DIR/lib/process"/*.sh; do
    . "$try_run_install__lib_path"
  done

  if test -n "$PROFILE"; then
    info "Using profile: $PROFILE"
  fi

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
  if test -z "$_PACKAGES" -a -z "$_CUSTOM" -a -z "$_SETUP" && _has_skip update; then
    info "Nothing to perform, exiting..."
    quit 0
  fi

  _summarize_packages
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

_check_sudo() {
  if test -n "$(command -v sudo)"; then
    return
  fi

  error "insufficient permission, no 'sudo' available"
}

#############
# Main APIs #
#############

download_file() {
  if test "$(curl --create-dirs -fsL "$1" -o "$2" -w "%{http_code}")" -eq 200; then
    return 0
  fi
  # cleanup unsuccessful download
  if test -f "$2"; then
    rm -f "$2"
  fi
  return 1
}

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

sudo_cmd() {
  if test "$(whoami)" = "root"; then
    cmd "$@"
    return $?
  else
    _check_sudo
    if test -n "$_VERBOSE_CMD"; then
      _VERBOSE_CMD="sudo $_VERBOSE_CMD"
    fi
    if test -n "$_QUIET_FLAGS"; then
      _QUIET_FLAGS="sudo $_QUIET_FLAGS"
    fi
    cmd sudo "$@"
    return $?
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
  cmd__return_code="$?"
  _QUIET_CMD=""
  _QUIET_FLAGS=""
  _VERBOSE_CMD=""
  _VERBOSE_FLAGS=""
  return $cmd__return_code
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
