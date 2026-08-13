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

if test "$OSKIND" = "macos" && has_profile -work; then
  add_pre_setup 'setup_trackpad' 'macos-trackpad'
fi

setup_trackpad() {
  step "Setting up trackpad/mouse..."
  ############
  # Trackpad #
  ############
  config "NSGlobalDomain" "com.apple.trackpad.forceClick" 0
  config "NSGlobalDomain" "com.apple.mouse.tapBehavior" 1

  config "com.apple.AppleMultitouchTrackpad" "Clicking" true
  config "com.apple.AppleMultitouchTrackpad" "TrackpadRightClick" true
  config "com.apple.AppleMultitouchTrackpad" "ForceSuppressed" true
  config "com.apple.driver.AppleBluetoothMultitouch.trackpad" "Clicking" true
  config "com.apple.driver.AppleBluetoothMultitouch.trackpad" "TrackpadRightClick" true
  config "com.apple.driver.AppleBluetoothMultitouch.trackpad" "ForceSuppressed" true

  config "com.apple.AppleMultitouchMouse" "Clicking" true
  config "com.apple.AppleMultitouchMouse" "MouseButtonMode" "TwoButton"
  config "com.apple.driver.AppleBluetoothMultitouch.mouse" "Clicking" true
  config "com.apple.driver.AppleBluetoothMultitouch.mouse" "MouseButtonMode" "TwoButton"
}
