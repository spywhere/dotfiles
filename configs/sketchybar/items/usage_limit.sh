#!/bin/bash

sketchybar --add item usage right \
           --set usage \
           drawing=off \
           update_freq=300 \
           script="$CONFIG_DIR/plugins/usage_limit.sh" \
           icon.drawing=off \
           label.font="SF Pro:Semibold:14" \
           popup.topmost=on \
           popup.height=20 \
           popup.align=right \
           popup.background.drawing=on \
           popup.background.border_width=1 \
           popup.background.corner_radius=8 \
           popup.background.color=0xff282d33 \
           popup.background.border_color=0x40ffffff \
           --subscribe usage mouse.clicked

sketchybar --add item usage.primary right \
           --move usage.primary after usage \
           --set usage.primary \
           drawing=off \
           script="$CONFIG_DIR/plugins/usage_limit.sh" \
           icon.drawing=off \
           label.font.size=8 \
           label.y_offset=5 \
           width=0 \
           --subscribe usage.primary mouse.clicked

sketchybar --add item usage.secondary right \
           --move usage.secondary after usage.primary \
           --set usage.secondary \
           drawing=off \
           script="$CONFIG_DIR/plugins/usage_limit.sh" \
           icon.drawing=off \
           label.font.size=8 \
           label.y_offset=-5 \
           --subscribe usage.secondary mouse.clicked

sketchybar --move usage after usage.secondary
