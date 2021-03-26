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
# nodejs requirements
require 'gnupg2'
# python requirements
require 'build-base'
require 'lib-bz'
require 'lib-readline'
require 'lib-sqlite'
require 'lib-ssl'
require 'lib-zlib'

add_setup 'setup_version_manager'

setup_version_manager() {
  print "Setting up version manager..."
  local plugins="1password deno golang nodejs python rust"
  set +e
  print "Setting up version manager plugins..."
  for plugin in $plugins; do
    bash -c ". ~/.asdf/asdf.sh && asdf plugin add $plugin"
  done
  set -e
  bash ~/.asdf/plugins/nodejs/bin/import-release-team-keyring
  cd $HOME
  print "Installing version manager plugins..."
  bash -c '. ~/.asdf/asdf.sh && asdf install'
  cd $CURRENT_DIR
}
