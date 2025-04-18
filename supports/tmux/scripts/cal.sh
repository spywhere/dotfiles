#!/bin/sh

# shellcheck disable=SC1091
. "$HOME/.dots/binaries/_cache"

if test -n "$(command -v scrolling-text)"; then
  print() {
    scrolling-text "$1" 35 "$(date +%s)"
  }
else
  print() {
    printf '%s\n' "$1"
  }
fi

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
    print "$(calfield datetime)"
  elif test "$1" = 'title'; then
    print "$(calfield title)"
  elif test "$1" = 'location'; then
    print "$(calfield location -npn)"
  else
    printf '[%s] %s [%s]\n' "$(calfield datetime)" "$(calfield title)" "$(calfield location -npn)"
  fi
fi
