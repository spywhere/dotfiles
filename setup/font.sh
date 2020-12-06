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
  # Try downloading fonts to this directory would be much faster and use
  #   smaller storage size
  # - https://github.com/ryanoasis/nerd-fonts#option-6-ad-hoc-curl-download
  # - https://github.com/ryanoasis/nerd-fonts/blob/master/install.sh#L238-L254
  return
}
