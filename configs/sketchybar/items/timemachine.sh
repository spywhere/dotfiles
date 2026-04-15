#!/bin/bash

sketchybar --add item timemachine right \
           --set timemachine \
           drawing=off \
           icon.font.size=12 \
           label.font="SF Pro:Bold:10" \
           script="$CONFIG_DIR/plugins/timemachine.sh" \
           popup.horizontal=on \
           popup.topmost=on \
           popup.background.drawing=on \
           popup.background.border_width=1 \
           popup.background.corner_radius=8 \
           popup.background.color=0xff282d33 \
           popup.background.border_color=0x40ffffff \
           update_freq=3600 \
           --subscribe timemachine mouse.clicked

sketchybar --add item timemachine.icon popup.timemachine \
           --set timemachine.icon \
           width=0 \
           icon.padding_left=12 \
           icon.font="SF Pro:Semibold:24" \
           icon.color=0xffa4a6aa

sketchybar --add item timemachine.volume popup.timemachine \
           --set timemachine.volume \
           width=0 \
           label.padding_left=40

sketchybar --add item timemachine.storage popup.timemachine \
           --set timemachine.storage \
           width=0 \
           label.padding_left=40 \
           label.font="SF Pro:Bold:10" \
           label.color=0xffa4a6aa

sketchybar --add slider timemachine.progress popup.timemachine \
           --subscribe timemachine.progress mouse.clicked \
           --set timemachine.progress \
           slider.width=300 \
           slider.background.drawing=off \
           slider.background.height=14 \
           slider.background.corner_radius=3 \
           slider.percentage=0 \
           slider.highlight_color=0xff2e4c77 \
           slider.knob.font="SF Pro:Bold:10" \
           slider.knob.color=0xffb4b6bb

sketchybar --add item timemachine.action popup.timemachine \
           --set timemachine.action \
           width=15 \
           padding_left=-35 \
           icon.padding_left=0 \
           icon.padding_right=0 \
           icon.font="SF Pro:Semibold:15" \
           icon.color=0xff007aff \
           label.drawing=off \
           click_script="$CONFIG_DIR/plugins/timemachine.sh"
