#!/bin/sh

# shellcheck disable=SC1091
. "$HOME/.dots/binaries/_cache"

if test -n "$(command -v scrolling-text)"; then
  print() {
    scrolling-text "$1" "$2" "$(date +%s)"
  }
else
  print() {
    printf '%s\n' "$1"
  }
fi

if test -n "$(command -v icalBuddy)"; then
  calitem() {
    icalBuddy -ea -nc -b '' -ss '' -ps '|\t|' -npn "$@"
  }

  filter() {
    grep -v -i -e 'ooo' -e 'appointment' -e 'lunch' -e 'busy' -e 'blocked'
  }

  item="$(calitem -iep 'datetime,title,location' -po 'datetime,title,location' -n eventsNow | filter | head -n 1)"

  if test -z "$item"; then
    return
  fi

  datetime="$(echo "$item" | cut -f 1)"
  title="$(echo "$item" | cut -f 2)"
  location="$(echo "$item" | cut -f 3)"

  if test "$1" = 'time'; then
    print "$datetime"
  elif test "$1" = 'title'; then
    print "$title" 35
  elif test "$1" = 'location'; then
    print "$location" 20
  else
    printf '[%s] %s [%s]\n' "$datetime" "$title" "$location"
  fi
fi
