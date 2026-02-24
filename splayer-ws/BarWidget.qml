import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.Commons
import qs.Services.UI
import qs.Widgets

Item {
  id: root

  property var pluginApi: null
  property ShellScreen screen
  property string widgetId: ""
  property string section: ""

  function valueOr(value, fallback) {
    return (value === undefined || value === null) ? fallback : value
  }

  function tr(key, fallback) {
    var mapped = (pluginApi && pluginApi.tr) ? pluginApi.tr(key) : ""
    return mapped || fallback
  }

  readonly property var mainInstance: (pluginApi && pluginApi.mainInstance) ? pluginApi.mainInstance : null
  readonly property var defaultSettings: (pluginApi
    && pluginApi.manifest
    && pluginApi.manifest.metadata
    && pluginApi.manifest.metadata.defaultSettings)
    ? pluginApi.manifest.metadata.defaultSettings
    : ({})
  readonly property var defaultDisplay: defaultSettings.display || ({})
  readonly property var defaultLyric: defaultSettings.lyric || ({})
  readonly property var defaultBehavior: defaultSettings.behavior || ({})

  readonly property var displayCfg: (mainInstance && mainInstance.settings && mainInstance.settings.display)
    ? mainInstance.settings.display
    : defaultDisplay
  readonly property var behaviorCfg: (mainInstance && mainInstance.settings && mainInstance.settings.behavior)
    ? mainInstance.settings.behavior
    : defaultBehavior
  readonly property var lyricCfg: (mainInstance && mainInstance.settings && mainInstance.settings.lyric)
    ? mainInstance.settings.lyric
    : defaultLyric

  function lineText(line) {
    if (line === undefined || line === null) return ""

    if (typeof line === "string" || typeof line === "number" || typeof line === "boolean") {
      var primitive = line.toString().trim()
      return primitive || ""
    }

    var words = Array.isArray(line.words) ? line.words : []
    if (words.length > 0) {
      var joined = ""
      for (var i = 0; i < words.length; i++) {
        var unit = words[i]
        if (!unit) continue
        if (unit.word !== undefined && unit.word !== null) {
          joined += unit.word
          continue
        }
        if (unit.text !== undefined && unit.text !== null) {
          joined += unit.text
        }
      }
      joined = joined.toString().trim()
      if (joined) return joined
    }

    var keys = ["text", "lyric", "line", "content"]
    for (var k = 0; k < keys.length; k++) {
      var value = line[keys[k]]
      if (value === undefined || value === null) continue
      var mapped = value.toString().trim()
      if (mapped) return mapped
    }

    var fallback = line.toString ? line.toString().trim() : ""
    if (fallback && fallback !== "[object Object]") return fallback
    return ""
  }

  function syncTypewriterText(forceRestart) {
    var target = root.displayText
    if (!forceRestart && target === root.typewriterTargetText) return

    root.typewriterTargetText = target

    if (!root.shouldTypewrite || !target) {
      typewriterTimer.stop()
      root.typewriterCursor = target.length
      root.typewriterDisplayText = target
      return
    }

    root.typewriterCursor = 0
    root.typewriterDisplayText = ""
    typewriterTimer.restart()
  }

  function refreshWidestLyricLineWidth() {
    var source = Array.isArray(root.lyricSourceLines) ? root.lyricSourceLines : []
    var widest = 0

    for (var i = 0; i < source.length; i++) {
      var text = lineText(source[i])
      if (!text) continue

      lyricWidthMetrics.text = text
      var measured = Math.ceil(Number(lyricWidthMetrics.advanceWidth))
      if (isFinite(measured) && measured > widest) widest = measured
    }

    lyricWidthMetrics.text = ""
    root._widestLyricLineWidth = widest
  }

  readonly property int widgetWidth: Number(valueOr(displayCfg.width, 360))
  readonly property int minWidgetWidth: Number(valueOr(displayCfg.minWidth, 180))
  readonly property int fixedWidgetWidth: Math.max(minWidgetWidth, widgetWidth)
  readonly property bool showArtist: Boolean(valueOr(displayCfg.showArtist, true))
  readonly property bool showAlbum: Boolean(valueOr(displayCfg.showAlbum, false))
  readonly property bool showProgress: Boolean(valueOr(displayCfg.showProgress, true))
  readonly property bool showLyric: Boolean(valueOr(displayCfg.showLyric, true))
  readonly property string emptyText: valueOr(displayCfg.emptyText, "").toString()
  readonly property bool openPanelOnClick: Boolean(valueOr(behaviorCfg.openPanelOnClick, true))
  readonly property var lyricSourceLines: {
    var preferYrc = Boolean(valueOr(mainInstance ? mainInstance.preferYrc : undefined, true))
    var yrcData = mainInstance ? mainInstance.yrcData : undefined
    var lrcData = mainInstance ? mainInstance.lrcData : undefined
    if (preferYrc && Array.isArray(yrcData) && yrcData.length > 0) return yrcData
    if (Array.isArray(lrcData) && lrcData.length > 0) return lrcData
    return []
  }
  property int _widestLyricLineWidth: 0
  readonly property int widestLyricLineWidth: _widestLyricLineWidth

  readonly property string connectionState: valueOr(mainInstance ? mainInstance.connectionState : undefined, "disconnected").toString()
  readonly property bool connected: connectionState === "connected"
  readonly property bool playing: Boolean(valueOr(mainInstance ? mainInstance.isPlaying : undefined, false))

  readonly property string trackLine: {
    var name = valueOr(mainInstance ? mainInstance.trackName : undefined, "").toString().trim()
    var artist = valueOr(mainInstance ? mainInstance.artistName : undefined, "").toString().trim()
    var album = valueOr(mainInstance ? mainInstance.albumName : undefined, "").toString().trim()

    if (!name && !artist && !album) return ""
    if (showAlbum && album) {
      if (showArtist && artist) return artist + " - " + name + " · " + album
      if (name) return name + " · " + album
      return album
    }
    if (showArtist && artist) {
      if (name) return artist + " - " + name
      return artist
    }
    return name || artist || album
  }

  readonly property string lyricLine: valueOr(mainInstance ? mainInstance.currentLyric : undefined, "").toString().trim()
  readonly property string displayText: {
    if (!connected) return emptyText || tr("widget.disconnected", "SPlayer 未连接")
    if (showLyric && lyricLine) return lyricLine
    if (trackLine) return trackLine
    return emptyText || tr("widget.empty", "暂无播放信息")
  }
  readonly property bool typewriterEnabled: Boolean(valueOr(lyricCfg.typewriterEnabled, true))
  readonly property int rawTypewriterIntervalMs: Number(valueOr(lyricCfg.typewriterIntervalMs, 45))
  readonly property int typewriterIntervalMs: Math.max(10, Math.min(300, Math.round(rawTypewriterIntervalMs)))
  readonly property bool shouldTypewrite: Boolean(showLyric && connected && lyricLine && typewriterEnabled)
  property string typewriterTargetText: ""
  property string typewriterDisplayText: ""
  property int typewriterCursor: 0
  readonly property int lyricDrivenWidgetWidth: {
    var iconWidth = Math.max(16, Math.ceil(iconMeasure.implicitWidth))
    var textWidth = Math.max(0, Math.ceil(widestLyricLineWidth))
    var padding = Math.ceil(Style.marginM * 2 + Style.marginS)
    var rawWidth = padding + iconWidth + textWidth
    return Math.max(minWidgetWidth, Math.min(fixedWidgetWidth, rawWidth))
  }
  readonly property int resolvedWidgetWidth: {
    if (showLyric && connected && widestLyricLineWidth > 0) return lyricDrivenWidgetWidth
    return fixedWidgetWidth
  }

  readonly property real ratio: Number(valueOr(mainInstance ? mainInstance.progressRatio : undefined, 0))
  readonly property real clampedRatio: Math.max(0, Math.min(1, ratio))
  readonly property bool showProgressLine: connected && showProgress && Number(valueOr(mainInstance ? mainInstance.durationMs : undefined, 0)) > 0

  onDisplayTextChanged: syncTypewriterText(false)
  onShouldTypewriteChanged: syncTypewriterText(true)
  onLyricSourceLinesChanged: refreshWidestLyricLineWidth()

  Component.onCompleted: {
    syncTypewriterText(true)
    refreshWidestLyricLineWidth()
  }

  Timer {
    id: typewriterTimer
    interval: root.typewriterIntervalMs
    repeat: true
    running: false

    onTriggered: {
      if (root.typewriterCursor >= root.typewriterTargetText.length) {
        root.typewriterDisplayText = root.typewriterTargetText
        stop()
        return
      }

      root.typewriterCursor += 1
      root.typewriterDisplayText = root.typewriterTargetText.slice(0, root.typewriterCursor)
    }
  }

  TextMetrics {
    id: lyricWidthMetrics
    text: ""
    font.pointSize: Style.barFontSize
  }

  NIcon {
    id: iconMeasure
    visible: false
    icon: connected ? (playing ? "music" : "music-off") : "network-offline"
    applyUiScale: false
  }

  Layout.preferredWidth: resolvedWidgetWidth
  Layout.minimumWidth: resolvedWidgetWidth
  Layout.maximumWidth: resolvedWidgetWidth

  width: resolvedWidgetWidth
  implicitWidth: resolvedWidgetWidth
  height: Style.capsuleHeight
  implicitHeight: Style.capsuleHeight

  Rectangle {
    id: capsule
    anchors.fill: parent
    color: Style.capsuleColor
    radius: Style.radiusL
    border.color: Style.capsuleBorderColor
    border.width: Style.capsuleBorderWidth
    clip: true

    Item {
      id: contentSlot
      anchors {
        fill: parent
        leftMargin: Style.marginM
        rightMargin: Style.marginM
      }

      RowLayout {
        id: contentRow
        anchors.centerIn: parent
        width: Math.min(contentSlot.width, implicitWidth)
        spacing: Style.marginS

        NIcon {
          icon: connected ? (playing ? "music" : "music-off") : "network-offline"
          applyUiScale: false
          color: connected ? Color.mPrimary : Color.mOnSurfaceVariant
          Layout.alignment: Qt.AlignVCenter
        }

        NText {
          Layout.fillWidth: true
          Layout.alignment: Qt.AlignVCenter
          text: root.typewriterDisplayText
          color: connected ? Color.mOnSurface : Color.mOnSurfaceVariant
          pointSize: Style.barFontSize
          elide: Text.ElideRight
          wrapMode: Text.NoWrap
        }
      }
    }

  }

  Item {
    id: progressOverlay
    visible: root.showProgressLine
    anchors.fill: parent
    z: 2

    Item {
      id: progressBorderMask
      anchors {
        left: parent.left
        top: parent.top
        bottom: parent.bottom
      }
      width: parent.width * root.clampedRatio
      clip: true

      Rectangle {
        x: 0
        y: 0
        width: root.width
        height: root.height
        radius: capsule.radius
        color: "transparent"
        border.color: Color.mPrimary
        border.width: Math.max(2, Style.capsuleBorderWidth)
      }
    }
  }

  NPopupContextMenu {
    id: contextMenu
    model: {
      var items = []
      if (mainInstance) {
        items.push({
          "label": playing ? tr("menu.pause", "暂停") : tr("menu.play", "播放"),
          "action": "toggle",
          "icon": playing ? "media-pause" : "media-play"
        })
        items.push({
          "label": tr("menu.prev", "上一首"),
          "action": "prev",
          "icon": "media-prev"
        })
        items.push({
          "label": tr("menu.next", "下一首"),
          "action": "next",
          "icon": "media-next"
        })
      }
      items.push({
        "label": tr("menu.reconnect", "重连"),
        "action": "reconnect",
        "icon": "refresh"
      })
      items.push({
        "label": tr("menu.settings", "设置"),
        "action": "settings",
        "icon": "settings"
      })
      return items
    }

    onTriggered: action => {
      contextMenu.close()
      PanelService.closeContextMenu(screen)

      if (action === "toggle" && mainInstance && mainInstance.sendControl) mainInstance.sendControl("toggle")
      if (action === "prev" && mainInstance && mainInstance.sendControl) mainInstance.sendControl("prev")
      if (action === "next" && mainInstance && mainInstance.sendControl) mainInstance.sendControl("next")
      if (action === "reconnect" && mainInstance && mainInstance.reconnect) mainInstance.reconnect()
      if (action === "settings" && pluginApi && pluginApi.manifest) {
        BarService.openPluginSettings(root.screen, pluginApi.manifest)
      }
    }
  }

  MouseArea {
    anchors.fill: parent
    acceptedButtons: Qt.LeftButton | Qt.RightButton
    hoverEnabled: true

    onClicked: mouse => {
      if (mouse.button === Qt.RightButton) {
        PanelService.showContextMenu(contextMenu, root, screen)
        return
      }

      if (openPanelOnClick) {
        if (pluginApi && pluginApi.openPanel) pluginApi.openPanel(root.screen, root)
      } else {
        if (mainInstance && mainInstance.sendControl) mainInstance.sendControl("toggle")
      }
    }

    onEntered: {
      TooltipService.show(root, root.displayText, BarService.getTooltipDirection(root.screen ? root.screen.name : ""))
    }
    onExited: TooltipService.hide()
  }
}
