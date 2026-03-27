#!/bin/bash

COUNT=0
count() {
  COUNT="$(( COUNT + 1))"
}

popup_item() {
  sketchybar --add item "$2" "popup.$1" \
             --set "$2" \
             width=280 \
             icon="$3"  \
             icon.font="SF Pro:Semibold:10" \
             label="$4" \
             label.font="SF Pro:Medium:13" \
             click_script="$5; sketchybar -m --set apple.logo background.drawing=off popup.drawing=off" \
             background.drawing=on \
             background.height=29 \
             background.padding_left=5 \
             background.padding_right=5 \
             icon.padding_left=10 \
             label.padding_right=10 \
             background.corner_radius=10 \
             "$@" \
             script="$CONFIG_DIR/plugins/apple.sh" \
             --subscribe "$2" mouse.entered mouse.exited
}

apple_item() {
  name="$1"
  shift
  popup_item apple.logo "apple.$name" "$@"
}

apple_item_divider() {
  count
  apple_item "divider.$COUNT" "1" "2" ";" \
    width=265 \
    label= \
    icon.drawing=off \
    label.drawing=on \
    label.width=265 \
    background.height=1 \
    background.padding_left=15 \
    background.padding_right=0 \
    label.background.color=0x40ffffff
}

apple_item_gap() {
  count
  apple_item "gap.$COUNT" "1" "2" ";" \
    icon.drawing=off \
    label.drawing=off \
    background.height=5
}

sketchybar --add item apple.logo left \
           --set apple.logo \
           label.drawing=off \
           label.font="SF Pro:Medium:13" \
           icon=󰀵 \
           icon.font="SF Pro:Semibold:18" \
           icon.padding_left=0 \
           icon.padding_right=0 \
           icon.align=center \
           icon.width=45 \
           background.padding_left=5 \
           background.padding_right=5 \
           background.color=0x40ffffff \
           background.corner_radius=10 \
           background.height=25 \
           background.drawing=off \
           popup.topmost=on \
           popup.height=0 \
           popup.blur_radius=20 \
           popup.background.drawing=on \
           popup.background.color=0xa0222222 \
           popup.background.border_width=1 \
           popup.background.border_color=0x40ffffff \
           popup.background.corner_radius=10 \
           script="$CONFIG_DIR/plugins/apple.sh" \
           --subscribe apple.logo mouse.clicked front_app_switched

apple_item_gap

apple_item about 􁟬 'About This Mac' "open -a 'About This Mac'"

apple_item_divider

apple_item settings 􀍟 'System Settings...' "open -a 'System Settings'"
apple_item appstore  'App Store' "open -a 'App Store'" icon.font="JetBrainsMono Nerd Font:Regular:12"

apple_item_divider

apple_item forcequit 􀒉 'Force Quit...' "osascript -e 'tell application \"System Events\" to key code 53 using {command down,option down}'"

apple_item_divider

apple_item sleep 􀜚 'Sleep' "osascript -e 'tell app \"System Events\" to sleep'"
apple_item restart 􀯆 'Restart...' "osascript -e 'tell app \"loginwindow\" to «event aevtrrst»'"
apple_item shutdown 􀆨 'Shut Down...' "osascript -e 'tell app \"loginwindow\" to «event aevtrsdn»'"

apple_item_divider

apple_item lockscreen 􀎠 'Lock Screen' "osascript -e 'tell application \"System Events\" to keystroke \"q\" using {command down,control down}'"
apple_item logout 􀉭 "Log Out $(id -F)..." "osascript -e 'tell application \"System Events\" to keystroke \"q\" using {command down,shift down}'"

apple_item_gap
