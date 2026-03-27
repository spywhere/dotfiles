#!/bin/bash

sketchybar --add item slack right \
           --set slack \
           icon.font.size=18 \
           icon.padding_right=0 \
           update_freq=60 \
           script="$CONFIG_DIR/plugins/slack.sh" \
           --subscribe slack front_app_switched
