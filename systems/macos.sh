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

system_usage() {
  print "For macOS, the following options can be used"
  print 22 "  no-brew" "Skip package installations via Homebrew"
  print 22 "  no-app-store" "Skip package installations via App Store"
}

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

has_app() {
  has_directory "/Applications/$1.app"
}

has_screensaver() {
  has_directory "$HOME/Library/Screen Savers/$1.saver"
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
  install_packages__bin_packages=""

  install_packages__tap_repos=""

  install_packages__formula_packages=""
  install_packages__cask_packages=""
  install_packages__flagged_packages=""
  install_packages__intel_formula_packages=""
  install_packages__intel_cask_packages=""
  install_packages__intel_flagged_packages=""
  install_packages__mas_packages=""
  install_packages__nativefier_packages=""

  step "Collecting packages..."
  for install_packages__package in "$@"; do
    install_packages__manager="$(parse_field "$install_packages__package" manager)"

    if test "$install_packages__manager" = "bin"; then
      install_packages__bin_packages="$(_add_to_list "$install_packages__bin_packages" "$install_packages__package")"
    elif test "$install_packages__manager" = "brew" -o "$install_packages__manager" = "brow"; then
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
    elif test "$install_packages__manager" = "nativefier"; then
      install_packages__name="$(parse_field "$install_packages__package" package_name)"
      install_packages__url="$(parse_field "$install_packages__package" package)"
      install_packages__options="$(parse_field "$install_packages__package" options)"
      if test -n "$install_packages__options"; then
        install_packages__options="$(_escape_special "$install_packages__options")"
      fi
      install_packages__nativefier_packages="$(_add_to_list "$install_packages__nativefier_packages" "$install_packages__name;$install_packages__url;$install_packages__options")"
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

  if test -n "$install_packages__nativefier_packages"; then
    if ! has_cmd nativefier; then
      step "Installing nativefier for application building..."
      run_brew formula nativefier
    fi
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

  if test -n "$install_packages__bin_packages"; then
    eval "set -- $install_packages__bin_packages"
    install_bins "$@"
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

  if test -n "$install_packages__nativefier_packages"; then
    step "Building applications using Nativefier..."
    eval "set -- $install_packages__nativefier_packages"
    for install_packages__package in "$@"; do
      install_packages__name=$(printf "%s" "$install_packages__package" | cut -d';' -f1)
      install_packages__url=$(printf "%s" "$install_packages__package" | cut -d';' -f2)
      install_packages__options=$(printf "%s" "$install_packages__package" | cut -d';' -f3-)
      install_packages__output_app="$(deps nativefier)"
      eval "set -- $(_unescape_special "$install_packages__options")"
      cmd nativefier "$install_packages__url" -n "$install_packages__name" "$@" "$install_packages__output_app"
      for install_packages__file_path in "$install_packages__output_app/$install_packages__name"-*/*.app; do
        install_packages__file_name="$(basename "$install_packages__file_path")"
        install_packages__app_path="/Applications/$install_packages__file_name"
        info "Installing $install_packages__file_name..."
        if test -d "$install_packages__app_path"; then
          cmd rm -rf "$install_packages__app_path"
        fi
        cmd cp -r "$install_packages__file_path" "$install_packages__app_path"
      done
    done
  fi

}

plist() {
  config__name="$HOME/Library/Preferences/$1.plist"
  config__key="$2"
  config__value="$3"

  if (/usr/libexec/PlistBuddy -c "Print $config__key" >/dev/null 2>&1); then
    cmd /usr/libexec/PlistBuddy -c "Set $config__key $config__value" "$config__name"
  else
    warn "Key '$config__key' cannot be found in '$1'"
  fi
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
  if _has_skip brew && ! _has_indicate "$2"; then
    mark_installed
    return
  fi

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
  if _has_skip brew && ! _has_indicate "$2"; then
    mark_installed
    return
  fi

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
  if _has_skip brew && ! _has_indicate "$1"; then
    mark_installed
    return
  fi

  _use_brew_tap__tap="$1"

  field manager tap
  field tap "$_use_brew_tap__tap"
  add_package "$_use_brew_tap__tap"
}

use_mas() {
  if _has_skip app-store && ! _has_indicate "$1"; then
    mark_installed
    return
  fi

  use_mas__package="$1"
  use_mas__package_id="$2"

  field manager_name "App Store"
  field manager mas
  field package "$use_mas__package_id"
  add_package "$use_mas__package"
}

use_nativefier() {
  if _has_skip nativefier && ! _has_indicate "$1"; then
    mark_installed
    return
  fi

  use_nativefier__name="$1"
  use_nativefier__url="$2"
  shift
  shift

  if test "$#" -gt 0; then
    field options "$(_make_list "$@")"
  fi

  field manager_name "Nativefier"
  field manager nativefier
  field package "$use_nativefier__url"
  add_package "$use_nativefier__name"
}
