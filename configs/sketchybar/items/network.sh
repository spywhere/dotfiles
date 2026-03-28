#!/bin/bash

sketchybar --add item network.up right \
           --set network.up \
           icon=􀄨 \
           icon.font.size=7 \
           label.font.size=8 \
           label.y_offset=1 \
           label.align=right \
           label.width=45 \
           y_offset=5 \
           width=0 \
           label="0 KB/s" \
           update_freq=1 \
           script="$CONFIG_DIR/plugins/network.sh"

sketchybar --add item network.down right \
           --set network.down \
           icon=􀄩 \
           icon.font.size=7 \
           label.font.size=8 \
           label.y_offset=-1 \
           label.align=right \
           label.width=45 \
           y_offset=-5 \
           label="0 KB/s"
