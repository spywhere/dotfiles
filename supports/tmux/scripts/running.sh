CYCLE_INTERVAL=5

docker_start=""

if test "$(uname)" = "Darwin"; then
  if test "$(command -v docker 2>/dev/null)"; then
    docker_info=$(docker info 2>&1)
    if test $? -eq 0; then
      docker_start=""
    fi
    if echo $docker_info | grep "refused"; then
      docker_start=""
    fi
  fi
fi

badges="$docker_start"
badge_sizes=$(printf "%s" "$badges" | wc -m)

_scrolling_text() {
  local text="$1"
  local size="$2"
  local offset="$3"
  if test $# -ge 4; then
    local text_length="$4"
  else
    local text_length=$(printf "%s" "$text" | wc -m)
  fi
  if test "$text_length" -gt $size; then
    local index=$(( $offset % $text_length ))
    local padded_text="$text$text"
    printf "%s" "${padded_text:$index:$size}"
  else
    printf "%s" "$text"
  fi
}

if test "$badge_sizes" -gt 1; then
  printf "%s" "$(_scrolling_text "$badges" "1" "$(( $(date "+%s") / $CYCLE_INTERVAL ))" "$badge_sizes")"
else
  printf "%s" "$badges"
fi
