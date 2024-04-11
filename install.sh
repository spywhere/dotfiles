#!/bin/sh

set -e

if test -n "$INSTALLER_DIR" && test -f "$INSTALLER_DIR/install.sh"; then
  sh "$INSTALLER_DIR/install.sh" "$@"
else
  sh -c "$(curl -sSL dots.spywhere.me)" - "$@"
fi
