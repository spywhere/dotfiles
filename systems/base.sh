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
  return
}

# update <mode>
#  mode:
#    update
#    upgrade
update() {
  return
}

# link <source> <target>
link() {
  local source="$1"
  local target="$2"
  ln -fs "$HOME/$DOTFILES/configs/$1" "$HOME/$2"
}

# use_apk <repo> <package>
use_apk() {
  return
}

# use_apt <package>
use_apt() {
  return
}

# use_brew <package>
use_brew() {
  return
}

# use_dpkg <name> <url>
use_dpkg() {
  return
}

# use_docker <package>
use_docker_build() {
  if test -n "$_FULFILLED"; then
    return
  fi

  local package="$1"
  add_package docker "$package"
}
