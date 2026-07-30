#!/bin/bash

if ! test -n "$(command -v codexbar)"; then
  sketchybar --set "$NAME.session" label="Required" label.width=45 \
             --set "$NAME" label="codexbar" label.width=45
  exit
fi

readable_time() {
  local abbrevs=(
      $((60 * 60 * 24)):d
      $((60 * 60)):h
      $((60)):m
  )

  for item in "${abbrevs[@]}"; do
      local factor="${item%:*}"
      local abbrev="${item#*:}"
      if test "$1" -ge "${factor}"; then
          echo "$1" "$factor" "$abbrev" | awk '{printf "%d%s", $1 / $2, $3}'
          if test -z "$2" && test "$abbrev" != "m" -a "$(( $1 % factor ))" -gt 0; then
            printf ' '
            readable_time "$(( $1 % factor ))" -
          fi
          return
      fi
  done

  echo "${1}s"
}

icon_for_percent() {
  case "$1" in
    [8-9][0-9]|100)
      echo "􁐛"
    ;;
    [6-7][0-9])
      echo "􀍾"
    ;;
    [4-5][0-9])
      echo "􁐚"
    ;;
    [2-3][0-9])
      echo "􁰉"
    ;;
    *)
      echo "􁐙"
    ;;
  esac
}

color_for_percent() {
  case "$1" in
    [6-9][0-9]|100)
      echo 0xffffffff
    ;;
    [4-5][0-9])
      echo 0xffffcc66
    ;;
    [2-3][0-9])
      echo 0xffff9933
    ;;
    *)
      echo 0xffff6666
    ;;
  esac
}

label_for_percent() {
  if test "$1" -eq 0; then
    echo "$2"
  else
    echo "$1%"
  fi
}

width_for_percent() {
  if test "$1" -eq 0 -o "$2" -eq 0; then
    echo 35
  else
    echo 30
  fi
}

async_update() {
  data="$(codexbar usage --json | jq 'first|{session:{percent:(100-.usage.primary.usedPercent),timer:(.usage.primary.resetsAt|fromdate-now|floor)},weekly:{percent:(100-.usage.secondary.usedPercent),timer:(.usage.secondary.resetsAt|fromdate-now|floor)}}')"

  SESSION_PERCENTAGE="$(echo "$data" | jq -r '.session.percent')"
  SESSION_TIMER="$(echo "$data" | jq -r ".session.timer")"
  WEEKLY_PERCENTAGE="$(echo "$data" | jq -r '.weekly.percent')"
  WEEKLY_TIMER="$(echo "$data" | jq -r ".weekly.timer")"
  WIDTH="$(width_for_percent "$SESSION_PERCENTAGE" "$WEEKLY_PERCENTAGE")"

  sketchybar \
    --set "$NAME.session" \
    icon="$(icon_for_percent "$SESSION_PERCENTAGE")" \
    icon.color="$(color_for_percent "$SESSION_PERCENTAGE")" \
    label="$(label_for_percent "$SESSION_PERCENTAGE" "$(readable_time "$SESSION_TIMER")")" \
    --set "$NAME" \
    label="$(label_for_percent "$WEEKLY_PERCENTAGE" "$(readable_time "$WEEKLY_TIMER")")" \
    --animate sin 10 \
    --set "$NAME.session" \
    label.width="$WIDTH" \
    --set "$NAME" \
    label.width="$WIDTH"
}

async_update &
