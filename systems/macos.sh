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

setup() {
  if has_cmd brew; then
    return
  fi

  if ! has_cmd ruby; then
    error "Failed: either install \"ruby\" or \"homebrew\", and try again"
    quit 1
  fi

  print "Installing Homebrew..."
  sudo_cmd -v
  cmd bash -c "NONINTERACTIVE=1 $(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)"
}

update() {
  cmd brew update --force # https://github.com/Homebrew/brew/issues/1151
  if test $1 = "upgrade"; then
    cmd brew upgrade
    cmd brew cleanup
  fi
}

tap_repo() {
  for repo in $@; do
    cmd brew tap $repo
  done
}

install_packages() {
  local tap_repos=""
  local brew_packages=""
  for package in $@; do
    local manager=$(printf "%s" "$package" | cut -d'|' -f1)
    local name=$(printf "%s" "$package" | cut -d'|' -f2-)

    if test "$manager" = "brew"; then
      brew_packages=$(_add_item "$brew_packages" " " "$name")
    elif test "$manager" = "tap"; then
      tap_repos=$(_add_item "$tap_repos" " " "$name")
    fi
  done

  print "Tapping repositories..."
  tap_repo $tap_repos
  print "Installing packages..."
  cmd brew install $brew_packages
}

use_brew() {
  local package="$1"
  add_package brew "$package"
}

use_brew_tap() {
  local tap="$1"
  add_package tap "$tap"
}
