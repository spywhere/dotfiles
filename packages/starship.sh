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

has_executable 'starship'

require 'curl'

use_custom 'curl_starship'

curl_starship() {
  curl_starship__base_path="/usr/local/bin"
  if test ! -d "$curl_starship__base_path"; then
    sudo_cmd mkdir -p "$curl_starship__base_path"
  fi
  cmd sh -c "$(curl -fsSL https://starship.rs/install.sh)" - -y -b "$curl_starship__base_path"
  return
}
