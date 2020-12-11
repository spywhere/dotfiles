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

use_brew 'qlcolorcode'
use_brew 'qlimagesize'
use_brew 'qlmarkdown'
use_brew 'qlprettypatch'
use_brew 'qlstephen'
use_brew 'quicklook-csv'
use_brew 'quicklook-json'
use_brew 'quicklookase'
use_brew 'webpquicklook'
