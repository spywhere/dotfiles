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
  local repo
  for repo in $@; do
    cmd brew tap $repo
  done
}

install_packages() {
  local tap_repos=""
  local formula_packages=""
  local cask_packages=""
  local flagged_packages=""
  local package
  for package in $@; do
    local manager=$(printf "%s" "$package" | cut -d'|' -f1)

    if test "$manager" = "brew"; then
      local tap=$(printf "%s" "$package" | cut -d'|' -f2)
      local name=$(printf "%s" "$package" | cut -d'|' -f3)
      local flags=$(printf "%s" "$package" | cut -d'|' -f4-)

      if test "$tap" = "cask"; then
        cask_packages=$(_add_item "$cask_packages" " " "$name")
      elif test "$tap" = "formula" -a -n "$flags"; then
        flagged_packages=$(_add_item "$flagged_packages" " " "$name|$flags")
      elif test "$tap" = "formula"; then
        formula_packages=$(_add_item "$formula_packages" " " "$name")
      fi
    elif test "$manager" = "tap"; then
      local name=$(printf "%s" "$package" | cut -d'|' -f2)
      tap_repos=$(_add_item "$tap_repos" " " "$name")
    fi
  done

  local brew_flags=""
  if test $FORCE_INSTALL -eq 1; then
    brew_flags="--force"
  fi
  if test -n "$tap_repos"; then
    print "Tapping repositories..."
    tap_repo $tap_repos
  fi
  if test -n "$formula_packages"; then
    print "Installing packages..."
    cmd brew install --formula $brew_flags $formula_packages
  fi
  if test -n "$flagged_packages"; then
    print "Installing packages with additional flags..."
    local package
    for package in $flagged_packages; do
      local name=$(printf "%s" "$package" | cut -d'|' -f1)
      local flags=$(printf "%s" "$package" | cut -d'|' -f2-)
      cmd brew install --formula $brew_flags $name $flags
    done
  fi
  if test -n "$cask_packages"; then
    print "Installing cask packages..."
    cmd brew install --cask $brew_flags $cask_packages
  fi
}

use_brew() {
  local tap="$1"
  local package="$2"
  shift
  shift
  add_package brew "$tap" "$package" $@
}

use_brew_tap() {
  local tap="$1"
  add_package tap "$tap"
}
