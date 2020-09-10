#!/bin/sh

set -e

if
  (! command -v print >/dev/null 2>&1) ||
  ! `print 3 a b >/dev/null 2>&1` ||
  test "`print 3 a b`" != "a  b";
then
  echo "Please run this script through \"install.sh\" instead"
  exit 1
fi

print "font.sh"
# Try downloading fonts to this directory would be much faster and use
#   smaller storage size
# - https://github.com/ryanoasis/nerd-fonts#option-6-ad-hoc-curl-download
# - https://github.com/ryanoasis/nerd-fonts/blob/master/install.sh#L238-L254
