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

deno_pr_merged() {
  if curl -sSL 'https://api.github.com/repos/asdf-community/asdf-deno/pulls/29' | grep -q '"merged": true'; then
    return 0
  else
    return 1
  fi
}

setup_version_manager() {
  if has_cmd asdf; then
    run_asdf() {
      asdf "$@"
    }
  elif test -f "$HOME/.asdf/asdf.sh"; then
    run_asdf() {
      bash -c ". $HOME/.asdf/asdf.sh && asdf $*"
    }
  else
    warn "ASDF cannot be found on PATH or ~/.asdf"
    return 1
  fi

  setup_version_manager__plugins="fzf neovim nodejs python rust shellcheck tuist zig"
  step "Setting up version manager plugins..."
  set +e
  for setup_version_manager__plugin in $setup_version_manager__plugins; do
    run_asdf plugin add "$setup_version_manager__plugin"
  done
  if deno_pr_merged; then
    run_asdf plugin add deno
  else
    run_asdf plugin add deno https://github.com/spywhere/asdf-deno.git
  fi
  run_asdf plugin add upgrade https://github.com/spywhere/asdf-upgrade.git
  set -e

  if test -f "$HOME/.tool-versions"; then
    cmd cd "$HOME"
    step "Installing version manager plugins..."
    # asdf v0.9 will now error if the plugin is missing from .tool-versions
    #   Ref: https://github.com/asdf-vm/asdf/issues/574
    # Possible solutions:
    #   - A new install flag: https://github.com/asdf-vm/asdf/issues/968#issuecomment-991106501
    setup_version_manager__plugins="fzf nodejs python neovim"
    set +e
    for setup_version_manager__plugin in $setup_version_manager__plugins; do
      run_asdf install "$setup_version_manager__plugin"
    done
    set -e
  fi
  cmd cd "$CURRENT_DIR"
}
