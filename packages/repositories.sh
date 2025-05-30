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

# Debian
if test "$OS" = "raspios" -a "$(uname -m)" != "aarch64"; then
  use_apt_repo 'http://mirror.kku.ac.th/raspbian/raspbian/ bullseye main contrib non-free rpi'
  use_apt_repo 'http://raspbian.raspberrypi.org/raspbian/ testing main contrib non-free rpi'
fi

# MacOS
use_brew_tap 'homebrew/autoupdate'
