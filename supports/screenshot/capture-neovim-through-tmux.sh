#!/bin/sh

OLD_TMUX="$TMUX"
unset TMUX

DESTROY_UNATTACHED="$(tmux show-option -g destroy-unattached)"

tmux set -g destroy-unattached off

# Start neovim
tmux new-session -d -s ss 'nvim'

# Make sure it's done loading
sleep 1

# Capture as a text file
# tmux capture-pane -p -e -C -J -t ss:1 > nvim-ss.txt

# Capture as a HTML file
tmux2html ss:0 -o nvim-ss.html
# Convert into image
wkhtmltoimage nvim-ss.html nvim-ss.png
rm -f nvim-ss.html

tmux kill-session -t ss

# shellcheck disable=SC2086
tmux set -g $DESTROY_UNATTACHED

export TMUX="$OLD_TMUX"
