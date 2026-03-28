#!/bin/sh

PERCENTAGE="$(pmset -g batt | grep -Eo "\d+%" | cut -d% -f1)"
CHARGING="$(pmset -g batt | grep 'AC Power')"
REMAINING="$(pmset -g batt | grep -Eo "\d+:\d+ remaining" | cut -d' ' -f1)"

if [ "$PERCENTAGE" = "" ]; then
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

if [[ "$CHARGING" != "" ]]; then
  ICON="􀢋"
fi

if test -z "$REMAINING"; then
  sketchybar --animate sin 10 \
    --set "$NAME.status" \
    label.color=0x00ffffff \
    --set "$NAME" \
    label.y_offset=0 \
    label.font.size=13 \
    label.width=35
else
  sketchybar --animate sin 10 \
    --set "$NAME.status" \
    label.color=0xffffffff \
    --set "$NAME" \
    label.y_offset=-5 \
    label.font.size=8 \
    label.width=30

  sketchybar --set "$NAME.status" label="$REMAINING" label.color="$LABEL_COLOR"
fi

sketchybar --set "$NAME" icon="$ICON" label="$PERCENTAGE%" label.color="$LABEL_COLOR"
