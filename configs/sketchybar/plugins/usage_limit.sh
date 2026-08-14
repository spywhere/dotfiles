#!/bin/bash

color_for_percent() {
  case "$1" in
    [6-9][0-9]|100) echo 0xffffffff ;;
    [4-5][0-9]) echo 0xffffcc66 ;;
    [2-3][0-9]) echo 0xffff9933 ;;
    *) echo 0xffff6666 ;;
  esac
}

provider_label() {
  case "$1" in
    codex) echo "Codex" ;;
    claude) echo "Claude" ;;
    *) echo "$1" ;;
  esac
}

limit_label() {
  case "$1" in
    primary) echo "Session" ;;
    secondary) echo "Weekly" ;;
  esac
}

readable_time() {
  local seconds="$1"
  local nested="$2"
  local units=(
    $((60 * 60 * 24)):d
    $((60 * 60)):h
    60:m
  )
  local unit factor suffix remainder

  for unit in "${units[@]}"; do
    factor="${unit%%:*}"
    suffix="${unit#*:}"
    if test "$seconds" -ge "$factor"; then
      remainder="$((seconds % factor))"
      if test -z "$nested" && test "$remainder" -gt 0; then
        # nested="-" marks the recursive call so it can't recurse again, capping output at two units
        printf '%s %s\n' "$((seconds / factor))$suffix" "$(readable_time "$remainder" -)"
      else
        printf '%s%s\n' "$((seconds / factor))" "$suffix"
      fi
      return
    fi
  done
  printf '%ss\n' "$seconds"
}

format_reset() {
  local seconds="$1"

  if test "$seconds" = "null" || test -z "$seconds"; then
    printf '%s\n' "reset unavailable"
  elif test "$seconds" -le 0 2>/dev/null; then
    printf '%s\n' "resets now"
  else
    case "$seconds" in
      *[!0-9]*) printf '%s\n' "reset unavailable" ;;
      *) return 1 ;;
    esac
  fi
}

compact_reset() {
  local seconds="$1"
  local prefix="$2"

  if test "$seconds" -gt 0 2>/dev/null && [[ "$seconds" != *[!0-9]* ]]; then
    printf '%s%s\n' "$prefix" "$(readable_time "$seconds")"
  else
    format_reset "$seconds"
  fi
}

set_persistent_usage() {
  local parent="$1"
  local provider="$2"
  local record="$3"
  local limit used remaining reset top_label bottom_label limit_count

  top_label=""
  bottom_label=""
  limit_count=0
  for limit in primary secondary; do
    if test "$(printf '%s' "$record" | jq -r ".${limit} != null")" = "true"; then
      used="$(printf '%s' "$record" | jq -r ".${limit}.usedPercent | floor")"
      remaining="$(( 100 - used ))"
      reset="$(printf '%s' "$record" | jq -r ".${limit}.resetSeconds")"
      limit_count="$((limit_count + 1))"
      if test "$limit_count" = "1"; then
        top_label="$remaining%"
        bottom_label="$(compact_reset "$reset")"
      else
        top_label="$top_label $bottom_label"
        bottom_label="$remaining% $(compact_reset "$reset")"
      fi
    fi
  done

  if test "$limit_count" = "1"; then
    sketchybar --set "$parent" drawing=on label="$(provider_label "$provider")" \
               --set "$parent.primary" drawing=on label="$top_label" width=0 label.width=35 \
               --set "$parent.secondary" drawing=on label="$bottom_label" label.width=35
  else
    sketchybar --set "$parent" drawing=on label="$(provider_label "$provider")" \
               --set "$parent.primary" drawing=on label="$top_label" width=0 label.width=60 \
               --set "$parent.secondary" drawing=on label="$bottom_label" label.width=60
  fi
}

add_limit_item() {
  local parent="$1"
  local item_id="$2"
  local limit="$3"
  local record="$4"
  local used remaining reset label

  used="$(printf '%s' "$record" | jq -r ".${limit}.usedPercent | floor")"
  remaining="$(( 100 - used ))"
  reset="$(printf '%s' "$record" | jq -r ".${limit}.resetSeconds")"
  label="${used}% used, $(compact_reset "$reset" "resets in ")"

  sketchybar --add slider "$item_id" "$parent" \
             --set "$item_id" \
             padding_left=20 \
             icon="$(limit_label "$limit"):" \
             icon.font="SF Pro:Regular:12" \
             icon.width=60 \
             icon.align=left \
             icon.padding_left=0 \
             icon.padding_right=6 \
             label="$label" \
             label.font="SF Pro:Regular:12" \
             label.width=dynamic \
             label.padding_left=10 \
             label.padding_right=10 \
             slider.width=120 \
             slider.percentage="$remaining" \
             slider.highlight_color="$(color_for_percent "$remaining")" \
             slider.background.height=6 \
             slider.knob.drawing=off
}

select_provider() {
  local records="$1"
  local stored highest

  if test "$(defaults read com.steipete.codexbar menuBarShowsHighestUsage 2>/dev/null)" = "1"; then
    highest="$(printf '%s' "$records" | jq -r '
      map(. + {score: ([.primary.usedPercent, .secondary.usedPercent]
                        | map(select(. != null and . < 100)) | max? // -1)})
      | map(select(.score >= 0)) | sort_by(.score) | reverse | .[0].provider // empty
    ')"
    if test -n "$highest"; then
      printf '%s\n' "$highest"
      return
    fi
    printf '%s' "$records" | jq -r '.[0].provider'
    return
  fi

  stored="$(defaults read com.steipete.codexbar selectedMenuProvider 2>/dev/null)"
  if test -n "$stored" && printf '%s' "$records" | jq -e --arg provider "$stored" \
      '.[] | select(.provider == $provider)' >/dev/null; then
    printf '%s\n' "$stored"
    return
  fi
  printf '%s' "$records" | jq -r '.[0].provider'
}

normalize_usage() {
  jq -ce '
    map(
      {provider: (.provider // .id // "unknown")}
      + (.usage | {primary, secondary} | map_values(
          select(. != null)
          | {usedPercent, resetSeconds: ((.resetsAt | fromdate? - now | floor) // null)}
        ))
      | select(.primary != null or .secondary != null)
    )
    | if length == 0 then error("no valid usage records") else . end
  '
}

render_usage() {
  local parent="$1"
  local records="$2"
  local selected selected_record

  selected="$(select_provider "$records")"
  selected_record="$(printf '%s' "$records" | jq -c --arg provider "$selected" '.[] | select(.provider == $provider)')"
  if test -z "$selected_record"; then
    return 1
  fi
  set_persistent_usage "$parent" "$selected" "$selected_record"
}

render_popup() {
  local parent="$1"
  local records="$2"
  local provider provider_index provider_record record limit

  sketchybar --set "$parent" popup.drawing=off \
             --remove "/$parent\\.popup\\..*/"
  while IFS= read -r provider_record; do
    provider="$(printf '%s' "$provider_record" | jq -r '.provider')"
    provider_index="$(printf '%s' "$provider_record" | jq -r '.index')"
    record="$(printf '%s' "$records" | jq -c --arg provider "$provider" '.[] | select(.provider == $provider)')"
    sketchybar --add item "$parent.popup.$provider_index" "popup.$parent" \
               --set "$parent.popup.$provider_index" icon.drawing=off \
               label="$(provider_label "$provider")" label.font="SF Pro:Semibold:13" label.width=dynamic \
               label.padding_left=10 label.padding_right=10
    for limit in primary secondary; do
      if test "$(printf '%s' "$record" | jq -r ".${limit} != null")" = "true"; then
        add_limit_item "popup.$parent" "$parent.popup.$provider_index.$limit" "$limit" "$record"
      fi
    done
  done <<EOF
$(printf '%s' "$records" | jq -c 'to_entries[] | {index: .key, provider: .value.provider}')
EOF
}

update_usage() {
  local parent raw records

  parent="${NAME%%.*}"
  if ! command -v codexbar >/dev/null || ! command -v jq >/dev/null; then
    return 0
  fi
  raw="$(codexbar usage --json 2>/dev/null)" || return 0
  records="$(printf '%s' "$raw" | normalize_usage)" || return 0
  sketchybar --set "$parent" icon="$records" icon.drawing=off
  render_usage "$parent" "$records" || return 0
  render_popup "$parent" "$records"
}

if test "$SENDER" = "mouse.clicked"; then
  sketchybar --set "${NAME%%.*}" popup.drawing=toggle
elif test "$NAME" = "usage"; then
  update_usage
fi
