#!/bin/sh

_has_item() {
  has_item__list="$1"
  has_item__item="$2"

  for has_item__found_item  in $has_item__list; do
    if test "$has_item__found_item" = "$has_item__item"; then
      return 0
    fi
  done
  return 1
}

_add_to_list() {
  add_to_list__target="$(printf "%s" "$1" | sed 's/^ $//g')"
  shift

  if test -n "$add_to_list__target"; then
    printf "%s\n" "$add_to_list__target"
  fi
  for i in "$@"; do
    printf '%s\n' "$i" | sed "s/'/'\\\\''/g" | sed "1s/^/'/" | sed "\$s/\$/' \\\\/"
  done
  printf ' '
}

_make_list() {
  _add_to_list "" "$@"
}

_has_item_in_list() {
  has_item_in_list__list="$1"
  has_item_in_list__item="$2"

  eval "set -- $has_item_in_list__list"
  for has_item_in_list__found_item in "$@"; do
    if test "$has_item_in_list__found_item" = "$has_item_in_list__item"; then
      return 0
    fi
  done
  return 1
}
