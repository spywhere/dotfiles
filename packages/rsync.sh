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

has_string 'version 3\.[0-9]*\.[0-9]*' rsync --version

use_apk 'main' 'rsync'
use_apt 'rsync'
use_pacman 'rsync' --reinstall
use_brew formula 'rsync'
