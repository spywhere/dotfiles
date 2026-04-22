#!/bin/bash

sketchybar --add item display_monitor right \
  --set display_monitor \
  icon.drawing=off \
  icon=􀨧 \
  label.drawing=off \
  label="$(sketchybar --query displays | sha512)" \
  script="$CONFIG_DIR/plugins/display_monitor.sh" \
  update_freq=5 \
  --subscribe display_monitor display_change
