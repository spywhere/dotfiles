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

has_executable 'fd'

cpu_type="$(uname -m)"
libc_type=""
case "$cpu_type" in
  x86_64)
    cpu_type="amd64"
    ;;
  i686)
    cpu_type="i386"
    ;;
  armv7l)
    cpu_type="armhf"
    ;;
  aarch64)
    cpu_type="arm64"
    ;;
  *)
    ;;
esac
if test "$OSKIND" = "alpine" && test "$cpu_type" = "amd64" -o "$cpu_type" = "i386"; then
  libc_type="-musl"
fi

use_brew formula 'fd'
use_dpkg 'fd' "https://github.com/sharkdp/fd" "%url/releases/download/v%version/fd${libc_type}_%version_$cpu_type.deb" "8.2.1"
