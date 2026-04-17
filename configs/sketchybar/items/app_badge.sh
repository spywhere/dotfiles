#!/bin/bash

add_app_badge() {
  local identifier="$1"
  local app_name="$2"
  local icon="$3"
  shift
  shift
  shift

  if test -d "/Applications/$app_name.app"; then
    sketchybar --add item "$identifier" right \
               --set "$identifier" \
               drawing=off \
               icon="$icon" \
               icon.font.size=18 \
               icon.padding_right=0 \
               update_freq=60 \
               script="$CONFIG_DIR/plugins/app_badge.sh '$app_name' $*" \
               --subscribe "$identifier" front_app_switched
  fi
}

add_app_badge slack Slack 󰒱 0xffeed49f 0xffed8796
add_app_badge protonmail 'Proton Mail' 􀍛 0xff99ccff
add_app_badge outlook 'Microsoft Outlook' 􀍛 0xff99ccff
