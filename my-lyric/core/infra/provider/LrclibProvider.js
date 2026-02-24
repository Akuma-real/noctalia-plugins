.pragma library
.import "../../domain/LrcParser.js" as LrcParser

function _firstLine(plainLyrics) {
  var text = (plainLyrics || "").toString().trim()
  if (!text) return ""
  return (text.split("\n")[0] || "").toString().trim()
}

function buildRequest(track, cfg) {
  var info = track || ({})
  var config = cfg || ({})
  var title = (info.title || "").toString().trim()
  var artist = (info.artist || "").toString().trim()
  var durationSec = Math.round(Number(info.durationSec || 0))
  var baseUrl = (config.baseUrl || "https://lrclib.net/api/get").toString().trim()

  if (!title || !artist) {
    return { ok: false, status: "no-track" }
  }
  if (!baseUrl) {
    baseUrl = "https://lrclib.net/api/get"
  }

  var url = baseUrl
    + "?track_name=" + encodeURIComponent(title)
    + "&artist_name=" + encodeURIComponent(artist)

  if (durationSec > 0) {
    url += "&duration=" + encodeURIComponent(durationSec)
  }

  return { ok: true, status: "", url: url }
}

function parseResponse(body) {
  var data = null
  try {
    data = JSON.parse((body || "").toString())
  } catch (e) {
    return { ok: false, status: "bad json", lines: [], plainFirstLine: "" }
  }

  var syncedLyrics = data && data.syncedLyrics ? data.syncedLyrics : ""
  var plainLyrics = data && data.plainLyrics ? data.plainLyrics : ""
  var lines = LrcParser.parse(syncedLyrics)

  return {
    ok: true,
    status: "",
    lines: lines,
    plainFirstLine: _firstLine(plainLyrics)
  }
}
