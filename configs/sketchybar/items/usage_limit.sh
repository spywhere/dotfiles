#!/bin/bash

sketchybar --add item usage.session right \
           --set usage.session \
           drawing=off \
           label.font.size=8 \
           label.y_offset=5 \
           label.width=30 \
           width=0

sketchybar --add item usage right \
           --set usage \
           drawing=off \
           update_freq=300 \
           script="$CONFIG_DIR/plugins/usage_limit.sh" \
           icon.font="SF Pro:Regular:18" \
           label.font.size=8 \
           label.y_offset=-5 \
           label.width=30
