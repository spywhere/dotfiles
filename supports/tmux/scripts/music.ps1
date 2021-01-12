$processes = Get-Process itunes -ErrorAction SilentlyContinue

if (!$processes) {
  # iTunes is not opened
  "stopped"
  return
}

$itunes = New-Object -ComObject iTunes.Application

if (!$itunes.CurrentTrack) {
  # Not song is playing / pausing
  "stopped"
  return
}

$playing = $itunes.PlayerState
$current = $itunes.CurrentTrack

if ($playing) {
  "state:play"
} else {
  "state:pause"
}

"title:{0}" -f $current.Name
"artist:{0}" -f $current.Artist
"position:{0}" -f $itunes.PlayerPosition
"duration:{0}" -f $current.Duration
