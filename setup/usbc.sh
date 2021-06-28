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

if test "$OS" = "raspbian"; then
  add_setup 'setup_usbc'
fi

setup_usbc() {
  info "Checking if already enabling access over USB-C..."
  if sudo_cmd test -f /root/usb.sh; then
    info "Already enabled"
    return
  fi
  step "Enabling access over USB-C..."

  echo "dtoverlay=dwc2" | sudo tee -a /boot/config.txt >/dev/null
  echo "modules-load=dwc2" | sudo tee -a /boot/cmdline.txt >/dev/null
  sudo_cmd touch /boot/ssh
  echo "libcomposite" | sudo tee -a /etc/modules >/dev/null
  echo "denyinterfaces usb0" | sudo tee -a /etc/dhcpcd.conf >/dev/null
  cmd mkdir -p /etc/dnsmasq.d
  cmd mkdir -p /etc/network/interfaces.d
  cat $HOME/$DOTFILES_NAME/supports/usbc/etc/dnsmasq.d/usb | sudo tee /etc/dnsmasq.d/usb >/dev/null
  cat $HOME/$DOTFILES_NAME/supports/usbc/etc/network/interfaces.d/usb0 | sudo tee /etc/network/interfaces.d/usb0 >/dev/null
  cat $HOME/$DOTFILES_NAME/supports/usbc/root/usb.sh | sudo tee /root/usb.sh >/dev/null
  sudo_cmd chmod 755 /root/usb.sh
  sudo_cmd sed -i $'s/exit 0$/sh \\/root\\/usb.sh\\\nexit 0/g' /etc/rc.local
}
