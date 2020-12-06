#!/bin/sh

set -e

if
  (! command -v print >/dev/null 2>&1) ||
  ! $(print 3 a b >/dev/null 2>&1) ||
  test "$(print 3 a b)" != "a  b";
then
  printf "Please run this script through \"install.sh\" instead"
  exit 1
fi

# (a better grep) fzf.vim dependencies
use_apk 'community' 'ripgrep'
use_apt 'ripgrep'
use_brew 'ripgrep'
