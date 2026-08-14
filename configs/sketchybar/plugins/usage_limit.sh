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
      reset="$(printf '%s' "$record" | jq -r ".${limit}.resetCompact")"
      limit_count="$((limit_count + 1))"
      if test "$limit_count" = "1"; then
        top_label="$remaining%"
        bottom_label="$reset"
      else
        top_label="$top_label $bottom_label"
        bottom_label="$remaining% $reset"
      fi
    fi
  done

  sketchybar --set "$parent" drawing=on icon.drawing=off label="$(provider_label "$provider")" \
              --set "$parent.primary" drawing=on label="$top_label" \
              --set "$parent.secondary" drawing=on label="$bottom_label"
}

add_limit_item() {
  local parent="$1"
  local item_id="$2"
  local limit="$3"
  local record="$4"
  local used remaining detail label

  used="$(printf '%s' "$record" | jq -r ".${limit}.usedPercent | floor")"
  remaining="$(( 100 - used ))"
  detail="$(printf '%s' "$record" | jq -r ".${limit}.reset")"
  label="$(limit_label "$limit"): ${used}% used, ${remaining}% remaining — ${detail}"

  sketchybar --add slider "$item_id" "$parent" \
             --set "$item_id" \
             padding_left=10 \
             icon.drawing=off \
             label="$label" \
             label.font="SF Pro:Regular:12" \
             label.width=280 \
             label.padding_left=10 \
             label.padding_right=6 \
             slider.width=120 \
             slider.percentage="$used" \
             slider.highlight_color="$(color_for_percent "$remaining")" \
             slider.background.height=6 \
             slider.knob.drawing=off
}

select_provider() {
  local records="$1"
  local stored highest

  if test "$(defaults read com.steipete.codexbar menuBarShowsHighestUsage 2>/dev/null)" = "1"; then
    highest="$(printf '%s' "$records" | jq -r '
      map(. as $provider | [.primary.usedPercent?, .secondary.usedPercent?]
          | map(select(. != null and . < 100)) | max? // -1
          | $provider + {score: .})
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
    if type != "array" then error("usage must be an array") else . end
    | def reset_seconds:
        try ((.resetsAt | fromdate) - now | floor) catch null;
      def reset_compact:
        reset_seconds as $seconds
          | if ($seconds | type) != "number" then "unavailable"
            elif $seconds > 0 then
              ($seconds / 86400 | floor) as $days
              | (($seconds % 86400) / 3600 | floor) as $hours
              | (($seconds % 3600) / 60 | floor) as $minutes
              | if $days > 0 then ($days | tostring) + "d" + ($hours | tostring) + "h" + ($minutes | tostring) + "m"
                elif $hours > 0 then ($hours | tostring) + "h" + ($minutes | tostring) + "m"
                else ($minutes | tostring) + "m"
                end
            else "due"
            end;
    map(. as $record | {
        provider: ($record.provider // $record.id // empty),
        primary: ($record.usage.primary? // null),
        secondary: ($record.usage.secondary? // null)
      })
    | map(select((.provider | (type == "string" and length > 0)))
          | select(((.primary.usedPercent? | type) == "number" and .primary.usedPercent >= 0 and .primary.usedPercent <= 100)
                   or ((.secondary.usedPercent? | type) == "number" and .secondary.usedPercent >= 0 and .secondary.usedPercent <= 100)))
      | map(.primary |= if . == null or (.usedPercent | type) != "number" or .usedPercent < 0 or .usedPercent > 100 then null else {
        usedPercent: .usedPercent,
        reset: (if (.resetDescription | type) == "string" then .resetDescription else (reset_seconds as $seconds | if ($seconds | type) == "number" and $seconds > 0 then "resets in " + ($seconds / 3600 | floor | tostring) + "h" elif ($seconds | type) == "number" then "reset due" else "reset unavailable" end) end),
        resetCompact: reset_compact
      } end)
      | map(.secondary |= if . == null or (.usedPercent | type) != "number" or .usedPercent < 0 or .usedPercent > 100 then null else {
        usedPercent: .usedPercent,
        reset: (if (.resetDescription | type) == "string" then .resetDescription else (reset_seconds as $seconds | if ($seconds | type) == "number" and $seconds > 0 then "resets in " + ($seconds / 3600 | floor | tostring) + "h" elif ($seconds | type) == "number" then "reset due" else "reset unavailable" end) end),
        resetCompact: reset_compact
      } end)
  '
}

validate_cached_usage() {
  jq -ce '
    if type != "array" or length == 0 then error("usage cache must be a non-empty array") else . end
    | if all(.[];
        (type == "object")
        and (keys | sort) == ["primary", "provider", "secondary"]
        and (.provider | type == "string" and length > 0)
        and ([(.primary), (.secondary)] | all(.[]; . == null or (
          type == "object" and (keys | sort) == ["reset", "resetCompact", "usedPercent"]
          and (.usedPercent | type == "number" and . >= 0 and . <= 100)
          and (.reset | type == "string") and (.resetCompact | type == "string")
        ))) and (.primary != null or .secondary != null)
      ) then . else error("invalid usage cache record") end
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
               label="$(provider_label "$provider")" label.font="SF Pro:Semibold:13" label.width=396 \
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
  records="$(printf '%s' "$raw" | normalize_usage | validate_cached_usage)" || {
    return 0
  }
  sketchybar --set "$parent" icon="$records" icon.drawing=off
  render_usage "$parent" "$records" || return 0
  render_popup "$parent" "$records"
}

if test "$SENDER" = "mouse.clicked"; then
  sketchybar --set "${NAME%%.*}" popup.drawing=toggle
elif test "$NAME" = "usage"; then
  update_usage
fi
