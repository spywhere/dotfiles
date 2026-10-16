#!/bin/bash

add_app_badge() {
  local identifier="$1"
  local app_name="$2"
  local bundle_id="$3"
  local icon="$4"
  shift
  shift
  shift
  shift

  if test -d "/Applications/$app_name.app"; then
    sketchybar --add item "$identifier" right \
               --set "$identifier" \
               icon="$icon" \
               icon.width=0 \
               icon.font.size=18 \
               icon.padding_right=0 \
               label.width=0 \
               update_freq=60 \
               script="$CONFIG_DIR/plugins/app_badge.sh '$bundle_id' '$app_name' $*" \
               --subscribe "$identifier" front_app_switched
  fi
}

add_app_badge slack Slack com.tinyspeck.slackmacgap 󰒱 0xffeed49f 0xffed8796
add_app_badge protonmail 'Proton Mail' ch.protonmail.desktop 􀍛 0xff99ccff
add_app_badge outlook 'Microsoft Outlook' com.microsoft.Outlook 􀍛 0xff99ccff
