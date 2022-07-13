// cscript.exe <file>.js

function getApplication(name, binary) {
  var locator = WScript.CreateObject('WbemScripting.SWbemLocator');
  var service = locator.ConnectServer()
  if (service.ExecQuery('select * from win32_process where name = \'' + binary + '.exe\'').Count > 0) {
    return WScript.CreateObject(name + '.Application');
  }
}

function getITunes() {
  // Reference: https://www.joshkunz.com/iTunesControl
  var app = getApplication('iTunes', 'itunes');

  if (!app) {
    return;
  }

  var currentTrack = app.CurrentTrack;
  if (!currentTrack) {
    return;
  }

  return {
    app: app,
    name: 'iTunes',
    title: currentTrack.Name,
    artist: currentTrack.Artist,
    currentTime: app.PlayerPosition,
    totalTime: currentTrack.Duration,
    state: app.PlayerState == 1 ? "playing" : "paused",
    playpause: 'PlayPause()',
    stop: 'Stop()',
    previous: 'BackTrack()',
    next: 'NextTrack()'
  };
}

function getActivePlayer() {
  var player = getITunes();

  return player || {};
}

var player = getActivePlayer();

WScript.Echo(player.state || 'stopped');
WScript.Echo(Math.round(player.currentTime || 0));
WScript.Echo(Math.round(player.totalTime || 0));
WScript.Echo(player.title || 'stopped');
WScript.Echo(player.artist || 'stopped');
WScript.Echo(player.name);
WScript.Echo(player.playpause);
WScript.Echo(player.stop);
WScript.Echo(player.previous);
WScript.Echo(player.next);
