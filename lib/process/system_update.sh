#!/bin/sh

_summarize_system_update() {
  if _has_skip update; then
    return
  fi

  if _has_skip upgrade; then
    print "$esc_green==>$esc_reset System update will be performed"
  else
    print "$esc_green==>$esc_reset System update and upgrade will be performed"
  fi
}

_run_system_update() {
  if _has_skip update; then
    return
  fi

  if _has_skip upgrade; then
    step "Updating system..."
    update "update"
  else
    step "Updating and upgrading system..."
    update "upgrade"
  fi
}
