#!/bin/sh

if test "$(command -v vcgencmd 2>/dev/null)"; then
  printf "%s°C" "$(vcgencmd measure_temp | sed -e "s/temp=//" -e "s/'C//")"
else
  printf ""
fi
