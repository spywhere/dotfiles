#!/bin/bash

CURRENT_DIR=$(pwd)
if [[ $(uname) == "Darwin" ]]; then
  # Check for Homebrew and install if we don't have it
  if test ! "$(command -v brew)"; then
    echo "Installing Homebrew..."
    /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
  fi

  # Update Homebrew recipes
  echo "Checking for Homebrew update..."
  brew update --force # https://github.com/Homebrew/brew/issues/1151

  # Install all our dependencies with bundle (See Brewfile)
  echo "Satisfying dependencies..."
  brew tap homebrew/bundle
  brew bundle
else
  echo "Installing packages..."
  grep "#apt" Brewfile | cut -d' ' -f2 | xargs sudo apt install -y
  
  echo "The following packages must be installed manually:"
  grep "#make" Brewfile | cut -d' ' -f2 | xargs -n1 echo "  -"

  echo "Attempting to install a manual packages..."
  bash packages.sh
fi

echo "Updating shell to zsh..."
chsh -s "$(command -v zsh)"

rm -f "$HOME/.zshrc"
ln -s "$HOME/dotfiles/zshrc" "$HOME/.zshrc"

bash setup.sh

echo "Installing fonts..."
cd $HOME
git clone --depth 1 https://github.com/ryanoasis/nerd-fonts
cd nerd-fonts
./install.sh
cd $CURRENT_DIR

echo "Setting up configurations..."

# Symlink tmux config file to the home directory
rm -rf "$HOME/.tmux.conf"
ln -s "$HOME/dotfiles/tmux/tmux.conf" "$HOME/.tmux.conf"

# Symlink tig config file to the home directory
rm -rf "$HOME/.tigrc"
ln -s "$HOME/dotfiles/tig/tig.conf" "$HOME/.tigrc"

# Symlink nvim config file to the home directory
rm -rf "$HOME/.config/nvim"
mkdir -p $HOME/.config
ln -s "$HOME/dotfiles/nvim/" "$HOME/.config/nvim"

# Install tmux plugin manager
if [ ! -d "$HOME/.tmux/plugins/tpm" ]; then
  echo "Installing tmux plugin manager..."
  git clone https://github.com/tmux-plugins/tpm "$HOME/.tmux/plugins/tpm"
fi

# Copying shell configuration
rm -rf "$HOME/.aliases"
ln -s "$HOME/dotfiles/.aliases" "$HOME/.aliases"
rm -rf "$HOME/.variables"
ln -s "$HOME/dotfiles/.variables" "$HOME/.variables"

echo "Done!"
cd $CURRENT_DIR
