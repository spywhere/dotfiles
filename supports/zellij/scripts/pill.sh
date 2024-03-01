#!/bin/sh

if test -z "$1"; then
  exit
fi

name="$1"
shift
style="$1"
shift
prefix=""
suffix=""
data=""

if test "$name" != "-"; then
  data="$(sh "$HOME/.dots/supports/tmux/scripts/$name.sh")"
fi

segment_icon() {
  icon="$1"
  fg="$2"
  bg="$3"
  accent="$4"
  if test -z "$accent"; then
    accent="$fg"
  fi
  printf '#[fg=%s,bg=%s]#[fg=%s,bg=%s]%s ' "$accent" "$bg" "$bg" "$accent" "$icon"
}

if test "$style" = "wrap"; then
  fg="$1"
  bg="$2"
  wfg="$3"
  wbg="$4"
  if test -z "$wfg"; then
    wfg="$fg"
  fi
  if test -z "$wbg"; then
    wbg="$bg"
  fi
  prefix="#[fg=$bg,bg=$wbg]#[fg=$fg,bg=$bg]"
  suffix="#[fg=$bg,bg=$wbg]"
elif test "$style" = "segment"; then
  icon="$1"
  fg="$2"
  bg="$3"
  accent="$4"
  tbg="$5"
  if test -z "$accent"; then
    accent="$fg"
  fi
  if test -z "$tbg"; then
    tbg="$bg"
  fi
  prefix="$(segment_icon "$icon" "$fg" "$bg" "$accent")#[fg=$fg,bg=$tbg] "
  suffix=" "
elif test "$style" = "icon"; then
  icon="$1"
  fg="$2"
  bg="$3"
  accent="$4"
  if test -z "$accent"; then
    accent="$fg"
  fi
  prefix="$(segment_icon "$icon" "$fg" "$bg" "$accent")"
fi

if test -n "$data" || test "$name" = "-"; then
  printf '%s%s%s' "$prefix" "$data" "$suffix"
fi
