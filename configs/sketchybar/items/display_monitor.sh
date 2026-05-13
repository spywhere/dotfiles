#!/bin/bash

sketchybar --add item display_monitor right \
  --set display_monitor \
  icon.drawing=off \
  icon=􀨧 \
  label.drawing=off \
  label="$("$CONFIG_DIR/plugins/display_monitor.sh" hash)" \
  script="$CONFIG_DIR/plugins/display_monitor.sh" \
  --subscribe display_monitor display_change
