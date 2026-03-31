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
  if test -z "$_OUTPUT" -o "$_OUTPUT" = " " -o "$2" = "--force" -o "$2" = "-f"; then
    _OUTPUT="$1"
  fi
}

set_output() {
  _OUTPUT="$1"
}

_output_predicate() {
  local predicate
  predicate="$1"
  local str
  str="$2"
  shift
  shift
  if "$predicate" "$ITEM" "$str"; then
    output "$@"
  fi
}

prefix() {
  _output_predicate has_prefix "$@"
}

suffix() {
  _output_predicate has_suffix "$@"
}

contains() {
  _output_predicate is_contains "$@"
}

exact() {
  _output_predicate is_exact "$@"
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
    exact "Close All" "􀏍"
    exact "Close All Windows" "􀏍"
    ;;
  Edit)
    prefix "Undo" "􀄼"
    prefix "Redo" "􀄽"

    exact "Cut" "􀉈"
    prefix "Copy" "􀉁"
    exact "Paste" "􀉃"
    exact "Paste and Match Style" "􀉃"
    exact "Delete" "􀈑"
    exact "Select All" "􀂔"
    exact "Deselect All" "􀂔"

    exact "Writing Tools" "􂷴"
    exact "AutoFill" "􀈏"
    exact "Start Dictation…" "􀊰"
    exact "Emoji & Symbols" "􀙌"
    ;;
  View)
    exact "Show Tab Bar" ""
    exact "Hide Tab Bar" ""
    exact "Show All Tabs" ""
    exact "Hide All Tabs" ""

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
    if has_prefix "$ITEM" "Move to"; then
      if has_suffix "$ITEM" "iPad"; then
        output "􀥔"
      else
        output "􀢹"
      fi
    fi

    output "􀏜"
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
      File)
        exact "New Finder Window" "􀏇"
        exact "New Folder" "􀤰"
        exact "New Smart Folder" "􀣋"
        exact "New Tab" "􀐇"
        exact "Open" "􀄔"
        exact "Open and Close Window" "􀄔"
        exact "Close Window" "􀆄"
        exact "Close All" "􀏍"

        exact "Get Info" "􀅴"
        exact "Show Inspector" "􀅴"
        exact "Rename" "􀈊"
        prefix "Compress" "􀤧"
        exact "Duplicate" "􀐇"
        exact "Duplicate Exactly" "􀐇"
        exact "Make Alias" "􀉐"
        prefix "Quick Look" "􀋭"
        exact "Close Quick Look" "􀋭"
        prefix "Slideshow" "􀊙"
        exact "Print" "􂨖"

        exact "Share…" "􀈂"
        exact "Manage Shared File…" "􀉳"

        exact "Show Original" "􁎱"
        exact "Add to Sidebar" "􀋂"
        exact "Add to Dock" "􀣿"

        exact "Move to Trash" "􀜧"
        exact "Delete Immediately…" "􀈑"
        exact "Eject" "􀆥"

        exact "Tags…" "􀋡"

        exact "Find" "􀊫"
        ;;
      Edit)
        prefix "Move Item Here" "􀈕"
        prefix "Paste" "􀉃"

        exact "Show Clipboard" "􀟹"
        ;;
      View)
        exact "as Icons" "􀇷"
        exact "as List" "􀋲"
        exact "as Columns" "􀏟"
        exact "as Gallery" "􀏡"

        exact "Use Groups" "􀓙"
        exact "Sort By" "􀄬"
        exact "Clean Up" "􀇸"
        exact "Clean Up Selection" "􀇸"
        exact "Clean Up by" " "

        exact "Hide Sidebar" "􀏚"
        exact "Show Sidebar" "􀏚"
        exact "Hide Preview" "􀏛"
        exact "Show Preview" "􀏛"

        exact "Hide Toolbar" ""
        exact "Show Toolbar" ""
        exact "Hide Path Bar" ""
        exact "Show Path Bar" ""
        exact "Hide Status Bar" ""
        exact "Show Status Bar" ""

        exact "Customize Toolbar…" "􀎕"

        exact "Show View Options" "􀣋"
        exact "Show Preview Options" " "
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

        output "􀏜"

        exact "Show Progress Window" " " --force
        ;;
      Help)
        exact "Mac User Guide" "􁜾"
        exact "Tips for Your Mac" "􀛭"
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
        exact "Reset Font Size" "􀅐"
        exact "Increase Font Size" "􀵷"
        exact "Decrease Font Size" "􀵿"

        exact "Command Palette" "􀱢"
        exact "Change Tab Title..." "􁚛"
        exact "Terminal Read-only" "􀋮"

        exact "Quick Terminal" "􀩼"

        exact "Terminal Inspector" "􀐩"
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
