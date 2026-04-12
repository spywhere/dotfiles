#!/bin/bash

sketchybar --add item weather right \
           --set weather \
           icon.font.size=12 \
           icon.padding_right=0 \
           script="$CONFIG_DIR/plugins/weather.sh Bangkok" \
           update_freq=600
