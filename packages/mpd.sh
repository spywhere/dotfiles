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

has_executable 'mpd'

use_apk 'community' 'mpd'
use_apt 'mpd'
if has_flag "apple-silicon"; then
  use_brew formula 'mpd' '--build-from-source'
else
  use_brew formula 'mpd'
fi
