.pragma library
.import "SettingsSchema.js" as Schema

function _clone(value) {
  return JSON.parse(JSON.stringify(value))
}

function _isObject(value) {
  return value !== null && typeof value === "object" && !Array.isArray(value)
}

function _asObject(value) {
  return _isObject(value) ? value : ({})
}

function _toString(value, fallback) {
  var text = (value === undefined || value === null) ? "" : value.toString()
  text = text.trim()
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

function _normalizeProviderId(value, fallback) {
  var id = _toString(value, fallback).toLowerCase()
  if (id === "lrcapi" || id === "lrc.cx") return "lrccx"
  return id
}

function normalize(raw) {
  var src = _asObject(raw)
  var out = Schema.cloneDefaults()
  var defaults = Schema.DEFAULTS
  var limits = Schema.LIMITS

  if (src.providerBaseUrl !== undefined) {
    out.providers.lrclib.baseUrl = _toString(src.providerBaseUrl, out.providers.lrclib.baseUrl)
    out.provider.active = "lrclib"
  }
  if (src.updateMs !== undefined) {
    out.polling.updateMs = _toInt(src.updateMs, limits.updateMs.min, limits.updateMs.max, out.polling.updateMs)
  }
  if (src.width !== undefined) {
    out.display.width = _toInt(src.width, limits.width.min, limits.width.max, out.display.width)
  }
  if (src.minWidth !== undefined) {
    out.display.minWidth = _toInt(src.minWidth, limits.minWidth.min, limits.minWidth.max, out.display.minWidth)
  }
  if (src.trackAdaptive !== undefined) {
    out.display.trackAdaptive = _toBool(src.trackAdaptive, out.display.trackAdaptive)
  }
  if (src.showWhenEmpty !== undefined) {
    out.display.showWhenEmpty = _toBool(src.showWhenEmpty, out.display.showWhenEmpty)
  }
  if (src.emptyText !== undefined) {
    out.display.emptyText = (src.emptyText || "").toString()
  }

  var provider = _asObject(src.provider)
  var providers = _asObject(src.providers)
  var lrccx = _asObject(providers.lrccx)
  var lrclib = _asObject(providers.lrclib)
  var polling = _asObject(src.polling)
  var display = _asObject(src.display)
  var cache = _asObject(src.cache)

  if (provider.active !== undefined) {
    out.provider.active = _normalizeProviderId(provider.active, out.provider.active)
  }
  if (lrccx.baseUrl !== undefined) {
    out.providers.lrccx.baseUrl = _toString(lrccx.baseUrl, out.providers.lrccx.baseUrl)
  }
  if (lrccx.timeoutMs !== undefined) {
    out.providers.lrccx.timeoutMs = _toInt(
      lrccx.timeoutMs,
      limits.timeoutMs.min,
      limits.timeoutMs.max,
      out.providers.lrccx.timeoutMs
    )
  }
  if (lrclib.baseUrl !== undefined) {
    out.providers.lrclib.baseUrl = _toString(lrclib.baseUrl, out.providers.lrclib.baseUrl)
  }
  if (lrclib.timeoutMs !== undefined) {
    out.providers.lrclib.timeoutMs = _toInt(
      lrclib.timeoutMs,
      limits.timeoutMs.min,
      limits.timeoutMs.max,
      out.providers.lrclib.timeoutMs
    )
  }
  if (polling.updateMs !== undefined) {
    out.polling.updateMs = _toInt(
      polling.updateMs,
      limits.updateMs.min,
      limits.updateMs.max,
      out.polling.updateMs
    )
  }
  if (display.width !== undefined) {
    out.display.width = _toInt(display.width, limits.width.min, limits.width.max, out.display.width)
  }
  if (display.minWidth !== undefined) {
    out.display.minWidth = _toInt(
      display.minWidth,
      limits.minWidth.min,
      limits.minWidth.max,
      out.display.minWidth
    )
  }
  if (display.trackAdaptive !== undefined) {
    out.display.trackAdaptive = _toBool(display.trackAdaptive, out.display.trackAdaptive)
  }
  if (display.showWhenEmpty !== undefined) {
    out.display.showWhenEmpty = _toBool(display.showWhenEmpty, out.display.showWhenEmpty)
  }
  if (display.emptyText !== undefined) {
    out.display.emptyText = (display.emptyText || "").toString()
  }
  if (cache.enabled !== undefined) {
    out.cache.enabled = _toBool(cache.enabled, out.cache.enabled)
  }
  if (cache.ttlSec !== undefined) {
    out.cache.ttlSec = _toInt(cache.ttlSec, limits.ttlSec.min, limits.ttlSec.max, out.cache.ttlSec)
  }
  if (cache.maxEntries !== undefined) {
    out.cache.maxEntries = _toInt(
      cache.maxEntries,
      limits.maxEntries.min,
      limits.maxEntries.max,
      out.cache.maxEntries
    )
  }

  if (!out.provider.active || !out.providers[out.provider.active]) {
    out.provider.active = defaults.provider.active
  }
  if (!out.providers.lrccx.baseUrl) {
    out.providers.lrccx.baseUrl = defaults.providers.lrccx.baseUrl
  }
  if (!out.providers.lrclib.baseUrl) {
    out.providers.lrclib.baseUrl = defaults.providers.lrclib.baseUrl
  }
  if (out.display.minWidth > out.display.width) {
    out.display.minWidth = out.display.width
  }

  return out
}

function needsMigration(raw) {
  var src = _asObject(raw)
  if (
    src.providerBaseUrl !== undefined
    || src.updateMs !== undefined
    || src.width !== undefined
    || src.minWidth !== undefined
    || src.trackAdaptive !== undefined
    || src.showWhenEmpty !== undefined
    || src.emptyText !== undefined
  ) {
    return true
  }
  var normalized = normalize(src)
  return JSON.stringify(src) !== JSON.stringify(normalized)
}

function clone(settings) {
  return _clone(normalize(settings))
}
