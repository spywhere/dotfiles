#!/bin/bash

tm_pref() {
  plutil -extract "$1" raw "/Library/Preferences/com.apple.TimeMachine.plist"
}

to_timestamp() {
  date -j -f '%FT%TZ' "$1" +%s
}

human_readable() {
  local abbrevs=(
      $((10 ** 18)):ZB
      $((10 ** 15)):EB
      $((10 ** 12)):TB
      $((10 ** 9)):GB
      $((10 ** 6)):MB
      $((10 ** 3)):KB
      1:B
  )

  for item in "${abbrevs[@]}"; do
      local factor="${item%:*}"
      local abbrev="${item#*:}"
      if test "$1" -ge "${factor}"; then
          echo "$1" "$factor" "$abbrev" | awk '{printf "%.2f %s", $1 / $2, $3}'
          return
      fi
  done

  echo "0 B"
}

get_last_destination() {
  if ! test -n "$(command -v plutil)"; then
    return
  fi
  tm_last_destination="$(tm_pref LastDestinationID)"
  if test "$?" -ne 0; then
    return
  fi
  tm_count_destinations="$(tm_pref Destinations)"
  index=0
  while test "$index" -lt "$tm_count_destinations"; do
    tm_destination_id="$(tm_pref "Destinations.$index.DestinationID")"

    if test "$tm_destination_id" = "$tm_last_destination"; then
      echo "$index"
      return
    fi
    index="$(( index + 1))"
  done
}

has_last_failed() {
  if test -z "$1"; then
    return 1
  fi

  tm_count_attempts="$(tm_pref "Destinations.$1.AttemptDates")"
  tm_count_snapshots="$(tm_pref "Destinations.$1.SnapshotDates")"

  tm_last_attempt="$(to_timestamp "$(tm_pref "Destinations.$1.AttemptDates.$(( tm_count_attempts - 1 ))")")"
  tm_last_snapshot="$(to_timestamp "$(tm_pref "Destinations.$1.SnapshotDates.$(( tm_count_snapshots - 1 ))")")"

  if test "$tm_last_snapshot" -lt "$tm_last_attempt"; then
    return 0
  fi

  return 1
}

update_status() {
  tm_status="$(tmutil status)"
  tm_phase="$(echo "$tm_status" | grep BackupPhase | grep -Eo "\w+;" | cut -d';' -f1)"
  tm_last_destination="$2"

  progress_draw="off"
  progress_multi=0
  size_multi=0
  action_icon="􀊄"
  tm_percent_raw="0"
  tm_percent=""
  icon="􀖊"
  if test "$(sketchybar --query timemachine | jq -r .icon.value)" = "$icon"; then
    icon="􀖋"
  fi
  result_icon=""
  result_color="0x00a4a6aa"
  if test -n "$(tm_pref "Destinations.$tm_last_destination.RESULT")"; then
    result_color="0xffff4747"
    result_icon="􀇿"
  fi
  volume_icon="􀤝"
  if test -n "$(tm_pref "Destinations.$tm_last_destination.NetworkURL")"; then
    volume_icon="􀩯"
  fi
  update_freq=2
  case "$tm_phase" in
    FindingBackupVol)
      tm_phase="Finding"
      ;;
    Starting)
      ;;
    MountingDiskImage)
      tm_phase="Mounting"
      ;;
    PreparingSourceVolumes)
      tm_phase="Preparing"
      ;;
    DeletingOldBackup)
      tm_phase="Cleaning"
      ;;
    FindingChanges)
      tm_phase="Changes"
      tm_progress=" $(echo "$tm_status" | grep FractionOfProgressBar | grep -Eo "\d+(\.\d+)?")%"
      tm_done=" $(echo "$tm_status" | grep FractionDone | grep -Eo "\d+(\.\d+)?")%"
      tm_percent_raw="$(echo "$tm_progress" "$tm_done" | awk '{printf "%d\n" , ($1 * $2) * 100}' )"
      tm_percent=" $tm_percent_raw%"
      ;;
    Copying)
      tm_progress=" $(echo "$tm_status" | grep FractionOfProgressBar | grep -Eo "\d+(\.\d+)?")%"
      tm_done=" $(echo "$tm_status" | grep 'Percent =' | grep -Eo "\d+(\.\d+)?(e\-\d+)?")%"
      tm_percent_raw="$(echo "$tm_progress" "$tm_done" | awk '{printf "%d\n" , ((1.0 - $1) + ($1 * $2)) * 100}' )"
      tm_percent=" $tm_percent_raw%"

      tm_files="$(echo "$tm_status" | grep 'files =' | grep -Eo "\d+")"
      tm_bytes="$(echo "$tm_status" | grep 'bytes =' | grep -Eo "\d+")"
      sketchybar --set "$1.size" label="$(printf "%'d" "$tm_files") Files ($(human_readable "$tm_bytes"))"
      size_multi=1
      ;;
    Finishing)
      tm_percent_raw="95"
      tm_percent=" $tm_percent_raw%"
      ;;
    Stopping)
      tm_percent_raw="95"
      tm_percent=" $tm_percent_raw%"
      ;;
    ThinningPreBackup)
      tm_phase="Preparing"
      ;;
    ThinningPostBackup|LazyThinning)
      tm_phase="Thinning"
      tm_percent_raw="98"
      tm_percent=" $tm_percent_raw%"
    ;;
    *)
      if has_last_failed "$tm_last_destination"; then
        icon="􀱨"
      else
        icon="􀣔"
      fi
      update_freq=10
      ;;
  esac

  if test -n "$tm_phase"; then
    progress_draw="on"
    progress_multi=1

    result_color="0xffa4a6aa"
    result_icon="􀴽"
    action_icon="􀛷"
  fi

  storage_used="$(human_readable "$(tm_pref "Destinations.$tm_last_destination.BytesUsed")")"
  storage_available="$(human_readable "$(tm_pref "Destinations.$tm_last_destination.BytesAvailable")")"

  sketchybar \
    --set "$1" \
    drawing=on \
    update_freq="$update_freq" \
    --set "$1.volume" label="$(tm_pref "Destinations.$tm_last_destination.LastKnownVolumeName")" \
    --set "$1.storage" label="$storage_used used, $storage_available free" \
    --animate sin 10 \
    --set "$1.progress" \
    padding_left=$(( -60 * progress_multi )) \
    y_offset=$(( -30 + 12 * progress_multi + 10 * size_multi )) \
    slider.background.drawing="$progress_draw" \
    slider.width=$(( 240 + 60 * progress_multi )) \
    slider.percentage="$tm_percent_raw" \
    slider.knob="$tm_phase$tm_percent" \
    --set "$1.icon" \
    icon="$volume_icon" \
    y_offset=$(( 0 + 10 * progress_multi + 10 * size_multi )) \
    --set "$1.volume" \
    y_offset=$(( 8 + 10 * progress_multi + 10 * size_multi )) \
    --set "$1.storage" \
    y_offset=$(( -10 + 10 * progress_multi + 10 * size_multi )) \
    --set "$1" \
    icon="$icon" \
    label="$tm_phase$tm_percent" \
    popup.height=$(( 40 + 20 * progress_multi + 20 * size_multi )) \
    --set "$1.size" \
    y_offset=$(( -25 )) \
    label.color.alpha="$size_multi" \
    --set "$1.result" \
    y_offset=$(( 0 + 10 * progress_multi + 10 * size_multi )) \
    icon="$result_icon" \
    icon.color="$result_color" \
    --set "$1.action" \
    y_offset=$(( 0 + 10 * progress_multi + 10 * size_multi )) \
    padding_right=$(( 10 + 10 * progress_multi )) \
    icon="$action_icon"

  time_hide="$(sketchybar --query "$1.icon" | jq -r '.label.value')"
  if test -n "$time_hide" -a "$(date +%s)" -gt "$time_hide"; then
    sketchybar \
      --set "$1.result" popup.drawing=off \
      --set "$1" popup.drawing=off \
      --set "$NAME.icon" label=
  fi
}

case "$NAME" in
  *.icon)
    sketchybar --animate sin 3 --set "$NAME" icon.color.alpha=0.5 icon.color.alpha=1
    open "x-apple.systempreferences:com.apple.Time-Machine-Settings.extension"
    ;;
  *.result)
    sketchybar --set "$NAME" popup.drawing=toggle
    ;;
  *.action)
    if test -n "$tm_phase"; then
      tmutil stopbackup
      sketchybar \
        --set "$NAME" icon="􀊄" \
        --animate sin 3 \
        --set "$NAME" icon.color.alpha=0.5 icon.color.alpha=1
    else
      tmutil startbackup
      sketchybar \
        --set "$NAME" icon="􀛷" \
        --animate sin 3 \
        --set "$NAME" icon.color.alpha=0.5 icon.color.alpha=1
    fi
    ;;
  *)
    tm_last_destination="$(get_last_destination)"

    if test -z "$tm_last_destination"; then
      exit
    fi

    case "$SENDER" in
      mouse.clicked)
        sketchybar \
          --set "$NAME.result" popup.drawing=off \
          --set "$NAME" popup.drawing=toggle \
          --set "$NAME.icon" label="$(echo "$(date +%s)" | awk '{print $1 + 60}')"
        ;;
    esac

    update_status "$NAME" "$tm_last_destination"
    ;;
esac
