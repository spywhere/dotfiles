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

has_executable 'bat'

cpu_type="$(uname -m)"
libc_type=""
case "$cpu_type" in
  x86_64)
    cpu_type="amd64"
    ;;
  i386)
    cpu_type="i686"
    ;;
  armv6l|armv7l)
    cpu_type="armhf"
    ;;
  aarch64)
    cpu_type="arm64"
    ;;
  *)
    ;;
esac

# use_nix 'bat'
use_brew formula 'bat'
use_dpkg 'bat' "https://github.com/sharkdp/bat" "%url/releases/download/v%version/bat${libc_type}_%version_$cpu_type.deb" "0.19.0"
