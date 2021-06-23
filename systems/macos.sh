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

_run_intel_brew() {
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

_run_brew() {
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

  cmd "$executable" "$@"
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

  cmd mas install "$@"
}

update() {
  _run_brew update --force # https://github.com/Homebrew/brew/issues/1151
  if test "$1" = "upgrade"; then
    _run_brew upgrade
    _run_brew cleanup
  fi
}

tap_repo() {
  local repo
  for repo in $@; do
    _run_brew tap $repo
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

  step "Collecting packages..."
  local package
  for package in "$@"; do
    local manager="$(parse_field "$package" manager)"

    if test "$manager" = "brew" -o "$manager" = "brow"; then
      local name="$(parse_field "$package" package)"
      local kind="$(parse_field "$package" kind)"
      local flags="$(parse_field "$package" flags)"
      if test -n "$flags"; then
        flags="$(_escape_special "$flags")"
      fi

      if has_flag "apple-silicon" && test "$manager" = "brow"; then
        if test "$kind" = "cask"; then
          intel_cask_packages="$(_add_to_list "$intel_cask_packages" "$name")"
        elif test "$kind" = "formula" -a -n "$flags"; then
          intel_flagged_packages="$(_add_to_list "$intel_flagged_packages" "$name;$flags")"
        elif test "$kind" = "formula"; then
          intel_formula_packages="$(_add_to_list "$intel_formula_packages" "$name")"
        fi
      else
        if test "$kind" = "cask"; then
          cask_packages="$(_add_to_list "$cask_packages" "$name")"
        elif test "$kind" = "formula" -a -n "$flags"; then
          flagged_packages="$(_add_to_list "$flagged_packages" "$name;$flags")"
        elif test "$kind" = "formula"; then
          formula_packages="$(_add_to_list "$formula_packages" "$name")"
        fi
      fi
    elif test "$manager" = "tap"; then
      local tap="$(parse_field "$package" tap)"
      tap_repos="$(_add_to_list "$tap_repos" "$tap")"
    elif test "$manager" = "mas"; then
      local package_id="$(parse_field "$package" package)"
      mas_packages="$(_add_to_list "$mas_packages" "$package_id")"
    fi
  done

  local brew_flags=""
  if test "$FORCE_INSTALL" -eq 1; then
    brew_flags="--force"
  fi

  run_brew() {
    local kind="$1"
    shift
    _run_brew install "--$kind" $brew_flags $@
  }

  run_intel_brew() {
    local kind="$1"
    shift
    _run_intel_brew install "--$kind" $brew_flags $@
  }

  if test -n "$mas_packages"; then
    if ! has_cmd mas; then
      step "Installing mas for App Store installation..."
      run_brew formula mas
    fi
    wait_for_app_store
  fi

  if test -n "$tap_repos"; then
    step "Tapping repositories..."
    eval "set -- $tap_repos"
    tap_repo "$@"
  fi

  if test -n "$formula_packages"; then
    step "Installing packages..."
    eval "set -- $formula_packages"
    run_brew formula "$@"
    if test -n "$intel_formula_packages"; then
      eval "set -- $intel_formula_packages"
      run_intel_brew formula "$@"
    fi
  fi

  if test -n "$flagged_packages"; then
    step "Installing packages with additional flags..."
    eval "set -- $flagged_packages"
    local package
    for package in "$@"; do
      local name=$(printf "%s" "$package" | cut -d';' -f1)
      local flags=$(printf "%s" "$package" | cut -d';' -f2-)
      eval "set -- $(_unescape_special "$flags")"
      run_brew formula $name "$@"
    done
    if test -n "$intel_flagged_packages"; then
      eval "set -- $intel_flagged_packages"
      for package in "$@"; do
        local name=$(printf "%s" "$package" | cut -d';' -f1)
        local flags=$(printf "%s" "$package" | cut -d';' -f2-)
        eval "set -- $(_unescape_special "$flags")"
        run_intel_brew formula $name "$@"
      done
    fi
  fi

  if test -n "$cask_packages"; then
    step "Installing cask packages..."
    eval "set -- $cask_packages"
    run_brew cask "$@"
    if test -n "$intel_cask_packages"; then
      eval "set -- $intel_cask_packages"
      run_intel_brew cask "$@"
    fi
  fi

  if test -n "$mas_packages"; then
    step "Installing App Store packages..."
    eval "set -- $mas_packages"
    run_mas "$@"
  fi
}

use_brow() {
  local kind="$1"
  local package="$2"
  shift
  shift

  field manager brow
  field kind "$kind"
  field package "$package"
  if test "$#" -gt 0; then
    field flags "$(_make_list "$@")"
  fi
  add_package "$package"
}

use_brew() {
  local kind="$1"
  local package="$2"
  shift
  shift

  field manager brew
  field kind "$kind"
  field package "$package"
  if test "$#" -gt 0; then
    field flags "$(_make_list "$@")"
  fi
  add_package "$package"
}

use_brew_tap() {
  local tap="$1"

  field manager tap
  field tap "$tap"
  add_package "$tap"
}

use_mas() {
  if _has_skip mas; then
    return
  fi

  local package="$1"
  local package_id="$2"

  field manager_name "App Store"
  field manager mas
  field package "$package_id"
  add_package "$package"
}
