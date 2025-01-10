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

add_setup 'setup_ssh'

ssh__target="$HOME/$DOTFILES/configs/ssh"

try_generate_keypairs__has_generate=0
try_generate_keypairs() {
  if _has_indicate ssh-rsa; then
    try_generate_keypairs__suffix="id_rsa"
    try_generate_keypairs__generate() {
      ssh-keygen -b 2048 -t rsa -f "$1" -q -N ""
    }
  else
    try_generate_keypairs__suffix="sk"
    try_generate_keypairs__user="$(whoami)"
    try_generate_keypairs__generate() {
      ssh-keygen -t ed25519-sk -f "$1" -O resident -O application="ssh://$2" -O user="$try_generate_keypairs__user" -O verify-required -N ""
    }
  fi

  while test -n "$1"; do
    try_generate_keypairs__path="$ssh__target/$1.$try_generate_keypairs__suffix"

    if test -f "$try_generate_keypairs__path"; then
      info "SSH keypair for $1 is already exists"
      shift
      continue
    fi

    step "Generating SSH keypair for $1..."
    try_generate_keypairs__generate "$try_generate_keypairs__path" "$1"

    if test "$try_generate_keypairs__has_generate" -eq 0; then
        add_post_install_message "Revoke and reassign a new SSH keypair"
        try_generate_keypairs__has_generate=1
    fi
    shift
  done
}

contains() {
  case "$1" in
    *"$2"*)
      true
      ;;
    *)
      false
      ;;
  esac
}

has_suffix() {
  case "$1" in
    *"$2")
      true
      ;;
    *)
      false
      ;;
  esac
}

lookup_keypairs() {
  lookup_keypairs__path="$1"
  shift

  while test -n "$1"; do
    if ! contains  "$lookup_keypairs__path" "$1"; then
      shift
      continue
    fi

    printf '%s' "$1"
    break
  done
}

download_keypairs() {
  download_keypairs__path="$(deps keys)"
  if ! test -d "$download_keypairs__path"; then
    mkdir -p "$download_keypairs__path"
  fi
  cmd cd "$download_keypairs__path"

  ssh-keygen -K -q -P ''
  for file in ./id_*; do
    # shellcheck disable=SC2068
    if _has_indicate sk2; then
      download_keypairs__name="$(lookup_keypairs "$file" $@).sk2"
    else
      download_keypairs__name="$(lookup_keypairs "$file" $@).sk"
    fi
    if has_suffix "$file" ".pub"; then
      download_keypairs__file="$download_keypairs__name.pub"
    else
      download_keypairs__file="$download_keypairs__name"
    fi
    download_keypairs__path="$ssh__target/$download_keypairs__file"

    if test -f "$download_keypairs__path"; then
      info "SSH keypair for $download_keypairs__file is already exists"
      continue
    fi

    info "Download key $download_keypairs__file to $download_keypairs__path"
    cmd mv "$file" "$download_keypairs__path"
  done

  cmd cd "$CURRENT_DIR"
}

setup_ssh() {
  operation="download_keypairs"
  if _has_indicate generate; then
    step "Generating SSH keypairs..."
    operation="try_generate_keypairs"
  else
    step "Downloading SSH keypairs..."
  fi

  "$operation" srht github gitlab digitalocean personal
}
