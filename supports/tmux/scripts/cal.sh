#!/bin/sh

# shellcheck disable=SC1091
. "$HOME/.dots/binaries/_cache"

if test -n "$(command -v icalBuddy)"; then
  calitem() {
    icalBuddy -ea -nc -b '' -ss '' -ps '| |' "$@"
  }

  caltime() {
    calitem -iep 'datetime' -li 1 eventsNow
  }

  caltitle() {
    calitem -iep 'title' -li 1 eventsNow
  }

  if test "$1" = 'time'; then
    printf '%s\n' "$(caltime)"
  elif test "$1" = 'title'; then
    printf '%s\n' "$(caltitle)"
  else
    printf '[%s] %s\n' "$(caltime)" "$(caltitle)"
  fi
fi
