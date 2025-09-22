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

has_executable 'mosh'

# Mosh will need to be manually build to fix 24-bit colors issue
# Ref: https://github.com/mobile-shell/mosh/issues/961#issuecomment-565741393%22
# use_nix 'mosh'
use_apt 'mosh'
use_brew formula 'mosh'
