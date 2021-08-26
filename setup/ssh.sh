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

require 'ssh-keygen'

add_setup 'setup_ssh'

try_generate_keypair__has_generate=0
try_generate_keypair() {
  try_generate_keypair__path="$HOME/$DOTFILES/configs/ssh/$1.id_rsa"
  if test -f "$try_generate_keypair__path"; then
    info "SSH keypair for $1 is already exists"
  else
    step "Generating SSH keypair for $1..."
    ssh-keygen -b 2048 -t rsa -f "$try_generate_keypair__path" -q -N ""

    if test "$try_generate_keypair__has_generate" -eq 0; then
        add_post_install_message "Revoke and reassign a new SSH keypair"
        try_generate_keypair__has_generate=1
    fi
  fi
}

setup_ssh() {
  # generate SourceHut key pair
  try_generate_keypair srht

  # generate GitHub key pair
  try_generate_keypair github
}
