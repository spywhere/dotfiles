#!/bin/bash

sketchybar --add item display_monitor right \
  --set display_monitor \
  drawing=off \
  label="$(sketchybar --query displays | sha512)" \
  script="$CONFIG_DIR/plugins/display_monitor.sh" \
  --subscribe display_monitor display_change
