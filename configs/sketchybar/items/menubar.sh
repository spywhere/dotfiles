#!/bin/bash

# apple.logo / apple : apple
# front_app          : application
# application / app  : application + app menu
# app_menu           : app menu

sketchybar --add item application left \
           --set application \
           icon.font="sketchybar-app-font:Regular:16" \
           label.font="SF Pro:Bold:13.0" \
           script="$CONFIG_DIR/plugins/menubar.sh" \
           --subscribe application front_app_switched mouse.clicked
