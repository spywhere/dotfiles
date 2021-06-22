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

add_setup 'setup_font'

# install fonts
setup_font() {
  local font_path="$HOME/.local/share/fonts/NerdFonts"

  if test -d "$HOME/Library/Fonts"; then
    font_path="$HOME/Library/Fonts/NerdFonts"
  fi

  info "Installing fonts into $font_path..."
  mkdir -p "$font_path"
  info "Installing JetBrains Mono Nerd Font..."
  cmd curl -fLo "$font_path/JetBrains Mono Regular Nerd Font Complete.ttf" https://github.com/ryanoasis/nerd-fonts/blob/master/patched-fonts/JetBrainsMono/Ligatures/Regular/complete/JetBrains%20Mono%20Regular%20Nerd%20Font%20Complete.ttf?raw=true
}
