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

if ! has_cmd asdf; then
  use_custom 'install_asdf'
fi

install_asdf() {
  if ! test -d "$HOME/.asdf"; then
    full_clone https://github.com/asdf-vm/asdf "$HOME/.asdf"
    cmd cd $HOME/.asdf
    cmd git checkout "$(git describe --abbrev=0 --tags)"
    cmd cd $CURRENT_DIR
  fi
}
