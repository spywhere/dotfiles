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

workspaces="$(aerospace list-workspaces --all --json --format '%{workspace}%{monitor-appkit-nsscreen-screens-id}%{workspace-is-focused}%{workspace-is-visible}' | jq 'map(@base64).[]')"
for workspace64 in $workspaces; do
  workspace="$(echo "$workspace64" | jq -r '@base64d|fromjson|.workspace')"
  focused="$(echo "$workspace64" | jq -r '@base64d|fromjson|.["workspace-is-focused"]')"
  visible="$(echo "$workspace64" | jq -r '@base64d|fromjson|.["workspace-is-visible"]')"
  display="$(echo "$workspace64" | jq -r '@base64d|fromjson|.["monitor-appkit-nsscreen-screens-id"]')"

  item_id="aerospace.workspace.$workspace"

  sketchybar --add item "$item_id" left \
    --subscribe "$item_id" aerospace_workspace_change display_change system_woke front_app_switched \
    --set "$item_id" \
    icon.width=0 \
    label.width=0 \
    display="$display" \
    script="$CONFIG_DIR/plugins/aerospace.sh" \
    click_script="aerospace workspace $workspace"
done

sketchybar --add bracket aerospace.bar '/aerospace.workspace.*/' \
           --set aerospace.bar \
           background.color=0x20ffffff \
           background.corner_radius=25 \
           background.height=25
