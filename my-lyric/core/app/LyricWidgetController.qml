import QtQuick
import QtQml
import qs.Services.Media
import "../config/SettingsCodec.js" as SettingsCodec
import "../domain/TrackKey.js" as TrackKey
import "../domain/LyricMatcher.js" as LyricMatcher
import "../infra/provider/ProviderRegistry.js" as ProviderRegistry
import "../infra/cache" as Cache
import "../infra/provider" as ProviderInfra

Item {
  id: root

  property var pluginApi: null
  property var settings: SettingsCodec.normalize({})

  property string status: ""
  property string trackKey: ""
  property string currentLine: ""
  property string plainFirstLine: ""
  property string trackLongestLine: ""
  property var lines: []
  property bool migrationChecked: false

  readonly property int updateMs: Number(settings?.polling?.updateMs ?? 200)
  readonly property string activeProvider: (settings?.provider?.active ?? "lrccx").toString()
  readonly property var providerCfg: settings?.providers?.[activeProvider] || ({})
  readonly property bool cacheEnabled: Boolean(settings?.cache?.enabled ?? true)
  readonly property int cacheTtlSec: Number(settings?.cache?.ttlSec ?? 21600)
  readonly property int cacheMaxEntries: Number(settings?.cache?.maxEntries ?? 200)

  Cache.LyricCache {
    id: lyricCache
    enabled: root.cacheEnabled
    ttlSec: Math.max(0, root.cacheTtlSec)
    maxEntries: Math.max(1, root.cacheMaxEntries)
  }

  ProviderInfra.HttpClient {
    id: httpClient
  }

  function _deepCopy(value) {
    return JSON.parse(JSON.stringify(value))
  }

  function _persistNormalizedIfNeeded(raw, normalized) {
    if (!pluginApi || migrationChecked) return
    migrationChecked = true
    if (!SettingsCodec.needsMigration(raw)) return
    if (!pluginApi.pluginSettings) return

    var target = pluginApi.pluginSettings
    target.provider = _deepCopy(normalized.provider)
    target.providers = _deepCopy(normalized.providers)
    target.polling = _deepCopy(normalized.polling)
    target.display = _deepCopy(normalized.display)
    target.cache = _deepCopy(normalized.cache)

    var legacyKeys = ["providerBaseUrl", "updateMs", "width", "minWidth", "trackAdaptive", "showWhenEmpty", "emptyText"]
    for (var i = 0; i < legacyKeys.length; i++) {
      var key = legacyKeys[i]
      if (target[key] !== undefined) delete target[key]
    }
    pluginApi.saveSettings()
  }

  function _reloadSettings() {
    var raw = (pluginApi && pluginApi.pluginSettings) ? pluginApi.pluginSettings : ({})
    var normalized = SettingsCodec.normalize(raw)
    settings = normalized
    _persistNormalizedIfNeeded(raw, normalized)
  }

  function _trackSnapshot() {
    return {
      title: (MediaService.trackTitle || "").trim(),
      artist: (MediaService.trackArtist || "").trim(),
      durationSec: Math.round(MediaService.trackLength || 0)
    }
  }

  function _clearLyrics() {
    lines = []
    plainFirstLine = ""
    currentLine = ""
    trackLongestLine = ""
  }

  function _refreshTrackLongestLine() {
    var longest = ""
    for (var i = 0; i < lines.length; i++) {
      var text = (lines[i] && lines[i].text ? lines[i].text : "").toString().trim()
      if (!text) continue
      if (text.length > longest.length) longest = text
    }
    if (!longest) longest = (plainFirstLine || "").toString().trim()
    trackLongestLine = longest
  }

  function _fetchLyrics(track, key, forceNetwork) {
    status = ""
    _clearLyrics()
    if (!key) return

    if (!forceNetwork) {
      var cached = lyricCache.get(key)
      if (cached) {
        lines = cached.lines || []
        plainFirstLine = cached.plainFirstLine || ""
        _refreshTrackLongestLine()
        updateCurrentLine()
        return
      }
    }

    status = "loading"
    ProviderRegistry.fetchLyrics(activeProvider, track, providerCfg, httpClient, function(result) {
      if (key !== root.trackKey) return
      if (!result || !result.ok) {
        root.status = result && result.status ? result.status : "request failed"
        return
      }

      root.lines = result.lines || []
      root.plainFirstLine = result.plainFirstLine || ""
      root._refreshTrackLongestLine()
      root.status = ""
      if (root.cacheEnabled) {
        lyricCache.set(key, {
          lines: root.lines,
          plainFirstLine: root.plainFirstLine
        })
      }
      root.updateCurrentLine()
    })
  }

  function refreshNow(forceNetwork) {
    _reloadSettings()
    var track = _trackSnapshot()
    var key = TrackKey.make(track, activeProvider)
    trackKey = key
    _fetchLyrics(track, key, forceNetwork === true)
  }

  function updateCurrentLine() {
    var posMs = Math.round((MediaService.currentPosition || 0) * 1000)
    currentLine = LyricMatcher.pickLine(lines, posMs, plainFirstLine || "")
  }

  function onTrackMaybeChanged() {
    _reloadSettings()
    var track = _trackSnapshot()
    var key = TrackKey.make(track, activeProvider)
    if (key === trackKey) return
    trackKey = key
    _fetchLyrics(track, key, false)
  }

  Connections {
    target: MediaService
    function onTrackTitleChanged() { root.onTrackMaybeChanged() }
    function onTrackArtistChanged() { root.onTrackMaybeChanged() }
    function onTrackLengthChanged() { root.onTrackMaybeChanged() }
    function onSelectedPlayerIndexChanged() { root.onTrackMaybeChanged() }
  }

  Timer {
    interval: Math.max(80, root.updateMs)
    running: true
    repeat: true
    onTriggered: root.updateCurrentLine()
  }

  Component.onCompleted: root.onTrackMaybeChanged()
}
