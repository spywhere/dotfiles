#!/bin/bash

sketchybar --add item slack right \
           --set slack \
           drawing=off \
           icon="󰒱" \
           icon.font.size=18 \
           icon.padding_right=0 \
           update_freq=60 \
           script="$CONFIG_DIR/plugins/app_badge.sh Slack 0xffeed49f 0xffed8796" \
           --subscribe slack front_app_switched

sketchybar --add item protonmail right \
           --set protonmail \
           drawing=off \
           icon="􀍛" \
           icon.font.size=18 \
           icon.padding_right=0 \
           update_freq=60 \
           script="$CONFIG_DIR/plugins/app_badge.sh 'Proton Mail' 0xff99ccff" \
           --subscribe protonmail front_app_switched

sketchybar --add item outlook right \
           --set outlook \
           drawing=off \
           icon="􀍛" \
           icon.font.size=18 \
           icon.padding_right=0 \
           update_freq=60 \
           script="$CONFIG_DIR/plugins/app_badge.sh 'Microsoft Outlook' 0xff99ccff" \
           --subscribe outlook front_app_switched
