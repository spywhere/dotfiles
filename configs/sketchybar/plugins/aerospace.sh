#!/bin/bash

update_mode() {
  local mode
  mode=$(aerospace list-modes --current)

  if [ "$mode" == "main" ]; then
    sketchybar --set "$1" drawing=off
  else
    sketchybar --set "$1" drawing=on
  fi
}

update_windows_for_workspace() {
  local focused
  focused="$(aerospace list-workspaces --focused --format "%{workspace}")"
  local windows
  windows="$(aerospace list-windows --workspace "$1" --json --format '%{workspace-is-visible}%{app-name}' | jq 'map(@base64).[]')"
  local visible
  visible=$(echo "$windows" | head -n1 | jq -r '@base64d|fromjson|.["workspace-is-visible"]')
  local icon_padding
  icon_padding=0
  local icons
  local window
  for window64 in $windows; do
    local app
    app="$(echo "$window64" | jq -r '@base64d|fromjson|.["app-name"]')"
    icons="$("$CONFIG_DIR/plugins/icon_map.sh" "$app")"
  done
  if test -n "$icons"; then
    icon_padding=4
  fi
  local color_alpha
  if test "$focused" = "$1"; then
    color_alpha="1"
  elif test "$visible" = "true"; then
    color_alpha="0.4"
  else
    color_alpha="0.2"
  fi

  sketchybar --animate sin 10 \
             --set "$NAME" \
             width=dynamic \
             icon.width=dynamic \
             label.width=dynamic \
             icon.padding_left=8 \
             icon.padding_right="$icon_padding" \
             icon="$1" \
             icon.color.alpha="$color_alpha" \
             label="$icons" \
             label.font="sketchybar-app-font:Regular:16" \
             label.padding_left="$icon_padding" \
             label.padding_right=8 \
             label.color.alpha="$color_alpha"
}

case "$NAME" in
  *.mode)
    update_mode "$NAME"
    ;;
  *.workspace.*)
    current_workspace="$(echo "$NAME" | sed 's/^.*\.workspace\.//g')"

    has_workspace="no"
    workspaces="$(aerospace list-workspaces --all)"
    for workspace in $workspaces; do
      if test "$current_workspace" = "$workspace"; then
        has_workspace="yes"
        break
      fi
    done

    if test "$has_workspace" = "yes"; then
      update_windows_for_workspace "$current_workspace"
    else
      sketchybar --remove "$NAME"
    fi
    ;;
  *)
    workspaces="$(aerospace list-workspaces --all --json --format '%{workspace}%{monitor-appkit-nsscreen-screens-id}' | jq 'map(@base64).[]')"
    last_id=""
    for workspace64 in $workspaces; do
      workspace="$(echo "$workspace64" | jq -r '@base64d|fromjson|.workspace')"
      display="$(echo "$workspace64" | jq -r '@base64d|fromjson|.["monitor-appkit-nsscreen-screens-id"]')"

      item_id="aerospace.workspace.$workspace"

      item_display="$(sketchybar --query "$item_id" | jq -r '.bounding_rects|to_entries|map(select((.value.origin|min)+(.value.size|min)>0).key)|first')"
      if ! sketchybar --query "$item_id"; then
        sketchybar --add item "$item_id" left \
          --subscribe "$item_id" aerospace_workspace_change display_change system_woke front_app_switched \
          --set "$item_id" \
          icon.width=dynamic \
          label.width=dynamic \
          display="$display" \
          script="$CONFIG_DIR/plugins/aerospace.sh" \
          click_script="aerospace workspace $workspace"

        if test -n "$last_id"; then
          sketchybar --move "$item_id" after "$last_id"
        fi

        sketchybar --remove aerospace.bar \
          --add bracket aerospace.bar '/aerospace.workspace.*/' \
          --set aerospace.bar \
          background.color=0x20ffffff \
          background.corner_radius=25 \
          background.height=25
      fi

      if test "display-$display" = "$item_display"; then
        last_id="$item_id"
      fi
    done
    ;;
esac
