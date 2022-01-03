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

depends 'zsh'

add_setup 'setup_shell'

setup_shell() {
  # TODO: update default shell to a new one
  step "Updating default shell to zsh..."
}
