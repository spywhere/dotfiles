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

has_executable 'gomplate'

sys_type="$(uname -s)"
case "$sys_type" in
  Linux*)
    sys_type="linux"
    ;;
  Darwin*)
    sys_type="darwin"
    ;;
  *)
    ;;
esac
cpu_type="$(uname -m)"
case "$cpu_type" in
  x86_64)
    cpu_type="amd64"
    ;;
  i686)
    cpu_type="386"
    ;;
  aarch64)
    cpu_type="arm64"
    ;;
  armv6l)
    cpu_type="armv6"
    ;;
  armv7l)
    cpu_type="armv7"
    ;;
  *)
    ;;
esac

# use_yay 'gomplate'
use_brew formula 'gomplate'
use_bin 'gomplate' "https://github.com/hairyhenderson/gomplate" "%url/releases/download/v%version/gomplate_$sys_type-$cpu_type" "3.9.0"
