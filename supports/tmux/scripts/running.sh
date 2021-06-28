#!/bin/sh

CYCLE_INTERVAL=5

docker_start=""

if test "$(uname)" = "Darwin" -o "$(uname -r | sed 's/.*Microsoft.*/microsoft/g')" = "microsoft"; then
  if test "$(command -v docker 2>/dev/null)"; then
    docker_info=$(docker info 2>&1)
    if test $? -eq 0; then
      docker_start=""
    fi
    if echo "$docker_info" | grep "refused"; then
      docker_start=""
    fi
  fi
fi

badges="$docker_start"
badge_sizes=$(printf "%s" "$badges" | wc -m)

_scrolling_text() {
  __text="$1"
  __size="$2"
  __offset="$3"
  if test $# -ge 4; then
    __text_length="$4"
  else
    __text_length=$(printf "%s" "$__text" | wc -m)
  fi
  if test "$__text_length" -gt "$__size"; then
    __index=$(( __offset % __text_length ))
    __padded_text="$__text$__text"
    printf "%s" "$__padded_text" | cut -c"$(( __index + 1 ))-$(( __index + __size ))"
  else
    printf "%s" "$__text"
  fi
}

if test "$badge_sizes" -gt 1; then
  printf "%s" "$(_scrolling_text "$badges" "1" "$(( $(date "+%s") / CYCLE_INTERVAL ))" "$badge_sizes")"
else
  printf "%s" "$badges"
fi
