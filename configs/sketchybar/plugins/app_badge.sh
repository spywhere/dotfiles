#!/bin/bash

BUNDLE_ID="$1"
APP_NAME="$2"
shift
shift

APP_REF=$(lsappinfo find "bundleID=$BUNDLE_ID" | head -n 1)
STATUS_LABEL=""
if test -n "$APP_REF"; then
  STATUS_LABEL=$(lsappinfo info -only StatusLabel "$APP_REF")
fi

WIDTH="dynamic"
if [[ $STATUS_LABEL =~ \"label\"=\"([^\"]*)\" ]]; then
  LABEL="${BASH_REMATCH[1]}"
else
  LABEL=$(osascript - "$APP_NAME" <<'APPLESCRIPT'
on run argv
  set appName to item 1 of argv
  tell application "System Events"
    tell process "Dock"
      set dockItems to (UI elements of list 1 whose name is appName)
      if (count of dockItems) is 0 then return ""
      set badgeValue to value of attribute "AXStatusLabel" of item 1 of dockItems
      if badgeValue is missing value then return ""
      return badgeValue as text
    end tell
  end tell
end run
APPLESCRIPT
  ) || exit 0
fi

if [[ $LABEL == "" ]]; then
  WIDTH="0"
elif [[ $LABEL == "•" ]]; then
  if test -n "$1"; then
    ICON_COLOR="$1"
  else
    ICON_COLOR="0xffeed49f"
  fi
  LABEL=""
elif [[ $LABEL =~ ^[0-9]+$ ]]; then
  if test -n "$2"; then
    ICON_COLOR="$2"
  elif test -n "$1"; then
    ICON_COLOR="$1"
  else
    ICON_COLOR="0xffed8796"
  fi
else
  exit 0
fi

sketchybar --set "$NAME" label="$LABEL" \
  --animate sin 10 \
  --set "$NAME" icon.width="$WIDTH" label.width="$WIDTH" icon.color="$ICON_COLOR"
