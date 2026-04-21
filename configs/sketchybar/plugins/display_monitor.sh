#!/bin/bash

current_displays="$(sketchybar --query "$NAME" | jq -r .label.value)"
updated_displays="$(sketchybar --query displays | sha512)"

if test "$current_displays" != "$updated_displays"; then
  bash "$(echo "$CONFIG_DIR" | dirname)/aerospace/reorganize-workspaces.sh"
  sketchybar --set "$NAME" label="$updated_displays"
fi
