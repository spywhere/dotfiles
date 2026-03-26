#!/bin/bash

sketchybar --add event aerospace_workspace_change
sketchybar --add event aerospace_mode_change

sketchybar --add item aerospace_mode left \
  --subscribe aerospace_mode aerospace_mode_change \
  --set aerospace_mode icon="" \
  script="$CONFIG_DIR/plugins/aerospace.sh" \
  drawing=off

for sid in $(aerospace list-workspaces --all); do
  monitor=$(aerospace list-windows --workspace "$sid" --format "%{monitor-appkit-nsscreen-screens-id}")

  if [ -z "$monitor" ]; then
    monitor="1"
  fi

  sketchybar --add item space."$sid" left \
    --subscribe space."$sid" aerospace_workspace_change display_change system_woke mouse.entered mouse.exited \
    --set space."$sid" \
    display="$monitor" \
    icon="$sid" \
    background.drawing=on \
    label.font="sketchybar-app-font:Regular:16.0" \
    background.color="$ACCENT_COLOR" \
    icon.color="$BACKGROUND" \
    label.color="$BACKGROUND" \
    background.corner_radius=5 \
    background.height=25 \
    label.drawing=on \
    click_script="aerospace workspace $sid" \
    script="$CONFIG_DIR/plugins/aerospace.sh $sid"
done

sketchybar --add item space_separator left \
  --set space_separator icon="|" \
  label.drawing=off \
  background.drawing=off
