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
           icon.padding_left=12 \
           icon.padding_right=12 \
           icon.font="SF Pro:Semibold:24" \
           icon.color=0xffa4a6aa \
           label.drawing=off \
           click_script="$CONFIG_DIR/plugins/timemachine.sh"

sketchybar --add item timemachine.volume popup.timemachine \
           --set timemachine.volume \
           width=0 \
           icon.drawing=off \
           label.padding_left=0

sketchybar --add item timemachine.storage popup.timemachine \
           --set timemachine.storage \
           width=0 \
           icon.drawing=off \
           label.padding_left=0 \
           label.font="SF Pro:Bold:10" \
           label.color=0xffa4a6aa

sketchybar --add item timemachine.size popup.timemachine \
           --set timemachine.size \
           width=0 \
           icon.drawing=off \
           label.align=right \
           label.width=250 \
           label.font="SF Pro:Bold:10" \
           label.color=0xffa4a6aa

sketchybar --add slider timemachine.progress popup.timemachine \
           --subscribe timemachine.progress mouse.clicked \
           --set timemachine.progress \
           padding_left=-60 \
           slider.width=300 \
           slider.background.drawing=off \
           slider.background.height=14 \
           slider.background.corner_radius=3 \
           slider.percentage=0 \
           slider.highlight_color=0xff2e4c77 \
           slider.knob.font="SF Pro:Bold:10" \
           slider.knob.color=0xffb4b6bb

sketchybar --add item timemachine.result popup.timemachine \
           --set timemachine.result \
           width=15 \
           padding_left=-60 \
           padding_right=10 \
           icon.drawing=on \
           icon.padding_left=0 \
           icon.padding_right=0 \
           icon.font="SF Pro:Semibold:12" \
           icon.color=0xffff4747 \
           label.drawing=off
           # popup.align=right \
           # popup.height=20 \
           # popup.background.drawing=on \
           # popup.background.border_width=1 \
           # popup.background.corner_radius=8 \
           # popup.background.color=0xff282d33 \
           # popup.background.border_color=0x40ffffff \
           # click_script="$CONFIG_DIR/plugins/timemachine.sh"

# https://github.com/lukepistrol/TimeMachineStatus/issues/44
# sketchybar --add item timemachine.result.message popup.timemachine.result \
#            --set timemachine.result.message \
#            icon.font="SF Pro:Semibold:13" \
#            icon="Error" \
#            label.font="SF Pro:Semibold:10" \
#            label="Time Machine detected that your backups cannot be reliably restored." \
#            --add item timemachine.result.message2 popup.timemachine.result \
#            --set timemachine.result.message2 \
#            label.font="SF Pro:Semibold:10" \
#            label="Time Machine must erase your existing backup history" \
#            --add item timemachine.result.code popup.timemachine.result \
#            --set timemachine.result.code \
#            icon.font="SF Pro:Semibold:13" \
#            icon="Error Code" \
#            label.font="SF Pro:Semibold:10" \
#            label=501

sketchybar --add item timemachine.action popup.timemachine \
           --set timemachine.action \
           width=15 \
           icon.padding_left=0 \
           icon.padding_right=0 \
           icon.font="SF Pro:Semibold:15" \
           icon.color=0xff007aff \
           label.drawing=off \
           click_script="$CONFIG_DIR/plugins/timemachine.sh"
