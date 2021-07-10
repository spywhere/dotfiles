#!/bin/sh

set -e

if
  ! (command -v force_print >/dev/null 2>&1) ||
  ! (force_print 3 a b >/dev/null 2>&1) ||
  test "$(force_print 3 a b)" != "a  b";
then
  printf "Please run this script through \"install.sh\" instead"
  exit 1
fi

setup() {
  return 0
}

install_git() {
  return 1
}

# update <mode>
#  mode:
#    update
#    upgrade
update() {
  return 0
}

# install_packages <package>...
install_packages() {
  return 0
}

# _sh_cmd <source> <target> <command>
_sh_cmd() {
  sh_cmd__source="$HOME/$DOTFILES/configs/$1"
  sh_cmd__target="$HOME/$2"
  shift
  shift
  if ! test -f "$sh_cmd__source" -o -d "$sh_cmd__source"; then
    warn "No source file \"$sh_cmd__source\""
    return
  fi
  if test -f "$sh_cmd__target"; then
    rm -f "$sh_cmd__target"
  elif test -d "$sh_cmd__target"; then
    rm -rf "$sh_cmd__target"
  fi
  "$@" "$sh_cmd__source" "$sh_cmd__target"
}

# link <source> <target>
link() {
  link__source="$1"
  link__target="$2"
  shift
  shift
  _sh_cmd "$link__source" "$link__target" ln -fs "$@"
}

# copy <source> <target>
copy() {
  copy__source="$1"
  copy__target="$2"
  shift
  shift
  _sh_cmd "$copy__source" "$copy__target" cp -R "$@"
}

# use_apk <repo> <package>
use_apk() {
  return 0
}

# use_apt <package>
use_apt() {
  return 0
}

# use_brow <package>
use_brow() {
  return 0
}

# use_brew <package>
use_brew() {
  return 0
}

# use_brew_tap <package>
use_brew_tap() {
  return 0
}

# use_mas <package>
use_mas() {
  return 0
}

# use_dpkg <name> <url>
use_dpkg() {
  return 0
}
