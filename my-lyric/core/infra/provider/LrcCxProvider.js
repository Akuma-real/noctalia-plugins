.pragma library
.import "../../domain/LrcParser.js" as LrcParser

function _firstNonEmptyLine(rawText) {
  var text = (rawText || "").toString()
  if (!text) return ""

  var rows = text.split("\n")
  for (var i = 0; i < rows.length; i++) {
    var row = (rows[i] || "").toString().trim()
    if (!row) continue
    row = row.replace(/\[[^\]]*\]/g, "").trim()
    if (row) return row
  }
  return ""
}

function buildRequest(track, cfg) {
  var info = track || ({})
  var config = cfg || ({})
  var title = (info.title || "").toString().trim()
  var artist = (info.artist || "").toString().trim()
  var album = (info.album || "").toString().trim()
  var baseUrl = (config.baseUrl || "https://api.lrc.cx/lyrics").toString().trim()

  if (!title) {
    return { ok: false, status: "no-track" }
  }
  if (!baseUrl) {
    baseUrl = "https://api.lrc.cx/lyrics"
  }

  var url = baseUrl + "?title=" + encodeURIComponent(title)
  if (artist) {
    url += "&artist=" + encodeURIComponent(artist)
  }
  if (album && album !== "[Unknown Album]") {
    url += "&album=" + encodeURIComponent(album)
  }

  return { ok: true, status: "", url: url }
}

function parseResponse(body) {
  var raw = (body || "").toString()
  var lines = LrcParser.parse(raw)

  return {
    ok: true,
    status: "",
    lines: lines,
    plainFirstLine: lines.length > 0 ? (lines[0].text || "") : _firstNonEmptyLine(raw)
  }
}
