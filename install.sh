#!/bin/sh

CURRENT_DIR=$(pwd)

setup_homebrew() {
  # Check for Homebrew and install if we don't have it
  if test ! "$(command -v brew)"; then
    echo "Installing Homebrew..."
    /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
  fi
}

# If ~/.dotfiles is not found, probably running through cURL / sh combination
#   try cloning the repo and setup from there instead.
if [ ! -d "$HOME/.dotfiles" ]; then
  if test ! "$(command -v git)"; then
    echo "git not found, try installing one..."
    if [ "$(uname)" = "Darwin" ]; then
      setup_homebrew
      brew install git
    else
      sudo apt update
      sudo apt install -y git
    fi
  fi

  git clone https://github.com/spywhere/dotfiles "$HOME/.dotfiles"
  cd $HOME/.dotfiles
  $HOME/.dotfiles/install.sh
  cd $CURRENT_DIR
  exit 0
fi

if [ "$(uname)" = "Darwin" ]; then
  setup_homebrew
  # Update Homebrew recipes
  echo "Checking for Homebrew update..."
  brew update --force # https://github.com/Homebrew/brew/issues/1151

  # Install all our dependencies with bundle (See Brewfile)
  echo "Satisfying dependencies..."
  brew tap homebrew/bundle
  brew bundle
else
  echo "Updating package repositories..."
  sudo apt update
  echo "Updating packages... this might take a while..."
  sudo apt full-upgrade -y
  echo "Installing packages..."
  grep "#apt" Brewfile | cut -d' ' -f2 | xargs sudo apt install -y
  
  echo "The following packages must be installed manually:"
  grep "#make" Brewfile | cut -d' ' -f2 | xargs -n1 echo "  -"

  echo "Attempting to install a manual packages..."
  bash packages.sh
fi

echo "Updating shell to zsh..."
if [ "$(basename "$SHELL")" = "zsh" ]; then
  echo "Already running zsh"
else
  chsh -s "$(command -v zsh)"
fi

rm -f "$HOME/.zshrc"
ln -s "$HOME/.dotfiles/zshrc" "$HOME/.zshrc"

bash setup.sh

echo "Installing fonts..."
if [ ! -d "$HOME/.nerd-fonts" ]; then
  cd $HOME
  git clone --depth 1 https://github.com/ryanoasis/nerd-fonts "$HOME/.nerd-fonts"
  $HOME/.nerd-fonts/install.sh
  cd $CURRENT_DIR
else
  echo "Already installed"
fi

echo "Setting up configurations..."

# Symlink tmux config file to the home directory
rm -rf "$HOME/.tmux.conf"
ln -s "$HOME/.dotfiles/tmux/tmux.conf" "$HOME/.tmux.conf"

# Symlink tig config file to the home directory
rm -rf "$HOME/.tigrc"
ln -s "$HOME/.dotfiles/tig/tig.conf" "$HOME/.tigrc"

# Symlink nvim config file to the home directory
rm -rf "$HOME/.config/nvim"
mkdir -p $HOME/.config
ln -s "$HOME/.dotfiles/nvim/" "$HOME/.config/nvim"

# Install tmux plugin manager
if [ ! -d "$HOME/.tmux/plugins/tpm" ]; then
  echo "Installing tmux plugin manager..."
  git clone https://github.com/tmux-plugins/tpm "$HOME/.tmux/plugins/tpm"
fi

# Copying shell configuration
rm -rf "$HOME/.aliases"
ln -s "$HOME/.dotfiles/.aliases" "$HOME/.aliases"
rm -rf "$HOME/.variables"
ln -s "$HOME/.dotfiles/.variables" "$HOME/.variables"

echo "Done!"
cd $CURRENT_DIR
