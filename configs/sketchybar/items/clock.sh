#!/bin/bash

sketchybar --add item clock right \
           --set clock \
           update_freq=1 \
           icon.drawing=off \
           label.padding_right=0 \
           script="$CONFIG_DIR/plugins/clock.sh" \
           click_script="$CONFIG_DIR/plugins/controlcenter.sh"
