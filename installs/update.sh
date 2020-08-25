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

update() {
  if test $OS = "Mac"; then
    setup_homebrew
    print "Checking for Homebrew update..."
    do_command brew update --force # https://github.com/Homebrew/brew/issues/1151
    print "Updating packages... this might take a while..."
    do_command brew upgrade
  elif test $OS = "Debian"; then
    print "Updating package repositories..."
    do_sudo_command apt update
    print "Updating packages... this might take a while..."
    do_sudo_command apt full-upgrade -y
  elif test $OS = "Alpine"; then
    print "Updating package repositories..."
    do_command apk update
    print "Updating packages... this might take a while..."
    do_command apk upgrade
  else
    error "Failed: Unsupported operating system"
    quit 1
  fi
}

update
