#!/bin/bash

PERCENTAGE="$(pmset -g batt | grep -Eo "\d+%" | cut -d% -f1)"
CHARGING="$(pmset -g batt | grep 'AC Power')"
REMAINING="$(pmset -g batt | grep -Eo "\d+:\d+ remaining" | cut -d' ' -f1)"

if test -z "$PERCENTAGE"; then
  exit 0
fi

LABEL_COLOR=0xffffffff
case "${PERCENTAGE}" in
  9[0-9]|100)
    ICON="􀛨"
  ;;
  [6-8][0-9])
    ICON="􀺸"
  ;;
  [3-5][0-9])
    ICON="􀺶"
    LABEL_COLOR=0xffffcc66
  ;;
  [1-2][0-9])
    ICON="􀛩"
    LABEL_COLOR=0xffff9933
  ;;
  *)
    ICON="􀛪"
    LABEL_COLOR=0xffff6666
  ;;
esac

if test -n "$CHARGING"; then
  ICON="􀢋"
  LABEL_COLOR=0xff00aaff

  if test "$REMAINING" = "0:00"; then
    REMAINING=""
  fi
fi

if test -z "$REMAINING"; then
  WIDTH=40
  if test "$PERCENTAGE" = "100"; then
    WIDTH=45
  fi

  sketchybar --animate sin 10 \
    --set "$NAME.status" \
    label.color.alpha=0 \
    --set "$NAME" \
    label.y_offset=0 \
    label.font.size=13 \
    label.width="$WIDTH" \
    label.color="$LABEL_COLOR"
else
  y_offset="-5"
  if test "$(sketchybar --query "$NAME" | jq -r '.label.y_offset')" != "$y_offset"; then
    y_offset="label.y_offset=$y_offset"
  else
    y_offset=""
  fi

  sketchybar --animate sin 10 \
    --set "$NAME.status" \
    label.color="$LABEL_COLOR" \
    --set "$NAME" \
    label.font.size=8 \
    label.width=30 \
    label.color="$LABEL_COLOR" \
    "$y_offset"

  sketchybar --set "$NAME.status" label="$REMAINING"
fi

sketchybar --set "$NAME" icon="$ICON" label="$PERCENTAGE%"
