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

has_app 'ProtonMail'

SUPPORT_DIR="$HOME/$DOTFILES/supports/protonmail"

# Use older electron as there is an issue when logging in
# Ref: https://github.com/electron/electron/issues/31018
use_nativefier 'ProtonMail' 'https://mail.protonmail.com' --electron-version 13.6.6 --conceal --background-color '#1C213C' --icon "$SUPPORT_DIR/icon.icns" --inject "$SUPPORT_DIR/inject.css" --counter --title-bar-style hidden --disable-context-menu --darwin-dark-mode-support
