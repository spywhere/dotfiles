#!/bin/bash

if [[ $(uname) == "Darwin" ]]; then
  echo "No setup for now"
else
  echo "Setting up system..."

  echo "Enabling access over USB-C..."
  echo "dtoverlay=dwc2" | sudo tee -a /boot/config.txt
  echo "modules-load=dwc2" | sudo tee -a /boot/cmdline.txt
  sudo touch /boot/ssh
  echo "libcomposite" | sudo tee -a /etc/modules
  echo "denyinterfaces usb0" | sudo tee -a /etc/dhcpcd.conf
  sudo cp ~/dotfiles/files/etc/dnsmasq.d/usb /etc/dnsmasq.d/usb
  sudo cp ~/dotfiles/files/etc/network/interfaces.d/usb0 /etc/networks/interfaces.d/usb0
  sudo cp ~/dotfiles/files/root/usb.sh /root/usb.sh
  sudo chmod 755 /root/usb.sh
  sudo sed -i $'s/exit 0/\\/root\\/usb.sh\\\nexit 0/g' /etc/rc.local
fi
