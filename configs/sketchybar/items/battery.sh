#!/bin/bash

sketchybar --add item battery.status right \
           --set battery.status \
           label.font.size=8 \
           label.y_offset=5 \
           label.width=30 \
           width=0

sketchybar --add item battery right \
           --set battery \
           update_freq=1 \
           script="$CONFIG_DIR/plugins/battery.sh" \
           icon.font="SF Pro:Regular:18" \
           label.font.size=8 \
           label.y_offset=-5 \
           label.width=30 \
           --subscribe battery system_woke power_source_change
