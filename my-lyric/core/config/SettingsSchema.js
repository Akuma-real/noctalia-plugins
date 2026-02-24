.pragma library

var DEFAULTS = {
  provider: {
    active: "lrccx"
  },
  providers: {
    lrccx: {
      baseUrl: "https://api.lrc.cx/lyrics",
      timeoutMs: 3500
    },
    lrclib: {
      baseUrl: "https://lrclib.net/api/get",
      timeoutMs: 3500
    }
  },
  polling: {
    updateMs: 200
  },
  display: {
    width: 360,
    minWidth: 180,
    trackAdaptive: true,
    showWhenEmpty: false,
    emptyText: ""
  },
  cache: {
    enabled: true,
    ttlSec: 21600,
    maxEntries: 200
  }
}

var LIMITS = {
  timeoutMs: { min: 300, max: 20000 },
  updateMs: { min: 80, max: 4000 },
  width: { min: 180, max: 1200 },
  minWidth: { min: 120, max: 1200 },
  ttlSec: { min: 60, max: 604800 },
  maxEntries: { min: 10, max: 2000 }
}

function cloneDefaults() {
  return JSON.parse(JSON.stringify(DEFAULTS))
}
