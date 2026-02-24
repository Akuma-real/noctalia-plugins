.pragma library

function _normalizeProviderId(value) {
  var id = (value || "").toString().trim().toLowerCase()
  if (id === "lrcapi" || id === "lrc.cx") return "lrccx"
  if (id === "lrclib") return "lrclib"
  return "lrccx"
}

function make(track, providerId) {
  var src = track || ({})
  var providerKey = _normalizeProviderId(providerId)
  var title = (src.title || "").toString().trim()
  var artist = (src.artist || "").toString().trim()
  var durationSec = Math.round(Number(src.durationSec || 0))
  if (!title) return ""
  var artistKey = artist || "__unknown_artist__"
  return providerKey + "::" + artistKey + "::" + title + "::" + durationSec
}
