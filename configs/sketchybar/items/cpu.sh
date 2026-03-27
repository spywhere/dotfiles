#!/bin/bash

sketchybar --add graph cpu right 40 \
           --set cpu \
           graph.fill_color=0xff007aff \
           icon.padding_left=1 \
           icon.padding_right=0 \
           label.padding_left=0 \
           label.padding_right=1 \
           background.padding_left=0 \
           background.padding_right=0 \
           background.drawing=on \
           background.height=18 \
           background.border_width=1 \
           background.border_color=0xcccccccc \
           background.corner_radius=3 \
           update_freq=1 \
           script="$CONFIG_DIR/plugins/cpu.sh"

sketchybar --add item cpu.c right \
           --set cpu.c \
           icon=C \
           icon.font.size=7 \
           label.drawing=off \
           y_offset=6 \
           width=0

sketchybar --add item cpu.p right \
           --set cpu.p \
           icon=P \
           icon.font.size=7 \
           label.drawing=off \
           y_offset=0 \
           width=0

sketchybar --add item cpu.u right \
           --set cpu.u \
           icon=U \
           icon.font.size=7 \
           label.drawing=off \
           y_offset=-6
