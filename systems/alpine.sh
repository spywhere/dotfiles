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
  if test $1 = "upgrade"; then
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
  for package in $@; do
    local repo=$(printf "%s" "$package" | cut -d'|' -f2)
    local name=$(printf "%s" "$package" | cut -d'|' -f3)
    case $repo in
      main)
        main_packages=$(_add_item "$main_packages" " " "$name")
        ;;
      community)
        community_packages=$(_add_item "$community_packages" " " "$name")
        ;;
      testing)
        testing_packages=$(_add_item "$testing_packages" " " "$name")
        ;;
      edge)
        edge_packages=$(_add_item "$edge_packages" " " "$name")
        ;;
      *)
        warn "unknown repository \"$repo\" for \"$name\""
        ;;
    esac
  done
  if test -n "$main_packages"; then
    print "Installing main packages..."
    cmd apk add $main_packages
  fi
  if test -n "$edge_packages"; then
    print "Installing edge packages..."
    cmd apk add --repository=$(_get_mirror_repo main edge) $edge_packages
  fi
  if test -n "$community_packages"; then
    print "Installing community packages..."
    cmd apk add --repository=$(_get_mirror_repo community edge) $community_packages
  fi
  if test -n "$testing_packages"; then
    print "Installing testing packages..."
    cmd apk add --repository=$(_get_mirror_repo testing edge) $testing_packages
  fi
}

use_apk() {
  local repo="$1"
  local package="$2"
  add_package apk "$repo" "$package"
}
