.pragma library

var DEFAULTS = {
  connection: {
    host: "127.0.0.1",
    port: 25885,
    autoReconnect: true,
    reconnectMs: 1500,
    heartbeatSec: 20,
    websocatBin: "websocat"
  },
  display: {
    width: 360,
    minWidth: 180,
    showArtist: true,
    showAlbum: false,
    showProgress: true,
    showLyric: true,
    emptyText: ""
  },
  lyric: {
    preferYrc: true,
    typewriterEnabled: true,
    typewriterIntervalMs: 45
  },
  behavior: {
    openPanelOnClick: true
  }
}

var LIMITS = {
  port: { min: 1, max: 65535 },
  reconnectMs: { min: 200, max: 60000 },
  heartbeatSec: { min: 5, max: 120 },
  width: { min: 120, max: 1000 },
  minWidth: { min: 80, max: 1000 },
  typewriterIntervalMs: { min: 10, max: 300 }
}

function cloneDefaults() {
  return JSON.parse(JSON.stringify(DEFAULTS))
}
