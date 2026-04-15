#!/bin/bash

if test -z "$NAME"; then
  NAME="$1"
fi

update_mode() {
  local mode
  mode="$(aerospace list-modes --current)"

  if test "$mode" = "service"; then
    sketchybar --set "$1" drawing=on
  else
    sketchybar --set "$1" drawing=off
  fi
}

update_windows_for_workspace() {
  local focused
  focused="$(aerospace list-workspaces --focused --format "%{workspace}")"
  local workspace
  workspace="$(aerospace list-workspaces --all --json --format '%{workspace}%{workspace-is-visible}%{monitor-appkit-nsscreen-screens-id}' | jq --arg id "$1" 'map(select(.workspace==$id))|first|@base64')"
  local visible
  visible=$(echo "$workspace" | jq -r '@base64d|fromjson|."workspace-is-visible"//false')
  local display
  display=$(echo "$workspace" | jq -r '@base64d|fromjson|."monitor-appkit-nsscreen-screens-id"//"active"')
  local windows
  windows="$(aerospace list-windows --workspace "$1" --json --format '%{app-name}%{window-id}' | jq 'sort_by(."window-id")|map(@base64).[]')"
  local icon_padding
  icon_padding=0
  local icons
  local window
  for window64 in $windows; do
    local app
    app="$(echo "$window64" | jq -r '@base64d|fromjson|."app-name"')"
    icons="$icons$("$CONFIG_DIR/plugins/icon_map.sh" "$app")"
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
             display="$display" \
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
    # shellcheck disable=SC2001
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
    update_bracket="no"
    for workspace64 in $workspaces; do
      workspace="$(echo "$workspace64" | jq -r '@base64d|fromjson|.workspace')"
      display="$(echo "$workspace64" | jq -r '@base64d|fromjson|."monitor-appkit-nsscreen-screens-id"//"active"')"

      item_id="$NAME.workspace.$workspace"

      existing_item="$(sketchybar --query "$item_id")"
      if test $? -ne 0 ; then
        sketchybar --add item "$item_id" left \
          --subscribe "$item_id" aerospace_workspace_change space_windows_change display_change system_woke front_app_switched \
          --set "$item_id" \
          icon.width=0 \
          label.width=0 \
          display="$display" \
          script="$CONFIG_DIR/plugins/aerospace.sh" \
          click_script="aerospace workspace $workspace"

        if test -n "$last_id"; then
          sketchybar --move "$item_id" after "$last_id"
        fi

        update_bracket="yes"
        item_display=""
      else
        item_display="$(echo "$existing_item" | jq -r '.bounding_rects|to_entries|map(select((.value.origin|min)+(.value.size|min)>0).key)|first')"
      fi

      if test "display-$display" = "$item_display"; then
        last_id="$item_id"
      fi
    done
    if test "$update_bracket" = "yes"; then
      sketchybar --remove "$NAME.bar" \
        --add bracket "$NAME.bar" "/$NAME.workspace.*/" \
        --set "$NAME.bar" \
        background.color=0x20ffffff \
        background.corner_radius=25 \
        background.height=25
    fi
    ;;
esac
