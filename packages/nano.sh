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

has_string 'version 5\.[0-9]*' nano -version

use_apk 'main' 'nano'
use_apt 'nano'
use_pacman 'nano' --reinstall
use_brew formula 'nano'
