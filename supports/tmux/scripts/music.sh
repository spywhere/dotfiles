#!/bin/sh

# shellcheck disable=SC1090
. "$HOME/.dots/supports/tmux/scripts/cache.sh"

MPD_HOST="127.0.0.1"
MPD_PORT=6600
TITLE_MAX_LENGTH=25
ARTIST_MAX_LENGTH=20
IDLE_UPDATE_INTERVAL=5
PLAYING_UPDATE_INTERVAL=1

mpd="no"
music="no"

if (printf "close\n" | nc $MPD_HOST $MPD_PORT | grep -q "OK MPD"); then
  # mpd is running
  mpd="yes"
fi

if test -n "$(command -v osascript)"; then
  _music_data() {
    osascript -l JavaScript "$HOME/.dots/supports/tmux/scripts/music.js"
  }
  music_info="$(_cache_value music_info _music_data)"
  music_state="$(printf "%s" "$music_info" | awk 'NR==1')"
  if test "$music_state" = "playing"; then
    music="yes"
    music_status=1
  elif test "$music_state" = "paused"; then
    music="yes"
    music_status=0
  fi
fi

if test "$mpd" = "yes"; then
  _mpd_data() {
    sh -c "(printf \"status\ncurrentsong\nclose\n\"; sleep 0.05) | nc $MPD_HOST $MPD_PORT"
  }
  mpd_info=$(_cache_value mpd_info _mpd_data)
  mpd_state="$(printf "%s" "$mpd_info" | awk '$1 ~ /^state:/ { print $2 }')"
  if test "$mpd_state" = "stop"; then
    mpd="no"
  elif test "$mpd_state" = "play"; then
    mpd_status=1
  else
    mpd_status=0
  fi
fi

# if no player is running
if test "$mpd" = "no" -a "$music" = "no"; then
  printf ""
  tmux set-option -g status-interval $IDLE_UPDATE_INTERVAL
  exit
fi

if test "$mpd" = "yes"; then
  # mpd is running
  status=$mpd_status
  position="$(printf "%s" "$mpd_info" | awk '$1 ~ /^time:/ { print $2 }' | cut -d':' -f1)"
  duration="$(printf "%s" "$mpd_info" | awk '$1 ~ /^time:/ { print $2 }' | cut -d':' -f2)"
  title="$(printf "%s" "$mpd_info" | awk '$1 ~ /^Title:/ { print $0 }' | cut -d':' -f2- | sed 's/^ *//g')"
  artist="$(printf "%s" "$mpd_info" | awk '$1 ~ /^Artist:/ { print $0 }' | cut -d':' -f2- | sed 's/^ *//g')"

  if test -z "$position" -a -z "$duration"; then
    mpd="no"
  fi
elif test "$music" = "yes"; then
  # music is running
  status=$music_status
  position="$(printf "%s" "$music_info" | awk 'NR==2')"
  duration="$(printf "%s" "$music_info" | awk 'NR==3')"
  title="$(printf "%s" "$music_info" | awk 'NR==4')"
  artist="$(printf "%s" "$music_info" | awk 'NR==5')"
fi

_scrolling_text() {
  __text="$1"
  __size="$2"
  __offset="$3"
  if test $# -ge 4; then
    __text_length="$4"
  else
    __text_length=$(printf "%s" "$__text" | wc -m)
  fi
  if test "$__text_length" -gt "$__size"; then
    __index=$(( __offset % __text_length ))
    __padded_text="$__text$__text"
    printf "%s" "$__padded_text" | cut -c"$(( __index + 1 ))-$(( __index + __size ))"
  else
    printf "%s" "$__text"
  fi
}

title_length=$(printf "%s" "$title" | wc -m)
artist_length=$(printf "%s" "$artist" | wc -m)

if test "$title_length" -gt "$TITLE_MAX_LENGTH" -a "$artist_length" -gt "$ARTIST_MAX_LENGTH"; then
  text=$(_scrolling_text "$artist - $title" "$(( TITLE_MAX_LENGTH + ARTIST_MAX_LENGTH + 3 ))" "$position")
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

printf "%s %s [%02d:%02d/%02d:%02d]" "$symbol" "$text" "$(( position / 60 ))" "$(( position % 60 ))" "$(( duration / 60 ))" "$(( duration % 60 ))"
