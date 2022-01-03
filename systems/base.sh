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

##################
# Base Interface #
##################
system_usage() {
  return 0
}

setup() {
  return 0
}

install_git() {
  return 1
}

####################
# Common Interface #
####################

# update <mode>
#  mode:
#    update
#    upgrade
update() {
  return 0
}

# install_packages <package>...
install_packages() {
  return 0
}

install_bins() {
  install_bin__base_path="/usr/local/bin"
  for install_bin_packages__package in "$@"; do
    install_bin_packages__name="$(parse_field "$install_bin_packages__package" package)"
    install_bin_packages__url="$(parse_field "$install_bin_packages__package" url)"

    install_bin_packages__path=$(deps "$install_bin_packages__name")
    step "Downloading $install_bin_packages__url for installation..."
    if download_file "$install_bin_packages__url" "$install_bin_packages__path"; then
      step "Installing $install_bin_packages__name into $install_bin__base_path..."
      cmd chmod +x "$install_bin_packages__path"
      if test -w "$install_bin__base_path"; then
        cmd mv "$install_bin_packages__path" "$install_bin__base_path/$install_bin_packages__name"
      else
        sudo_cmd mv "$install_bin_packages__path" "$install_bin__base_path/$install_bin_packages__name"
      fi
    else
      error "Failed to download $install_bin_packages__url"
    fi
  done
}

_sort_version() {
  sed 'h; s/[+-]/./g; s/.p\([[:digit:]]\)/.z\1/; s/$/.z/; G; s/\n/ /' |
    LC_ALL=C sort -i -t. -k 1,1 -k 2,2n -k 3,3n -k 4,4n -k 5,5n |
    awk '{print $2}'
}

_get_latest_version() {
  git ls-remote --tags --refs "$1.git" 2>/dev/null |
    grep -o 'refs/tags/v*[0-9].*' |
    cut -d/ -f3- |
    sed 's/^v//' |
    _sort_version |
    tail -n 1
}

use_bin() {
  if test -n "$_FULFILLED"; then
    reset_object
    return
  fi

  use_bin__name="$1"
  use_bin__url="$2"
  use_bin__format_url="$3"
  use_bin__fallback_version="$4"

  if ! has_package curl; then
    require curl
  fi

  if test -n "$use_bin__format_url"; then
    _try_git
    print_inline "$esc_yellow==>$esc_reset Acquiring latest version of $use_bin__name..."
    use_bin__version="$(_get_latest_version "$use_bin__url" | sed 's/\//\\\//g')"
    if test -z "$use_bin__version" -a -n "$use_bin__fallback_version"; then
      warn "Failed to acquire the latest version of $use_bin__name, will install version $use_bin__fallback_version instead"
      use_bin__version="$use_bin__fallback_version"
    fi
    step "Acquired latest version of $use_bin__name... $use_bin__version"
    use_bin__safe_url="$(printf "%s" "$use_bin__url" | sed 's/\//\\\//g')"
    use_bin__url="$(printf "%s" "$use_bin__format_url" | sed "s/%url/$use_bin__safe_url/g" | sed "s/%version/$use_bin__version/g" | sed 's/%%/%/g')"
  fi

  field manager bin
  field package "$use_bin__name"
  field url "$use_bin__url"
  add_package
}

# _sh_cmd <source> <target> <command>
_sh_cmd() {
  sh_cmd__source="$HOME/$DOTFILES/$1"
  sh_cmd__target="$HOME/$2"
  shift
  shift
  if ! test -f "$sh_cmd__source" -o -d "$sh_cmd__source"; then
    warn "No source file \"$sh_cmd__source\""
    return
  fi
  if test -f "$sh_cmd__target"; then
    rm -f "$sh_cmd__target"
  elif test -d "$sh_cmd__target"; then
    rm -rf "$sh_cmd__target"
  fi
  "$@" "$sh_cmd__source" "$sh_cmd__target"
}

# raw_link <source> <target>
raw_link() {
  link__source="$1"
  link__target="$2"
  shift
  shift
  _sh_cmd "$link__source" "$link__target" ln -fs "$@"
}

# raw_copy <source> <target>
raw_copy() {
  copy__source="$1"
  copy__target="$2"
  shift
  shift
  _sh_cmd "$copy__source" "$copy__target" cp -R "$@"
}

# link <source> <target>
link() {
  link__source="$1"
  shift
  raw_link "configs/$link__source" "$@"
}

# copy <source> <target>
copy() {
  copy__source="$1"
  shift
  raw_copy "configs/$copy__source" "$@"
}

####################
# Alpine Interface #
####################

# use_apk <repo> <package>
use_apk() {
  return 0
}

####################
# Debian Interface #
####################

# use_apt_repo <repo>
use_apt_repo() {
  return 0
}

# use_apt <package>
use_apt() {
  return 0
}

# use_dpkg <name> <url>
use_dpkg() {
  return 0
}

##################
# Arch Interface #
##################

# use_pacman <package>
use_pacman() {
  return 0
}

###################
# MacOS Interface #
###################

# has_app <name>
has_app() {
  return 0
}

# has_screensaver <name>
has_screensaver() {
  return 0
}

# use_brow <package>
use_brow() {
  return 0
}

# use_brew <package>
use_brew() {
  return 0
}

# use_brew_tap <package>
use_brew_tap() {
  return 0
}

# use_mas <package>
use_mas() {
  return 0
}

# use_nativefier <package> <url>
use_nativefier() {
  return 0
}
