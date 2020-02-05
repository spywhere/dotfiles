#!/bin/bash

CURRENT_DIR=$(pwd)

echo "Installing docker..."
echo "References:"
echo "  - https://www.docker.com/blog/happy-pi-day-docker-raspberry-pi/"
echo "  - https://howchoo.com/g/nmrlzmq1ymn/how-to-install-docker-on-your-raspberry-pi"
if test ! "$(command -v docker)"; then
  curl -sSL get.docker.com | sh
  sudo usermod -aG docker $USER
else
  echo "docker already installed"
fi

cd $CURRENT_DIR
echo "Installing hstr..."
echo "References:"
echo "  - https://github.com/dvorka/hstr/blob/master/INSTALLATION.md#build-on-any-linux-distro"
if test ! "$(command -v hstr)"; then
  git clone https://github.com/dvorka/hstr
  cd ./hstr/build/tarball
  ./tarball-automake.sh
  cd ../..
  ./configure
  make
  make install
  cd $CURRENT_DIR
  rm -rf hstr
else
  echo "hstr already installed"
fi

cd $CURRENT_DIR
echo "Installing neovim..."
echo "References:"
echo "  - https://github.com/neovim/neovim/wiki/Building-Neovim#building"
if test ! "$(command -v nvim)"; then
  git clone https://github.com/neovim/neovim
  cd neovim
  make CMAKE_BUILD_TYPE=Release
  sudo make install
  cd $CURRENT_DIR
  rm -rf neovim
else
  echo "neovim already installed"
fi

cd $CURRENT_DIR
echo "Installing cmus..."
echo "References:"
echo "  - https://cmus.github.io/#download"
if test ! "$(command -v cmus)"; then
  git clone https://github.com/cmus/cmus .cmus
  cd .cmus
  ./configure prefix=$HOME/.cmus
  make install
else
  echo "cmus already installed"
fi

cd $CURRENT_DIR
echo "Installing mosh..."
echo "References:"
echo "  - https://github.com/mobile-shell/mosh/issues/961#issuecomment-565741393"
if test ! "$(command -v cmus)"; then
  git clone https://github.com/mobile-shell/mosh
  cd mosh
  ./autogen.sh
  ./configure
  make
  make install
  cd $CURRENT_DIR
  rm -rf mosh
else
  echo "mosh already installed"
fi

cd $CURRENT_DIR
echo "Installing oh-my-zsh..."
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
