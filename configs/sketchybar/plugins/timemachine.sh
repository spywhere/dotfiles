#!/bin/bash

tm_pref() {
  plutil -extract "$1" raw "/Library/Preferences/com.apple.TimeMachine.plist"
}

to_timestamp() {
  date -j -f '%FT%TZ' "$1" +%s
}

has_last_failed() {
  if ! test -n "$(command -v plutil)"; then
    return 1
  fi
  tm_last_destination="$(tm_pref LastDestinationID)"
  if test "$?" -ne 0; then
    return 1
  fi
  tm_count_destinations="$(tm_pref Destinations)"
  index=0
  tm_last_failed=0
  while test "$index" -lt "$tm_count_destinations"; do
    tm_destination_id="$(tm_pref "Destinations.$index.DestinationID")"

    if test "$tm_destination_id" != "$tm_last_destination"; then
      index="$(( index + 1))"
      continue
    fi

    tm_count_attempts="$(tm_pref "Destinations.$index.AttemptDates")"
    tm_count_snapshots="$(tm_pref "Destinations.$index.SnapshotDates")"

    tm_last_attempt="$(to_timestamp "$(tm_pref "Destinations.$index.AttemptDates.$(( tm_count_attempts - 1 ))")")"
    tm_last_snapshot="$(to_timestamp "$(tm_pref "Destinations.$index.SnapshotDates.$(( tm_count_snapshots - 1 ))")")"

    if test "$tm_last_snapshot" -lt "$tm_last_attempt"; then
      return 0
    fi

    index="$(( index + 1))"
  done

  return 1
}

tm_status="$(tmutil status)"
tm_phase="$(echo "$tm_status" | grep BackupPhase | grep -Eo "\w+;" | cut -d';' -f1)"

tm_percent=""
# icon="􀊯"
icon="􀖊"
if test "$(sketchybar --query timemachine | jq -r .icon.value)" = "$icon"; then
  # icon="􂣼"
  icon="􀖋"
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
  FindingChanges)
    tm_phase="Changes"
    tm_progress=" $(echo "$tm_status" | grep FractionOfProgressBar | grep -Eo "\d+(\.\d+)?")%"
    tm_done=" $(echo "$tm_status" | grep FractionDone | grep -Eo "\d+(\.\d+)?")%"
    tm_percent=" $(echo "$tm_progress" "$tm_done" | awk '{printf "%d\n" , ($1 * $2) * 100}' )%"
    ;;
  Copying)
    tm_progress=" $(echo "$tm_status" | grep FractionOfProgressBar | grep -Eo "\d+(\.\d+)?")%"
    tm_done=" $(echo "$tm_status" | grep 'Percent =' | grep -Eo "\d+(\.\d+)?(e\-\d+)?")%"
    tm_percent=" $(echo "$tm_progress" "$tm_done" | awk '{printf "%d\n" , ((1.0 - $1) + ($1 * $2)) * 100}' )%"
    ;;
  Finishing)
    tm_percent=" 95%"
    ;;
  Stopping)
    tm_percent=" 95%"
    ;;
  ThinningPreBackup)
    tm_phase="Preparing"
    ;;
  ThinningPostBackup|LazyThinning)
    tm_phase="Thinning"
    tm_percent=" 98%"
  ;;
  *)
    if has_last_failed; then
      icon="􀱨"
    else
      icon="􀣔"
    fi
    update_freq=10
    ;;
esac

sketchybar --animate sin 10 \
  --set "$NAME" \
  icon="$icon" \
  label="$tm_phase$tm_percent" \
  update_freq="$update_freq"
