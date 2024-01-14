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

has_app 'Proton Pass'

SUPPORT_DIR="$HOME/$DOTFILES/supports/proton/pass"

profile -work
use_nativefier 'Proton Pass' 'https://pass.proton.me' --fast-quit --conceal --background-color '#1C1B23' --icon "$SUPPORT_DIR/icon.icns" --inject "$SUPPORT_DIR/inject.css" --title-bar-style hidden --disable-context-menu --darwin-dark-mode-support
