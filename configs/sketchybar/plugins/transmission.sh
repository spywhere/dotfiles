#!/bin/bash

readable_time() {
  local abbrevs=(
      $((60 * 60 * 24)):days
      $((60 * 60)):hours
      $((60)):mins
  )

  for item in "${abbrevs[@]}"; do
      local factor="${item%:*}"
      local abbrev="${item#*:}"
      if test "$1" -ge "${factor}"; then
          echo "$1" "$factor" "$abbrev" | awk '{printf "%.0f %s", $1 / $2, $3}'
          return
      fi
  done

  echo "${1}s"
}

readable_size() {
  local abbrevs=(
      $((10 ** 18)):ZB
      $((10 ** 15)):EB
      $((10 ** 12)):TB
      $((10 ** 9)):GB
      $((10 ** 6)):MB
      $((10 ** 3)):KB
      1:B
  )

  for item in "${abbrevs[@]}"; do
      local factor="${item%:*}"
      local abbrev="${item#*:}"
      if test "$1" -ge "${factor}"; then
          echo "$1" "$factor" "$abbrev" | awk '{printf "%.2f %s", $1 / $2, $3}'
          return
      fi
  done

  echo "0 B"
}

create_torrent_item() {
  local parent_name="$1"
  shift
  local separator="$1"
  shift
  local id="$1"
  shift
  local status="$1"
  shift
  local name="$1"
  shift

  sketchybar \
    --add item "$parent_name.torrent.$id" popup.transmission \
    --set "$parent_name.torrent.$id" \
    background.drawing="$separator" \
    background.height=1 \
    background.border_width=1 \
    background.border_color=0x40ffffff \
    label.width=350 \
    script="$CONFIG_DIR/plugins/transmission.sh" \
    --add item "$parent_name.torrent.$id.name" popup.transmission \
    --set "$parent_name.torrent.$id.name" \
    scroll_texts=on \
    background.drawing=on \
    background.height=25 \
    label="$name" \
    label.max_chars=45 \
    label.scroll_duration=600 \
    label.padding_left=25 \
    --add slider "$parent_name.torrent.$id.progress" popup.transmission \
    --set "$parent_name.torrent.$id.progress" \
    icon.padding_left=10 \
    icon.padding_right=10 \
    slider.width=250 \
    slider.background.drawing=on \
    slider.background.height=5 \
    slider.background.corner_radius=3 \
    slider.highlight_color=0xff2e4c77 \
    slider.knob.font="SF Pro:Bold:10" \
    slider.knob.color=0xffb4b6bb \
    --add item "$parent_name.torrent.$id.info" popup.transmission \
    --set "$parent_name.torrent.$id.info" \
    background.drawing=on \
    background.height=25 \
    label.padding_left=25

  update_torrent_item "$parent_name" "$id" "$status" "$@"
}

update_torrent_item() {
  local parent_name="$1"
  shift
  local id="$1"
  shift
  local status="$1"
  shift
  local size_left="$1"
  shift
  local total="$1"
  shift
  local trail="$1"
  local icon="􀈃"
  local size_done="$(( total - size_left ))"
  local percent_done
  percent_done="$(echo "$size_done" "$total" | awk '{printf "%.2f", $1 / $2 * 100}')"

  case "$status" in
    1|2)
      # queued/check
      icon="􂰶"
      ;;
    3|4)
      # queued/download
      icon="􀈅"
      ;;
    5|6)
      # queued/seed
      icon="􀈃"
      ;;
  esac

  sketchybar \
    --set "$parent_name.torrent.$id.progress" \
    icon="$icon" \
    label="$percent_done%" \
    slider.percentage="$(echo "$percent_done" | awk '{printf "%d", $1}')" \
    --set "$parent_name.torrent.$id.info" \
    label="$(readable_size "$size_done") / $(readable_size "$total")$trail"
}

update_item_and_popup() {
  local name="$1"
  local torrents
  torrents="$(transmission-remote -j -l | jq '.result.torrents|map(.+{completion: (.size_when_done-.left_until_done)/.size_when_done})|sort_by(.completion,-.id)|reverse|map(@base64)|.[]')"
  local total_torrents
  total_torrents="$(echo "$torrents" | jq -sr 'length')"

  if test "$total_torrents" = "0"; then
    sketchybar --remove "/$name\.torrent.*/"
    return
  fi

  local total_items
  total_items="$(sketchybar --query bar | jq --arg name "$name" '.items|map(select(startswith("\($name).torrent") and endswith("name")))|length')"
  if test "$total_items" -gt "$total_torrents"; then
    sketchybar --remove "/$name\.torrent.*/"
  fi
  local active=""
  local separator="off"
  for torrent64 in $torrents; do
    local torrent_id
    torrent_id="$(echo "$torrent64" | jq -r '@base64d|fromjson|.id')"
    local torrent_name
    torrent_name="$(echo "$torrent64" | jq -r '@base64d|fromjson|.name')"
    local torrent_status
    torrent_status="$(echo "$torrent64" | jq -r '@base64d|fromjson|.status')"

    local torrent_size_left
    torrent_size_left="$(echo "$torrent64" | jq -r '@base64d|fromjson|.left_until_done')"
    local torrent_total
    torrent_total="$(echo "$torrent64" | jq -r '@base64d|fromjson|.size_when_done')"

    local torrent_eta
    torrent_eta="$(echo "$torrent64" | jq -r '@base64d|fromjson|.eta')"
    local torrent_ratio
    torrent_ratio="$(echo "$torrent64" | jq -r '@base64d|fromjson|.upload_ratio')"
    local torrent_download
    torrent_download="$(echo "$torrent64" | jq -r '@base64d|fromjson|.rate_download')"
    local torrent_upload
    torrent_upload="$(echo "$torrent64" | jq -r '@base64d|fromjson|.rate_upload')"

    local torrent_trail=""
    case "$torrent_status" in
      3|4)
        # queued/download
        if test "$torrent_eta" -ge 0; then
          torrent_trail=" ($(readable_time "$torrent_eta"))"
        fi
        if test "$torrent_download" -gt 0; then
          torrent_trail="$torrent_trail 􀄩 $(readable_size "$torrent_download")/s"
          if test "$active" != "down"; then
            active="down"
          fi
        fi
        ;;
      5|6)
        # queued/seed
        torrent_trail=" ($(printf '%.4f' "$torrent_ratio"))"
        if test "$torrent_upload" -gt 0; then
          torrent_trail="$torrent_trail 􀄨 $(readable_size "$torrent_upload")/s"
          if test -z "$active"; then
            active="up"
          fi
        fi
        ;;
    esac
    create_torrent_item "$name" "$separator" "$torrent_id" "$torrent_status" "$torrent_name" "$torrent_size_left" "$torrent_total" "$torrent_trail"
    separator="on"
  done

  local item_data
  item_data="$(sketchybar --query "$name")"
  local current_icon
  current_icon="$(echo "$item_data" | jq -r .icon.value)"
  local draw_popup
  draw_popup="$(echo "$item_data" | jq -r .popup.drawing)"
  local icon="􀁾"
  if test "$active" = "down"; then
    icon="􀁸"
    if test "$current_icon" = "$icon"; then
      icon="􀁹"
    fi
  elif test "$active" = "up"; then
    icon="􀁶"
    if test "$current_icon" = "$icon"; then
      icon="􀁷"
    fi
  fi

  sketchybar \
    --set "$name" \
    drawing=on \
    icon="$icon" \
    label="$total_torrents"

  if test -n "$active"; then
    sketchybar --set "$name" update_freq=2
  elif test "$draw_popup" = "off"; then
    sketchybar \
      --set "$name" update_freq=60 \
      --set "/$name\.torrent\.*/" update_freq=0 \
      --set "$name.metadata" label=
  fi

  local time_hide
  time_hide="$(sketchybar --query "$name.metadata" | jq -r '.label.value')"
  if test -n "$time_hide" -a "$(date +%s)" -gt "$time_hide"; then
    sketchybar \
      --set "$name" popup.drawing=off update_freq=60 \
      --set "$name.metadata" label=
  fi
}

# shellcheck disable=SC2153
case "$NAME" in
  *.torrent.*)
    ;;
  *.metadata)
    ;;
  *)
    case "$SENDER" in
      mouse.clicked)
        sketchybar \
          --set "$NAME" popup.drawing=toggle update_freq=2 \
          --set "$NAME.metadata" label="$(date +%s | awk '{print $1 + 60}')"
        exit
        ;;
    esac

    update_item_and_popup "$NAME"
    ;;
esac
