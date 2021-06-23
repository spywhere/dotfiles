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

. systems/base.sh

setup() {
  local apple_silicon=""
  if test "$(arch)" = "arm64"; then
    info "Detected running on Apple Silicon..."
    add_flag "apple-silicon"
    apple_silicon="arm64"
  fi

  if has_cmd pkgutil && test -n "$apple_silicon" -a "$(pkgutil --pkgs=com.apple.pkg.RosettaUpdateAuto)" != "com.apple.pkg.RosettaUpdateAuto"; then
    info "Installing Rosetta 2..."
    cmd softwareupdate --install-rosetta --agree-to-license
  fi

  if ! has_cmd ruby; then
    error "Failed: either install \"ruby\" or \"homebrew\", and try again"
    quit 1
  fi

  if test -n "$apple_silicon" -a ! -f /opt/homebrew/bin/brew; then
    info "Installing (Apple Silicon) Homebrew..."
    sudo_cmd -v
    cmd bash -c "NONINTERACTIVE=1 $(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)"
  fi

  if test -f /opt/homebrew/bin/brew; then
    export PATH="/opt/homebrew/bin:$PATH"
  fi

  if test -f /usr/local/Homebrew/bin/brew; then
    return
  fi

  if test -z "$apple_silicon"; then
    info "Installing Homebrew..."
    sudo_cmd -v
    cmd bash -c "NONINTERACTIVE=1 $(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)"
  fi
}

run_intel_brew() {
  local brew_path="/usr/local/Homebrew/bin"
  local executable=""

  if test -f "$brew_path/brew"; then
    executable="$brew_path/brew"
  else
    error "Failed: homebrew setup has been completed, but \"brew\" command cannot be found at $brew_path"
    quit 1
  fi

  cmd arch -x86_64 "$executable" $@
}

run_brew() {
  local brew_path="/usr/local/Homebrew/bin"
  local executable=""
  if has_flag "apple-silicon"; then
    brew_path="/opt/homebrew/bin"
  fi

  if test -f "$brew_path/brew"; then
    executable="$brew_path/brew"
  else
    error "Failed: homebrew setup has been completed, but \"brew\" command cannot be found at $brew_path"
    quit 1
  fi

  cmd "$executable" $@
}

has_login_app_store() {
  if mas account >/dev/null; then
    return 0
  else
    return 1
  fi
}

wait_for_app_store() {
  last_check=""
  while ! has_login_app_store; do
    printf "%s%s\r" "$esc_yellow==> ACTION REQUIRED$esc_reset: Please sign in into App Store..." "$last_check"
    sleep 5
    last_check=" (last check at $(date "+%H:%M:%S"))"
  done
  if test -n "$last_check"; then
    info "App Store signed in                                                 "
  fi
}

run_mas() {
  if ! has_cmd mas; then
    error "Failed: \"mas\" command cannot be found, eventhough it pass the checks. This might indicate some issue"
    quit 1
  fi

  wait_for_app_store

  cmd mas install $@
}

update() {
  run_brew update --force # https://github.com/Homebrew/brew/issues/1151
  if test "$1" = "upgrade"; then
    run_brew upgrade
    run_brew cleanup
  fi
}

tap_repo() {
  local repo
  for repo in $@; do
    run_brew tap $repo
  done
}

install_packages() {
  local tap_repos=""

  local formula_packages=""
  local cask_packages=""
  local flagged_packages=""
  local intel_formula_packages=""
  local intel_cask_packages=""
  local intel_flagged_packages=""
  local mas_packages=""

  local package
  for package in $@; do
    local manager=$(printf "%s" "$package" | cut -d'|' -f1)

    if test "$manager" = "brew" -o "$manager" = "brow"; then
      local tap=$(printf "%s" "$package" | cut -d'|' -f2)
      local name=$(printf "%s" "$package" | cut -d'|' -f3)
      local flags=$(printf "%s" "$package" | cut -d'|' -f4-)

      if has_flag "apple-silicon" && test "$manager" = "brow"; then
        if test "$tap" = "cask"; then
          intel_cask_packages=$(_add_item "$intel_cask_packages" " " "$name")
        elif test "$tap" = "formula" -a -n "$flags"; then
          intel_flagged_packages=$(_add_item "$intel_flagged_packages" " " "$name|$flags")
        elif test "$tap" = "formula"; then
          intel_formula_packages=$(_add_item "$intel_formula_packages" " " "$name")
        fi
      else
        if test "$tap" = "cask"; then
          cask_packages=$(_add_item "$cask_packages" " " "$name")
        elif test "$tap" = "formula" -a -n "$flags"; then
          flagged_packages=$(_add_item "$flagged_packages" " " "$name|$flags")
        elif test "$tap" = "formula"; then
          formula_packages=$(_add_item "$formula_packages" " " "$name")
        fi
      fi
    elif test "$manager" = "tap"; then
      local name=$(printf "%s" "$package" | cut -d'|' -f2)
      tap_repos=$(_add_item "$tap_repos" " " "$name")
    fi
  done

  local brew_flags=""
  if test $FORCE_INSTALL -eq 1; then
    brew_flags="--force"
  fi

  if test -n "$mas_packages"; then
    if ! has_cmd mas; then
      info "Installing mas for App Store installation..."
      run_brew install --formula $brew_flags mas
    fi
    wait_for_app_store
  fi

  if test -n "$tap_repos"; then
    info "Tapping repositories..."
    tap_repo $tap_repos
  fi

  if test -n "$formula_packages"; then
    info "Installing packages..."
    run_brew install --formula $brew_flags $formula_packages
    if test -n "$intel_formula_packages"; then
      run_intel_brew install --formula $brew_flags $intel_formula_packages
    fi
  fi

  if test -n "$flagged_packages"; then
    info "Installing packages with additional flags..."
    local package
    for package in $flagged_packages; do
      local name=$(printf "%s" "$package" | cut -d'|' -f1)
      local flags=$(printf "%s" "$package" | cut -d'|' -f2- | sed 's/|/ /g')
      run_brew install --formula $brew_flags $name $flags
    done
    if test -n "$intel_flagged_packages"; then
      for package in $intel_flagged_packages; do
        local name=$(printf "%s" "$package" | cut -d'|' -f1)
        local flags=$(printf "%s" "$package" | cut -d'|' -f2- | sed 's/|/ /g')
        run_intel_brew install --formula $brew_flags $name $flags
      done
    fi
  fi

  if test -n "$cask_packages"; then
    info "Installing cask packages..."
    run_brew install --cask $brew_flags $cask_packages
    if test -n "$intel_cask_packages"; then
      run_intel_brew install --cask $brew_flags $intel_cask_packages
    fi
  fi

  if test -n "$mas_packages"; then
    info "Installing App Store packages..."
    run_mas $mas_packages
  fi
}

use_brow() {
  local tap="$1"
  local package="$2"
  shift
  shift
  add_package brow "$tap" "$package" $@
}

use_brew() {
  local tap="$1"
  local package="$2"
  shift
  shift
  add_package brew "$tap" "$package" $@
}

use_brew_tap() {
  local tap="$1"
  add_package tap "$tap"
}
