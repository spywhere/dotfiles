#!/usr/bin/env bash

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
  echo "Installing MAS..."
  brew install mas

  # Install Brew Packages
  echo "Checking homebrew packages..."
  brew_packages=()
  while read line; do
      brew_packages+=($line)
  done < "homebrew-core"
  if [ -n "$brew_packages" ]; then
    brew install ${ brew_packages }
  fi
  
  # Install Brew Cask Packages
  echo "Checking homebrew cask packages..."
  brew_packages=()
  while read line; do
      brew_packages+=($line)
  done < "homebrew-cask"
  if [ -n "$brew_packages" ]; then
    brew cask install ${ brew_packages }
  fi

  # Install Mac Apps
  mas_signin_msg=$(mas account | sed -n "/Not signed in/p")

  while [ "$mas_signin_msg" ]; do
      echo "[$mas_signin_msg]"
      read -p "Mac AppStore Email: " mas_mail
      read -s -p "Mac AppStore Password: " mas_pwd
      echo
      
      echo "Signing in to the Mac AppStore..."
      mas_signin_msg=$(mas signin $mas_mail $mas_pwd | sed -n "/failed/p")
      if [ "$mas_signin_msg" ]; then
          echo "Failed to signin. Please try again..."
      fi
  done

  mas_account=$(mas account)

  echo "Signed in as $mas_account"
  
  echo "Checking Mac Apps..."
  while read line; do
      appid=$(echo $line | sed "s/\([0-9]*\).*/\1/")
      mas install $appid
  done < "apps"
}
