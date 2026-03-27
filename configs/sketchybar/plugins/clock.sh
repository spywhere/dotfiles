#!/bin/sh

clock_separator=" "
if test "$(( $(date '+%S') % 2 ))" -eq 0; then
  clock_separator=":"
fi
sketchybar --set "$NAME" label="$(date "+%a %d %b  %H$clock_separator%M")"
