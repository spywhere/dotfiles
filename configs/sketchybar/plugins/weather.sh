#!/bin/bash

data="$(curl --fail-early -m 2 -fsSL "wttr.in/$1?format=%i,%f" 2>/dev/null)"
wwo_code="$(echo "$data" | cut -d, -f1)"
temp="$(echo "$data" | cut -d, -f2 | sed 's/^\+//g')"

if test "$(date +%H)" -lt 6 -o "$(date +%H)" -ge 20; then
  daynight() {
    echo "$2"
  }
else
  daynight() {
    echo "$1"
  }
fi

case "$wwo_code" in
  113)
    # Sunny
    icon="$(daynight 􀆮 􀇁 )"
    ;;
  116)
    # PartlyCloudy
    icon="$(daynight 􀇕 􀇛 )"
    ;;
  119)
    # Cloudy
    icon="􀇃"
    ;;
  122)
    # VeryCloudy
    icon="􀇣"
    ;;
  143|248|260)
    # Fog
    icon="􀇋"
    ;;
  176|263|353)
    # LightShowers
    icon="􀇅"
    ;;
  179|362|365|374)
    # LightSleetShowers
    icon="􀇑"
    ;;
  182|185|281|284|311|314|317|350|377)
    # LightSleet
    icon="􀇑"
    ;;
  200|386)
    # ThunderyShowers
    icon="􀇓"
    ;;
  227|320)
    # LightSnow
    icon="􀇦"
    ;;
  230|329|332|338)
    # HeavySnow
    icon="􀇥"
    ;;
  266|293|296)
    # LightRain
    icon="􀇇"
    ;;
  299|305|356)
    # HeavyShowers
    icon="$(daynight 􀇗 􀇝 )"
    ;;
  302|308|359)
    # HeavyRain
    icon="􀇉"
    ;;
  323|326|368)
    # LightSnowShowers
    icon="􁷑"
    ;;
  335|371|395)
    # HeavySnowShowers
    icon="􀇏"
    ;;
  389)
    # ThunderyHeavyRain
    icon="􀇟"
    ;;
  392)
    # ThunderySnowShowers
    icon="􀇟"
    ;;
  *)
    icon="􀚏"
    ;;
esac

sketchybar --animate sin 10 \
  --set "$NAME" \
  icon="$icon" \
  label="$temp"
