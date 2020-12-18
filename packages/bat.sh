#!/bin/sh

set -e

if
  (! command -v force_print >/dev/null 2>&1) ||
  ! $(force_print 3 a b >/dev/null 2>&1) ||
  test "$(force_print 3 a b)" != "a  b";
then
  printf "Please run this script through \"install.sh\" instead"
  exit 1
fi

require 'curl'

use_brew formula 'bat'
use_dpkg 'bat' 'https://github.com/sharkdp/bat/releases/download/v0.17.1/bat_0.17.1_armhf.deb'
