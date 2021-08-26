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

has_executable 'pfetch'

require 'curl'

if ! has_cmd pfetch; then
  use_custom 'curl_pfetch'
fi

curl_pfetch() {
  # use_curl 'pfetch' 'https://raw.githubusercontent.com/dylanaraps/pfetch/master/pfetch'
  return
}
