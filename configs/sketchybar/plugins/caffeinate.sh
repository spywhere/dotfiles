#!/bin/bash

if test "$SENDER" = "mouse.clicked"; then
  killall caffeinate || true
fi

if pgrep caffeinate; then
  sketchybar --set "$NAME" drawing=on
else
  sketchybar --set "$NAME" drawing=off
fi
