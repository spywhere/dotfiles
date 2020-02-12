#!/bin/sh

if [ "$(uname)" = "Darwin" ]; then
  if [ -d "$HOME/Library/Application Support/iTerm2/DynamicProfiles" ]; then
    echo "iTerm2 found, setup dynamic profiles..."
    # Remove files inside the directory
    rm -rf "$HOME/Library/Application Support/iTerm2/DynamicProfiles"
    # Remove the directory itself
    rm -rf "$HOME/Library/Application Support/iTerm2/DynamicProfiles"
    ln -s "$HOME/.dotfiles/files/iterm2/DynamicProfiles" "$HOME/Library/Application Support/iTerm2"
  fi
  if [ -d "$HOME/Library/Application Support/Übersicht/widgets" ]; then
    echo "Übersicht found, setup widgets..."
    rm -rf "$HOME/Library/Application Support/Übersicht/widgets/bar"
    ln -s "$HOME/.dotfiles/files/ubersicht/widgets/bar" "$HOME/Library/Application Support/Übersicht/widgets"
  fi
  rm -f "$HOME/.yabairc"
  ln -s "$HOME/.dotfiles/yabairc" "$HOME/.yabairc"
  rm -f "$HOME/.skhdrc"
  ln -s "$HOME/.dotfiles/skhdrc" "$HOME/.skhdrc"
else
  echo "Setting up system..."

  echo "Enabling access over USB-C..."
  if sudo test -f /root/usb.sh; then
    echo "Already enabled"
  else
    echo "dtoverlay=dwc2" | sudo tee -a /boot/config.txt
    echo "modules-load=dwc2" | sudo tee -a /boot/cmdline.txt
    sudo touch /boot/ssh
    echo "libcomposite" | sudo tee -a /etc/modules
    echo "denyinterfaces usb0" | sudo tee -a /etc/dhcpcd.conf
    mkdir -p /etc/dnsmasq.d
    mkdir -p /etc/network/interfaces.d
    cat $HOME/.dotfiles/files/etc/dnsmasq.d/usb | sudo tee /etc/dnsmasq.d/usb
    cat $HOME/.dotfiles/files/etc/network/interfaces.d/usb0 | sudo tee /etc/network/interfaces.d/usb0
    cat $HOME/.dotfiles/files/root/usb.sh | sudo tee /root/usb.sh
    sudo chmod 755 /root/usb.sh
    sudo sed -i $'s/exit 0$/\\/root\\/usb.sh\\\nexit 0/g' /etc/rc.local
  fi
fi
