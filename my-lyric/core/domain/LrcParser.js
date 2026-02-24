.pragma library

function parse(syncedLyrics) {
  var out = []
  var raw = (syncedLyrics || "").toString()
  if (!raw) return out

  var lines = raw.split("\n")
  for (var i = 0; i < lines.length; i++) {
    var line = (lines[i] || "").toString().trim()
    if (!line) continue

    var tagRe = /\[(\d+):(\d+(?:\.\d+)?)\]/g
    var tags = []
    var m = null
    while ((m = tagRe.exec(line)) !== null) {
      tags.push({ mm: parseInt(m[1], 10), ss: parseFloat(m[2]) })
    }
    if (tags.length === 0) continue

    var text = line.replace(/^\s*(?:\[\d+:\d+(?:\.\d+)?\]\s*)+/, "").trim()
    if (!text) continue

    for (var j = 0; j < tags.length; j++) {
      var mm = tags[j].mm
      var ss = tags[j].ss
      if (!isFinite(mm) || !isFinite(ss)) continue
      out.push({ tMs: Math.round((mm * 60 + ss) * 1000), text: text })
    }
  }

  out.sort(function(a, b) { return a.tMs - b.tMs })
  return out
}
