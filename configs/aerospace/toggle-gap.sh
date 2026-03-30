#!/bin/bash

value="$(grep 'outer\.top' "$(aerospace config --config-path)" | cut -d',' -f2 | grep -Eo '\d*')"
if test "$value" = "$1"; then
  value="0"
else
  value="$1"
fi
sed -i '' "/outer\.top/s/, [0-9]*/, $value/g" "$(aerospace config --config-path)"

aerospace reload-config
