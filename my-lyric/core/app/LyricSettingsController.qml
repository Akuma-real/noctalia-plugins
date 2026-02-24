import QtQuick
import "../config/SettingsCodec.js" as SettingsCodec

QtObject {
  id: root

  property var pluginApi: null
  property var settings: SettingsCodec.normalize({})

  function _deepCopy(value) {
    return JSON.parse(JSON.stringify(value))
  }

  function _writeNormalizedSettings(normalized) {
    if (!pluginApi) return
    if (!pluginApi.pluginSettings) {
      try { pluginApi.pluginSettings = ({}) } catch (e) { return }
    }

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
  }

  function reloadSettings() {
    var raw = (pluginApi && pluginApi.pluginSettings) ? pluginApi.pluginSettings : ({})
    var normalized = SettingsCodec.normalize(raw)
    settings = normalized

    if (pluginApi && SettingsCodec.needsMigration(raw)) {
      _writeNormalizedSettings(normalized)
      pluginApi.saveSettings()
    }
  }

  function setSettings(nextSettings) {
    settings = SettingsCodec.normalize(nextSettings || ({}))
  }

  function saveSettings() {
    if (!pluginApi) return
    var normalized = SettingsCodec.normalize(settings)
    settings = normalized
    _writeNormalizedSettings(normalized)
    pluginApi.saveSettings()
  }

  Component.onCompleted: reloadSettings()
}
