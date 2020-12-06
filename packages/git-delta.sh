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

depends 'curl'

use_brew 'git-delta'
use_dpkg 'git-delta' 'https://github.com/dandavison/delta/releases/download/0.4.1/git-delta_0.4.1_armhf.deb'
