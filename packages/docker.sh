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

use_brew 'docker-edge'
use_apk 'community' 'docker'

require 'curl'
use_custom 'install_docker'

install_docker() {
  if has_cmd docker; then
    return
  fi
  print "Installing Docker..."

  local path=$(deps "install-docker.sh")
  print "Downloading installation script..."
  cmd curl -sSL get.docker.com -o $path
  print "Running installation script..."
  cmd sh $path
  if test "$(whoami)" = "root"; then
    print "run as root: no user group set"
  else
    sudo_cmd usermod -aG docker $USER
  fi
}
