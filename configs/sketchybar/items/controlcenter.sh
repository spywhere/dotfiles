#!/bin/bash

sketchybar --add alias "Control Center,BentoBox-0" right \
           --set "Control Center,BentoBox-0" \
           icon.drawing=off \
           label.drawing=off \
           click_script="$CONFIG_DIR/plugins/controlcenter.sh"
