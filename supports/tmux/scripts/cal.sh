#!/bin/sh

# shellcheck disable=SC1091
. "$HOME/.dots/binaries/_cache"

if test -n "$(command -v icalBuddy)"; then
  calitem() {
    icalBuddy -ea -nc -b '' -ss '' -ps '| |' "$@"
  }

  calfield() {
    fieldname="$1"
    shift
    calitem -iep "$fieldname" -li 1 "$@" eventsNow
  }

  if test "$1" = 'time'; then
    printf '%s\n' "$(calfield datetime)"
  elif test "$1" = 'title'; then
    printf '%s\n' "$(calfield title)"
  elif test "$1" = 'location'; then
    printf '%s\n' "$(calfield location -npn)"
  else
    printf '[%s] %s [%s]\n' "$(calfield datetime)" "$(calfield title)" "$(calfield location -npn)"
  fi
fi
