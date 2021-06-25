#!/bin/sh

set -e

if
  (! command -v force_print >/dev/null 2>&1) ||
  ! $(force_print 3 a b >/dev/null 2>&1) ||
  test "$(force_print 3 a b)" != "a  b";
then
  printf "Please run this script through \"install.sh\" instead"
  exit 1
fi

setup() {
  return 0
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
  local source="$HOME/$DOTFILES/configs/$1"
  local target="$HOME/$2"
  shift
  shift
  if ! test -f "$source" -o -d "$source"; then
    warn "No source file \"$source\""
    return
  fi
  if test -f "$target"; then
    rm -f "$target"
  elif test -d "$target"; then
    rm -rf "$target"
  fi
  "$@" "$source" "$target"
}

# link <source> <target>
link() {
  local source="$1"
  local target="$2"
  shift
  shift
  _sh_cmd "$source" "$target" ln -fs "$@"
}

# copy <source> <target>
copy() {
  local source="$1"
  local target="$2"
  shift
  shift
  _sh_cmd "$source" "$target" cp -R "$@"
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
