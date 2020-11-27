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

use_brew 'docker-edge'
use_apk 'community' 'docker'
use_custom 'install_docker'

install_docker() {
  echo 'Custom code work!'
}
