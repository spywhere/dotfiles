# Cut a string into smaller pieces (0-based index with negative length supported)
# substring <string> [start] [length]
substring() {
  start="0"
  end="$(printf "%s" "$1" | wc -c)"
  if test -n "$2" && test "$2" -ge 0; then
    start="$2"
  fi
  if test -n "$3"; then
    if test "$3" -ge 0; then
    end="$(( $end - $start - $3 ))"
    else
      end="$(( $end + $3 - 1 ))"
    fi
  fi
  printf "%s" "$1" | cut -c -$(( $end + 1 )) | cut -c $(( $start + 1 ))-
}
