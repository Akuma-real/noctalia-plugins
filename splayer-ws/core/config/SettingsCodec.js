.pragma library
.import "SettingsSchema.js" as Schema

function _isObject(value) {
  return value !== null && typeof value === "object" && !Array.isArray(value)
}

function _asObject(value) {
  return _isObject(value) ? value : ({})
}

function _toString(value, fallback) {
  var text = (value === undefined || value === null) ? "" : value.toString().trim()
  return text ? text : fallback
}

function _toBool(value, fallback) {
  if (value === undefined || value === null) return fallback
  return !!value
}

function _toInt(value, minValue, maxValue, fallback) {
  var num = Math.round(Number(value))
  if (!isFinite(num)) num = fallback
  if (num < minValue) num = minValue
  if (num > maxValue) num = maxValue
  return num
}

function normalize(raw) {
  var src = _asObject(raw)
  var out = Schema.cloneDefaults()
  var limits = Schema.LIMITS

  var connection = _asObject(src.connection)
  var display = _asObject(src.display)
  var lyric = _asObject(src.lyric)
  var behavior = _asObject(src.behavior)

  if (connection.host !== undefined) {
    out.connection.host = _toString(connection.host, out.connection.host)
  }
  if (connection.port !== undefined) {
    out.connection.port = _toInt(connection.port, limits.port.min, limits.port.max, out.connection.port)
  }
  if (connection.autoReconnect !== undefined) {
    out.connection.autoReconnect = _toBool(connection.autoReconnect, out.connection.autoReconnect)
  }
  if (connection.reconnectMs !== undefined) {
    out.connection.reconnectMs = _toInt(
      connection.reconnectMs,
      limits.reconnectMs.min,
      limits.reconnectMs.max,
      out.connection.reconnectMs
    )
  }
  if (connection.heartbeatSec !== undefined) {
    out.connection.heartbeatSec = _toInt(
      connection.heartbeatSec,
      limits.heartbeatSec.min,
      limits.heartbeatSec.max,
      out.connection.heartbeatSec
    )
  }
  if (connection.websocatBin !== undefined) {
    out.connection.websocatBin = _toString(connection.websocatBin, out.connection.websocatBin)
  }

  if (display.width !== undefined) {
    out.display.width = _toInt(display.width, limits.width.min, limits.width.max, out.display.width)
  }
  if (display.minWidth !== undefined) {
    out.display.minWidth = _toInt(display.minWidth, limits.minWidth.min, limits.minWidth.max, out.display.minWidth)
  }
  if (display.showArtist !== undefined) {
    out.display.showArtist = _toBool(display.showArtist, out.display.showArtist)
  }
  if (display.showAlbum !== undefined) {
    out.display.showAlbum = _toBool(display.showAlbum, out.display.showAlbum)
  }
  if (display.showProgress !== undefined) {
    out.display.showProgress = _toBool(display.showProgress, out.display.showProgress)
  }
  if (display.showLyric !== undefined) {
    out.display.showLyric = _toBool(display.showLyric, out.display.showLyric)
  }
  if (display.emptyText !== undefined) {
    out.display.emptyText = (display.emptyText || "").toString()
  }

  if (lyric.preferYrc !== undefined) {
    out.lyric.preferYrc = _toBool(lyric.preferYrc, out.lyric.preferYrc)
  }
  if (lyric.typewriterEnabled !== undefined) {
    out.lyric.typewriterEnabled = _toBool(lyric.typewriterEnabled, out.lyric.typewriterEnabled)
  }
  if (lyric.typewriterIntervalMs !== undefined) {
    out.lyric.typewriterIntervalMs = _toInt(
      lyric.typewriterIntervalMs,
      limits.typewriterIntervalMs.min,
      limits.typewriterIntervalMs.max,
      out.lyric.typewriterIntervalMs
    )
  }

  if (behavior.openPanelOnClick !== undefined) {
    out.behavior.openPanelOnClick = _toBool(behavior.openPanelOnClick, out.behavior.openPanelOnClick)
  }

  if (!out.connection.host) {
    out.connection.host = Schema.DEFAULTS.connection.host
  }
  if (!out.connection.websocatBin) {
    out.connection.websocatBin = Schema.DEFAULTS.connection.websocatBin
  }
  if (out.display.minWidth > out.display.width) {
    out.display.minWidth = out.display.width
  }

  return out
}
