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

. systems/base.sh

update() {
  if test $1 = "upgrade"; then
    cmd apk -U upgrade
  else
    cmd apk update
  fi
}

use_apk() {
  local repo="$1"
  local package="$2"
  add_package apk "$repo" "$package"
}
