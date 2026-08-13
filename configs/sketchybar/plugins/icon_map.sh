#!/bin/bash

SCRIPT_DIR="$(dirname "$0")"

if test "$1" = "Voyager" -o "$1" = "Voyager Beta"; then
  echo ":tabby:"
  exit
fi

jq -r --arg app "$1" 'map(select(.appNames|index([$app])))|first|.iconName//":default:"' "$SCRIPT_DIR/icon_map.json"
