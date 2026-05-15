#!/bin/bash

SCRIPT_DIR="$(dirname "$0")"

jq -r --arg app "$1" 'map(select(.appNames|index([$app])))|first|.iconName//":default:"' "$SCRIPT_DIR/icon_map.json"
