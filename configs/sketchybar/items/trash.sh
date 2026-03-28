#!/bin/bash

sketchybar --add item trash right \
           --set trash \
           icon=􀈑 \
           icon.color=0xffff9966 \
           label.drawing=off \
           update_freq=60 \
           script="$CONFIG_DIR/plugins/trash.sh" \
           --subscribe trash mouse.clicked
