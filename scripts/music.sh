#!/bin/sh

cmus="no"
mpd="no"

MPD_HOST="127.0.0.1"
MPD_PORT=6600

if test "$(command -v cmus-remote)"; then
  # cmus installed
  cmus="yes"
fi

if $(echo | nc $MPD_HOST $MPD_PORT | grep -q "OK MPD"); then
  # mpd is running
  mpd="yes"
fi

if [ "$cmus" = "yes" ]; then
  cmus_info=$(cmus-remote -Q 2>/dev/null)
  cmus_state=$(echo "$cmus_info" | sed -n 's/^status //p')
  if [ $? -ne 0 ]; then
    # cmus is not running
    cmus="no"
  elif [ $cmus_state = "playing" ]; then
    cmus_status=1
  elif [ $cmus_state = "paused" ]; then
    cmus_status=0
  else
    # stopped
    cmus="no"
  fi
fi

if [ "$mpd" = "yes" ]; then
  mpd_info=$((echo status; sleep 0.05) | nc $MPD_HOST $MPD_PORT)
  if [ "$(echo "$mpd_info" | awk '$1 ~ /^state/ { print $2 }')" = "play" ]; then
    mpd_status=1
  else
    mpd_status=0
  fi
fi

# if both playing is not running
if [ $mpd = "no" ] && [ $cmus = "no" ]; then
  printf ""
  tmux set-option -g status-interval 5
  exit
fi

if [ $cmus = "yes" ]; then
  # cmus is running
  status=$cmus_status
  title=$(echo "$cmus_info" | sed -n 's/^tag title //p')
  artist=$(echo "$cmus_info" | sed -n 's/^tag artist //p')
  position=$(echo "$cmus_info" | sed -n 's/^position //p')
  duration=$(echo "$cmus_info" | sed -n 's/^duration //p')
elif [ $mpd = "yes" ]; then
  # mpd is running
  status=$mpd_status
  position=$(echo "$mpd_info" | awk '$1 ~ /^time:/ { print $2 }' | cut -d':' -f1)
  duration=$(echo "$mpd_info" | awk '$1 ~ /^time:/ { print $2 }' | cut -d':' -f2)
  mpd_info=$((echo currentsong; sleep 0.05) | nc $MPD_HOST $MPD_PORT)
  title=$(echo "$mpd_info" | awk '$1 ~ /^Title:/ { print $2 }')
  artist=$(echo "$mpd_info" | awk '$1 ~ /^Artist:/ { print $2 }')
fi

if [ $status -ne 0 ]; then
  symbol="▶"
  tmux set-option -g status-interval 1
else
  symbol=" "
  tmux set-option -g status-interval 5
fi

printf " %s %s - %s [%02d:%02d/%02d:%02d] " "$symbol" "$artist" "$title" "$(($position / 60))" "$(($position % 60))" "$(($duration / 60))" "$(($duration % 60))"
