#!/bin/sh

set -e

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
      sudo apt install --no-install-recommends -y git
    fi
  fi

  echo "Cloning dotfiles into ~/.dotfiles..."
  git clone https://github.com/spywhere/dotfiles "$HOME/.dotfiles"
  cd $HOME/.dotfiles
  echo "Executing script..."
  sh $HOME/.dotfiles/install.sh
  cd $CURRENT_DIR
  exit 0
fi

if [ ! "$DOTFILES" = "installed" ]; then
  export DOTFILES=installed
  sh $HOME/.dotfiles/install.sh
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
  sleep 1
  sudo apt update
  echo "Updating packages... this might take a while..."
  sleep 1
  sudo apt full-upgrade -y
  echo "Installing packages..."
  sleep 1
  grep "#apt" Brewfile | cut -d' ' -f2 | xargs sudo apt install --no-install-recommends -y
  
  echo "The following packages must be installed manually:"
  grep "#make" Brewfile | cut -d' ' -f2 | xargs -n1 echo "  -"
  sleep 1

  echo "Attempting to install a manual packages..."
  bash packages.sh
fi

echo "Updating shell to zsh..."
sleep 1
if [ "$(basename "$SHELL")" = "zsh" ]; then
  echo "Already running zsh"
else
  if sudo test -f /bin/zsh; then
    chsh -s /bin/zsh
  else
    chsh -s "$(command -v zsh)"
  fi
fi

rm -f "$HOME/.zshrc"
ln -s "$HOME/.dotfiles/zshrc" "$HOME/.zshrc"

bash setup.sh

echo "Installing fonts..."
sleep 1
if [ ! -d "$HOME/.nerd-fonts" ]; then
  cd $HOME
  git clone --depth 1 https://github.com/ryanoasis/nerd-fonts "$HOME/.nerd-fonts"
  $HOME/.nerd-fonts/install.sh
  cd $CURRENT_DIR
else
  echo "Already installed"
fi

echo "Installing node version switcher (nvs)..."
sleep 1
export NVS_HOME="$HOME/.nvs"
if [ ! -d "$NVS_HOME" ]; then
  git clone https://github.com/jasongin/nvs "$NVS_HOME"
  sh -c 'sh "$NVS_HOME/nvs.sh" install; :'
else
  echo "Already installed"
fi

echo "Setting up configurations..."

# Symlink tmux config file to the home directory
rm -rf "$HOME/.tmux.conf"
ln -s "$HOME/.dotfiles/tmux/tmux.conf" "$HOME/.tmux.conf"

# Symlink git config file to the home directory
rm -rf "$HOME/.gitignore_global"
ln -s "$HOME/.dotfiles/git/gitignore" "$HOME/.gitignore_global"
rm -rf "$HOME/.gitconfig"
ln -s "$HOME/.dotfiles/git/gitconfig" "$HOME/.gitconfig"

# Symlink tig config file to the home directory
rm -rf "$HOME/.tigrc"
ln -s "$HOME/.dotfiles/tig/tig.conf" "$HOME/.tigrc"

# Symlink nvim config file to the home directory
rm -rf "$HOME/.config/nvim"
mkdir -p $HOME/.config
ln -s "$HOME/.dotfiles/nvim/" "$HOME/.config/nvim"

# Symlink mpd config file to the home directory
rm -rf "$HOME/.mpd"
ln -s "$HOME/.dotfiles/mpd/" "$HOME/.mpd"

# Symlink ncmpcpp config file to the home directory
rm -rf "$HOME/.ncmpcpp"
ln -s "$HOME/.dotfiles/ncmpcpp/" "$HOME/.ncmpcpp"

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

# Symlink mycli config file to the home directory (if not already)
if [ ! -f "$HOME/.myclirc" ]; then
  ln -s "$HOME/.dotfiles/myclirc" "$HOME/.myclirc"
fi

echo "Done!"
echo "NOTE: Don't forget to..."
echo "  - Run 'nvim' for the first time setup"
echo "  - Press <Prefix+I> for tmux plugins installation"
cd $CURRENT_DIR
