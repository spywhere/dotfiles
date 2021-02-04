#!/bin/sh

. $HOME/.dots/supports/tmux/scripts/cache.sh

MPD_HOST="127.0.0.1"
MPD_PORT=6600
TITLE_MAX_LENGTH=25
ARTIST_MAX_LENGTH=20
IDLE_UPDATE_INTERVAL=5
PLAYING_UPDATE_INTERVAL=1

mpd="no"

if $(printf "close\n" | nc $MPD_HOST $MPD_PORT | grep -q "OK MPD"); then
  # mpd is running
  mpd="yes"
fi

if test "$mpd" = "yes"; then
  _mpd_music() {
    sh -c '(printf "status\ncurrentsong\nclose\n"; sleep 0.05) | nc $MPD_HOST $MPD_PORT'
  }
  mpd_info=$(_cache_value mpd_info _mpd_music)
  if test "$(printf "%s" "$mpd_info" | awk '$1 ~ /^state:/ { print $2 }')" = "play"; then
    mpd_status=1
  else
    mpd_status=0
  fi
fi

# if no player is running
if test "$mpd" = "no"; then
  printf ""
  tmux set-option -g status-interval $IDLE_UPDATE_INTERVAL
  exit
fi

if test "$mpd" = "yes"; then
  # mpd is running
  status=$mpd_status
  position=$(printf "%s" "$mpd_info" | awk '$1 ~ /^time:/ { print $2 }' | cut -d':' -f1)
  duration=$(printf "%s" "$mpd_info" | awk '$1 ~ /^time:/ { print $2 }' | cut -d':' -f2)
  title=$(printf "%s" "$mpd_info" | awk '$1 ~ /^Title:/ { print $0 }' | cut -d':' -f2- | sed 's/^ *//g')
  artist=$(printf "%s" "$mpd_info" | awk '$1 ~ /^Artist:/ { print $0 }' | cut -d':' -f2- | sed 's/^ *//g')
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
    printf "%s" "$padded_text" | cut -c"$(( $index + 1 ))-$(( $index + $size ))"
  else
    printf "%s" "$text"
  fi
}

title_length=$(printf "%s" "$title" | wc -m)
artist_length=$(printf "%s" "$artist" | wc -m)

if test "$title_length" -gt "$TITLE_MAX_LENGTH" -a "$artist_length" -gt "$ARTIST_MAX_LENGTH"; then
  text=$(_scrolling_text "$artist - $title" "$(( $TITLE_MAX_LENGTH + $ARTIST_MAX_LENGTH + 3 ))" "$position")
else
  title=$(_scrolling_text "$title" "$TITLE_MAX_LENGTH" "$position" "$title_length")
  artist=$(_scrolling_text "$artist" "$ARTIST_MAX_LENGTH" "$position" "$artist_length")
  text="$artist - $title"
fi

if test $status -ne 0; then
  symbol="▶"
  tmux set-option -g status-interval $PLAYING_UPDATE_INTERVAL
else
  symbol=" "
  tmux set-option -g status-interval $IDLE_UPDATE_INTERVAL
fi

printf "%s %s [%02d:%02d/%02d:%02d]" "$symbol" "$text" "$(($position / 60))" "$(($position % 60))" "$(($duration / 60))" "$(($duration % 60))"
