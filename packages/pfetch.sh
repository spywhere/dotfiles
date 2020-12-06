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

use_custom 'curl_pfetch'

curl_pfetch() {
  # use_curl 'pfetch' 'https://raw.githubusercontent.com/dylanaraps/pfetch/master/pfetch'
  return
}

