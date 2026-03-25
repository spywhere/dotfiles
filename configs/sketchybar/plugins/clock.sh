#!/bin/sh

# The $NAME variable is passed from sketchybar and holds the name of
# the item invoking this script:
# https://felixkratz.github.io/SketchyBar/config/events#events-and-scripting

clock_separator=" "
if test "$(( $(date '+%S') % 2 ))" -eq 0; then
  clock_separator=":"
fi
sketchybar --set "$NAME" label="$(date "+%a %d %b  %H$clock_separator%M")"
