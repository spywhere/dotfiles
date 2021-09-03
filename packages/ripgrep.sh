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

has_executable 'rg'

# (a better grep) fzf.vim dependencies
use_apk 'community' 'ripgrep'
use_apt 'ripgrep'
use_pacman 'ripgrep'
use_brew formula 'ripgrep'
