#!/usr/bin/env bash

if test "$1" = "--left"; then
  # Get status left from vim
  printf "%s" "[LEFT]"
  exit
elif test "$1" = "--right"; then
  # Get status right from vim
  printf "%s" "[RIGHT]"
  exit
fi
tmux_key="\#{neovim_integration}"

build_script() {
  printf "%s" "#(~/.dots/supports/tmux/scripts/nvim.sh"
  if test -n "$1"; then
    printf " %s" "$1"
  fi
  printf "%s" ")"
}

process_status() {
  local raw_status
  raw_status="$(tmux show-option -gqv "status-$1")"
  local new_status
  new_status="$(tmux show-option -gqv "@neovim-status-$1")"
  local status
  status="${raw_status//${tmux_key}/}"
  if test -z "$new_status"; then
    new_status="$status"
  fi

  # shellcheck disable=SC2059
  tmux set-option -gq "status-$1" "#{?#{&&:#{==:#{pane_current_command},nvim},#{pane_at_bottom}},$(printf "$2" "$new_status"),$status}"
}

process_status "left" "$(build_script --left)%s"
process_status "right" "%s$(build_script --right)"

### END OF SCRIPT ###

########
# tmux #
########

# Be sure to replace root , with #, on both status-left and status-right

#######
# vim #
#######

# Send command to vim
# set laststatus=1  # To hide status line when less than 2 windows opened
# set laststatus=0  # To always hide status line
