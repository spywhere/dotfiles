#!/bin/sh

cmus="no"
mpd="no"

MPD_HOST="127.0.0.1"
MPD_PORT=6600

if test "$(command -v cmus-remote)"; then
  # cmus installed
  cmus="yes"
fi

if $(echo close | nc $MPD_HOST $MPD_PORT | grep -q "OK MPD"); then
  # mpd is running
  mpd="yes"
fi

if [ "$cmus" = "yes" ]; then
  cmus_info=$(cmus-remote -Q 2>/dev/null)
  cmus_state=$(echo "$cmus_info" | sed -n 's/^status //p')
  if [ $? -ne 0 ]; then
    # cmus is not running
    cmus="no"
  elif [ "$cmus_state" = "playing" ]; then
    cmus_status=1
  elif [ "$cmus_state" = "paused" ]; then
    cmus_status=0
  else
    # stopped
    cmus="no"
  fi
fi

if [ "$mpd" = "yes" ]; then
  mpd_info=$( (echo "status\ncurrentsong\nclose"; sleep 0.05) | nc $MPD_HOST $MPD_PORT)
  if [ "$(echo "$mpd_info" | awk '$1 ~ /^state:/ { print $2 }')" = "play" ]; then
    mpd_status=1
  else
    mpd_status=0
  fi
fi

# if both playing is not running
if [ $mpd = "no" ] && [ $cmus = "no" ]; then
  echo ""
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
  title=$(echo "$mpd_info" | awk '$1 ~ /^Title:/ { print $0 }' | cut -d':' -f2- | sed 's/^ *//g')
  artist=$(echo "$mpd_info" | awk '$1 ~ /^Artist:/ { print $0 }' | cut -d':' -f2- | sed 's/^ *//g')
fi

_scrolling_text() {
  local text="$1"
  local size="$2"
  local offset="$3"
  if test $# -ge 4; then
    local text_length="$4"
  else
    local text_length=$(printf "%s" "$text" | wc -m)
  fi
  if test "$text_length" -gt $size; then
    local index=$(( $offset % ($text_length + 3) ))
    local padded_text="$text   $text"
    printf "%s" "${padded_text:$index:$size}"
  else
    printf "%s" "$text"
  fi
}

title_max_length=25
artist_max_length=20

title_length=$(printf "%s" "$title" | wc -m)
artist_length=$(printf "%s" "$artist" | wc -m)

if test "$title_length" -gt "$title_max_length" -a "$artist_length" -gt "$artist_max_length"; then
  text=$(_scrolling_text "$artist - $title" "$(( $title_max_length + $artist_max_length + 3 ))" "$position")
else
  title=$(_scrolling_text "$title" "$title_max_length" "$position" "$title_length")
  artist=$(_scrolling_text "$artist" "$artist_max_length" "$position" "$artist_length")
  text="$artist - $title"
fi

if [ $status -ne 0 ]; then
  symbol="▶"
  tmux set-option -g status-interval 1
else
  symbol=" "
  tmux set-option -g status-interval 5
fi

printf "%s %s [%02d:%02d/%02d:%02d]" "$symbol" "$text" "$(($position / 60))" "$(($position % 60))" "$(($duration / 60))" "$(($duration % 60))"
