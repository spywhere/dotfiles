#!/bin/sh

set -e

########################
# Internal Information #
########################

CURRENT_DIR=`pwd`
FLAGS=$@

# Set a dot files directory if one is not found
if test -z "$DOTFILES"; then
  DOTFILES=.dots
fi

# Try to set home variable if one is not found
if test -z "$HOME"; then
  HOME=`echo ~`
fi

# Figure out if we run through local file or not
# $0 will produced a shell command if we piped the file
REMOTE_INSTALL=0
if test "$0" = "sh"; then
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
print() {
  if test "$SILENT" -eq 1; then
    return
  fi

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

# Print a boolean value as string
#   print_bool <pad size> <padded string> <bool variable> [prefix] [suffix]
print_bool() {
  if test "$3" -eq 0; then
    print "$1" "$2" "$4No$5"
  else
    print "$1" "$2" "$4Yes$5"
  fi
}

# Call a function when a variable is true
#   call_on_true <variable> <function> [argument ...]
call_on_true() {
  if test "$1" -eq 0;then
    return
  fi
  shift
  "$@"
}

# Set / Unset option
#   set_option <option set> <option position> <option value>
set_option() {
  # Set that option to on, regardless of the previous state
  VALUE="$(( $1 | ( 1 << $2 ) ))"
  if test "$3" -eq 0; then
    # Turn bit off, when needed
    echo "$(( $VALUE ^ (1 << $2) ))"
  else
    echo "$VALUE"
  fi
}

# Set / Unset option by config name
#   set_config <option set> <option position> <config name>
set_config() {
  case "$3" in
    no*)
      set_option "$1" "$2" 0
      ;;
    *)
      set_option "$1" "$2" 1
      ;;
  esac
}

is_number() {
  DIGIT_LENGTH=`expr "x$1" : "x[0-9]*$"`
  if test "$DIGIT_LENGTH" -eq 1; then
    return 1
  else
    return 0
  fi
}

detect_os() {
  case `uname -s` in
    Linux*)
      OS="Linux"
      if test -f /etc/debian_version; then
        PKGMGR=" - Advanced Packaging Tool (apt)"
        OS="Debian"
      elif test -f /etc/alpine-release; then
        PKGMGR=" - Alpine Linux Package Manager (apk)"
        OS="Alpine"
      fi
      ;;
    Darwin*)
      PKGMGR=" - Homebrew (brew)"
      OS="Mac"
      ;;
    *)
      OS="unsupported"
      ;;
  esac
}

# All options turned on
CONFIG=1023
CONFIG_VERMGR=3
CONFIG_SYMLINK=511
RUN_LOCAL=0
DUMB=0
KEEP_FILES=0
SILENT=0
VERBOSE=0
PRINT_CONFIG=0

PKGMGR=""
OS="unsupported"

main() {
  detect_os

  # Read flags
  while test "$1" != ""; do
    PARAM=`echo $1 | sed 's/=.*//g'`
    VALUE=`echo $1 | sed 's/^[^=]*=//g'`
    case $PARAM in
      -h | --help)
        usage
        quit
        ;;
      -i | --info)
        info
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
      -s | --silent)
        SILENT=1
        ;;
      -v | --verbose)
        VERBOSE=1
        ;;
      --save)
        PRINT_CONFIG=1
        ;;
      --load)
        LOAD_CONFIG=`echo $VALUE | cut -s -d'-' -f1`
        LOAD_CONFIG_VERMGR=`echo $VALUE | cut -s -d'-' -f2`
        LOAD_CONFIG_SYMLINK=`echo $VALUE | cut -s -d'-' -f3`
        if is_number "$LOAD_CONFIG"; then
          CONFIG="$LOAD_CONFIG"
        fi
        if is_number "$LOAD_CONFIG_VERMGR"; then
          CONFIG_VERMGR="$LOAD_CONFIG_VERMGR"
        fi
        if is_number "$LOAD_CONFIG_SYMLINK"; then
          CONFIG_SYMLINK="$LOAD_CONFIG_SYMLINK"
        fi
        ;;
      -*)
        echo "ERROR: unknown flag \"$1\""
        usage
        quit 1
        ;;
      *)
        break
        ;;
    esac

    shift
  done

  # Read options
  while test "$1" != ""; do
    case $1 in
      noall)
        CONFIG=0
        ;;
      update | noupdate)
        CONFIG=`set_config $CONFIG 0 $1`
        ;;
      package | nopackage)
        CONFIG=`set_config $CONFIG 1 $1`
        ;;
      binary | nobinary)
        CONFIG=`set_config $CONFIG 2 $1`
        ;;
      make | nomake)
        CONFIG=`set_config $CONFIG 3 $1`
        ;;
      shell | noshell)
        CONFIG=`set_config $CONFIG 4 $1`
        ;;
      zsh | nozsh)
        CONFIG=`set_config $CONFIG 5 $1`
        ;;
      setup | nosetup)
        CONFIG=`set_config $CONFIG 6 $1`
        ;;
      font | nofont)
        CONFIG=`set_config $CONFIG 7 $1`
        ;;
      vermgr | novermgr)
        CONFIG=`set_config $CONFIG 8 $1`
        ;;
      vermgr-plugin | novermgr-plugin)
        CONFIG_VERMGR=`set_config $CONFIG_VERMGR 0 $1`
        ;;
      tool-version | notool-version)
        CONFIG_VERMGR=`set_config $CONFIG_VERMGR 1 $1`
        ;;
      config | noconfig)
        CONFIG=`set_config $CONFIG 9 $1`
        ;;
      alacritty | noalacritty)
        CONFIG_SYMLINK=`set_config $CONFIG_SYMLINK 0 $1`
        ;;
      tmux | notmux)
        CONFIG_SYMLINK=`set_config $CONFIG_SYMLINK 1 $1`
        ;;
      git | nogit)
        CONFIG_SYMLINK=`set_config $CONFIG_SYMLINK 2 $1`
        ;;
      tig | notig)
        CONFIG_SYMLINK=`set_config $CONFIG_SYMLINK 3 $1`
        ;;
      nvim | nonvim)
        CONFIG_SYMLINK=`set_config $CONFIG_SYMLINK 4 $1`
        ;;
      mpd | nompd)
        CONFIG_SYMLINK=`set_config $CONFIG_SYMLINK 5 $1`
        ;;
      ncmpcpp | noncmpcpp)
        CONFIG_SYMLINK=`set_config $CONFIG_SYMLINK 6 $1`
        ;;
      mycli | nomycli)
        CONFIG_SYMLINK=`set_config $CONFIG_SYMLINK 7 $1`
        ;;
      alias | noalias)
        CONFIG_SYMLINK=`set_config $CONFIG_SYMLINK 8 $1`
        ;;
      -*)
        echo "ERROR: expect option but got a flag \"$1\" instead"
        usage
        quit 1
        ;;
      *)
        echo "ERROR: unknown option \"$1\""
        usage
        quit 1
        ;;
    esac

    shift
  done

  if test "$PRINT_CONFIG" -eq 1; then
    echo "$CONFIG-$CONFIG_VERMGR-$CONFIG_SYMLINK"
    quit
  fi

  try_run_install
  quit
}

usage() {
  SILENT=0
  print "Usage: $0 [flag ...] [option ...]"
  print
  print "Flags:"
  print 20 "  -h, --help" "Show this help message"
  print 20 "  -i, --info" "Print out the setup environment information"
  print 20 "  -l, --local" "Run install script locally without update"
  print 20 "  -d, --dumb" "Do not attempt to install dependencies automatically"
  print 20 "  -k, --keep" "Keep downloaded dependencies"
  print 20 "  -s, --silent" "Suppress output messages when possible"
  print 20 "  -v, --verbose" "Produce command output messages when possible"
  print 20 "  --save" "Produce an option set"
  print 20 "  --load=..." "Load an option set"
  print
  print "Every options and sub-options are turned on by default."
  print "All sub-options will be turned off if its parent option turned off."
  print
  print "To turn off specific option, add a 'no' prefix to the option."
  print
  print "Options:"
  print 20 "  noall" "Turn off all options and its sub-options"
  print 20 "  update" "Fully upgrade all packages if possible"
  print 20 "  package" "Install packages"
  print 20 "  binary" "Install raw binary files"
  print 20 "  make" "Build and install packages from source"
  print 20 "  shell" "Update the shell"
  print 20 "  zsh" "Symlink a .zshrc"
  print 20 "  setup" "Setup the system preferences"
  print 20 "  font" "Install fonts"
  print 20 "  vermgr" "Install version manager"
  print 20 "    vermgr-plugin" "Install version manager plugins"
  print 20 "    tool-version" "Tool versions"
  print 20 "  config" "Symlink configs (no symlink at all if turned off)"
  print 20 "    alacritty" "alacritty configs"
  print 20 "    tmux" "tmux configs and plugin manager"
  print 20 "    git" "git configs"
  print 20 "    tig" "tig configs"
  print 20 "    nvim" "nvim configs"
  print 20 "    mpd" "mpd configs"
  print 20 "    ncmpcpp" "ncmpcpp configs"
  print 20 "    mycli" "mycli configs"
  print 20 "    alias" "Aliases and variables"
}

info() {
  SILENT=0
  print      20 "Operating System" ": $OS$PKGMGR"
  print      20 "Home Directory" ": $HOME"
  print      20 "Working Directory" ": $CURRENT_DIR"
  print      20 ".dots Target" ": $DOTFILES -> $HOME/$DOTFILES"
  print_bool 20 "Remote Install" "$REMOTE_INSTALL" ": "
  print_bool 20 "Local Copy" "$LOCAL_COPY" ": "
}

#################
# Main Commands #
#################

setup_homebrew() {
  if test `command -v brew`; then
    return
  fi

  if test -f "/usr/bin/ruby"; then
    error "Failed: Either install \"ruby\" or \"homebrew\", and try again"
    quit 1
  fi

  print "Installing Homebrew..."
  /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
}

setup_sudo() {
  if test `command -v "sudo"`; then
    return
  fi

  print "Installing sudo..."
  do_command apt update
  do_command apt install -y sudo
}

try_install() {
  if test "$DUMB" -eq 1; then
    error "Failed: Command \"$1\" is required"
    quit 1
  fi

  if test $OS = "Mac"; then
    setup_homebrew
    print "Installing $1..."
    do_command brew update
    do_command brew install "$1"
  elif test $OS = "Debian"; then
    setup_sudo
    print "Installing $1..."
    do_command sudo apt update
    do_command sudo apt install --no-install-recommends -y "$1"
  elif test $OS = "Alpine"; then
    print "Installing $1..."
    do_command apk update
    do_command apk add "$1"
  else
    error "Failed: Unsupported operating system"
    quit 1
  fi
}

try_command() {
  if test `command -v "$1"`; then
    return
  fi
  try_install "$1"
}

do_command() {
  if test "$VERBOSE" -eq 0; then
    "$@" >/dev/null 2>&1
  else
    "$@"
  fi
}

clone() {
  try_command git
  if test -n "$3"; then
    print "Cloning $3..."
  fi
  # do_command git clone "$1" "$2"
  cp -r /etc/app "$2"
}

try_run_install() {
  SKIP_UPDATE=0
  if test "$LOCAL_COPY" -eq 0; then
    if test "$RUN_LOCAL" -eq 1; then
      error "Failed: Local copy of dotfiles is not found at $HOME/$DOTFILES"
      quit 1
    fi

    clone https://github.com/spywhere/dotfiles "$HOME/$DOTFILES" dotfiles
    SKIP_UPDATE=1
  fi

  run_install "$SKIP_UPDATE"
}

run_install() {
  cd $HOME/$DOTFILES

  # Try to update when install remotely, but not the first clone
  if test "$1" -eq 0 && test "$REMOTE_INSTALL" -eq 1; then
    try_command git
    print "Updating dotfiles to latest version..."
    do_command git reset --hard
    do_command git fetch
    do_command git pull
  fi

  # Run local script when install remotely
  if test "$REMOTE_INSTALL" -eq 1; then
    print "Executing local script..."
    sh $HOME/$DOTFILES/install.sh $FLAGS
    quit
  fi

  print "Ready"
  run_install_script $CONFIG 0 update
  run_install_script $CONFIG 1 package
  run_install_script $CONFIG 2 binary
  run_install_script $CONFIG 3 make
  run_install_script $CONFIG 4 shell
  run_install_script $CONFIG 5 zsh
  run_install_script $CONFIG 6 setup
  run_install_script $CONFIG 7 font
  run_install_script $CONFIG 8 vermgr
  run_install_script $CONFIG 9 config
}

run_install_script() {
  if test "$(( $1 >> $2 & 1 ))" -eq 0; then
    return
  fi
  print "Running $3..."
  . $HOME/$DOTFILES/installs/$3.sh
}

main "$@"
