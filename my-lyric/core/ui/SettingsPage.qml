import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Widgets

ColumnLayout {
  id: root

  property var controller: null

  property string vProviderInput: "lrccx"
  property string vProviderActive: "lrccx"
  property string vLrcCxBaseUrl: "https://api.lrc.cx/lyrics"
  property int vLrcCxTimeoutMs: 3500
  property string vLrclibBaseUrl: "https://lrclib.net/api/get"
  property int vLrclibTimeoutMs: 3500
  property int vUpdateMs: 200
  property int vWidth: 360
  property int vMinWidth: 180
  property bool vTrackAdaptive: true
  property bool vShowWhenEmpty: false
  property string vEmptyText: ""
  property bool vCacheEnabled: true
  property int vCacheTtlSec: 21600
  property int vCacheMaxEntries: 200

  spacing: Style.marginL

  function normalizeProviderId(rawId) {
    var id = (rawId || "").toString().trim().toLowerCase()
    if (id === "lrcapi" || id === "lrc.cx") return "lrccx"
    if (id === "lrclib") return "lrclib"
    return "lrccx"
  }

  function defaultEndpointFor(providerId) {
    var id = normalizeProviderId(providerId)
    return id === "lrclib"
      ? "https://lrclib.net/api/get"
      : "https://api.lrc.cx/lyrics"
  }

  function currentProviderBaseUrl() {
    return vProviderActive === "lrclib"
      ? vLrclibBaseUrl
      : vLrcCxBaseUrl
  }

  function setCurrentProviderBaseUrl(nextUrl) {
    if (vProviderActive === "lrclib") {
      vLrclibBaseUrl = nextUrl
    } else {
      vLrcCxBaseUrl = nextUrl
    }
  }

  function currentProviderTimeoutMs() {
    return vProviderActive === "lrclib"
      ? vLrclibTimeoutMs
      : vLrcCxTimeoutMs
  }

  function setCurrentProviderTimeoutMs(nextTimeoutMs) {
    if (vProviderActive === "lrclib") {
      vLrclibTimeoutMs = Math.round(nextTimeoutMs)
    } else {
      vLrcCxTimeoutMs = Math.round(nextTimeoutMs)
    }
  }

  function providerHint() {
    if (vProviderActive === "lrclib") {
      return "Current: lrclib (LRCLIB JSON API)"
    }
    return "Current: lrccx (LrcAPI text/LRC API)"
  }

  function loadFromController() {
    var s = controller?.settings || ({})
    var active = normalizeProviderId(s?.provider?.active ?? "lrccx")
    vProviderInput = active
    vProviderActive = active

    vLrcCxBaseUrl = (
      s?.providers?.lrccx?.baseUrl
      ?? defaultEndpointFor("lrccx")
    ).toString()
    vLrcCxTimeoutMs = Number(s?.providers?.lrccx?.timeoutMs ?? 3500)

    vLrclibBaseUrl = (
      s?.providers?.lrclib?.baseUrl
      ?? defaultEndpointFor("lrclib")
    ).toString()
    vLrclibTimeoutMs = Number(s?.providers?.lrclib?.timeoutMs ?? 3500)

    vUpdateMs = Number(s?.polling?.updateMs ?? 200)
    vWidth = Number(s?.display?.width ?? 360)
    vMinWidth = Number(s?.display?.minWidth ?? 180)
    vTrackAdaptive = Boolean(s?.display?.trackAdaptive ?? true)
    vShowWhenEmpty = Boolean(s?.display?.showWhenEmpty ?? false)
    vEmptyText = (s?.display?.emptyText ?? "").toString()
    vCacheEnabled = Boolean(s?.cache?.enabled ?? true)
    vCacheTtlSec = Number(s?.cache?.ttlSec ?? 21600)
    vCacheMaxEntries = Number(s?.cache?.maxEntries ?? 200)
  }

  function buildSettings() {
    return {
      provider: {
        active: normalizeProviderId(vProviderInput)
      },
      providers: {
        lrccx: {
          baseUrl: (vLrcCxBaseUrl || defaultEndpointFor("lrccx")).toString().trim() || defaultEndpointFor("lrccx"),
          timeoutMs: Math.round(vLrcCxTimeoutMs)
        },
        lrclib: {
          baseUrl: (vLrclibBaseUrl || defaultEndpointFor("lrclib")).toString().trim() || defaultEndpointFor("lrclib"),
          timeoutMs: Math.round(vLrclibTimeoutMs)
        }
      },
      polling: {
        updateMs: Math.round(vUpdateMs)
      },
      display: {
        width: Math.round(vWidth),
        minWidth: Math.min(Math.round(vMinWidth), Math.round(vWidth)),
        trackAdaptive: vTrackAdaptive,
        showWhenEmpty: vShowWhenEmpty,
        emptyText: (vEmptyText || "").toString()
      },
      cache: {
        enabled: vCacheEnabled,
        ttlSec: Math.round(vCacheTtlSec),
        maxEntries: Math.round(vCacheMaxEntries)
      }
    }
  }

  function saveSettings() {
    if (!controller) return
    controller.setSettings(buildSettings())
    controller.saveSettings()
  }

  Component.onCompleted: loadFromController()

  Connections {
    target: controller
    function onSettingsChanged() { root.loadFromController() }
  }

  NTextInput {
    Layout.fillWidth: true
    label: "Provider ID"
    description: "Supported: lrccx (default), lrclib"
    text: root.vProviderInput
    onTextChanged: {
      root.vProviderInput = text
      root.vProviderActive = root.normalizeProviderId(text)
    }
  }

  NTextInput {
    Layout.fillWidth: true
    label: "Provider endpoint"
    description: root.providerHint()
    text: root.currentProviderBaseUrl()
    onTextChanged: root.setCurrentProviderBaseUrl(text)
  }

  NLabel { label: "Provider timeout (ms)" }
  NSlider {
    from: 300; to: 20000; stepSize: 100
    value: root.currentProviderTimeoutMs()
    onValueChanged: root.setCurrentProviderTimeoutMs(value)
  }
  Text { text: root.currentProviderTimeoutMs() + " ms"; color: Color.mOnSurfaceVariant; font.pointSize: Style.fontSizeS }

  NLabel { label: "Update interval (ms)" }
  NSlider {
    from: 80; to: 4000; stepSize: 20
    value: root.vUpdateMs
    onValueChanged: root.vUpdateMs = Math.round(value)
  }
  Text { text: root.vUpdateMs + " ms"; color: Color.mOnSurfaceVariant; font.pointSize: Style.fontSizeS }

  NLabel { label: "Max widget width (px)" }
  NSlider {
    from: 180; to: 1200; stepSize: 10
    value: root.vWidth
    onValueChanged: root.vWidth = Math.round(value)
  }
  Text { text: root.vWidth + " px"; color: Color.mOnSurfaceVariant; font.pointSize: Style.fontSizeS }

  NToggle {
    label: "Track adaptive width"
    description: "Resize per track using the longest lyric line, and keep it stable until next track."
    checked: root.vTrackAdaptive
    onToggled: checked => root.vTrackAdaptive = checked
  }

  NLabel { label: "Min widget width (px)" }
  NSlider {
    from: 120; to: 1200; stepSize: 10
    value: root.vMinWidth
    onValueChanged: root.vMinWidth = Math.round(value)
  }
  Text {
    text: Math.min(root.vMinWidth, root.vWidth) + " px"
    color: Color.mOnSurfaceVariant
    font.pointSize: Style.fontSizeS
  }

  NToggle {
    label: "Show even when empty"
    description: "If off, widget collapses when no lyric line is available."
    checked: root.vShowWhenEmpty
    onToggled: checked => root.vShowWhenEmpty = checked
  }

  NTextInput {
    Layout.fillWidth: true
    label: "Empty text"
    description: "Shown when 'Show even when empty' is enabled."
    text: root.vEmptyText
    onTextChanged: root.vEmptyText = text
  }

  NToggle {
    label: "Enable cache"
    description: "Cache fetched lyrics by track key."
    checked: root.vCacheEnabled
    onToggled: checked => root.vCacheEnabled = checked
  }

  NLabel { label: "Cache TTL (seconds)" }
  NSlider {
    from: 60; to: 604800; stepSize: 60
    value: root.vCacheTtlSec
    onValueChanged: root.vCacheTtlSec = Math.round(value)
  }
  Text { text: root.vCacheTtlSec + " s"; color: Color.mOnSurfaceVariant; font.pointSize: Style.fontSizeS }

  NLabel { label: "Cache max entries" }
  NSlider {
    from: 10; to: 2000; stepSize: 10
    value: root.vCacheMaxEntries
    onValueChanged: root.vCacheMaxEntries = Math.round(value)
  }
  Text { text: root.vCacheMaxEntries + ""; color: Color.mOnSurfaceVariant; font.pointSize: Style.fontSizeS }
}
