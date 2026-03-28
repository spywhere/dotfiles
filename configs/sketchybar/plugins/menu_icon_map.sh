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

output() {
  echo "$1"
  exit
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
    exact "App Store" " JetBrainsMono Nerd Font:Regular:13"

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

    output " "
    ;;
  "$APP"|1)
    exact "About $APP" "􀅴"
    exact "Settings…" "􀍟"

    exact "Services" "􀥎"

    exact "Hide $APP" "􀍟"
    exact "Hide Others" "􂠗"
    exact "Show All" "􀢌"

    exact "Quit $APP" "􀏍"
    exact "Quit and Close All Windows" "􀏍"

    output " "
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

    output " "
    ;;
esac

case "$APP" in
  Ghostty)
    case "$MENU" in
      File)
        if has_prefix "$ITEM" "Close"; then
          exact "Close" "􀆄"
          exact "Close All Windows" "􀏍"

          output " "
        fi
        ;;
    esac
    ;;
  *)
    ;;
esac
