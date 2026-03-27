#!/bin/bash

INPUT="$@"

has_prefix() {
  case "$1" in
    "$2"*)
      return 0
      ;;
    *)
      return 1
      ;;
  esac
}

has_suffix() {
  case "$1" in
    *"$2")
      return 0
      ;;
    *)
      return 1
      ;;
  esac
}

is_contains() {
  case "$1" in
    *"$2"*)
      return 0
      ;;
    *)
      return 1
      ;;
  esac
}

is_exact() {
  test "$1" = "$2"
}

output() {
  echo "$1"
  exit
}

prefix() {
  if has_prefix "$INPUT" "$1"; then
    output "$2"
  fi
}

suffix() {
  if has_suffix "$INPUT" "$1"; then
    output "$2"
  fi
}

contains() {
  if is_contains "$INPUT" "$1"; then
    output "$2"
  fi
}

exact() {
  if is_exact "$INPUT" "$1"; then
    output "$2"
  fi
}

if has_prefix "$INPUT" "Close"; then
  exact "Close" "􀆄"
  exact "Close All Windows" "􀏍"

  output " "
fi
