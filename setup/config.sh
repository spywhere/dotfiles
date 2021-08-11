#!/bin/sh

set -e

if
  ! (command -v force_print >/dev/null 2>&1) ||
  ! (force_print 3 a b >/dev/null 2>&1) ||
  test "$(force_print 3 a b)" != "a  b";
then
  printf "Please run this script through \"install.sh\" instead"
  exit 1
fi

add_setup 'setup_config'

setup_config() {
  step "Setting up configurations..."

  if has_package alacritty; then
    step "  - Alacritty"
    link alacritty/alacritty.yml .alacritty.yml
  fi

  step "  - asdf"
  link asdf/asdf .tool-versions
  link asdf/npm-packages .default-npm-packages
  link asdf/python-packages .default-python-packages

  if ! test -d "$HOME/.config"; then
    cmd mkdir -p "$HOME/.config"
  fi

  step "  - bat"
  link bat/ .config/bat

  step "  - code-server"
  link code-server/ .config/code-server

  step "  - git"
  link git/gitalias .gitalias
  link git/gitconfig .gitconfig
  if test -f "$HOME/$DOTFILES/configs/git/gitconfig.$OS"; then
    link "git/gitconfig.$OS" .gitconfig.platform
  elif test -f "$HOME/$DOTFILES/configs/git/gitconfig.$OSKIND"; then
    link "git/gitconfig.$OSKIND" .gitconfig.platform
  else
    warn "No platform specific git configuration for \"$OSNAME\""
  fi
  link git/gitignore .gitignore_global

  step "  - github"
  link github/ .config/github

  if has_package iterm2; then
    step "  - iTerm2"
    link iterm2/ "Library/Application Support/iTerm2"
  fi

  if has_package kitty; then
    step "  - kitty"
    link kitty/ .config/kitty
  fi

  step "  - mpd"
  link mpd/ .mpd

  step "  - mycli"
  link mycli/myclirc .myclirc

  step "  - ncmpcpp"
  link ncmpcpp/ .ncmpcpp

  step "  - neomutt"
  link neomutt/ .config/neomutt

  step "  - neovim"
  link nvim/ .config/nvim
  add_post_install_message "Run 'nvim' for the first time setup"

  step "  - ssh"
  link ssh/ .ssh

  step "  - tig"
  link tig/tig.conf .tigrc

  step "  - tmux"
  link tmux/tmux.conf .tmux.conf

  if ! test -f "$HOME/.wakatime.cfg"; then
    # copy instead as file can contain a secret
    step "  - wakatime"
    copy wakatime/wakatime.cfg .wakatime.cfg
  fi

  step "  - w3m"
  link w3m/ .w3m

  step "  - zsh"
  link zsh/zshrc .zshrc
}
