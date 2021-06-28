#!/bin/sh

_get_tmp_dir() {
  __tmpdir="${TMPDIR:-${TMP:-${TEMP:-/tmp}}}"
  if test ! -d "$__tmpdir"; then
    __tmpdir=~/.tmp
  fi
  printf "%s/tmux-scripts-%s" "$__tmpdir" "$(id -u)"
}

_now() {
  date "+%s.%N"
}

_get_cache_value() {
  __key="$1"
  __timeout="${2:-1}"
  __cache="$(_get_tmp_dir)/$__key"
  if test ! -f "$__cache"; then
    return
  fi
  if test "$__timeout" -eq 0; then
    printf "yes\n"
    tail -n+2 "$__cache"
    return
  fi
  __store="$(head -n1 "$__cache")"
  if awk \
    -v store="$__store" \
    -v timeout="$__timeout" \
    -v now="$(_now)" \
    'BEGIN{if (now - timeout < store) exit 1; exit 0}'; then
    printf "no\n"
  else
    printf "yes\n"
  fi
  tail -n+2 "$__cache"
}

_put_cache_value() {
  __sync="$1"
  __key="$2"
  shift
  shift
  __value="$*"
  __tmpdir="$(_get_tmp_dir)"
  if test ! -d "$__tmpdir"; then
    mkdir -p "$__tmpdir"
    chmod 700 "$__tmpdir"
  fi
  printf  "%s\n%s" "$(_now)" "$__value" > "$__tmpdir/$__key"
  if test "$__sync" = "yes"; then
    printf "%s" "$__value"
  fi
}

_cache_value() {
  __key="$1"
  __cmd="$2"
  shift
  shift
  __value="$(_get_cache_value "$__key")"
  if test -z "$__value"; then
    _put_cache_value "yes" "$__key" "$($__cmd "$@")"
    return
  fi
  __valid="$(printf "%s" "$__value" | head -n1)"
  if test "$__valid" = "no"; then
    (_put_cache_value "no" "$__key" "$($__cmd "$@")" &)
  fi
  printf "%s" "$(printf "%s" "$__value" | tail -n+2)"
}
