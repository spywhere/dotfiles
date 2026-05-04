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

parse_torrent() {
  local callback="$1"
  local torrent64="$2"

  local name
  name="$(echo "$torrent64" | jq -r '@base64d|fromjson|.name')"
  local id
  id="$(echo "$torrent64" | jq -r '@base64d|fromjson|.id')"
  local status
  status="$(echo "$torrent64" | jq -r '@base64d|fromjson|.status')"

  local size_left
  size_left="$(echo "$torrent64" | jq -r '@base64d|fromjson|.left_until_done')"
  local total
  total="$(echo "$torrent64" | jq -r '@base64d|fromjson|.size_when_done')"

  local eta
  eta="$(echo "$torrent64" | jq -r '@base64d|fromjson|.eta')"
  local ratio
  ratio="$(echo "$torrent64" | jq -r '@base64d|fromjson|.upload_ratio')"
  local download_rate
  download_rate="$(echo "$torrent64" | jq -r '@base64d|fromjson|.rate_download')"
  local upload_rate
  upload_rate="$(echo "$torrent64" | jq -r '@base64d|fromjson|.rate_upload')"

  local trail=""
  case "$status" in
    3|4)
      # queued/download
      if test "$eta" -ge 0; then
        trail=" ($(readable_time "$eta"))"
      fi
      if test "$download_rate" -gt 0; then
        trail="$trail 􀄩 $(readable_size "$download_rate")/s"
      fi
      ;;
    5|6)
      # queued/seed
      trail=" ($(printf '%.4f' "$ratio"))"
      if test "$upload_rate" -gt 0; then
        trail="$trail 􀄨 $(readable_size "$upload_rate")/s"
      fi
      ;;
  esac
  "$callback" "$name" "$id" "$status" "$size_left" "$total" "$trail"
}

create_torrent_item() {
  local parent_name="$1"
  shift
  local separator="$1"
  shift
  local name="$1"
  shift
  local id="$1"
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

  update_torrent_item "$parent_name" "$id" "$@"
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

update_torrent_menu() {
  local item_name
  # shellcheck disable=SC2001
  item_name="$(echo "$1" | sed 's/\.torrent\..*$//g')"
  local torrent64
  # shellcheck disable=SC2001
  torrent64="$(transmission-remote -j -t "$(echo "$1" | sed 's/^.*\.torrent\.//g')" -i | jq '.result.torrents|first//""|@base64')"

  update_torrent_menu_callback() {
    shift # remove name
    update_torrent_item "$item_name" "$@"
  }

  if test -z "$torrent64" -o "$torrent64" = '""'; then
    sketchybar --remove "$1" --remove "/$1\..*/"
  else
    parse_torrent update_torrent_menu_callback "$torrent64"
  fi
}

populate_items() {
  local item_name="$1"
  local torrents
  torrents="$(transmission-remote -j -l | jq '.result.torrents|map(.+{completion: (.size_when_done-.left_until_done)/.size_when_done})|sort_by(.completion,-.id)|reverse|map(@base64)|.[]')"

  local separator="off"
  for torrent64 in $torrents; do
    # shellcheck disable=SC2329
    populate_items_callback() {
      local id="$2"

      if ! sketchybar --query "$item_name.torrent.$id"; then
        create_torrent_item "$item_name" "$separator" "$@"
      fi
    }

    parse_torrent populate_items_callback "$torrent64"
    separator="on"
  done
}

update_item() {
  local item_name="$1"
  local torrents
  torrents="$(transmission-remote -j -l | jq '.result.torrents|length as $total|reduce .[] as $item ({up:0,down:0};{up:.up+$item.rate_upload,down:.down+$item.rate_download})|{total:$total,active: if .down > 0 then "down" elif .up > 0 then "up" else "" end}|@base64')"
  local total_torrents
  total_torrents="$(echo "$torrents" | jq -r '@base64d|fromjson|.total')"
  local active
  active="$(echo "$torrents" | jq -r '@base64d|fromjson|.active')"

  local item_data
  item_data="$(sketchybar --query "$item_name")"
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
    --set "$item_name" \
    drawing=on \
    icon="$icon" \
    label="$total_torrents"

  if test -n "$active"; then
    sketchybar --set "$item_name" update_freq=2
  elif test "$draw_popup" = "off"; then
    sketchybar \
      --set "$item_name" update_freq=60 \
      --set "/$item_name\.torrent\.*/" update_freq=0 \
      --set "$item_name.metadata" label=
  fi

  local time_hide
  time_hide="$(sketchybar --query "$item_name.metadata" | jq -r '.label.value')"
  if test -n "$time_hide" -a "$(date +%s)" -gt "$time_hide"; then
    sketchybar \
      --set "$item_name" popup.drawing=off update_freq=60 \
      --set "/$item_name\.torrent\.*/" update_freq=0 \
      --set "$item_name.metadata" label=
  fi
}

# shellcheck disable=SC2153
case "$NAME" in
  *.torrent.*)
    update_torrent_menu "$NAME"
    ;;
  *.metadata)
    ;;
  *)
    case "$SENDER" in
      mouse.clicked)
        populate_items "$NAME"

        sketchybar \
          --set "$NAME" popup.drawing=toggle update_freq=2 \
          --set "/$NAME\.torrent\.*/" update_freq=2 \
          --set "$NAME.metadata" label="$(date +%s | awk '{print $1 + 60}')"
        exit
        ;;
    esac

    update_item "$NAME"
    ;;
esac
