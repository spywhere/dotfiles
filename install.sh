#!/bin/sh

set -e

REPO_NAME="spywhere/dotfiles"

if test -n "$INSTALLER_DIR" && test -f "$INSTALLER_DIR/install.sh"; then
  sh "$INSTALLER_DIR/install.sh" "$REPO_NAME" "$@"
else
  sh -c "$(curl -sSL dots.spywhere.me)" - "$REPO_NAME" "$@"
fi
