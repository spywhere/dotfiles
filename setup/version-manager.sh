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
  setup_version_manager__plugins="deno fzf golang neovim nodejs python rust shellcheck"
  step "Setting up version manager plugins..."
  set +e
  for setup_version_manager__plugin in $setup_version_manager__plugins; do
    bash -c ". $HOME/.asdf/asdf.sh && asdf plugin add $setup_version_manager__plugin"
  done
  set -e
  bash "$HOME/.asdf/plugins/nodejs/bin/import-release-team-keyring"
  cmd cd "$HOME"
  step "Installing version manager plugins..."
  # asdf v0.9 will now error if the plugin is missing from .tool-versions
  #   Ref: https://github.com/asdf-vm/asdf/issues/574
  # Possible solutions:
  #   - A new install flag: https://github.com/asdf-vm/asdf/issues/968#issuecomment-991106501
  setup_version_manager__plugins="nodejs python fzf neovim"
  set +e
  for setup_version_manager__plugin in $setup_version_manager__plugins; do
    bash -c ". $HOME/.asdf/asdf.sh && asdf install $setup_version_manager__plugin"
  done
  set -e
  cmd cd "$CURRENT_DIR"
}
