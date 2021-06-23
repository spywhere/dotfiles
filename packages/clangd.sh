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

# use as a language server for C-based languages
use_apt 'clang-tools'
# see https://releases.llvm.org/10.0.0/tools/clang/tools/extra/docs/clangd/Installation.html
use_brew formula 'llvm'
# see https://github.com/clangd/clangd/issues/450
use_apk 'main' 'clang-extra-tools'
