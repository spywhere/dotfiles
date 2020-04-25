#!/bin/sh

set -e

DOTFILES_NAME=.dotfiles
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
if [ ! -d "$HOME/$DOTFILES_NAME" ]; then
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

  echo "Cloning dotfiles into ~/$DOTFILES_NAME..."
  git clone https://github.com/spywhere/dotfiles "$HOME/$DOTFILES_NAME"
  export DOTFILES_FIRSTTIME="yes"
fi

if [ ! "$DOTFILES" = "installed" ]; then
  export DOTFILES=installed
  cd $HOME/$DOTFILES_NAME
  if [ "$DOTFILES_FIRSTTIME" != "yes" ]; then
    echo "Updating dotfiles..."
    git reset --hard
    git fetch
    git pull
  fi
  echo "Executing script..."
  sh $HOME/$DOTFILES_NAME/install.sh
  cd $CURRENT_DIR
  exit 0
fi

export DOTFILES=

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

  echo "Installing binaries..."
  grep "#curl" Brewfile | cut -d ' ' -f2,3 | xargs -n2 sh -c 'echo Installing $(basename "$1")... && curl -sSL "$0" | sudo tee "$1" >/dev/null && sudo chmod 755 "$1"'
  
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
ln -s "$HOME/$DOTFILES_NAME/zshrc" "$HOME/.zshrc"

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

echo "Installing version manager (asdf)..."
sleep 1
if [ ! -d "$HOME/.asdf" ]; then
  git clone https://github.com/asdf-vm/asdf "$HOME/.asdf"
  cd $HOME/.asdf
  git checkout "$(git describe --abbrev=0 --tags)"
  cd $CURRENT_DIR
else
  echo "Already installed"
fi

echo "Setting up configurations..."

# Symlink Alacritty config file to the home directory
rm -rf "$HOME/.alacritty.yml"
ln -s "$HOME/$DOTFILES_NAME/alacritty.yml" "$HOME/.alacritty.yml"

# Symlink tmux config file to the home directory
rm -rf "$HOME/.tmux.conf"
ln -s "$HOME/$DOTFILES_NAME/tmux/tmux.conf" "$HOME/.tmux.conf"

# Symlink git config file to the home directory
rm -rf "$HOME/.gitignore_global"
ln -s "$HOME/$DOTFILES_NAME/git/gitignore" "$HOME/.gitignore_global"
rm -rf "$HOME/.gitalias"
ln -s "$HOME/$DOTFILES_NAME/git/gitalias" "$HOME/.gitalias"
if [ ! -f "$HOME/.gitconfig" ]; then
  ln -s "$HOME/$DOTFILES_NAME/git/gitconfig" "$HOME/.gitconfig"
fi

# Symlink tig config file to the home directory
rm -rf "$HOME/.tigrc"
ln -s "$HOME/$DOTFILES_NAME/tig/tig.conf" "$HOME/.tigrc"

# Symlink nvim config file to the home directory
rm -rf "$HOME/.config/nvim"
mkdir -p $HOME/.config
ln -s "$HOME/$DOTFILES_NAME/nvim/" "$HOME/.config/nvim"

# Symlink mpd config file to the home directory
if [ ! -d "$HOME/.mpd" ]; then
  ln -s "$HOME/$DOTFILES_NAME/mpd/" "$HOME/.mpd"
fi

# Symlink ncmpcpp config file to the home directory
if [ ! -d "$HOME/.ncmpcpp" ]; then
  ln -s "$HOME/$DOTFILES_NAME/ncmpcpp/" "$HOME/.ncmpcpp"
fi

# Install tmux plugin manager
if [ ! -d "$HOME/.tmux/plugins/tpm" ]; then
  echo "Installing tmux plugin manager..."
  git clone https://github.com/tmux-plugins/tpm "$HOME/.tmux/plugins/tpm"
fi

# asdf tool versions
rm -rf "$HOME/.tool-versions"
ln -s "$HOME/$DOTFILES_NAME/asdf" "$HOME/.tool-versions"
rm -rf "$HOME/.default-npm-packages"
ln -s "$HOME/$DOTFILES_NAME/npm-packages" "$HOME/.default-npm-packages"
echo "Adding version manager plugins..."
set +e
bash -c '. ~/.asdf/asdf.sh && asdf plugin-add 1password https://github.com/samtgarson/asdf-1password.git'
bash -c '. ~/.asdf/asdf.sh && asdf plugin-add deno https://github.com/asdf-community/asdf-deno.git'
bash -c '. ~/.asdf/asdf.sh && asdf plugin-add docker-slim https://github.com/everpeace/asdf-docker-slim.git'
bash -c '. ~/.asdf/asdf.sh && asdf plugin-add golang https://github.com/kennyp/asdf-golang.git'
bash -c '. ~/.asdf/asdf.sh && asdf plugin add firebase https://github.com/jthegedus/asdf-firebase.git'
bash -c '. ~/.asdf/asdf.sh && asdf plugin-add nodejs https://github.com/asdf-vm/asdf-nodejs.git'
bash -c '. ~/.asdf/asdf.sh && asdf plugin-add python https://github.com/danhper/asdf-python.git'
bash -c '. ~/.asdf/asdf.sh && asdf plugin-add rust https://github.com/code-lever/asdf-rust.git'
bash -c '. ~/.asdf/asdf.sh && asdf plugin-add terraform https://github.com/Banno/asdf-hashicorp.git'
set -e
bash ~/.asdf/plugins/nodejs/bin/import-release-team-keyring
echo "Install default tool versions..."
cd $HOME
bash -c '. ~/.asdf/asdf.sh && asdf install'
cd $CURRENT_DIR

# Copying shell configuration
rm -rf "$HOME/.aliases"
ln -s "$HOME/$DOTFILES_NAME/aliases" "$HOME/.aliases"
rm -rf "$HOME/.variables"
ln -s "$HOME/$DOTFILES_NAME/variables" "$HOME/.variables"

# Symlink mycli config file to the home directory (if not already)
if [ ! -f "$HOME/.myclirc" ]; then
  ln -s "$HOME/$DOTFILES_NAME/myclirc" "$HOME/.myclirc"
fi

echo "Done!"
echo "NOTE: Don't forget to..."
echo "  - Run 'nvim' for the first time setup"
echo "  - Press <Prefix+I> for tmux plugins installation"
cd $CURRENT_DIR
