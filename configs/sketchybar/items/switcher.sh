#!/bin/bash

sketchybar --add event switcher_switched

sketchybar --add item switcher left \
  --subscribe switcher switcher_switched \
  --set switcher \
  icon="􀜊" \
  click_script="sketchybar --trigger switcher_switched" \
  script="$CONFIG_DIR/plugins/switcher.sh"

switcher() {
  labels="$1"
  current="$1"
  shift
  while test -n "$1"; do
    labels="$labels $1"
    shift
  done
  sketchybar --set switcher label="$labels"
  items "$current"
}
