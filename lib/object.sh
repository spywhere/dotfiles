#!/bin/sh

. "$HOME/$DOTFILES/lib/list.sh"
. "$HOME/$DOTFILES/lib/string.sh"

_FIELDS=""
field() {
  field__name="$1"
	shift
  if test "$#" -eq 0; then
    printf ""
    return
  fi
  field__output="$field__name"
	for field__value in "$@"
	do
    field__output="$field__output:$(_escape_special "$field__value")"
	done

  _FIELDS="$(_add_item "$_FIELDS" ";" "$field__output")"
}

reset_object() {
  _FIELDS=""
}

make_object() {
  printf "%s" "$_FIELDS"
}

_map_field() {
	map_field__object="$1"
  map_field__callback="$2"
	for map_field__field in $(printf "%s" "$map_field__object" | awk 'BEGIN{RS=";"}{print $0}')
	do
    map_field__field_name="$(printf "%s" "$map_field__field" | cut -d':' -f1)"
    map_field__field_value="$(printf "%s" "$map_field__field" | cut -d':' -f2-)"
    if ! "$map_field__callback" "$map_field__field_name" "$map_field__field_value"; then
      return 1
    fi
	done
}

has_field() {
	has_field__object="$1"
	has_field__name="$2"

  _has_field() {
    if test "$1" = "$has_field__name"; then
      return 1
    fi
  }
  if ! _map_field "$has_field__object" "_has_field"; then
    return 0
  else
    return 1
  fi
}

parse_field() {
	parse_field__object="$1"
	parse_field__name="$2"

  _parse_field() {
    if test "$1" = "$parse_field__name"; then
      printf "%s" "$2"
      return 1
    fi
  }
  _unescape_special "$(_map_field "$parse_field__object" "_parse_field")"
}
