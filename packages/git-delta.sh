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

has_executable 'delta'

cpu_type="$(uname -m)"
libc_type=""
case "$cpu_type" in
  x86_64)
    cpu_type="amd64"
    ;;
  i686)
    cpu_type="i386"
    ;;
  aarch64)
    cpu_type="arm64"
    ;;
  armv7l)
    cpu_type="armhf"
    ;;
  *)
    ;;
esac
if test "$cpu_type" = "amd64"; then
  # there seems to be an issue with Ubuntu setup, where musl is needed
  # https://github.com/dandavison/delta/issues/504
  libc_type="-musl"
fi

use_brew formula 'git-delta'
use_dpkg 'git-delta' "https://github.com/dandavison/delta" "%url/releases/download/%version/git-delta${libc_type}_%version_$cpu_type.deb" "0.8.3"
