#!/bin/bash

sketchybar --add item front_app left \
           --set front_app \
           icon.font="sketchybar-app-font:Regular:16" \
           label.font="SF Pro:Bold:13.0" \
           script="$CONFIG_DIR/plugins/front_app.sh" \
           --subscribe front_app front_app_switched
