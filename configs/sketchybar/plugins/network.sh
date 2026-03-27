#!/bin/bash

if ! test -n "$(command -v ifstat)"; then
  sketchybar --set netup label="Required" \
             --set netdown label="ifstat"
  exit
fi

UPDOWN="$(ifstat -i en0 1 1 | tail -n1)"
DOWN="$(echo "$UPDOWN" | awk '{ printf "%.0f", $1 }')"
UP="$(echo "$UPDOWN" | awk '{ printf "%.0f", $2 }')"

function human_readable() {
    local abbrevs=(
        $((1 << 50)):ZB
        $((1 << 40)):EB
        $((1 << 30)):TB
        $((1 << 20)):GB
        $((1 << 10)):MB
        $((1)):KB
    )

    local bytes="${1}"

    local size="0"
    local final_abbrev="KB"
    for item in "${abbrevs[@]}"; do
        local factor="${item%:*}"
        local abbrev="${item#*:}"
        if [[ "${bytes}" -ge "${factor}" ]]; then
            size="$(bc -l <<< "${bytes} / ${factor}")"
            final_abbrev="$abbrev"
            break
        fi
    done

    printf "%.0f %s\n" "$size" "$final_abbrev"
}

DOWN_FORMAT=$(human_readable "$DOWN")
UP_FORMAT=$(human_readable "$UP")

sketchybar --set netup label="$UP_FORMAT/s" \
           --set netdown label="$DOWN_FORMAT/s"
