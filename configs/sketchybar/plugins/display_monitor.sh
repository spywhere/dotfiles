#!/bin/bash

calculate_hash() {
  current_size="$(echo "$1" | jq -r length)"
  # current_hash="$(echo "$1" | md5sum)"

  echo "$current_size"
  # echo "$current_size:$current_hash"
}

compare_hash() {
  # If we switched from
  #   1 to more displays: return true
  #   back to 1 display: return false
  test "$2" -gt 1 -a "$1" != "$2"
}

if test "$1" = "hash"; then
  calculate_hash "$(sketchybar --query displays)"
  exit 0
fi

case "$SENDER" in
  display_change)
    previous_hash="$(sketchybar --query "$NAME" | jq -r .label.value)"
    current_hash="$(calculate_hash "$(sketchybar --query displays)")"

    if test "$previous_hash" != "$current_hash"; then
      sketchybar --set "$NAME" label="$current_hash" icon.drawing=on update_freq=5
      if compare_hash "$previous_hash" "$current_hash"; then
        sleep 5 && bash "$(dirname "$CONFIG_DIR")/aerospace/reorganize-workspaces.sh"
      fi
    fi
    ;;
  forced)
    ;;
  *)
    sketchybar --set "$NAME" icon.drawing=off update_freq=0
    ;;
esac
