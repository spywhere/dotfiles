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
  sudo_cmd pacman -Sy --noconfirm --needed git
}

update() {
  if test "$1" = "upgrade"; then
    sudo_cmd pacman -Syu --noconfirm
  else
    sudo_cmd pacman -Sy --noconfirm
  fi
}

install_packages() {
  install_packages__bin_packages=""

  install_packages__install_packages=""
  install_packages__reinstall_packages=""
  step "Collecting packages..."
  for install_packages__package in "$@"; do
    install_packages__manager="$(parse_field "$install_packages__package" manager)"

    if test "$install_packages__manager" = "bin"; then
      install_packages__bin_packages="$(_add_to_list "$install_packages__bin_packages" "$install_packages__package")"
    else
      install_packages__name="$(parse_field "$install_packages__package" package)"
      install_packages__reinstall="$(parse_field "$install_packages__package" reinstall)"
      if test -n "$install_packages__reinstall"; then
        install_packages__reinstall_packages="$(_add_to_list "$install_packages__reinstall_packages" "$install_packages__name")"
      else
        install_packages__install_packages="$(_add_to_list "$install_packages__install_packages" "$install_packages__name")"
      fi
    fi
  done
  if test -n "$install_packages__install_packages"; then
    step "Installing packages..."
    eval "set -- $install_packages__install_packages"
    sudo_cmd pacman -S --noconfirm --needed "$@"
  fi
  if test -n "$install_packages__reinstall_packages"; then
    eval "set -- $install_packages__reinstall_packages"
    sudo_cmd pacman -S --noconfirm "$@"
  fi
  if test -n "$install_packages__bin_packages"; then
    eval "set -- $install_packages__bin_packages"
    install_bins "$@"
  fi
}

use_pacman() {
  use_pacman__package="$1"
  shift

  while test "$1" != ""; do
    case "$1" in
      --reinstall)
        field reinstall 1
        ;;
    esac

    shift
  done

  field manager pacman
  field package "$use_pacman__package"
  add_package
}
