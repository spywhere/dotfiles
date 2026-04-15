#!/bin/bash

items() {
  while test -n "$1"; do
    if test -f "$CONFIG_DIR/items/$1.sh"; then
      source "$CONFIG_DIR/items/$1.sh"
    fi
    shift
  done
}

case "$SENDER" in
  switcher_switched)
    item_info="$(sketchybar --query switcher)"
    labels="$(echo "$item_info" | jq -r '.label.value|split(" ")|.[1:]+.[0:1]|join(" ")')"
    last="$(echo "$item_info" | jq -r '.label.value|split(" ")|.[0]')"
    current="$(echo "$item_info" | jq -r '.label.value|split(" ")|.[1]')"
    sketchybar --set "$NAME" icon="[$current]" label="$labels"

    source "$CONFIG_DIR/items/$current.sh"
    sketchybar --remove "/$last.*/"
    ;;
esac
