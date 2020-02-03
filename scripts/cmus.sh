#!/bin/sh

info=$(cmus-remote -Q 2>/dev/null)

if [ $? -ne 0 ]; then
  printf "Not playing"
  exit
fi

title=$(echo "$info" | sed -n 's/^tag title //p')
artist=$(echo "$info" | sed -n 's/^tag artist //p')
duration=$(echo "$info" | sed -n 's/^duration //p')
position=$(echo "$info" | sed -n 's/^position //p')

printf "%s - %s [%02d:%02d/%02d:%02d]" "$artist" "$title" "$(($position / 60))" "$(($position % 60))" "$(($duration / 60))" "$(($duration % 60))"
