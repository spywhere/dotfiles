#!/bin/sh

set -e

if
  (! command -v force_print >/dev/null 2>&1) ||
  ! $(force_print 3 a b >/dev/null 2>&1) ||
  test "$(force_print 3 a b)" != "a  b";
then
  printf "Please run this script through \"install.sh\" instead"
  exit 1
fi

add_setup 'setup_config'

setup_config() {
  # alacritty
  link alacritty/alacritty.yml .alacritty.yml

  # asdf
  link asdf/asdf .tool-versions
  link asdf/npm-packages .default-npm-packages
  link asdf/python-packages .default-python-packages

  # bat
  link bat/ .config/bat

  # git
  link git/gitalias .gitalias
  link git/gitconfig .gitconfig
  link git/gitconfig.$OS .gitconfig.platform
  link git/gitignore .gitignore_global

  # github
  link github/ .config/github

  # mpd
  link mpd/ .mpd

  # mycli
  link mycli/myclirc .myclirc

  # ncmpcpp
  link ncmpcpp/ .ncmpcpp

  # neomutt
  link neomutt/ .config/neomutt

  # nvim
  link nvim/ .config/nvim
  add_post_install_message "Run 'nvim' for the first time setup"

  # tig
  link tig/tig.conf .tigrc

  # tmux
  link tmux/tmux.conf .tmux.conf

  # w3m
  link w3m/ .w3m

  # zsh
  link zsh/zshrc .zshrc
}
