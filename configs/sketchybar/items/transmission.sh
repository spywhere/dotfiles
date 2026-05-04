#!/bin/bash

if test -n "$(command -v transmission-remote)"; then
  sketchybar --add item transmission right \
    --set transmission \
    drawing=off \
    update_freq=60 \
    script="$CONFIG_DIR/plugins/transmission.sh" \
    popup.topmost=on \
    popup.height=dynamic \
    popup.align=right \
    popup.background.drawing=on \
    popup.background.border_width=1 \
    popup.background.corner_radius=8 \
    popup.background.color=0xff282d33 \
    popup.background.border_color=0x40ffffff \
    --subscribe transmission mouse.clicked \
    --add item transmission.metadata right \
    --set transmission.metadata \
    drawing=off
fi
