#!/bin/sh

weather="$(curl --fail-early -m 2 -fsSL wttr.in/Bangkok?format=%f 2>/dev/null)"
if test $? -eq 0; then
  printf "%s" "$weather"
fi
printf ""
