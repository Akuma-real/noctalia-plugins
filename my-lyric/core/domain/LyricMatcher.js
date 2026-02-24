.pragma library

function pickLine(lines, positionMs, fallback) {
  var items = Array.isArray(lines) ? lines : []
  var pos = Math.max(0, Math.round(Number(positionMs || 0)))
  var current = ""

  for (var i = 0; i < items.length; i++) {
    var row = items[i] || ({})
    var tMs = Math.round(Number(row.tMs))
    if (isNaN(tMs)) continue
    if (tMs <= pos) {
      var text = (row.text || "").toString().trim()
      if (text) current = text
    } else {
      break
    }
  }

  if (current) return current
  return (fallback || "").toString()
}
