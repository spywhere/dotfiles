#!/bin/bash

STATUS_LABEL=$(lsappinfo info -only StatusLabel Slack)
DRAWING="on"
ICON="󰒱"
if [[ $STATUS_LABEL =~ \"label\"=\"([^\"]*)\" ]]; then
  LABEL="${BASH_REMATCH[1]}"

  if [[ $LABEL == "" ]]; then
    DRAWING="off"
    ICON_COLOR="0xffa6da95"
  elif [[ $LABEL == "•" ]]; then
    ICON_COLOR="0xffeed49f"
    LABEL=""
  elif [[ $LABEL =~ ^[0-9]+$ ]]; then
    ICON_COLOR="0xffed8796"
  else
    exit 0
  fi
else
  exit 0
fi

sketchybar --set "$NAME" drawing="$DRAWING" icon="$ICON" label="$LABEL" icon.color="$ICON_COLOR"
