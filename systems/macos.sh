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

setup() {
  if test "$(command -v brew)"; then
    return
  fi

  if test -f "/usr/bin/ruby"; then
    error "Failed: either install \"ruby\" or \"homebrew\", and try again"
    quit 1
  fi

  print "Installing Homebrew..."
  /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
}

update() {
  cmd brew update
  if test $1 = "upgrade"; then
    cmd brew upgrade
    cmd brew cleanup
  fi
}

use_brew() {
  local package="$1"
  add_package brew "$package"
}
