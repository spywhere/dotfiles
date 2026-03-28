#!/bin/bash

APP="$1"
MENU="$2"
ITEM="$3"

has_prefix() {
  case "$1" in
    "$2"*)
      return 0
      ;;
    *)
      return 1
      ;;
  esac
}

has_suffix() {
  case "$1" in
    *"$2")
      return 0
      ;;
    *)
      return 1
      ;;
  esac
}

is_contains() {
  case "$1" in
    *"$2"*)
      return 0
      ;;
    *)
      return 1
      ;;
  esac
}

is_exact() {
  test "$1" = "$2"
}

_OUTPUT=" "
output() {
  if test -z "$_OUTPUT" -o "$_OUTPUT" = " "; then
    _OUTPUT="$1"
  fi
}

prefix() {
  if has_prefix "$ITEM" "$1"; then
    output "$2"
  fi
}

suffix() {
  if has_suffix "$ITEM" "$1"; then
    output "$2"
  fi
}

contains() {
  if is_contains "$ITEM" "$1"; then
    output "$2"
  fi
}

exact() {
  if is_exact "$ITEM" "$1"; then
    output "$2"
  fi
}

# Standard Menu
case "$MENU" in
  apple|0)
    exact "About This Mac" "􁟬"
    exact "System Information" "􁟬"

    exact "System Settings…" "􀍟"
    exact "App Store" " JetBrainsMono Nerd Font:Regular:15"

    exact "Force Quit…" "􀒉"
    exact "Force Quit $APP" "􀒉"

    exact "Sleep…" "􀜚"
    exact "Sleep" "􀜚"
    exact "Restart…" "􀯆"
    exact "Restart" "􀯆"
    exact "Shut Down…" "􀆨"
    exact "Shut Down" "􀆨"

    exact "Lock Screen" "􀎠"
    exact "Log Out $(id -F)…" "􀉭"
    exact "Log Out $(id -F)" "􀉭"
    ;;
  "$APP"|1)
    exact "About $APP" "􀅴"
    exact "Settings…" "􀍟"

    exact "Services" "􀥎"

    exact "Hide $APP" "􀥁"
    exact "Hide Others" "􂠗"
    exact "Show All" "􀢌"

    exact "Quit $APP" "􀏍"
    exact "Quit and Close All Windows" "􀏍"
    ;;
  File)
    exact "Close" "􀆄"
    exact "Close All Windows" "􀏍"
    ;;
  Edit)
    prefix "Undo" "􀄼"
    prefix "Redo" "􀄽"

    exact "Cut" "􀉈"
    prefix "Copy" "􀉁"
    exact "Paste" "􀉃"
    exact "Select All" "􀂔"
    exact "Deselect All" "􀂔"

    exact "Writing Tools" "􂷴"
    exact "AutoFill" "􀈏"
    exact "Start Dictation…" "􀊰"
    exact "Emoji & Symbols" "􀙌"
    ;;
  View)
    exact "Show Tab Bar" ""
    exact "Show All Tabs" ""

    exact "Enter Full Screen" "􂂟"
    ;;
  Window)
    exact "Minimize" "􀏉"
    exact "Minimize All" "􀏉"
    exact "Zoom" "􀠹"
    exact "Zoom All" "􀠹"
    exact "Fill" "􀤳"
    exact "Center" "􀥝"

    exact "Move & Resize" "􀥟"
    exact "Full Screen Tile" "􀧈"

    exact "Remove Window from Set" "􀏗"

    exact "Show Previous Tab" "􀄂"
    exact "Show Next Tab" "􀄄"
    exact "Move Tab to New Window" "􀏑"
    exact "Merge All Windows" "􀢌"

    exact "Bring All to Front" "􀯰"
    exact "Arrange in Front" "􃑷"

    suffix "Move Window Back to Mac" "􀙗"
    if has_prefix "$ITEM" "Move to" && has_suffix "$ITEM" "iPad"; then
      output "􀥔"
    fi
    ;;
  Help)
    prefix "Send $APP Feedback" ""
    ;;
esac

case "$APP" in
  Finder)
    case "$MENU" in
      "$APP"|1)
        prefix "Empty Trash" "􀈑"
        ;;
      Go)
        exact "Back" "􀯶"
        exact "Forward" "􀯻"
        prefix "Enclosing Folder" "􃀧"
        exact "Select Startup Disk" "􀤂"

        exact "Recents" "􀐫"
        exact "Documents" "􀈷"
        exact "Desktop" "􀣰"
        exact "Downloads" "􀁸"
        exact "Home" "􀎞"
        exact "Library" "􀤨"
        exact "Computer" "􁟬"
        exact "AirDrop" "󰐻 JetBrainsMono Nerd Font:Regular:15"
        exact "Network" "􀤆"
        exact "iCloud Drive" "􀇂"
        exact "Shared" "􀈝"
        exact "Applications" " JetBrainsMono Nerd Font:Regular:15"
        exact "Utilities" "􀤊"

        exact "Recent Folders" "􀐫"

        exact "Go to Folder…" "􃀩"
        exact "Connect to Server…" "􀩲"

        output "􀈕"
        ;;
      Window)
        exact "Cycle Through Windows" "􁉽"
        ;;
    esac
    ;;
  Ghostty)
    case "$MENU" in
      "$APP"|1)
        prefix "Check for Updates" "􀈄"
        exact "Reload Configuration" "􀊯"
        exact "Secure Keyboard Entry" "􀼑"
        exact "Make Ghostty the Default Terminal" "􀋃"
        ;;
      File)
        exact "New Window" "􀥃"
        exact "New Tab" "􀏜"

        exact "Split Right" "􀤵"
        exact "Split Left" "􀤴"
        exact "Split Down" "􀾯"
        exact "Split Up" "􀾮"
        ;;
      Edit)
        exact "Paste Selection" "􀉄"

        exact "Find" "􀕹"
        ;;
      View)
        ;;
      Window)
        exact "Toggle Full Screen" "􀠹"
        exact "Show/Hide All Terminals" "􀋭"

        exact "Zoom Split" "􀅊"
        exact "Select Previous Split" "􀆋"
        exact "Select Next Split" "􀆌"

        exact "Return To Default Size" ""

        exact "Float on Top" "􀫝"
        ;;
      Help)
        exact "Ghostty Help" "􀛭"
        ;;
    esac
    ;;
  *)
    ;;
esac

echo "$_OUTPUT"
