#!/bin/bash

sketchybar --add item trash right \
           --set trash \
           drawing=off \
           icon=􀈑 \
           icon.color=0xffff9966 \
           label.padding_left=0 \
           update_freq=60 \
           script="$CONFIG_DIR/plugins/trash.sh" \
           --subscribe trash mouse.clicked
