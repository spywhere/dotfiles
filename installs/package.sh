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
    do_command grep "#deb" Brewfile | cut -d' ' -f2 | xargs sudo apt install --no-install-recommends -y
  elif test $OS = "Alpine"; then
    print "Installing edge packages..."
    do_command grep "#edge-alpine" Brewfile | cut -d' ' -f2 | xargs apk add --repository=http://dl-cdn.alpinelinux.org/alpine/edge/main
    print "Installing testing packages..."
    do_command grep "#testing-alpine" Brewfile | cut -d' ' -f2 | xargs apk add --repository=http://dl-cdn.alpinelinux.org/alpine/edge/testing
    print "Installing community packages..."
    do_command grep "#community-alpine" Brewfile | cut -d' ' -f2 | xargs apk add --repository=http://dl-cdn.alpinelinux.org/alpine/edge/community
    print "Installing packages..."
    do_command grep "#alpine" Brewfile | cut -d' ' -f2 | xargs apk add
  else
    error "Failed: Unsupported operating system"
    quit 1
  fi
}

install_packages
