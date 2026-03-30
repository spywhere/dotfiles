#!/bin/bash

STATUS_LABEL=$(lsappinfo info -only StatusLabel "$1")
DRAWING="on"
if [[ $STATUS_LABEL =~ \"label\"=\"([^\"]*)\" ]]; then
  LABEL="${BASH_REMATCH[1]}"

  if [[ $LABEL == "" ]]; then
    DRAWING="off"
  elif [[ $LABEL == "•" ]]; then
    if test -n "$2"; then
      ICON_COLOR="$2"
    else
      ICON_COLOR="0xffeed49f"
    fi
    LABEL=""
  elif [[ $LABEL =~ ^[0-9]+$ ]]; then
    if test -n "$3"; then
      ICON_COLOR="$3"
    elif test -n "$2"; then
      ICON_COLOR="$2"
    else
      ICON_COLOR="0xffed8796"
    fi
  else
    exit 0
  fi
else
  exit 0
fi

sketchybar --set "$NAME" drawing="$DRAWING" label="$LABEL" icon.color="$ICON_COLOR"
