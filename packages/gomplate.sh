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

require 'curl'

use_brew formula 'gomplate'
use_custom 'curl_gomplate'

curl_gomplate() {
  # use_custom 'curl_gomplate' 'https://github.com/hairyhenderson/gomplate/releases/download/v3.8.0/gomplate_linux-armv7-slim'
  return
}
