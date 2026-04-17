#!/bin/bash

COUNT=0
count() {
  COUNT=$(( COUNT + 1 ))
}

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
  name="$1"
  size_left="$2"
  total="$3"
  trail="$4"
  icon="􀈅"
  size_done="$(( total - size_left ))"
  percent_done="$(echo "$size_done" "$total" | awk '{printf "%.2f", $1 / $2 * 100}')"

  if test "$size_left" = "0"; then
    icon="􀈃"
  fi

  count
  sketchybar \
    --add item "transmission.torrent.$COUNT" popup.transmission \
    --set "transmission.torrent.$COUNT" \
    background.drawing=on \
    background.height=1 \
    background.border_width=1 \
    background.border_color=0x40ffffff \
    label.width=350 \
    --add item "transmission.torrent.$COUNT.name" popup.transmission \
    --set "transmission.torrent.$COUNT.name" \
    scroll_texts=on \
    background.drawing=on \
    background.height=25 \
    label="$name" \
    label.max_chars=45 \
    label.scroll_duration=600 \
    label.padding_left=25 \
    --add slider "transmission.torrent.$COUNT.progress" popup.transmission \
    --set "transmission.torrent.$COUNT.progress" \
    background.drawing=on \
    icon="$icon" \
    icon.padding_left=10 \
    icon.padding_right=10 \
    label="$percent_done%" \
    slider.width=250 \
    slider.background.drawing=on \
    slider.background.height=5 \
    slider.background.corner_radius=3 \
    slider.percentage=$(echo "$percent_done" | awk '{printf "%d", $1}') \
    slider.highlight_color=0xff2e4c77 \
    slider.knob.font="SF Pro:Bold:10" \
    slider.knob.color=0xffb4b6bb \
    --add item "transmission.torrent.$COUNT.info" popup.transmission \
    --set "transmission.torrent.$COUNT.info" \
    background.drawing=on \
    background.height=25 \
    label="$(readable_size "$size_done") / $(readable_size "$total")$trail" \
    label.padding_left=25
}

update_items() {
  torrents="$(transmission-remote -j -l | jq '.result.torrents|map(@base64)|.[]')"
  total_torrents="$(echo "$torrents" | jq -sr 'length')"
  total_items="$(sketchybar --query bar | jq --arg name "$NAME" '.items|map(select(startswith("\($name).torrent") and endswith("name")))|length')"
  if test "$total_items" -gt "$total_torrents"; then
    sketchybar --remove "/$NAME\.torrent.*/"
  fi
  update_freq=60
  active=""
  for torrent64 in $torrents; do
    torrent_name="$(echo "$torrent64" | jq -r '@base64d|fromjson|.name')"

    torrent_size_left="$(echo "$torrent64" | jq -r '@base64d|fromjson|.left_until_done')"
    torrent_total="$(echo "$torrent64" | jq -r '@base64d|fromjson|.size_when_done')"

    torrent_eta="$(echo "$torrent64" | jq -r '@base64d|fromjson|.eta')"
    torrent_ratio="$(echo "$torrent64" | jq -r '@base64d|fromjson|.upload_ratio')"
    torrent_download="$(echo "$torrent64" | jq -r '@base64d|fromjson|.rate_download')"
    torrent_upload="$(echo "$torrent64" | jq -r '@base64d|fromjson|.rate_upload')"

    torrent_trail=""
    if test "$torrent_size_left" = "0"; then
      torrent_trail=" ($torrent_ratio)"
      if test "$torrent_upload" -gt 0; then
        torrent_trail="$torrent_trail 􀄨 $(readable_size "$torrent_upload")/s"
        if test -z "$active"; then
          active="up"
        fi
      fi
    else
      torrent_trail=" ($(readable_time "$torrent_eta"))"
      if test "$torrent_download" -gt 0; then
        torrent_trail="$torrent_trail 􀄩 $(readable_size "$torrent_download")/s"
        if test "$active" != "down"; then
          active="down"
        fi
      fi
    fi
    create_torrent_item "$torrent_name" "$torrent_size_left" "$torrent_total" "$torrent_trail"
  done

  if test -n "$active"; then
    update_freq=2
  fi

  icon="􀁾"
  if test "$active" = "down"; then
    icon="􀁸"
    if test "$(sketchybar --query "$NAME" | jq -r .icon.value)" = "$icon"; then
      icon="􀁹"
    fi
  elif test "$active" = "up"; then
    icon="􀁶"
    if test "$(sketchybar --query "$NAME" | jq -r .icon.value)" = "$icon"; then
      icon="􀁷"
    fi
  fi

  draw=on
  if test "$total_torrents" = "0"; then
    draw=off
    sketchybar --set "$NAME" popup.drawing=off
  fi

  sketchybar \
    --set "$NAME" \
    drawing="$draw" \
    icon="$icon" \
    label="$total_torrents" \
    update_freq="$update_freq"

  time_hide="$(sketchybar --query "$NAME.metadata" | jq -r '.label.value')"
  if test -n "$time_hide" -a "$(date +%s)" -gt "$time_hide"; then
    sketchybar \
      --set "$NAME" popup.drawing=off \
      --set "$NAME.metadata" label=
  fi
}

case "$SENDER" in
  mouse.clicked)
    sketchybar \
      --set "$NAME" popup.drawing=toggle update_freq=2 \
      --set "$NAME.metadata" label="$(date +%s | awk '{print $1 + 60}')"
    exit
    ;;
esac

update_items
