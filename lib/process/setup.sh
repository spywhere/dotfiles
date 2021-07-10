#!/bin/sh

_prepare_setup() {
  if ! _has_skip setup || test -n "$_INDICATED"; then
    for try_run_install__setup_path in "$HOME/$DOTFILES/setup"/*.sh; do
      try_run_install__setup=$(basename "$try_run_install__setup_path")
      try_run_install__setup=${try_run_install__setup%.sh}

      print_inline "$esc_yellow==>$esc_reset Checking setup $try_run_install__setup..."

      # Skip requested setups
      if (_has_skip setup || _has_skip "$try_run_install__setup") && ! _has_indicate "$try_run_install__setup"; then
        continue
      fi

      _RUNNING="$try_run_install__setup"
      _FULFILLED=""
      . "$try_run_install__setup_path"
    done
  fi
}

_summarize_setup() {
  if test -n "$_SETUP"; then
    print "$esc_green==>$esc_reset The following setups will be run:"
    eval "set -- $_SETUP"
    for try_run_install__fn in "$@"; do
      try_run_install__setup_name="$(parse_field "$try_run_install__fn" display_name)"

      if test -z "$try_run_install__setup_name"; then
        try_run_install__setup_name="$(parse_field "$try_run_install__fn" fn)"
      fi

      print "  $esc_blue-$esc_reset $try_run_install__setup_name"
    done
  fi
}

_run_setup() {
  if test -n "$_SETUP"; then
    step "Running setups..."
    eval "set -- $_SETUP"
    for try_run_install__setup in "$@"; do
      try_run_install__fn="$(parse_field "$try_run_install__setup" fn)"
      "$try_run_install__fn"
    done
  fi
}
