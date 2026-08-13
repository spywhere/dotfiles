#!/bin/sh

_prepare_pre_setup() {
  if ! test -d "$HOME/$DOTFILES/pre_setup"; then
    warn "No pre_setup found"
    return
  fi

  if _has_skip pre_setup && test -z "$_INDICATED"; then
    return
  fi

  for try_run_install__pre_setup_path in "$HOME/$DOTFILES/pre_setup"/*.sh; do
    try_run_install__pre_setup=$(basename "$try_run_install__pre_setup_path")
    try_run_install__pre_setup=${try_run_install__pre_setup%.sh}

    print_inline "$esc_yellow==>$esc_reset Checking pre_setup $try_run_install__pre_setup..."

    # Skip requested pre-setups
    if (_has_skip pre_setup || _has_skip "$try_run_install__pre_setup") && ! _has_indicate "$try_run_install__pre_setup"; then
      continue
    fi

    _RUNNING="$try_run_install__pre_setup"
    _FULFILLED=""
    . "$try_run_install__pre_setup_path"
  done
}

_summarize_pre_setup() {
  if test -z "$_PRE_SETUP"; then
    return
  fi

  print "$esc_green==>$esc_reset The following pre-setups will be run:"
  eval "set -- $_PRE_SETUP"
  for try_run_install__fn in "$@"; do
    try_run_install__pre_setup_name="$(parse_field "$try_run_install__fn" display_name)"

    if test -z "$try_run_install__pre_setup_name"; then
      try_run_install__pre_setup_name="$(parse_field "$try_run_install__fn" fn)"
    fi

    print "  $esc_blue-$esc_reset $try_run_install__pre_setup_name"
  done
}

_run_pre_setup() {
  if test -z "$_PRE_SETUP"; then
    return
  fi

  step "Running pre-setups..."
  eval "set -- $_PRE_SETUP"
  for try_run_install__pre_setup in "$@"; do
    try_run_install__fn="$(parse_field "$try_run_install__pre_setup" fn)"
    "$try_run_install__fn"
  done
}
