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

has_executable 'clangd'

# use as a language server for C-based languages
field package_name clangd

if has_flag wsl; then
  # Somehow, Ubuntu on WSL doesn't like to have clang-tools install
  use_apt 'clangd-9'
else
  use_apt 'clang-tools'
fi
# see https://releases.llvm.org/10.0.0/tools/clang/tools/extra/docs/clangd/Installation.html
use_brew formula 'llvm'
# see https://github.com/clangd/clangd/issues/450
