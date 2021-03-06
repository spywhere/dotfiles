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

install_git() {
  sudo_cmd apt update -y
  sudo_cmd apt install -y git
}

update() {
  sudo_cmd apt update -y
  if test "$1" = "upgrade"; then
    sudo_cmd apt full-upgrade -y
  fi
}

install_dpkg_packages() {
  for install_dpkg_packages__package in "$@"; do
    install_dpkg_packages__name="$(parse_field "$install_dpkg_packages__package" package)"
    install_dpkg_packages__url="$(parse_field "$install_dpkg_packages__package" url)"

    install_dpkg_packages__path=$(deps "$install_dpkg_packages__name.deb")
    step "Downloading $install_dpkg_packages__path for installation..."
    cmd curl -sSL "$install_dpkg_packages__url" -o "$install_dpkg_packages__path"
    step "Installing $install_dpkg_packages__name through dpkg..."
    sudo_cmd dpkg --install "$install_dpkg_packages__path"
  done
}

install_packages() {
  install_packages__apt_packages=""
  install_packages__dpkg_packages=""
  for install_packages__package in "$@"; do
    install_packages__manager="$(parse_field "$install_packages__package" manager)"
    install_packages__name="$(parse_field "$install_packages__package" package)"

    if test "$install_packages__manager" = "apt"; then
      install_packages__apt_packages="$(_add_to_list "$install_packages__apt_packages" "$install_packages__name")"
    elif test "$install_packages__manager" = "dpkg"; then
      install_packages__dpkg_packages="$(_add_to_list "$install_packages__dpkg_packages" "$install_packages__package")"
    fi
  done

  step "Installing packages..."
  eval "set -- $install_packages__apt_packages"
  sudo_cmd apt install --no-install-recommends -y "$@"
  eval "set -- $install_packages__dpkg_packages"
  install_dpkg_packages "$@"
}

use_apt() {
  use_apt__package="$1"

  field manager apt
  field package "$use_apt__package"
  add_package
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

use_dpkg() {
  use_dpkg__name="$1"
  use_dpkg__url="$2"
  use_dpkg__format_url="$3"
  use_dpkg__fallback_version="$4"

  if ! has_package curl; then
    require curl
  fi

  if test -n "$use_dpkg__format_url"; then
    _try_git
    step "Acquiring latest version of $use_dpkg__name..."
    use_dpkg__version="$(_get_latest_version "$use_dpkg__url" | sed 's/\//\\\//g')"
    if test -z "$use_dpkg__version" -a -n "$use_dpkg__fallback_version"; then
      warn "Failed to acquire the latest version of $use_dpkg__name, will install version $use_dpkg__fallback_version instead"
      use_dpkg__version="$use_dpkg__fallback_version"
    fi
    use_dpkg__safe_url="$(printf "%s" "$use_dpkg__url" | sed 's/\//\\\//g')"
    use_dpkg__url="$(printf "%s" "$use_dpkg__format_url" | sed "s/%url/$use_dpkg__safe_url/g" | sed "s/%version/$use_dpkg__version/g" | sed 's/%%/%/g')"
  fi

  field manager dpkg
  field package "$use_dpkg__name"
  field url "$use_dpkg__url"
  add_package
}
