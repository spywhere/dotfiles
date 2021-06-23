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

MIRROR="http://dl-cdn.alpinelinux.org/alpine/{branch}/{repo}"

_get_mirror_repo() {
  local repo="$1"
  local branch="$2"
  printf "%s" "$MIRROR" | sed "s/{repo}/$repo/g" | sed "s/{branch}/$branch/g"
}

update() {
  if test "$1" = "upgrade"; then
    cmd apk -U upgrade
  else
    cmd apk update
  fi
}

install_packages() {
  local main_packages=""
  local community_packages=""
  local testing_packages=""
  local edge_packages=""
  local package
  step "Collecting packages..."
  for package in "$@"; do
    local repo="$(parse_field "$package" repo)"
    local name="$(parse_field "$package" package)"
    case $repo in
      main)
        main_packages="$(_add_to_list "$main_packages" "$name")"
        ;;
      community)
        community_packages="$(_add_to_list "$community_packages" "$name")"
        ;;
      testing)
        testing_packages="$(_add_to_list "$testing_packages" "$name")"
        ;;
      edge)
        edge_packages="$(_add_to_list "$edge_packages" "$name")"
        ;;
      *)
        warn "unknown repository \"$repo\" for \"$name\""
        ;;
    esac
  done
  if test -n "$main_packages"; then
    step "Installing main packages..."
    eval "set -- $main_packages"
    cmd apk add "$@"
  fi
  if test -n "$edge_packages"; then
    step "Installing edge packages..."
    eval "set -- $edge_packages"
    cmd apk add --repository="$(_get_mirror_repo main edge)" "$@"
  fi
  if test -n "$community_packages"; then
    step "Installing community packages..."
    eval "set -- $community_packages"
    cmd apk add --repository="$(_get_mirror_repo community edge)" "$@"
  fi
  if test -n "$testing_packages"; then
    step "Installing testing packages..."
    eval "set -- $testing_packages"
    cmd apk add --repository="$(_get_mirror_repo testing edge)" "$@"
  fi
}

use_apk() {
  local repo="$1"
  local package="$2"

  field manager apk
  field repo "$repo"
  field package "$package"
  add_package
}
