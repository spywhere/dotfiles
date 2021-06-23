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

fonts=""
add_font() {
  local name="$(printf "%s" "$1" | sed 's/ /%20/g')"
  local file="$(printf "%s" "$2" | sed 's/ /%20/g')"
  local url="$3"

  fonts=$(_add_item "$fonts" ";" "$name|$file|$url")
}

install_fonts() {
  local font_path="$HOME/.local/share/fonts/NerdFonts"

  if test -d "$HOME/Library/Fonts"; then
    font_path="$HOME/Library/Fonts/NerdFonts"
  fi

  local missing_fonts=""

  for font_info in $(_split "$fonts"); do
    local file=$(printf "%s" "$font_info" | cut -d'|' -f2 | sed 's/%20/ /g')

    if ! test -f "$font_path/$file"; then
      missing_fonts=$(_add_item "$missing_fonts" ";" "$font_info")
    fi
  done

  if test -n "$missing_fonts"; then
    step "Installing fonts into $font_path..."
    if ! test -d "$font_path"; then
      mkdir -p "$font_path"
    fi
    for font_info in $(_split "$missing_fonts"); do
      local name=$(printf "%s" "$font_info" | cut -d'|' -f1 | sed 's/%20/ /g')
      local file=$(printf "%s" "$font_info" | cut -d'|' -f2 | sed 's/%20/ /g')
      local url=$(printf "%s" "$font_info" | cut -d'|' -f3)

      step "Installing $name..."
      cmd curl -fLo "$font_path/$file" "$url"
    done
  fi
}

# install fonts
setup_font() {
  add_font "JetBrains Mono Nerd Font" "JetBrains Mono Regular Nerd Font Complete.ttf" "https://github.com/ryanoasis/nerd-fonts/blob/master/patched-fonts/JetBrainsMono/Ligatures/Regular/complete/JetBrains%20Mono%20Regular%20Nerd%20Font%20Complete.ttf?raw=true"

  install_fonts
}
