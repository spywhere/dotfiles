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

download_binary() {
  while test "$1" != ""; do
    DOWNLOAD_URL=$1
    shift
    BINARY_NAME=$1
    shift
    print "Installing $BINARY_NAME..."
    do_command mkdir -p "$INSTALL_PATH"
    do_command curl -o "$INSTALL_PATH/$BINARY_NAME" "$DOWNLOAD_URL"
    print "Download $DOWNLOAD_URL as $INSTALL_PATH/$BINARY_NAME"
    do_command chmod +x "$INSTALL_PATH/$BINARY_NAME"
  done
}

install_binary() {
  if
    test $OS = "Mac" ||
    test $OS = "Debian" ||
    test $OS = "Alpine";
  then
    # Setup default installation path, if one is not found
    if test -z "$INSTALL_PATH"; then
      INSTALL_PATH=/usr/local/bin
    fi

    try_command curl
    print "Installing binaries..."
    BINARIES=`grep "#binary" Brewfile | cut -d ' ' -f2,3`
    download_binary $BINARIES
  else
    error "Failed: Unsupported operating system"
    quit 1
  fi
}

install_binary
