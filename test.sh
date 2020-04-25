#!/bin/sh

# This script is POSIX-compliant with assumption of the following commands
# - pwd
# - echo
# - expr
# - printf
# - cut
# - sed
# - test

set -e

#######################
# Utilities Functions #
#######################

# Print a padded string
#   print [string] [string]
#   print <pad size> <padded string> <string>
print() {
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

########################
# Internal Information #
########################

CURRENT_DIR=`pwd`

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
if test "$0" == "sh"; then
  REMOTE_INSTALL=1
fi

# Figure out if we already have a local copy
LOCAL_COPY=0
if test -d "$HOME/$DOTFILES"; then
  LOCAL_COPY=1
fi

usage() {
  print "Usage: $0 [flag ...] [option ...]"
  print
  print "Flags:"
  print 20 "  -h, --help" "Show this help message"
  print 20 "  -i, --info" "Print out the setup environment information"
  print 20 "  -l, --local" "Run install script locally"
  print 20 "  -d, --dumb" "Do not attempt to install dependencies automatically"
  print 20 "  -k, --keep" "Keep downloaded dependencies"
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

# All options turned on
CONFIG=1023
CONFIG_VERMGR=3
CONFIG_SYMLINK=511
RUN_LOCAL=0
DUMB=0
KEEP_FILES=0
PRINT_CONFIG=0

main() {
  # Read flags
  while test "$1" != ""; do
    PARAM=`echo $1 | sed 's/=.*//g'`
    VALUE=`echo $1 | sed 's/^[^=]*=//g'`
    case $PARAM in
      -h | --help)
        usage
        exit
        ;;
      -i | --info)
        info
        exit
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
        exit 1
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
        exit 1
        ;;
      *)
        echo "ERROR: unknown option \"$1\""
        usage
        exit 1
        ;;
    esac

    shift
  done

  if test "$PRINT_CONFIG" -eq 1; then
    echo "$CONFIG-$CONFIG_VERMGR-$CONFIG_SYMLINK"
    exit
  fi

  usage
  exit 1
}

info() {
  print      20 "Home Directory" ": $HOME"
  print      20 "Working Directory" ": $CURRENT_DIR"
  print      20 ".dots Target" ": $DOTFILES -> $HOME/$DOTFILES"
  print_bool 20 "Remote Install" "$REMOTE_INSTALL" ": "
  print_bool 20 "Local Copy" "$LOCAL_COPY" ": "
}

main "$@"
