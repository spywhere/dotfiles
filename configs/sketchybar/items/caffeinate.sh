#!/bin/bash

sketchybar --add item caffeinate right \
           --set caffeinate \
           drawing=on \
           icon=􂊭 \
           label.drawing=off \
           update_freq=30 \
           script="$CONFIG_DIR/plugins/caffeinate.sh" \
           --subscribe caffeinate mouse.clicked
