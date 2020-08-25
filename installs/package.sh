#!/bin/sh

set -e

if
  (! command -v print >/dev/null 2>&1) ||
  ! `print 3 a b >/dev/null 2>&1` ||
  test "`print 3 a b`" != "a  b";
then
  echo "Please run this script through \"install.sh\" instead"
  exit 1
fi

install_packages() {
  if test $OS = "Mac"; then
    setup_homebrew

    # Install all our dependencies with bundle (See Brewfile)
    print "Satisfying dependencies..."
    do_command brew tap homebrew/bundle
    do_command brew bundle
  elif test $OS = "Debian"; then
    print "Installing packages..."
    packages=$(grep "#deb" Brewfile | cut -d' ' -f2 | xargs)
    do_sudo_command apt install --no-install-recommends -y $packages
  elif test $OS = "Alpine"; then
    edge_packages=$(grep "#edge-alpine" Brewfile | cut -d' ' -f2 | xargs)
    testing_packages=$(grep "#testing-alpine" Brewfile | cut -d' ' -f2 | xargs)
    community_packages=$(grep "#community-alpine" Brewfile | cut -d' ' -f2 | xargs)
    packages=$(grep "#alpine" Brewfile | cut -d' ' -f2 | xargs)

    print "Installing edge packages..."
    do_sudo_command apk add --repository=http://dl-cdn.alpinelinux.org/alpine/edge/main $edge_packages

    print "Installing testing packages..."
    do_sudo_command apk add --repository=http://dl-cdn.alpinelinux.org/alpine/edge/testing $testing_packages

    print "Installing community packages..."
    do_sudo_command apk add --repository=http://dl-cdn.alpinelinux.org/alpine/edge/community $community_packages

    print "Installing packages..."
  do_sudo_command apk add $packages
  else
    error "Failed: Unsupported operating system"
    quit 1
  fi
}

install_packages
