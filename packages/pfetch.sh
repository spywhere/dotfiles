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

use_custom 'curl_pfetch'

curl_pfetch() {
  curl_pfetch__base_path="/usr/local/bin"
  curl_pfetch__path="$(deps pfetch)"
  cmd curl -sSL 'https://raw.githubusercontent.com/dylanaraps/pfetch/master/pfetch' -o "$curl_pfetch__path"
  cmd chmod +x "$curl_pfetch__path"
  if test ! -d "$curl_pfetch__base_path"; then
    sudo_cmd mkdir -p "$curl_pfetch__base_path"
  fi
  if test -w "$curl_pfetch__base_path"; then
    sudo_cmd mv "$curl_pfetch__path" "$curl_pfetch__base_path/pfetch"
  fi
  return
}
