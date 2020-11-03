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

DEPS_DIR="$HOME/$DOTFILES/deps"

# References:
#  - https://www.docker.com/blog/happy-pi-day-docker-raspberry-pi/
#  - https://howchoo.com/g/nmrlzmq1ymn/how-to-install-docker-on-your-raspberry-pi
make_docker() {
  if test $OS = "Alpine"; then
    print "Alpine is not supported"
    return
  fi
  do_command curl -sSL get.docker.com | sh
  if test "`whoami`" = "root"; then
    print "run as root: no user group set"
  else
    do_sudo_command usermod -aG docker $USER
  fi
}

# References:
#  - https://github.com/dvorka/hstr/blob/master/INSTALLATION.md#build-on-any-linux-distro
make_hstr() {
  if test $OS = "Alpine"; then
    print "Available through apk"
    return
  fi
  clone https://github.com/dvorka/hstr hstr hstr
  # debug
  print "entering build directory..."
  do_command cd ./hstr/build/tarball
  # debug
  print "preparing..."
  do_command sh ./tarball-automake.sh
  # debug
  print "exiting build directory..."
  do_command cd ../..
  # debug
  print "configuring..."
  do_command ./configure
  # debug
  print "compiling..."
  do_command make
  # debug
  print "installing..."
  do_sudo_command make install

  # print "Building image..."
  # docker build -t hstr . -f $HOME/$DOTFILES/supports/hstr/Dockerfile.$OS
  # print "Running image..."
  # docker run -it --name hstr-cli hstr hstr -v
  # print "Copy binaries..."
  # docker cp hstr-cli:/usr/bin/hstr .
  # ls
  # print "Cleaning up..."
  # docker rm hstr-cli
  # docker rmi hstr
}

# References:
#  - https://github.com/neovim/neovim/wiki/Building-Neovim#building
make_neovim() {
  clone https://github.com/neovim/neovim neovim neovim
  do_command cd neovim
  do_command make CMAKE_BUILD_TYPE=Release
  do_sudo_command make install
}

# References:
#  - https://github.com/mobile-shell/mosh/issues/961#issuecomment-565741393
make_mosh() {
  clone https://github.com/mobile-shell/mosh mosh mosh
  do_command cd mosh
  do_command ./autogen.sh
  do_command ./configure
  do_command make
  do_sudo_command make install
}

make_sc_im() {
  if test $OS = "Alpine"; then
    print "Alpine setup is not yet prepared"
    return
  fi
  clone https://github.com/jmcnamara/libxlsxwriter.git libxlsxwriter
  do_command cd libxlsxwriter/
  do_command make
  do_sudo_command make install
  do_sudo_command ldconfig
  do_command cd "$DEPS_DIR"
  clone https://github.com/andmarti1424/sc-im.git sc-im sc-im
  do_command cd sc-im/src
  do_command make
  do_sudo_command make install
}

try_make() {
  if test "$(( $1 >> $2 & 1 ))" -eq 0; then
    return
  fi

  if (
    test -n "$4" && test `command -v "$4"`
  ) || (
    test `command -v "$3"`
  ); then
    print "$3 is already installed"
    return
  fi

  print "Installing $3..."
  PREVIOUS_DIR=`pwd`
  do_command mkdir -p "$DEPS_DIR"
  do_command cd "$DEPS_DIR"
  case "$1" in
    docker)
      make_docker
      ;;
    hstr)
      make_hstr
      ;;
    neovim)
      make_neovim
      ;;
    mosh)
      make_mosh
      ;;
    sc-im)
      make_sc_im
      ;;
    *)
      ;;
  esac
  do_command cd "$PREVIOUS_DIR"
  do_command rm -rf "$DEPS_DIR"
}

make_packages() {
  if test -d "$DEPS_DIR"; then
    do_command rm -rf "$DEPS_DIR"
  fi

  # All packages already available through Homebrew
  if test $OS = "Mac"; then
    return
  fi
  try_make $CONFIG_MAKE 0 hstr
  try_make $CONFIG_MAKE 1 docker
  try_make $CONFIG_MAKE 2 neovim nvim
  try_make $CONFIG_MAKE 3 mosh
  try_make $CONFIG_MAKE 4 sc-im
}

make_packages
