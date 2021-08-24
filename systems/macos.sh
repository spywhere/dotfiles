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

install_git() {
  if ! test -n "$(command -v brew)"; then
    return 1
  fi
  cmd brew install git
}

setup() {
  setup__apple_silicon=""
  if has_flag "apple-silicon"; then
    setup__apple_silicon="arm64"
  fi

  if has_cmd pkgutil && test -n "$setup__apple_silicon" -a "$(pkgutil --pkgs=com.apple.pkg.RosettaUpdateAuto)" != "com.apple.pkg.RosettaUpdateAuto"; then
    info "Installing Rosetta 2..."
    cmd softwareupdate --install-rosetta --agree-to-license
  fi

  if ! has_cmd ruby; then
    error "Failed: either install \"ruby\" or \"homebrew\", and try again"
    quit 1
  fi

  if test -n "$setup__apple_silicon" -a ! -f /opt/homebrew/bin/brew; then
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

  if test -z "$setup__apple_silicon"; then
    info "Installing Homebrew..."
    sudo_cmd -v
    cmd bash -c "NONINTERACTIVE=1 $(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)"
  fi
}

_run_intel_brew() {
  run_intel_brew__brew_path="/usr/local/Homebrew/bin"
  run_intel_brew__executable=""

  if test -f "$run_intel_brew__brew_path/brew"; then
    run_intel_brew__executable="$run_intel_brew__brew_path/brew"
  else
    error "Failed: homebrew setup has been completed, but \"brew\" command cannot be found at $run_intel_brew__brew_path"
    quit 1
  fi

  cmd arch -x86_64 "$run_intel_brew__executable" "$@"
}

_run_brew() {
  run_brew__brew_path="/usr/local/Homebrew/bin"
  run_brew__executable=""
  if has_flag "apple-silicon"; then
    run_brew__brew_path="/opt/homebrew/bin"
  fi

  if test -f "$run_brew__brew_path/brew"; then
    run_brew__executable="$run_brew__brew_path/brew"
  else
    error "Failed: homebrew setup has been completed, but \"brew\" command cannot be found at $run_brew__brew_path"
    quit 1
  fi

  cmd "$run_brew__executable" "$@"
}

has_login_app_store() {
  if mas account >/dev/null; then
    return 0
  else
    return 1
  fi
}

wait_for_app_store() {
  wait_for_app_store__last_check=""
  while ! has_login_app_store; do
    printf "%s%s\r" "$esc_yellow==> ACTION REQUIRED$esc_reset: Please sign in into App Store..." "$wait_for_app_store__last_check"
    sleep 5
    wait_for_app_store__last_check=" (last check at $(date "+%H:%M:%S"))"
  done
  if test -n "$wait_for_app_store__last_check"; then
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
  for tap_repo__repo in "$@"; do
    _run_brew tap "$tap_repo__repo"
  done
}

install_packages() {
  install_packages__tap_repos=""

  install_packages__formula_packages=""
  install_packages__cask_packages=""
  install_packages__flagged_packages=""
  install_packages__intel_formula_packages=""
  install_packages__intel_cask_packages=""
  install_packages__intel_flagged_packages=""
  install_packages__mas_packages=""

  step "Collecting packages..."
  for install_packages__package in "$@"; do
    install_packages__manager="$(parse_field "$install_packages__package" manager)"

    if test "$install_packages__manager" = "brew" -o "$install_packages__manager" = "brow"; then
      install_packages__name="$(parse_field "$install_packages__package" package)"
      install_packages__kind="$(parse_field "$install_packages__package" kind)"
      install_packages__flags="$(parse_field "$install_packages__package" flags)"
      if test -n "$install_packages__flags"; then
        install_packages__flags="$(_escape_special "$install_packages__flags")"
      fi

      if has_flag "apple-silicon" && test "$install_packages__manager" = "brow"; then
        if test "$install_packages__kind" = "cask"; then
          install_packages__intel_cask_packages="$(_add_to_list "$install_packages__intel_cask_packages" "$install_packages__name")"
        elif test "$install_packages__kind" = "formula" -a -n "$install_packages__flags"; then
          install_packages__intel_flagged_packages="$(_add_to_list "$install_packages__intel_flagged_packages" "$install_packages__name;$install_packages__flags")"
        elif test "$install_packages__kind" = "formula"; then
          install_packages__intel_formula_packages="$(_add_to_list "$install_packages__intel_formula_packages" "$install_packages__name")"
        fi
      else
        if test "$install_packages__kind" = "cask"; then
          install_packages__cask_packages="$(_add_to_list "$install_packages__cask_packages" "$install_packages__name")"
        elif test "$install_packages__kind" = "formula" -a -n "$install_packages__flags"; then
          install_packages__flagged_packages="$(_add_to_list "$install_packages__flagged_packages" "$install_packages__name;$install_packages__flags")"
        elif test "$install_packages__kind" = "formula"; then
          install_packages__formula_packages="$(_add_to_list "$install_packages__formula_packages" "$install_packages__name")"
        fi
      fi
    elif test "$install_packages__manager" = "tap"; then
      install_packages__tap="$(parse_field "$install_packages__package" tap)"
      install_packages__tap_repos="$(_add_to_list "$install_packages__tap_repos" "$install_packages__tap")"
    elif test "$install_packages__manager" = "mas"; then
      install_packages__package_id="$(parse_field "$install_packages__package" package)"
      install_packages__mas_packages="$(_add_to_list "$install_packages__mas_packages" "$install_packages__package_id")"
    fi
  done

  install_packages__brew_flags=""
  if test "$FORCE_INSTALL" -eq 1; then
    install_packages__brew_flags="--force"
  fi

  run_brew() {
    install_packages_run_brew__kind="$1"
    shift
    _run_brew install "--$install_packages_run_brew__kind" $install_packages__brew_flags "$@"
  }

  run_intel_brew() {
    install_packages_run_intel_brew__kind="$1"
    shift
    _run_intel_brew install "--$install_packages_run_intel_brew__kind" $install_packages__brew_flags "$@"
  }

  if test -n "$install_packages__mas_packages"; then
    if ! has_cmd mas; then
      step "Installing mas for App Store installation..."
      run_brew formula mas
    fi
    wait_for_app_store
  fi

  if test -n "$install_packages__tap_repos"; then
    step "Tapping repositories..."
    eval "set -- $install_packages__tap_repos"
    tap_repo "$@"
  fi

  if test -n "$install_packages__formula_packages"; then
    step "Installing packages..."
    eval "set -- $install_packages__formula_packages"
    run_brew formula "$@"
    if test -n "$install_packages__intel_formula_packages"; then
      eval "set -- $install_packages__intel_formula_packages"
      run_intel_brew formula "$@"
    fi
  fi

  if test -n "$install_packages__flagged_packages"; then
    step "Installing packages with additional flags..."
    eval "set -- $install_packages__flagged_packages"
    for install_packages__package in "$@"; do
      install_packages__name=$(printf "%s" "$install_packages__package" | cut -d';' -f1)
      install_packages__flags=$(printf "%s" "$install_packages__package" | cut -d';' -f2-)
      eval "set -- $(_unescape_special "$install_packages__flags")"
      run_brew formula "$install_packages__name" "$@"
    done
    if test -n "$install_packages__intel_flagged_packages"; then
      eval "set -- $install_packages__intel_flagged_packages"
      for install_packages__package in "$@"; do
        install_packages__name=$(printf "%s" "$install_packages__package" | cut -d';' -f1)
        install_packages__flags=$(printf "%s" "$install_packages__package" | cut -d';' -f2-)
        eval "set -- $(_unescape_special "$install_packages__flags")"
        run_intel_brew formula "$install_packages__name" "$@"
      done
    fi
  fi

  if test -n "$install_packages__cask_packages"; then
    step "Installing cask packages..."
    eval "set -- $install_packages__cask_packages"
    run_brew cask "$@"
    if test -n "$install_packages__intel_cask_packages"; then
      eval "set -- $install_packages__intel_cask_packages"
      run_intel_brew cask "$@"
    fi
  fi

  if test -n "$install_packages__mas_packages"; then
    step "Installing App Store packages..."
    eval "set -- $install_packages__mas_packages"
    run_mas "$@"
  fi
}

plist() {
  config__name="$HOME/Library/Preferences/$1.plist"
  config__key="$2"
  config__value="$3"

  cmd /usr/libexec/PlistBuddy -c "Set $config__key $config__value" "$config__name"
}

_config() {
  _config__callback="$1"
  _config__name="$2"
  _config__key="$3"
  shift
  shift
  shift
  _config__rest=0

  if test "$#" -eq 1; then
    _config__type="-string"
    _config__value="$1"
  else
    _config__type="-array"
    _config__rest=1
  fi

  case "$1" in
    true | false)
      _config__type="-bool"
      ;;
    [0-9]*.[0-9]*)
      _config__type="-float"
      ;;
    [0-9]*)
      _config__type="-int"
      ;;
    -*)
      _config__type="$1"
      shift
      _config__rest=1
      ;;
  esac

  if test "$_config__rest" -eq 0; then
    "$_config__callback" "$_config__name" "$_config__key" "$_config__type" "$_config__value"
  else
    "$_config__callback" "$_config__name" "$_config__key" "$_config__type" "$@"
  fi
}

config() {
  config__callback() {
    cmd defaults write "$@"
  }
  _config config__callback "$@"
}

sudo_config() {
  sudo_config__name="$1"
  shift

  sudo_config__callback() {
    sudo_cmd defaults write "$@"
  }
  _config sudo_config__callback "/Library/Preferences/$1" "$@"
}

use_brow() {
  use_brow__kind="$1"
  use_brow__package="$2"
  shift
  shift

  field manager brow
  field kind "$use_brow__kind"
  field package "$use_brow__package"
  if test "$#" -gt 0; then
    field flags "$(_make_list "$@")"
  fi
  add_package "$use_brow__package"
}

use_brew() {
  use_brew__kind="$1"
  use_brew__package="$2"
  shift
  shift

  field manager brew
  field kind "$use_brew__kind"
  field package "$use_brew__package"
  if test "$#" -gt 0; then
    field flags "$(_make_list "$@")"
  fi
  add_package "$use_brew__package"
}

use_brew_tap() {
  _use_brew_tap__tap="$1"

  field manager tap
  field tap "$_use_brew_tap__tap"
  add_package "$_use_brew_tap__tap"
}

use_mas() {
  if _has_skip mas; then
    return
  fi

  use_mas__package="$1"
  use_mas__package_id="$2"

  field manager_name "App Store"
  field manager mas
  field package "$use_mas__package_id"
  add_package "$use_mas__package"
}
