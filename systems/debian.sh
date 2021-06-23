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

. systems/base.sh

update() {
  sudo_cmd apt update -y
  if test "$1" = "upgrade"; then
    sudo_cmd apt full-upgrade -y
  fi
}

install_dpkg_packages() {
  local package
  for package in "$@"; do
    local name="$(parse_field "$package" package)"
    local url="$(parse_field "$package" url)"

    local path=$(deps "$name.deb")
    step "Downloading $path for installation..."
    cmd curl -sSL $url -o $path
    step "Installing $name through dpkg..."
    sudo_cmd dpkg --install $path
  done
}

install_packages() {
  local apt_packages=""
  local dpkg_packages=""
  local package
  for package in "$@"; do
    local manager="$(parse_field "$package" manager)"
    local name="$(parse_field "$package" package)"

    if test "$manager" = "apt"; then
      apt_packages="$(_add_to_list "$apt_packages" "$name")"
    elif test "$manager" = "dpkg"; then
      dpkg_packages="$(_add_to_list "$dpkg_packages" "$package")"
    fi
  done

  step "Installing packages..."
  eval "set -- $apt_packages"
  sudo_cmd apt install --no-install-recommends -y "$@"
  eval "set -- $dpkg_packages"
  install_dpkg_packages "$@"
}

use_apt() {
  local package="$1"

  field manager apt
  field package "$package"
  add_package
}

_sort_version() {
  sed 'h; s/[+-]/./g; s/.p\([[:digit:]]\)/.z\1/; s/$/.z/; G; s/\n/ /' |
    LC_ALL=C sort -i -t. -k 1,1 -k 2,2n -k 3,3n -k 4,4n -k 5,5n |
    awk '{print $2}'
}

_get_latest_version() {
  git ls-remote --tags --refs "$1" |
    grep -o 'refs/tags/v*[0-9].*' |
    cut -d/ -f3- |
    sed 's/^v//' |
    _sort_version |
    tail -n 1
}

use_dpkg() {
  local name="$1"
  local url="$2"
  local format_url="$3"

  if ! has_package curl; then
    require curl
  fi

  if test -n "$format_url"; then
    _try_git
    local version="$(_get_latest_version "$url" | sed 's/\//\\\//g')"
    local safe_url="$(printf "%s" "$url" | sed 's/\//\\\//g')"
    url="$(printf "%s" "$format_url" | sed "s/%url/$safe_url/g" | sed "s/%version/$version/g" | sed 's/%%/%/g')"
  fi

  field manager dpkg
  field package "$name"
  field url "$url"
  add_package
}
