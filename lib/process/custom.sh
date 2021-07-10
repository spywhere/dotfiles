#!/bin/sh

_summarize_custom() {
  if test -n "$_CUSTOM"; then
    print "$esc_green==>$esc_reset The following installations will be run:"
    eval "set -- $_CUSTOM"
    for try_run_install__fn in "$@"; do
      try_run_install__package_name="$(parse_field "$try_run_install__fn" package_name)"

      if test -z "$try_run_install__package_name"; then
        try_run_install__package_name="$(parse_field "$try_run_install__fn" fn)"
      fi

      print "  $esc_blue-$esc_reset $try_run_install__package_name"
    done
  fi
}

_run_custom() {
  if test -n "$_CUSTOM"; then
    step "Performing custom installations..."
    eval "set -- $_CUSTOM"
    for try_run_install__custom in "$@"; do
      try_run_install__fn="$(parse_field "$try_run_install__custom" fn)"
      "$try_run_install__fn"
    done
  fi
}
