#!/bin/sh

if [ "$(uname)" = "Darwin" ]; then
  echo "No setup for now"
else
  echo "Setting up system..."

  echo "Enabling access over USB-C..."
  if [ ! -f /root/usb.sh ]; then
    echo "dtoverlay=dwc2" | sudo tee -a /boot/config.txt
    echo "modules-load=dwc2" | sudo tee -a /boot/cmdline.txt
    sudo touch /boot/ssh
    echo "libcomposite" | sudo tee -a /etc/modules
    echo "denyinterfaces usb0" | sudo tee -a /etc/dhcpcd.conf
    mkdir -p /etc/dnsmasq.d
    mkdir -p /etc/network/interfaces.d
    cat ~/dotfiles/files/etc/dnsmasq.d/usb | sudo tee /etc/dnsmasq.d/usb
    cat ~/dotfiles/files/etc/network/interfaces.d/usb0 | sudo tee /etc/network/interfaces.d/usb0
    cat ~/dotfiles/files/root/usb.sh | sudo tee /root/usb.sh
    sudo chmod 755 /root/usb.sh
    sudo sed -i $'s/exit 0$/\\/root\\/usb.sh\\\nexit 0/g' /etc/rc.local
  else
    echo "Already enabled"
  fi
fi
