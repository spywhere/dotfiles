#!/bin/sh

set -e

inline_support=0
esc_reset="" # reset
esc_blue="" # indicate process
esc_green="" # indicate options and information
esc_yellow="" # indicate warnings
esc_red="" # indicate errors

if test -t 1 && test -n "$TERM" -a -n "$(command -v tput)" && test "$(tput colors)" -ge 8 && test -n "$(command -v tty)"; then
  if test -n "$(command -v wc)"; then
    inline_support=1
  fi
  esc_reset="$(tput sgr0)"
  if test "$(tput colors)" -gt 8; then
    esc_blue="$(tput setaf 12)"
    esc_green="$(tput setaf 10)"
    esc_yellow="$(tput setaf 11)"
    esc_red="$(tput setaf 9)"
  else
    esc_blue="$(tput setaf 4)"
    esc_green="$(tput setaf 2)"
    esc_yellow="$(tput setaf 3)"
    esc_red="$(tput setaf 1)"
  fi
fi

_INLINING=0
print_inline() {
  if test "$VERBOSE" -eq 0 -o "$inline_support" -eq 0; then
    return
  fi

  printf "%s%${_INLINING}s\r" "$1" ""
  _INLINING="$(printf "%s" "$1" | wc -c)"
}

print() {
  if test "$VERBOSE" -eq 0; then
    return
  fi

  if test "$_INLINING" -gt 0; then
    printf "\r"
    _INLINING=0
  fi
  force_print "$@"
}

error() {
  if test -z "$@"; then
    >&2 printf "\n"
    return
  fi
  printf "$esc_red==> ERROR$esc_reset: %s\n" "$*" >&2
}

warn() {
  if test -z "$@"; then
    print
    return
  fi
  print "$esc_yellow==> WARN$esc_reset: $*"
}

info() {
  print "$esc_green==> INFO:$esc_reset $*"
}

step() {
  print "$esc_blue==>$esc_reset $*"
}

case "$(uname -s)" in
  Darwin*)
    is_mac () {
      return 0
    }
    ;;
  *)
    is_mac () {
      return 1
    }
    ;;
esac

if test "$(arch)" = "arm64"; then
  is_arm64() {
    return 0
  }
else
  is_arm64() {
    return 1
  }
fi

has_homebrew_installed() {
  if is_arm64 && test -f /opt/homebrew/bin/brew; then
    return 0
  elif ! is_arm64 && test -f /usr/local/Homebrew/bin/brew; then
    return 0
  fi

  return 1
}

install_homebrew() {
  export HOMEBREW_NO_ANALYTICS=1
  if ! has_homebrew_installed; then
    info "Installing Homebrew..."
    /bin/bash -c "NONINTERACTIVE=1 $(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  fi
}

install_rosetta() {
  if is_arm64 && test -n "$(command -v pkgutil)" -a "$(pkgutil --pkgs=com.apple.pkg.RosettaUpdateAuto)" != "com.apple.pkg.RosettaUpdateAuto"; then
    info "Installing Rosetta 2..."
    softwareupdate --install-rosetta --agree-to-license
  fi
}

install_nix() {
  curl -L https://nixos.org/nix/install | sh -s -- --daemon --yes
}

main() {
  if is_mac; then
    install_homebrew
    install_rosetta
  fi

  install_nix
}

main "$@"
