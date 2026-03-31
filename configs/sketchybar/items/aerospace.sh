#!/bin/bash

sketchybar --add event aerospace_workspace_change
sketchybar --add event aerospace_mode_change

# service mode icon
sketchybar --add item aerospace.mode left \
  --subscribe aerospace.mode aerospace_mode_change \
  --set aerospace.mode \
  icon="􀤊" \
  script="$CONFIG_DIR/plugins/aerospace.sh" \
  drawing=off

sketchybar --add item aerospace left \
  --subscribe aerospace aerospace_workspace_change display_change system_woke front_app_switched \
  --set aerospace \
  drawing=off \
  script="$CONFIG_DIR/plugins/aerospace.sh"

"$CONFIG_DIR/plugins/aerospace.sh" aerospace
