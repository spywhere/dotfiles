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

depends 'asdf'
depends 'bash'

add_setup 'setup_version_manager'

setup_version_manager() {
  local plugins="1password deno docker-slim golang firebase nodejs python rust"
  set +e
  for plugin in $plugins; do
    bash -c ". ~/.asdf/asdf.sh && asdf plugin add $plugin"
  done
  set -e
  bash ~/.asdf/plugins/nodejs/bin/import-release-team-keyring
  cd $HOME
  bash -c '. ~/.asdf/asdf.sh && asdf install'
  cd $CURRENT_DIR
}
