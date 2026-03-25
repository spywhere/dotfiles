#!/usr/bin/env bash

CURRENT_MODE=$(aerospace list-modes --current)

if [ "$CURRENT_MODE" == "main" ]; then
  sketchybar --set "$NAME" \
    drawing=off
else
  sketchybar --set "$NAME" \
    drawing=on
fi
