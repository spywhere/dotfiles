#!/bin/sh

_get_tmp_dir() {
  local tmpdir="${TMPDIR:-${TMP:-${TEMP:-/tmp}}}"
  if test ! -d "$tmpdir"; then
    tmpdir=~/.tmp
  fi
  printf "%s/tmux-scripts-%s" "$tmpdir" "$(id -u)"
}

_now() {
  date "+%s.%N"
}

_get_cache_value() {
  local key="$1"
  local timeout="${2:-1}"
  local cache="$(_get_tmp_dir)/$key"
  if test ! -f "$cache"; then
    return
  fi
  if test "$timeout" -eq 0; then
    printf "yes\n"
    tail -n+2 "$cache"
    return
  fi
  local store="$(head -n1 "$cache")"
  if awk \
    -v store="$store" \
    -v timeout="$timeout" \
    -v now=$(_now) \
    'BEGIN{if (now - timeout < store) exit 1; exit 0}'; then
    printf "no\n"
  else
    printf "yes\n"
  fi
  tail -n+2 "$cache"
}

_put_cache_value() {
  local sync="$1"
  local key="$2"
  shift
  shift
  local value="$@"
  local tmpdir="$(_get_tmp_dir)"
  if test ! -d "$tmpdir"; then
    mkdir -p "$tmpdir"
    chmod 700 "$tmpdir"
  fi
  printf  "%s\n%s" "$(_now)" "$value" > "$tmpdir/$key"
  if test "$sync" = "yes"; then
    printf "%s" "$value"
  fi
}

_cache_value() {
  local key="$1"
  local cmd="$2"
  shift
  shift
  local value="$(_get_cache_value "$key")"
  if test -z "$value"; then
    _put_cache_value "yes" "$key" "$($cmd $@)"
    return
  fi
  local valid="$(printf "%s" "$value" | head -n1)"
  if test "$valid" = "no"; then
    (_put_cache_value "no" "$key" "$($cmd $@)" &)
  fi
  printf "%s" "$(printf "%s" "$value" | tail -n+2)"
}
