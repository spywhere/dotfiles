#!/bin/bash

sketchybar --add item clock right \
           --set clock update_freq=1 icon=  script="$CONFIG_DIR/plugins/clock.sh"
