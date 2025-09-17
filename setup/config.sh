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

add_setup 'setup_config'

setup_macos() {
  ##########
  # System #
  ##########
  config "NSGlobalDomain" "AppleInterfaceStyle" "Dark"
  # config "NSGlobalDomain" "AppleShowScrollBars" "Automatic"
  config "NSGlobalDomain" "NSQuitAlwaysKeepsWindows" true
  config "NSGlobalDomain" "AppleShowAllExtensions" true
  config "NSGlobalDomain" "WebKitDeveloperExtras" true

  #############
  # Languages #
  #############
  config "NSGlobalDomain" "AppleLanguages" "en-TH" "th-TH"
  config "NSGlobalDomain" "AppleLocale" "en_TH"

  ###########
  # Dialogs #
  ###########
  config "NSGlobalDomain" "NSNavPanelExpandedStateForSaveMode" true
  config "NSGlobalDomain" "NSNavPanelExpandedStateForSaveMode2" true
  config "NSGlobalDomain" "PMPrintingExpandedStateForPrint" true
  config "NSGlobalDomain" "PMPrintingExpandedStateForPrint2" true

  config "NSGlobalDomain" "NSDocumentSaveNewDocumentsToCloud" false

  config "NSGlobalDomain" "NSTextShowsControlCharacters" true

  ############
  # Trackpad #
  ############
  config "NSGlobalDomain" "com.apple.trackpad.forceClick" 0
  config "NSGlobalDomain" "com.apple.mouse.tapBehavior" 1
  config "com.apple.driver.AppleBluetoothMultitouch.trackpad" "Clicking" 1

  ############
  # Keyboard #
  ############
  config "NSGlobalDomain" "ApplePressAndHoldEnabled" false
  config "NSGlobalDomain" "InitialKeyRepeat" 25
  config "NSGlobalDomain" "KeyRepeat" 2

  ################
  # Text editing #
  ################
  config "NSGlobalDomain" "NSAutomaticCapitalizationEnabled" 0
  config "NSGlobalDomain" "NSAutomaticDashSubstitutionEnabled" 0
  config "NSGlobalDomain" "NSAutomaticPeriodSubstitutionEnabled" 0
  config "NSGlobalDomain" "NSAutomaticSpellingCorrectionEnabled" 1
  config "NSGlobalDomain" "NSAutomaticTextCompletionEnabled" 0

  #########
  # Power #
  #########
  sudo_cmd pmset -a lidwake 1
  sudo_cmd pmset -a autorestart 1
  sudo_cmd pmset -b displaysleep 5
  sudo_cmd pmset -b sleep 10
  sudo_cmd pmset -c displaysleep 10
  sudo_cmd pmset -c sleep 0

  ################
  # System Setup #
  ################
  sudo_cmd systemsetup -setrestartfreeze on >/dev/null 2>&1
  # sudo_cmd systemsetup -setrestartpowerfailure on >/dev/null 2>&1
  sudo_cmd systemsetup -setcomputersleep off >/dev/null 2>&1

  ############
  # AppStore #
  ############
  config "com.apple.AppStore" "AutoPlayVideoSetting" "on"
  config "com.apple.AppStore" "InAppReviewEnabled" 0
  config "com.apple.AppStore" "WebKitDeveloperExtras" true
  config "com.apple.AppStore" "ShowDebugMenu" true

  ################
  # Disk Utility #
  ################
  config "com.apple.DiskUtility" "DUDebugMenuEnabled" true
  config "com.apple.DiskUtility" "advanced-image-options" true

  #################
  # Image Capture #
  #################
  config "com.apple.ImageCapture" "disableHotPlug" true

  ################
  # Time Machine #
  ################
  config "com.apple.TimeMachine" "DoNotOfferNewDisksForBackup" true

  ############
  # Touchbar #
  ############
  config "com.apple.controlstrip" "FullCustomized" \
    "com.apple.system.group.brightness" \
    "com.apple.system.mission-control" \
    "com.apple.system.launchpad" \
    "com.apple.system.group.keyboard-brightness" \
    "com.apple.system.group.media" \
    "com.apple.system.group.volume" \
    "com.apple.system.screen-lock"
  config "com.apple.controlstrip" "MiniCustomized" \
    "com.apple.system.brightness" \
    "com.apple.system.volume" \
    "com.apple.system.mute" \
    "com.apple.system.input-menu"

  ########
  # Dock #
  ########
  config "com.apple.dock" "expose-group-apps" true
  config "com.apple.dock" "minimize-to-application" true
  config "com.apple.dock" "show-process-indicators" true
  config "com.apple.dock" "mru-spaces" false
  config "com.apple.dock" "show-recents" false

  ##########
  # Finder #
  ##########
  plist "com.apple.finder" ":DesktopViewSettings:IconViewSettings:arrangeBy" name
  plist "com.apple.finder" ":DesktopViewSettings:IconViewSettings:showItemInfo" true
  plist "com.apple.finder" ":ICloudViewSettings:IconViewSettings:arrangeBy" name
  plist "com.apple.finder" ":ICloudViewSettings:IconViewSettings:showItemInfo" true
  plist "com.apple.finder" ":FK_StandardViewSettings:IconViewSettings:arrangeBy" name
  plist "com.apple.finder" ":FK_StandardViewSettings:IconViewSettings:showItemInfo" true

  config "com.apple.finder" "FXArrangeGroupViewBy" "Name"
  config "com.apple.finder" "FXDefaultSearchScope" "SCsp"
  config "com.apple.finder" "FXEnableExtensionChangeWarning" false
  config "com.apple.finder" "FXInfoPanesExpanded" -dict \
    General -bool true \
    OpenWith -bool true \
    Name -bool true \
    MetaData -bool true
  config "com.apple.finder" "FXPreferredGroupBy" "Name"
  config "com.apple.finder" "FXPreferredViewStyle" "icnv"
  config "com.apple.finder" "FXRemoveOldTrashItems" true
  config "com.apple.finder" "NewWindowTarget" "PfDo"
  config "com.apple.finder" "NewWindowTargetPath" "file://$HOME/Documents/"
  config "com.apple.finder" "ShowExternalHardDrivesOnDesktop" false
  config "com.apple.finder" "ShowHardDrivesOnDesktop" false
  config "com.apple.finder" "ShowPathBar" true
  config "com.apple.finder" "ShowRecentTags" false
  config "com.apple.finder" "ShowStatusBar" true
  config "com.apple.finder" "_FXSortFoldersFirst" true
  config "com.apple.finder" "_FXSortFoldersFirstOnDesktop" true

  ##############
  # Clock Menu #
  ##############
  config "com.apple.menuextra.clock" "DateFormat" "EEE d MMM  HH:mm"
  config "com.apple.menuextra.clock" "FlashDateSeparators" true
  config "com.apple.menuextra.clock" "Show24Hour" true

  ###########
  # Sidecar #
  ###########
  config "com.apple.sidecar.display" "showTouchbar" false
  config "com.apple.sidecar.display" "sidebarShown" false

  ###################
  # Software Update #
  ###################
  config "com.apple.commerce" "AutoUpdate" true
  config "com.apple.commerce" "AutoUpdateRestartRequired" true
  sudo_config "com.apple.SoftwareUpdate" "AutomaticCheckEnabled" true
  sudo_config "com.apple.SoftwareUpdate" "AutomaticDownload" true
  sudo_config "com.apple.SoftwareUpdate" "AutomaticallyInstallMacOSUpdates" true
  sudo_config "com.apple.SoftwareUpdate" "ConfigDataInstall" true
  sudo_config "com.apple.SoftwareUpdate" "CriticalUpdateInstall" true

  ################
  # Login window #
  ################
  # Show IP / Host / OS version / etc. when click the clock in login window
  sudo_config "com.apple.loginwindow" "AdminHostInfo" "HostName"
  sudo_config "com.apple.loginwindow" "GuestEnabled" false
  sudo_config "com.apple.loginwindow" "showInputMenu" true

  ###########
  # Network #
  ###########
  setup_macos__computer_name="$(whoami)'s $(sysctl -n hw.model | sed 's/[0-9,]*$//g' | sed 's/Pro$/ Pro/g' | sed 's/Air$/ Air/g')"
  sudo_cmd scutil --set LocalHostName "$(printf '%s' "$setup_macos__computer_name" | sed 's/[^a-zA-Z ]//g' | sed 's/ /-/g')"
  sudo_cmd scutil --set ComputerName "$setup_macos__computer_name"

  add_post_install_message "Be sure to restart the computer once for changes to take effect"
}

setup_config() {
  step "Setting up configurations..."

  if ! test -d "$HOME/.config"; then
    cmd mkdir -p "$HOME/.config"
  fi
  if ! test -d "$HOME/.shrimp"; then
    cmd mkdir -p "$HOME/.shrimp"
  fi

  step "  - Alacritty"
  link alacritty/alacritty.yml .alacritty.yml

  step "  - bat"
  link bat/ .config/bat

  step "  - code-server"
  link code-server/ .config/code-server

  step "  - editorconfig"
  raw_link .editorconfig .editorconfig

  step "  - git"
  link git/gitconfig .gitconfig
  if test -f "$HOME/$DOTFILES/configs/git/gitconfig.$OS"; then
    link "git/gitconfig.$OS" .gitconfig.platform
  elif test -f "$HOME/$DOTFILES/configs/git/gitconfig.$OSKIND"; then
    link "git/gitconfig.$OSKIND" .gitconfig.platform
  else
    warn "No platform specific git configuration for \"$OSNAME\""
  fi

  step "  - github"
  link github/ .config/github

  step "  - htop"
  link htop/ .config/htop

  step "  - iTerm2"
  link iterm2/ "Library/Application Support/iTerm2"

  step "  - jetbrains"
  link jetbrains/ideavimrc .ideavimrc

  step "  - kitty"
  link kitty/ .config/kitty

  step "  - mise"
  link mise/ .config/mise

  step "  - mpd"
  link mpd/ .mpd

  step "  - mycli"
  link mycli/myclirc .myclirc

  step "  - ncmpcpp"
  link ncmpcpp/ .ncmpcpp

  step "  - neomutt"
  link neomutt/ .config/neomutt

  step "  - neovide"
  link neovide/ .config/neovide

  step "  - neovim"
  link nvim/ .config/nvim
  add_post_install_message "Run 'nvim' for the first time setup"

  step "  - opencode"
  link opencode/ .config/opencode

  step "  - presenterm"
  if test "$OSKIND" = "macos"; then
    link presenterm/ "Library/Application Support/presenterm"
  else
    link presenterm/ .config/presenterm
  fi

  step "  - qutebrowser"
  link qutebrowser/ .config/qutebrowser

  step "  - shrimp"
  link shrimp/ .shrimp/recipe

  step "  - ssh"
  link ssh/ .ssh

  step "  - starship"
  link starship/starship.toml .config/starship.toml

  step "  - tig"
  link tig/tig.conf .tigrc

  step "  - tmux"
  link tmux/tmux.conf .tmux.conf

  if ! test -f "$HOME/.wakatime.cfg"; then
    # copy instead as file can contain a secret
    step "  - wakatime"
    copy wakatime/wakatime.cfg .wakatime.cfg
  fi

  step "  - w3m"
  link w3m/ .w3m

  step "  - zellij"
  link zellij/ .config/zellij

  step "  - zsh"
  link zsh/zshrc .zshrc

  if test "$OSKIND" = "macos" && has_profile -work; then
    step "Setting up system configurations..."
    setup_macos

    step "Setting up LaunchAgents..."
    step "  - restart"
    raw_copy "supports/mac/launchd/me.spywhere.restart.plist" "$HOME/Library/LaunchAgents/me.spywhere.restart.plist"
  fi
}
