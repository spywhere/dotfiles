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

MIRROR="https://dl-cdn.alpinelinux.org/alpine/{branch}/{repo}"

_get_mirror_repo() {
  get_mirror_repo__repo="$1"
  get_mirror_repo__branch="$2"
  printf "%s" "$MIRROR" | sed "s/{repo}/$get_mirror_repo__repo/g" | sed "s/{branch}/$get_mirror_repo__branch/g"
}

install_git() {
  sudo_cmd apk add --no-cache git
}

update() {
  if test "$1" = "upgrade"; then
    sudo_cmd apk -U upgrade
  else
    sudo_cmd apk update
  fi
}

install_packages() {
  install_packages__main_packages=""
  install_packages__community_packages=""
  install_packages__testing_packages=""
  install_packages__edge_packages=""
  step "Collecting packages..."
  for install_packages__package in "$@"; do
    install_packages__repo="$(parse_field "$install_packages__package" repo)"
    install_packages__name="$(parse_field "$install_packages__package" package)"
    case $install_packages__repo in
      main)
        install_packages__main_packages="$(_add_to_list "$install_packages__main_packages" "$install_packages__name")"
        ;;
      community)
        install_packages__community_packages="$(_add_to_list "$install_packages__community_packages" "$install_packages__name")"
        ;;
      testing)
        install_packages__testing_packages="$(_add_to_list "$install_packages__testing_packages" "$install_packages__name")"
        ;;
      edge)
        install_packages__edge_packages="$(_add_to_list "$install_packages__edge_packages" "$install_packages__name")"
        ;;
      *)
        warn "unknown repository \"$install_packages__repo\" for \"$install_packages__name\""
        ;;
    esac
  done
  if test -n "$install_packages__main_packages"; then
    step "Installing main packages..."
    eval "set -- $install_packages__main_packages"
    sudo_cmd apk add "$@"
  fi
  if test -n "$install_packages__edge_packages"; then
    step "Installing edge packages..."
    eval "set -- $install_packages__edge_packages"
    sudo_cmd apk add --repository="$(_get_mirror_repo main edge)" "$@"
  fi
  if test -n "$install_packages__community_packages"; then
    step "Installing community packages..."
    eval "set -- $install_packages__community_packages"
    sudo_cmd apk add --repository="$(_get_mirror_repo community edge)" "$@"
  fi
  if test -n "$install_packages__testing_packages"; then
    step "Installing testing packages..."
    eval "set -- $install_packages__testing_packages"
    sudo_cmd apk add --repository="$(_get_mirror_repo testing edge)" "$@"
  fi
}

use_apk() {
  use_apk__repo="$1"
  use_apk__package="$2"

  field manager apk
  field repo "$use_apk__repo"
  field package "$use_apk__package"
  add_package
}
