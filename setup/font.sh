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

# shellcheck disable=SC2120
install_fonts() {
  if test -z "$fonts"; then
    return
  fi

  install_fonts__font_path="$HOME/.local/share/fonts/NerdFonts"

  if test -d "$HOME/Library/Fonts"; then
    install_fonts__font_path="$HOME/Library/Fonts/NerdFonts"
  fi

  install_fonts__missing_fonts=""

  eval "set -- $fonts"
  for install_fonts__font_info in "$@"; do
    install_fonts__file="$(parse_field "$install_fonts__font_info" file)"

    if ! test -f "$install_fonts__font_path/$install_fonts__file"; then
      install_fonts__missing_fonts="$(_add_item "$install_fonts__missing_fonts" ";" "$install_fonts__font_info")"
    fi
  done

  if test -n "$install_fonts__missing_fonts"; then
    step "Installing fonts into $install_fonts__font_path..."
    if ! test -d "$install_fonts__font_path"; then
      cmd mkdir -p "$install_fonts__font_path"
    fi
    for install_fonts__font_info in "$@"; do
      install_fonts__name="$(parse_field "$install_fonts__font_info" name)"
      install_fonts__file="$(parse_field "$install_fonts__font_info" file)"
      install_fonts__url="$(parse_field "$install_fonts__font_info" url)"
      if test -z "$install_fonts__name"; then
        install_fonts__name="$install_fonts__file"
      fi

      step "Downloading and installing $install_fonts__name..."
      cmd curl -sfLo "$install_fonts__font_path/$install_fonts__file" "$install_fonts__url"
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
