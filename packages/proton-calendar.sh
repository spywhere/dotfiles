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

has_app 'Proton Calendar'

SUPPORT_DIR="$HOME/$DOTFILES/supports/proton/calendar"

profile -work
use_nativefier 'Proton Calendar' 'https://calendar.proton.me' --conceal --background-color '#1C1B23' --icon "$SUPPORT_DIR/icon.icns" --inject "$SUPPORT_DIR/inject.css" --counter --title-bar-style hidden --disable-context-menu --darwin-dark-mode-support
