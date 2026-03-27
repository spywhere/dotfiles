#!/bin/bash

COUNT=0
count() {
  COUNT="$(( COUNT + 1))"
}

fetch_menu() {
  script="$(cat <<EOF
var SystemEvents = Application('System Events');

var frontApps = SystemEvents.applicationProcesses.whose({ 'frontmost': true });

if (frontApps.length === 0) {
  throw new Error("No frontmost application found.");
}

var app = frontApps[0];
var appName = app.name();

if (app.menusBar.length === 0) {
  throw new Error("No menu bar found for " + appName + ". It might be a non-native app or lack accessibility support.");
}

var menuBar = app.menuBars[0];

function getMenuItems(menu, depth) {
  return menu.name().map((name, index) => ({
    name,
    items: getMenuItems(menu[index].menuItems)
  }));
}

JSON.stringify($1)
EOF)"

  osascript -l JavaScript -e "$script"
}

render_app() {
  sketchybar --set "$NAME" \
             label="$INFO" \
             icon="$("$CONFIG_DIR/plugins/icon_map.sh" "$INFO")" \
             background.padding_left=0 \
             background.padding_right=0 \
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
             popup.background.corner_radius=10

  draw_icon="on"
  label_padding="0"
  limit="1:"
  font="SF Pro:Bold:13"

  sketchybar --remove '/app\.menu\..*/'
  for menu64 in $(fetch_menu "menuBar.menus.name()" | jq "map(@base64)|.[$limit].[]"); do
    menu="$(echo "$menu64" | jq -r '@base64d')"

    if test "$draw_icon" = "on"; then
      render_menu "$menu" "$NAME" &
    else
      sketchybar --add item "app.menu.$menu" left \
                 --set "app.menu.$menu" \
                 icon="$("$CONFIG_DIR/plugins/icon_map.sh" "$INFO")" \
                 icon.font="sketchybar-app-font:Regular:16" \
                 icon.padding_left=10 \
                 icon.drawing="$draw_icon" \
                 label="$menu" \
                 label.font="$font" \
                 label.padding_left="$label_padding" \
                 label.padding_right=10 \
                 background.padding_left=0 \
                 background.padding_right=0 \
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
                 script="$CONFIG_DIR/plugins/app.sh" \
                 --subscribe "app.menu.$menu" mouse.clicked
      render_menu "$menu" "app.menu.$menu" &
    fi

    label_padding="10"
    font="SF Pro:Semibold:13"
    draw_icon="off"
  done
}

render_item() {
  menu="$1"
  popup="$2"
  identifier="$3"
  label="$4"
  shift
  shift
  shift
  shift
  sketchybar --add item "app.menu.$menu.$identifier" "popup.$popup" \
    --set "app.menu.$menu.$identifier" \
    width=280 \
    icon=""  \
    icon.font="SF Pro:Semibold:10" \
    label="$label" \
    label.font="SF Pro:Medium:13" \
    background.drawing=on \
    background.height=29 \
    background.padding_left=5 \
    background.padding_right=5 \
    icon.padding_left=10 \
    label.padding_right=10 \
    background.corner_radius=10 \
    "$@" \
    script="$CONFIG_DIR/plugins/app.sh" \
    --subscribe "app.menu.$menu.$identifier" mouse.entered mouse.exited mouse.clicked
}

render_divider() {
  count
  render_item "$1" "$2" "divider.$COUNT" "-" \
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

render_menu() {
  for menu64 in $(fetch_menu "menuBar.menus['$1'].menuItems.name()" | jq 'map(@base64)|.[]'); do
    menu="$(echo "$menu64" | jq -r '@base64d')"
    if test "$menu" = "null"; then
      render_divider "$1" "$2"
    else
      render_item "$1" "$2" "$menu" "$menu"
    fi
  done
}

case "$NAME" in
  *.divider)
    case "$NAME" in
      divider.*)
        exit
        ;;
      *)
        ;;
    esac
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
    if test "$NAME" != "application"; then
      parent="$(echo "$NAME" | cut -d. -f-3)"
      menu_id="$(echo "$NAME" | cut -d. -f3)"
      identifier="$(echo "$NAME" | cut -d. -f4)"
    fi

    if test -z "$identifier"; then
      sketchybar --set "$NAME" background.drawing=toggle popup.drawing=toggle
    else
      sketchybar --set "$parent" background.drawing=off popup.drawing=off
      fetch_menu "menuBar.menus['$menu_id'].menuItems['$identifier'].click()"
    fi
    ;;
  front_app_switched)
    render_app &
    sketchybar --set "/app\.menu\..*/" background.drawing=off popup.drawing=off
    ;;
  *)
    ;;
esac
