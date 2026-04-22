#!/bin/bash

case "$SENDER" in
  display_change)
    current_displays="$(sketchybar --query "$NAME" | jq -r .label.value)"
    updated_displays="$(sketchybar --query displays | sha512)"

    if test "$current_displays" != "$updated_displays"; then
      bash "$(dirname "$CONFIG_DIR")/aerospace/reorganize-workspaces.sh"
      sketchybar --set "$NAME" label="$updated_displays" icon.drawing=on
    fi
    ;;
  forced)
    ;;
  *)
    sketchybar --set "$NAME" icon.drawing=off
    ;;
esac
