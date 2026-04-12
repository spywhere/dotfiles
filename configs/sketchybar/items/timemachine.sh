#!/bin/bash

sketchybar --add item timemachine right \
           --set timemachine \
           icon.font.size=12 \
           label.font="SF Pro:Bold:10" \
           script="$CONFIG_DIR/plugins/timemachine.sh" \
           update_freq=60
