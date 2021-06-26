function isRunning(app) {
    try {
        return Application(app).running();
    } catch (error) {
        return false;
    }
}

let info = {};

if (isRunning("Spotify")) {
    let app = Application("Spotify");
    if (app.playerState() !== "stopped") {
        let currentTrack = app.currentTrack;
        info.spotify = {
            title: currentTrack.name(),
            artist: currentTrack.artist() || currentTrack.albumArtist(),
            currentTime: app.playerPosition(),
            totalTime: currentTrack.duration() / 1000,
            state: app.playerState() === "playing" ? "playing" : "paused"
        };
    }
}

if (isRunning("Music") || isRunning("iTunes")) {
    let appName;
    if (isRunning("Music")) {
        appName ="Music";
    } else {
        appName ="iTunes";
    }
    let app = Application(appName);
    if (app.playerState() !== "stopped") {
        let currentTrack = app.currentTrack;
        info.music = {
            title: currentTrack.name(),
            artist: currentTrack.artist() || currentTrack.albumArtist(),
            currentTime: app.playerPosition(),
            totalTime: currentTrack.duration(),
            state: app.playerState() === "playing" ? "playing" : "paused"
        };
    }
}

let player = Object.values(info).find((player) => player.state !== "stopped") || {};
[
  player.state || "stopped",
  Math.round(player.currentTime || 0),
  Math.round(player.totalTime || 0),
  player.title || "",
  player.artist || ""
].join("\n")
