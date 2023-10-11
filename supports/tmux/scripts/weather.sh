#!/bin/sh

# shellcheck disable=SC1091
. "$HOME/.dots/binaries/_cache"

_weather() {
  curl --fail-early -m 2 -fsSL wttr.in/Bangkok?format=%f 2>/dev/null
}
if test $? -eq 0; then
  printf "%s" "$(_cache_value weather _weather -t 300)"
fi
printf ""
