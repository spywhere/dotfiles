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

has_app 'Unsplash'

profile -work

SUPPORT_DIR="$HOME/$DOTFILES/supports/unsplash"

use_nativefier 'Unsplash' 'https://unsplash.com' --conceal --background-color '#000000' --icon "$SUPPORT_DIR/icon.icns" --inject "$SUPPORT_DIR/inject.css" --inject "$SUPPORT_DIR/inject.js" --disable-context-menu --darwin-dark-mode-support
