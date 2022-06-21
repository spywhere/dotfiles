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

optional

has_app 'Unsplash'

use_nativefier 'Unsplash' 'https://unsplash.com' --conceal --disable-context-menu --darwin-dark-mode-support
