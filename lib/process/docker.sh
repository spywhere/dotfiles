#!/bin/sh

_summarize_docker() {
  if test -n "$_DOCKER"; then
    print "$esc_green==>$esc_reset The following Docker buildings will be run:"
    eval "set -- $_DOCKER"
    for try_run_install__package in "$@"; do
      try_run_install__package_name="$(parse_field "$try_run_install__package" package_name)"

      if test -z "$try_run_install__package_name"; then
        try_run_install__package_name="$(parse_field "$try_run_install__package" package)"
      fi

      print "  $esc_blue-$esc_reset $try_run_install__package_name"
    done
  fi
}

_run_docker() {
  # TODO
  return 0
}
