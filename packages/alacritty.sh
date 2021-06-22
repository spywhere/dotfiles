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

optional

if has_flag "apple-silicon"; then
  use_custom 'install_alacritty'
else
  use_brew cask 'alacritty'
fi

install_alacritty() {
  if test -d /Applications/Alacritty.app; then
    return
  fi
  local path=$(deps "alacritty")
  clone https://github.com/alacritty/alacritty $path
  cmd cd $path
  print "Building Alacritty..."
  cmd make app
  if test -d "$path/target/release/osx/Alacritty.app"; then
    cmd cp -r "$path/target/release/osx/Alacritty.app" /Applications/
  else
    error "Failed: Alacritty is failed to build"
  fi
}
