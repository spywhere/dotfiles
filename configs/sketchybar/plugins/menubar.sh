#!/bin/bash

# Turn on/off checking for disabled menu items
#   Turning this off may improve the rendering performance
CHECK_FOR_DISABLED_MENU_ITEM="on"

# A script that accepts a menu title as an input
#   Returns an icon for the menu, or empty string for no icon
# Set to empty to use no icon
ICON_MAP_SCRIPT="$CONFIG_DIR/plugins/icon_map.sh"

MENU_BAR_FONT="SF Pro:Semibold:13"
MENU_BAR_BACKGROUND_COLOR="0x40ffffff"
MENU_BAR_PADDING=10
MENU_BAR_CORNER_RADIUS=10
MENU_BAR_HEIGHT=25

MENU_POPUP_BACKGROUND_COLOR="0xa0222222"
MENU_POPUP_BORDER_COLOR="0x40ffffff"
MENU_POPUP_BLUR_RADIUS=20
MENU_POPUP_CORNER_RADIUS=10

# A script that accepts a menu title as an input
#   Returns one of the following:
#     - an icon for the menu
#     - an icon for the menu and an override font (space separated)
#     - a space for no icon but keep the icon padding
#     - an empty string for no icon and no padding
# Set to empty to use no icon
MENU_ITEM_ICON_SCRIPT="$CONFIG_DIR/plugins/menu_icon_map.sh"
MENU_ITEM_ICON_FONT="SF Pro:Medium:12"
MENU_ITEM_ICON_WIDTH=30
MENU_ITEM_FONT="SF Pro:Medium:13"
MENU_ITEM_ACCENT_COLOR="0xff007aff"
MENU_ITEM_DISABLED_COLOR="0x40ffffff"
MENU_ITEM_WIDTH=280
MENU_ITEM_HEIGHT=29
MENU_ITEM_MARGIN=5
MENU_ITEM_PADDING=10
MENU_ITEM_CORNER_RADIUS=10

#########################

COUNT=0
count() {
  COUNT="$(( COUNT + 1))"
}

fetch_menu() {
  local script
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

create_menu_item() {
  local parent_id
  parent_id="$1"
  local menu_id
  menu_id="$2"
  local item_id
  item_id="$3"
  local label
  label="$4"
  shift
  shift
  shift
  shift
  local icon
  local icon_font
  icon_font="$MENU_ITEM_ICON_FONT"
  if test -n "$MENU_ITEM_ICON_SCRIPT"; then
    icon="$("$MENU_ITEM_ICON_SCRIPT" "$INFO" "$menu_id" "$label")"
    if echo "$icon" | grep -q '^..* ..*'; then
      icon_font="$(echo "$icon" | cut -d' ' -f2-)"
      icon="$(echo "$icon" | cut -d' ' -f1)"
    fi
  fi
  local icon_padding
  local label_padding
  local draw_icon
  if test -n "$icon"; then
    draw_icon="on"
    icon_padding="$MENU_ITEM_PADDING"
    label_padding="0"
  else
    draw_icon="off"
    icon_padding="0"
    label_padding="$MENU_ITEM_PADDING"
  fi

  sketchybar --add item "$parent_id.menu.$menu_id.$item_id" "popup.$parent_id" \
    --set "$parent_id.menu.$menu_id.$item_id" \
    width="$MENU_ITEM_WIDTH" \
    icon="$icon" \
    icon.align=center \
    icon.font="$icon_font" \
    icon.drawing="$draw_icon"  \
    icon.width="$MENU_ITEM_ICON_WIDTH" \
    icon.padding_left="$icon_padding" \
    icon.padding_right="$icon_padding" \
    label="$label" \
    label.font="$MENU_ITEM_FONT" \
    background.drawing=on \
    background.height="$MENU_ITEM_HEIGHT" \
    background.padding_left="$MENU_ITEM_MARGIN" \
    background.padding_right="$MENU_ITEM_MARGIN" \
    background.color="$MENU_ITEM_ACCENT_COLOR" \
    background.color.alpha=0 \
    label.padding_left="$label_padding" \
    label.padding_right="$MENU_ITEM_PADDING" \
    background.corner_radius="$MENU_ITEM_CORNER_RADIUS" \
    "$@"
}

create_clickable_menu_item() {
  local parent_id
  parent_id="$1"
  local menu_id
  menu_id="$2"
  local item_id
  item_id="$3"
  local label
  label="$4"
  shift
  shift
  shift
  shift
  create_menu_item "$parent_id" "$menu_id" "$item_id" "$label" "$@" \
    script="$CONFIG_DIR/plugins/menubar.sh" \
    --subscribe "$parent_id.menu.$menu_id.$item_id" mouse.entered mouse.exited mouse.clicked
}

create_menu_divider() {
  local parent_id
  parent_id="$1"
  local menu_id
  menu_id="$2"
  count
  create_menu_item "$parent_id" "$menu_id" "divider.$COUNT" "-" \
    width="$(( MENU_ITEM_WIDTH - MENU_ITEM_MARGIN - MENU_ITEM_PADDING ))" \
    label= \
    icon.drawing=off \
    label.width="$(( MENU_ITEM_WIDTH - MENU_ITEM_MARGIN - MENU_ITEM_PADDING ))" \
    background.height=1 \
    background.padding_left="$(( MENU_ITEM_MARGIN + MENU_ITEM_PADDING ))" \
    background.padding_right=0 \
    label.background.color="$MENU_ITEM_DISABLED_COLOR"
}

create_menu_margin() {
  local parent_id
  parent_id="$1"
  local menu_id
  menu_id="$2"
  count
  create_menu_item "$parent_id" "$menu_id" "divider.$COUNT" "-" \
    icon.drawing=off \
    label.drawing=off \
    background.height="$MENU_ITEM_MARGIN"
}

create_popup() {
  local parent_id
  parent_id="$1"
  local menu_id
  menu_id="$2"
  shift
  shift

  # Limitation: Cannot animate before removal
  #   'sleep' would break the rendering here
  # sketchybar --animate sin 10 \
  #   --set "/$parent_id\.menu\..*/" \
  #   label.color.alpha=0
  sketchybar --remove "/$parent_id\.menu\..*/"

  create_menu_margin "$parent_id" "$menu_id"
  menu_items_var="menuBar.menus['$menu_id'].menuItems"
  item_names="$(fetch_menu "$menu_items_var.name().map((item,index)=>({name:item,index}))" | jq 'map(@base64)|.[]')"
  if test "$CHECK_FOR_DISABLED_MENU_ITEM" = "on"; then
    item_enabled="$(fetch_menu "$menu_items_var.enabled()" | jq 'map(@base64)')"
  fi
  for menu64 in $item_names; do
    menu="$(echo "$menu64" | jq -r '@base64d|fromjson|.name')"

    if test "$CHECK_FOR_DISABLED_MENU_ITEM" = "on"; then
      menu_index="$(echo "$menu64" | jq -r '@base64d|fromjson|.index')"
      menu_enabled="$(echo "$item_enabled" | jq -r ".[$menu_index]|@base64d|fromjson")"
    fi

    if test "$menu" = "null"; then
      create_menu_divider "$parent_id" "$menu_id"
    elif test "$menu_enabled" = "false"; then
      create_menu_item "$parent_id" "$menu_id" "$menu" "$menu" \
        label.color="$MENU_ITEM_DISABLED_COLOR" \
        icon.color="$MENU_ITEM_DISABLED_COLOR"
    else
      create_clickable_menu_item "$parent_id" "$menu_id" "$menu" "$menu"
    fi
  done
  create_menu_margin "$parent_id" "$menu_id"
}

create_menu() {
  local item_id
  item_id="$1"
  local label
  label="$2"
  local reference_id
  reference_id="$3"
  shift
  shift
  shift
  sketchybar --add item "$item_id" left --move "$item_id" after "$reference_id"
  update_item_for_popup "$item_id" \
    icon.drawing=off \
    label="$label" \
    label.font="$MENU_BAR_FONT" \
    label.color.alpha=0 \
    label.padding_left="$MENU_BAR_PADDING" \
    label.padding_right="$MENU_BAR_PADDING" \
    script="$CONFIG_DIR/plugins/menubar.sh" \
    --subscribe "$item_id" mouse.clicked \
    --animate sin 10 \
    --set "$item_id" \
    label.color.alpha=1

  create_popup "$parent_id.menu.$menu" "$menu" &
}

update_item_for_popup() {
  local item_id
  item_id="$1"
  shift
  sketchybar --set "$item_id" \
             background.padding_left=0 \
             background.padding_right=0 \
             background.color="$MENU_BAR_BACKGROUND_COLOR" \
             background.corner_radius="$MENU_BAR_CORNER_RADIUS" \
             background.height="$MENU_BAR_HEIGHT" \
             background.drawing=off \
             popup.topmost=on \
             popup.height=0 \
             popup.blur_radius="$MENU_POPUP_BLUR_RADIUS" \
             popup.background.drawing=on \
             popup.background.color="$MENU_POPUP_BACKGROUND_COLOR" \
             popup.background.border_width=1 \
             popup.background.border_color="$MENU_POPUP_BORDER_COLOR" \
             popup.background.corner_radius="$MENU_POPUP_CORNER_RADIUS" \
             "$@"
}

populate_menus() {
  local parent_id
  parent_id="$1"
  shift
  local last_id
  last_id="$parent_id"
  for menu64 in $(fetch_menu "menuBar.menus.name()" | jq "map(@base64)|.[2:].[]"); do
    menu="$(echo "$menu64" | jq -r '@base64d')"

    create_menu "$parent_id.menu.$menu" "$menu" "$last_id" &
    last_id="$parent_id.menu.$menu"
  done
}

case "$SENDER" in
  mouse.entered)
    sketchybar --set "$NAME" background.color.alpha=1
    ;;
  mouse.exited)
    sketchybar --set "$NAME" background.color.alpha=0
    ;;
  mouse.clicked)
    local parent_id
    local menu_id
    local item_id
    if echo "$NAME" | grep -q '\.menu\.'; then
      parent_id="$(echo "$NAME" | sed 's/\.menu\..*//g')"
      local menu_identifier
      menu_identifier="$(echo "$NAME" | sed 's/.*\.menu\.//g')"
      if echo "$menu_identifier" | grep -q '\.'; then
        menu_id="$(echo "$menu_identifier" | cut -d. -f1)"
        item_id="$(echo "$menu_identifier" | cut -d. -f2)"
      fi
    fi

    if test -z "$item_id"; then
      sketchybar --set "$NAME" background.drawing=toggle popup.drawing=toggle
    else
      sketchybar --set "$parent_id" background.drawing=off popup.drawing=off
      sketchybar --set "$parent_id.menu.$menu_id" background.drawing=off popup.drawing=off
      fetch_menu "menuBar.menus['$menu_id'].menuItems['$item_id'].click()"
    fi
    ;;
  front_app_switched)
    sketchybar --set "$NAME" background.drawing=off popup.drawing=off
    local app_icon

    if test -n "$ICON_MAP_SCRIPT"; then
      app_icon="$("$ICON_MAP_SCRIPT" "$INFO")"
    fi

    case "$NAME" in
      apple|apple.logo)
        update_item_for_popup "$NAME"
        create_popup "$NAME" "0" &
        ;;
      front_app|application|app)
        update_item_for_popup "$NAME" \
          icon="$app_icon" \
          --animate sin 10 \
          --set "$NAME" \
          label="$INFO"
        create_popup "$NAME" "1" &
        ;;
    esac

    case "$NAME" in
      application|app|app_menu)
        populate_menus "$NAME" &
        ;;
    esac
    ;;
esac
