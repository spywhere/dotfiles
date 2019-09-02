#!/usr/bin/env bash

rat() {
  command=$1
  filepath=$2
  args=()
  while read line; do
    args+=($line)
  done < $filepath
  if [ -n "$args" ]; then
    echo "Running:" $command ${args[@]}
    $command ${args[@]}
  fi
}

pkg.install() {
  echo "Installing homebrew..."
  /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
  echo "Tapping taps..."
  brew tap homebrew/cask
  brew tap homebrew/cask-versions
  brew tap homebrew/cask-fonts
  brew tap domt4/autoupdate
  brew tap buo/cask-upgrade
  echo "Setting up homebrew auto-update..."
  mkdir -p ~/Library/LaunchAgents
  brew autoupdate --start --cleanup

  # Install Brew Packages
  echo "Checking homebrew packages..."
  rat "brew install" ".homebrew-core"
  
  # Install Brew Cask Packages
  echo "Checking homebrew cask packages..."
  rat "brew cask install" ".homebrew-cask"
  
  # Install Rust Toolchains
  echo "Installing Rust toolchains..."
  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | bash -s -y
  # Adding Rust binary to path
  echo "Adding Rust binaries to PATH..."
  source $HOME/.cargo/env
}
