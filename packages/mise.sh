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

has_executable 'mise'

use_brew formula 'mise'
use_custom 'install_mise'

install_mise() {
  if ! test -n "$(command -v mise)"; then
    if ! test -d '/usr/local/bin'; then
      cmd mkdir -p '/usr/local/bin'
    fi
    cmd export MISE_INSTALL_PATH=/usr/local/bin/mise
    cmd sh -c "$(curl -fsSL https://mise.run)"
    cmd cd "$CURRENT_DIR"
  fi
}
