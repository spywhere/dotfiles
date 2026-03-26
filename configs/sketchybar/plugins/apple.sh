#!/usr/bin/env bash

case "$NAME" in
  apple.divider.*|apple.gap.*)
    exit
    ;;
  *)
    ;;
esac

case "$SENDER" in
  mouse.entered)
    sketchybar --set "$NAME" background.color=0xff007aff
    ;;
  mouse.exited)
    sketchybar --set "$NAME" background.color=0x00000000
    ;;
  mouse.clicked)
    sketchybar --set "$NAME" background.drawing=toggle popup.drawing=toggle
    ;;
  front_app_switched)
    sketchybar --set "$NAME" background.drawing=off popup.drawing=off
    ;;
  *)
    ;;
esac
