#!/bin/bash

sketchybar --add item application left \
           --set application \
           icon.font="sketchybar-app-font:Regular:16" \
           label.font="SF Pro:Bold:13.0" \
           script="$CONFIG_DIR/plugins/app.sh" \
           --subscribe application front_app_switched mouse.clicked
