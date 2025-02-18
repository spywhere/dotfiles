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

has_executable 'asdf'

use_brew formula 'asdf'
use_custom 'install_asdf'

install_asdf() {
  if ! test -d "$HOME/.asdf"; then
    full_clone https://github.com/asdf-vm/asdf "$HOME/.asdf"
    # Use master as it currently broken
    #   Ref: https://github.com/asdf-vm/asdf/pull/1106
    # cmd cd "$HOME/.asdf"
    # cmd git checkout "$(git describe --abbrev=0 --tags)"
    cmd cd "$CURRENT_DIR"
  fi
}
