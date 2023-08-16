function isRunning(app) {
  try {
    return Application(app).running();
  } catch (error) {
    return false;
  }
}

function reduce(l, f, i) {
  let res = i;
  for (let i = 0; i < l.length; i++) {
    res = f(res, l[i]);
  }
  return res;
}

function map(l, f) {
  return reduce(l, (res, v) => {
    res.push(f(v));
    return res;
  }, []);
}

function filter(l, f, m) {
  return reduce(l, (res, v) => {
    if (f(v)) {
      res.push(m ? m(v) : v);
    }
    return res;
  }, []);
}

function tap(l ,f) {
  return reduce(l, (res, v) => {
    f(v);
    res.push(v);
    return res;
  }, []);
}

let info = {};

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
    tap(
      filter(
        app.playlists,
        (v) => v.name() === "Appetizers"
      ),
      (v) => {
        currentTrack.duplicate({to: v});
      }
    );
  }
}

"Current track added to Appetizers"
