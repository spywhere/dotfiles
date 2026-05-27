#!/bin/bash

is_day() {
  test "$(date +%H)" -ge 6 -a "$(date +%H)" -lt 20
}

wmo_icon() {
  if test "$2" = "day"; then
    daynight() {
      echo "$1"
    }
  else
    daynight() {
      echo "$2"
    }
  fi

  case "$1" in
    0)
      # Sunny
      daynight 􀆮 􀇁
      ;;
    1)
      # PartlyCloudy
      daynight 􀇕 􀇛
      ;;
    2)
      # Cloudy
      echo 􀇃
      ;;
    3)
      # VeryCloudy
      echo 􀇣
      ;;
    45|48)
      # Fog
      echo 􀇋
      ;;
    51|53|55)
      # LightShowers
      echo 􀇅
      ;;
    56|57)
      # LightSleetShowers
      echo 􀇑
      ;;
    96)
      # LightSleet
      echo 􀇑
      ;;
    95)
      # ThunderyShowers
      echo 􀇓
      ;;
    71|73)
      # LightSnow
      echo 􀇦
      ;;
    75|77)
      # HeavySnow
      echo 􀇥
      ;;
    61|66|80)
      # LightRain
      echo 􀇇
      ;;
    63)
      # HeavyShowers
      daynight 􀇗 􀇝
      ;;
    65|67|81)
      # HeavyRain
      echo 􀇉
      ;;
    85)
      # LightSnowShowers
      echo 􁷑
      ;;
    86)
      # HeavySnowShowers
      echo 􀇏
      ;;
    82)
      # ThunderyHeavyRain
      echo 􀇟
      ;;
    99)
      # ThunderySnowShowers
      echo 􀇟
      ;;
    *)
      echo 􀚏
      ;;
  esac
}

wwo_icon() {
  if test "$2" = "day"; then
    daynight() {
      echo "$1"
    }
  else
    daynight() {
      echo "$2"
    }
  fi

  case "$1" in
    113)
      # Sunny
      daynight 􀆮 􀇁
      ;;
    116)
      # PartlyCloudy
      daynight 􀇕 􀇛
      ;;
    119)
      # Cloudy
      echo 􀇃
      ;;
    122)
      # VeryCloudy
      echo 􀇣
      ;;
    143|248|260)
      # Fog
      echo 􀇋
      ;;
    176|263|353)
      # LightShowers
      echo 􀇅
      ;;
    179|362|365|374)
      # LightSleetShowers
      echo 􀇑
      ;;
    182|185|281|284|311|314|317|350|377)
      # LightSleet
      echo 􀇑
      ;;
    200|386)
      # ThunderyShowers
      echo 􀇓
      ;;
    227|320)
      # LightSnow
      echo 􀇦
      ;;
    230|329|332|338)
      # HeavySnow
      echo 􀇥
      ;;
    266|293|296)
      # LightRain
      echo 􀇇
      ;;
    299|305|356)
      # HeavyShowers
      daynight 􀇗 􀇝
      ;;
    302|308|359)
      # HeavyRain
      echo 􀇉
      ;;
    323|326|368)
      # LightSnowShowers
      echo 􁷑
      ;;
    335|371|395)
      # HeavySnowShowers
      echo 􀇏
      ;;
    389)
      # ThunderyHeavyRain
      echo 􀇟
      ;;
    392)
      # ThunderySnowShowers
      echo 􀇟
      ;;
    *)
      echo 􀚏
      ;;
  esac
}

wttr() {
  data="$(curl --fail-early -m 2 -fsSL "wttr.in/?format=%i,%f" 2>/dev/null)"
  if test $? -ne 0; then
    return 1
  fi
  echo "using wttr.in" >&2
  wwo_code="$(echo "$data" | cut -d, -f1)"
  temp="$(echo "$data" | cut -d, -f2 | sed 's/^\+//g')"

  time_of_day="night"
  if is_day; then
    time_of_day="day"
  fi

  echo "$(wwo_icon "$wwo_code" "$time_of_day")" "$temp"
}

ipwhois() {
  data="$(curl --fail-early -m 2 -fsSL 'ipwho.is' 2>/dev/null)"
  if test $? -ne 0; then
    return 1
  fi
  lat_data="$(echo "$data" | jq -r '.latitude')"
  lon_data="$(echo "$data" | jq -r '.longitude')"
  echo "lat: $lat_data, lon: $lon_data [ipwhois]" >&2
  echo "latitude=$lat_data&longitude=$lon_data"
}

ip_api() {
  data="$(curl --fail-early -m 2 -fsSL 'ip-api.com/json' 2>/dev/null)"
  if test $? -ne 0; then
    return 1
  fi
  lat_data="$(echo "$data" | jq -r '.lat')"
  lon_data="$(echo "$data" | jq -r '.lon')"
  echo "lat: $lat_data, lon: $lon_data [ip_api]" >&2
  echo "latitude=$lat_data&longitude=$lon_data"
}

open_meteo() {
  data="$(curl --fail-early -m 2 -fsSL "https://api.open-meteo.com/v1/forecast?$(ipwhois || ip_api)&current=weather_code,is_day,apparent_temperature&timezone=GMT" 2>/dev/null)"
  if test $? -ne 0 -o -z "$data"; then
    return 1
  fi
  echo "using open-meteo" >&2
  wmo_code="$(echo "$data" | jq -r '.current.weather_code')"
  day="$(echo "$data" | jq -r '.current.is_day')"
  temp="$(echo "$data" | jq -r '.current.apparent_temperature')"
  temp_unit="$(echo "$data" | jq -r '.current_units.apparent_temperature')"

  time_of_day="night"
  if test "$day" = "1"; then
    time_of_day="day"
  fi

  echo "$(wmo_icon "$wmo_code" "$time_of_day")" "$temp$temp_unit"
}

weather_data="$(open_meteo || wttr)"

if test -z "$weather_data"; then
  sketchybar --set "$NAME" \
    drawing=off \
    update_freq=60
  exit
fi

icon="$(echo "$weather_data" | cut -d' ' -f1)"
temp="$(echo "$weather_data" | cut -d' ' -f2)"

echo "$icon $temp" >&2

sketchybar --animate sin 10 \
  --set "$NAME" \
  drawing=on \
  icon="$icon" \
  label="$temp" \
  update_freq=600
