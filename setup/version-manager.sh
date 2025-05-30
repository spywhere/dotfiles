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

depends 'mise'
# nodejs requirements
require 'gnupg'
# python requirements
require 'build-base'
require 'lib-bz'
require 'lib-ffi'
require 'lib-readline'
require 'lib-sqlite'
require 'lib-ssl'
require 'lib-zlib'

add_setup 'setup_version_manager'

setup_version_manager() {
  if has_cmd mise; then
    run_mise() {
      mise "$@"
    }
  else
    warn "Mise cannot be found on PATH"
    return 1
  fi

  if test -f "$HOME/$DOTFILES/configs/mise/config.toml"; then
    cmd cd "$HOME"
    step "Installing version manager plugins..."
    set +e
    run_mise install fzf nodejs python asdf:neovim
    set -e
  fi
  cmd cd "$CURRENT_DIR"
}
