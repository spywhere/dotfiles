#!/bin/sh

set -e

DOTFILES_REPO="spywhere/dotfiles"

if test -n "$INSTALLER_DIR" && test -f "$INSTALLER_DIR/install.sh"; then
  sh "$INSTALLER_DIR/install.sh" "$DOTFILES_REPO" "$@"
else
  sh -c "$(curl -sSL dots.spywhere.me)" - "$DOTFILES_REPO" "$@"
fi
