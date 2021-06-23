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

# link <source> <target>
link() {
  local source="$1"
  local target="$2"
  if test -f "$HOME/$target"; then
    rm -f "$HOME/$target"
  elif test -d "$HOME/$target"; then
    rm -rf "$HOME/$target"
  fi
  ln -fs "$HOME/$DOTFILES/configs/$source" "$HOME/$target"
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
