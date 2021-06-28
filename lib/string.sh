#!/bin/sh

# Cut a string into smaller pieces (0-based index with negative length supported)
# substring <string> [start] [length]
substring() {
  __start="0"
  __end="$(printf "%s" "$1" | wc -c)"
  if test -n "$2" && test "$2" -ge 0; then
    __start="$2"
  fi
  if test -n "$3"; then
    if test "$3" -ge 0; then
    __end="$(( __end - __start - $3 ))"
    else
      __end="$(( __end + $3 - 1 ))"
    fi
  fi
  printf "%s" "$1" | cut -c -$(( __end + 1 )) | cut -c $(( __start + 1 ))-
}
