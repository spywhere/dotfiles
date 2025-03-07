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

use_brew cask 'qlprettypatch'
use_brew cask 'quicklook-csv'
use_brew cask 'quicklook-json'
use_brew cask 'quicklookase'
use_brew cask 'webpquicklook'
