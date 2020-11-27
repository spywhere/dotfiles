#!/bin/sh

set -e

if
  (! command -v print >/dev/null 2>&1) ||
  ! $(print 3 a b >/dev/null 2>&1) ||
  test "$(print 3 a b)" != "a  b";
then
  printf "Please run this script through \"install.sh\" instead"
  exit 1
fi

. systems/base.sh

update() {
  sudo_cmd apt update -y
  if test $1 = "upgrade"; then
    sudo_cmd apt full-upgrade -y
  fi
}

use_apt() {
  local package="$1"
  add_package apt "$package"
}

use_dpkg() {
  local name="$1"
  local url="$2"
  add_package dpkg "$name" "$url"
  # local path=$(deps "$name.deb")
  # cmd curl -sSL $url -o $path
  # sudo_cmd dpkg --install $path
}
