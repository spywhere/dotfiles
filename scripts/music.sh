#!/bin/sh

info=$(cmus-remote -Q 2>/dev/null)

if [ $? -ne 0 ]; then
  printf ""
  tmux set-option -g status-interval 5
  exit
fi

status=$(echo "$info" | sed -n 's/^status //p')
title=$(echo "$info" | sed -n 's/^tag title //p')
artist=$(echo "$info" | sed -n 's/^tag artist //p')
duration=$(echo "$info" | sed -n 's/^duration //p')
position=$(echo "$info" | sed -n 's/^position //p')

if [ "$status" = "playing" ]; then
  symbol="▶"
  tmux set-option -g status-interval 1
else
  symbol=" "
  tmux set-option -g status-interval 5
fi

printf " %s %s - %s [%02d:%02d/%02d:%02d] " "$symbol" "$artist" "$title" "$(($position / 60))" "$(($position % 60))" "$(($duration / 60))" "$(($duration % 60))"
