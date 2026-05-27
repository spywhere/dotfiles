#!/bin/bash

sketchybar --add item weather right \
           --set weather \
           drawing=off \
           icon.font.size=12 \
           icon.padding_right=0 \
           script="$CONFIG_DIR/plugins/weather.sh" \
           update_freq=60
