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

require curl

add_setup 'setup_font'

fonts=""
add_font() {
  if test -n "$1"; then
    field name "$1"
  fi
  fonts="$(_add_to_list "$fonts" "$(make_object)")"
  reset_object
}

install_fonts() {
  local font_path="$HOME/.local/share/fonts/NerdFonts"

  if test -d "$HOME/Library/Fonts"; then
    font_path="$HOME/Library/Fonts/NerdFonts"
  fi

  local missing_fonts=""

  eval "set -- $fonts"
  for font_info in "$@"; do
    local file="$(parse_field "$font_info" file)"

    if ! test -f "$font_path/$file"; then
      missing_fonts="$(_add_item "$missing_fonts" ";" "$font_info")"
    fi
  done

  if test -n "$missing_fonts"; then
    step "Installing fonts into $font_path..."
    if ! test -d "$font_path"; then
      mkdir -p "$font_path"
    fi
    for font_info in "$@"; do
      local name="$(parse_field "$font_info" name)"
      local file="$(parse_field "$font_info" file)"
      local url="$(parse_field "$font_info" url)"
      if test -z "$name"; then
        name="$file"
      fi

      step "Downloading and installing $name..."
      cmd curl -sfLo "$font_path/$file" "$url"
    done
  fi
}

# install fonts
setup_font() {
  field file "JetBrains Mono Regular Nerd Font Complete.ttf"
  field url "https://github.com/ryanoasis/nerd-fonts/blob/master/patched-fonts/JetBrainsMono/Ligatures/Regular/complete/JetBrains%20Mono%20Regular%20Nerd%20Font%20Complete.ttf?raw=true"
  add_font "JetBrains Mono Nerd Font"

  install_fonts
}
