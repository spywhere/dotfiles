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

SUPPORT_DIR="$HOME/$DOTFILES/supports/usbc"

if test "$OS" = "raspbian"; then
  add_setup 'setup_usbc'
fi

copy() {
  if ! sudo_cmd test -f "$1"; then
    sudo_cmd cp "$SUPPORT_DIR$1" "$1"
  fi
}

setup_usbc() {
  info "Checking if already enabling access over USB-C..."
  if sudo_cmd test -f /root/usb.sh; then
    info "Already enabled"
    return
  fi
  step "Enabling access over USB-C..."

  if ! sudo_cmd grep -q 'dtoverlay=dwc2' /boot/config.txt; then
    sudo_cmd sed -i '$a dtoverlay=dwc2' /boot/config.txt
  fi
  if ! sudo_cmd grep -q 'modules-load=dwc2' /boot/cmdline.txt; then
    sudo_cmd sed -i '$s/$/ modules-load=dwc2/g' /boot/cmdline.txt
  fi
  sudo_cmd touch /boot/ssh
  if ! sudo_cmd grep -q 'modules-load=dwc2' /etc/modules; then
    sudo_cmd sed -i '$a libcomposite' /etc/modules
  fi
  if ! sudo_cmd grep -q 'denyinterfaces usb0' /etc/dhcpcd.conf; then
    sudo_cmd sed -i '$a denyinterfaces usb0' /etc/dhcpcd.conf
  fi
  cmd mkdir -p /etc/dnsmasq.d
  cmd mkdir -p /etc/network/interfaces.d
  copy /etc/dnsmasq.d/usb
  copy /etc/network/interfaces.d/usb0
  copy /root/usb.sh
  sudo_cmd chmod 755 /root/usb.sh
  if ! sudo_cmd grep -q '/root/usb\.sh' /etc/rc.local; then
    sudo_cmd sed -i '$i sh /root/usb.sh\n' /etc/rc.local
  fi
}
