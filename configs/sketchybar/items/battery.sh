#!/bin/bash

sketchybar --add item battery right \
           --set battery update_freq=120 script="$CONFIG_DIR/plugins/battery.sh" \
           --subscribe battery system_woke power_source_change
