import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Widgets

ColumnLayout {
  id: root
  spacing: Style.marginL

  property var pluginApi: null

  property string editHost: "127.0.0.1"
  property int editPort: 25885
  property bool editAutoReconnect: true
  property int editReconnectMs: 1500
  property int editHeartbeatSec: 20
  property string editWebsocatBin: "websocat"

  property int editWidth: 360
  property int editMinWidth: 180
  property bool editShowArtist: true
  property bool editShowAlbum: false
  property bool editShowProgress: true
  property bool editShowLyric: true
  property string editEmptyText: ""

  property bool editPreferYrc: true
  property bool editTypewriterEnabled: true
  property int editTypewriterIntervalMs: 45
  property bool editOpenPanelOnClick: true

  function valueOr(value, fallback) {
    return (value === undefined || value === null) ? fallback : value
  }

  function tr(key, fallback) {
    var mapped = (pluginApi && pluginApi.tr) ? pluginApi.tr(key) : ""
    return mapped || fallback
  }

  function loadSettings() {
    var cfg = (pluginApi && pluginApi.pluginSettings) ? pluginApi.pluginSettings : ({})
    var defaults = (pluginApi
      && pluginApi.manifest
      && pluginApi.manifest.metadata
      && pluginApi.manifest.metadata.defaultSettings)
      ? pluginApi.manifest.metadata.defaultSettings
      : ({})

    var connection = cfg.connection || defaults.connection || ({})
    var display = cfg.display || defaults.display || ({})
    var lyric = cfg.lyric || defaults.lyric || ({})
    var behavior = cfg.behavior || defaults.behavior || ({})

    editHost = valueOr(connection.host, "127.0.0.1")
    editPort = valueOr(connection.port, 25885)
    editAutoReconnect = valueOr(connection.autoReconnect, true)
    editReconnectMs = valueOr(connection.reconnectMs, 1500)
    editHeartbeatSec = valueOr(connection.heartbeatSec, 20)
    editWebsocatBin = valueOr(connection.websocatBin, "websocat")

    editWidth = valueOr(display.width, 360)
    editMinWidth = valueOr(display.minWidth, 180)
    editShowArtist = valueOr(display.showArtist, true)
    editShowAlbum = valueOr(display.showAlbum, false)
    editShowProgress = valueOr(display.showProgress, true)
    editShowLyric = valueOr(display.showLyric, true)
    editEmptyText = valueOr(display.emptyText, "")

    editPreferYrc = valueOr(lyric.preferYrc, true)
    editTypewriterEnabled = valueOr(lyric.typewriterEnabled, true)
    var interval = Number(valueOr(lyric.typewriterIntervalMs, 45))
    if (!isFinite(interval)) interval = 45
    editTypewriterIntervalMs = Math.max(10, Math.min(300, Math.round(interval)))
    editOpenPanelOnClick = valueOr(behavior.openPanelOnClick, true)
  }

  onPluginApiChanged: {
    if (pluginApi) loadSettings()
  }

  Component.onCompleted: {
    if (pluginApi) loadSettings()
  }

  NTextInput {
    Layout.fillWidth: true
    label: tr("settings.connection.host", "WS Host")
    description: tr("settings.connection.host-desc", "SPlayer WebSocket 服务地址")
    text: root.editHost
    onTextChanged: root.editHost = text
  }

  ColumnLayout {
    Layout.fillWidth: true
    spacing: Style.marginS

    NLabel {
      label: tr("settings.connection.port", "WS Port") + ": " + root.editPort
      description: tr("settings.connection.port-desc", "SPlayer WebSocket 服务端口")
    }

    NSpinBox {
      from: 1
      to: 65535
      stepSize: 1
      value: root.editPort
      onValueChanged: if (value !== root.editPort) root.editPort = value
    }
  }

  NTextInput {
    Layout.fillWidth: true
    label: tr("settings.connection.websocat", "Websocat 可执行文件")
    description: tr("settings.connection.websocat-desc", "默认值为 websocat，可改为绝对路径")
    text: root.editWebsocatBin
    onTextChanged: root.editWebsocatBin = text
  }

  ColumnLayout {
    Layout.fillWidth: true
    spacing: Style.marginS

    NLabel {
      label: tr("settings.connection.reconnect-ms", "重连间隔(ms)") + ": " + root.editReconnectMs
      description: tr("settings.connection.reconnect-ms-desc", "连接断开后自动重连间隔")
    }

    NSpinBox {
      from: 200
      to: 60000
      stepSize: 100
      value: root.editReconnectMs
      onValueChanged: if (value !== root.editReconnectMs) root.editReconnectMs = value
    }
  }

  ColumnLayout {
    Layout.fillWidth: true
    spacing: Style.marginS

    NLabel {
      label: tr("settings.connection.heartbeat-sec", "心跳间隔(秒)") + ": " + root.editHeartbeatSec
      description: tr("settings.connection.heartbeat-sec-desc", "发送 PING 的周期")
    }

    NSpinBox {
      from: 5
      to: 120
      stepSize: 1
      value: root.editHeartbeatSec
      onValueChanged: if (value !== root.editHeartbeatSec) root.editHeartbeatSec = value
    }
  }

  NDivider {
    Layout.fillWidth: true
  }

  ColumnLayout {
    Layout.fillWidth: true
    spacing: Style.marginS

    NLabel {
      label: tr("settings.display.width", "组件宽度") + ": " + root.editWidth
      description: tr("settings.display.width-desc", "Bar 组件默认宽度")
    }

    NSlider {
      Layout.fillWidth: true
      from: 120
      to: 1000
      stepSize: 10
      value: root.editWidth
      onValueChanged: root.editWidth = value
    }
  }

  ColumnLayout {
    Layout.fillWidth: true
    spacing: Style.marginS

    NLabel {
      label: tr("settings.display.min-width", "最小宽度") + ": " + root.editMinWidth
      description: tr("settings.display.min-width-desc", "内容较少时保留的最小宽度")
    }

    NSlider {
      Layout.fillWidth: true
      from: 80
      to: 1000
      stepSize: 10
      value: root.editMinWidth
      onValueChanged: root.editMinWidth = value
    }
  }

  NTextInput {
    Layout.fillWidth: true
    label: tr("settings.display.empty-text", "空状态文本")
    description: tr("settings.display.empty-text-desc", "未连接或无播放信息时显示文本")
    text: root.editEmptyText
    onTextChanged: root.editEmptyText = text
  }

  Item {
    Layout.fillWidth: true
    Layout.preferredHeight: autoReconnectToggle.implicitHeight
    NToggle {
      id: autoReconnectToggle
      anchors.fill: parent
      label: tr("settings.connection.auto-reconnect", "自动重连")
      checked: root.editAutoReconnect
    }
    MouseArea {
      anchors.fill: parent
      cursorShape: Qt.PointingHandCursor
      onClicked: {
        root.editAutoReconnect = !root.editAutoReconnect
        autoReconnectToggle.checked = root.editAutoReconnect
      }
    }
  }

  Item {
    Layout.fillWidth: true
    Layout.preferredHeight: showArtistToggle.implicitHeight
    NToggle {
      id: showArtistToggle
      anchors.fill: parent
      label: tr("settings.display.show-artist", "显示歌手")
      checked: root.editShowArtist
    }
    MouseArea {
      anchors.fill: parent
      cursorShape: Qt.PointingHandCursor
      onClicked: {
        root.editShowArtist = !root.editShowArtist
        showArtistToggle.checked = root.editShowArtist
      }
    }
  }

  Item {
    Layout.fillWidth: true
    Layout.preferredHeight: showAlbumToggle.implicitHeight
    NToggle {
      id: showAlbumToggle
      anchors.fill: parent
      label: tr("settings.display.show-album", "显示专辑")
      checked: root.editShowAlbum
    }
    MouseArea {
      anchors.fill: parent
      cursorShape: Qt.PointingHandCursor
      onClicked: {
        root.editShowAlbum = !root.editShowAlbum
        showAlbumToggle.checked = root.editShowAlbum
      }
    }
  }

  Item {
    Layout.fillWidth: true
    Layout.preferredHeight: showProgressToggle.implicitHeight
    NToggle {
      id: showProgressToggle
      anchors.fill: parent
      label: tr("settings.display.show-progress", "显示进度条")
      checked: root.editShowProgress
    }
    MouseArea {
      anchors.fill: parent
      cursorShape: Qt.PointingHandCursor
      onClicked: {
        root.editShowProgress = !root.editShowProgress
        showProgressToggle.checked = root.editShowProgress
      }
    }
  }

  Item {
    Layout.fillWidth: true
    Layout.preferredHeight: showLyricToggle.implicitHeight
    NToggle {
      id: showLyricToggle
      anchors.fill: parent
      label: tr("settings.display.show-lyric", "显示歌词")
      checked: root.editShowLyric
    }
    MouseArea {
      anchors.fill: parent
      cursorShape: Qt.PointingHandCursor
      onClicked: {
        root.editShowLyric = !root.editShowLyric
        showLyricToggle.checked = root.editShowLyric
      }
    }
  }

  Item {
    Layout.fillWidth: true
    Layout.preferredHeight: preferYrcToggle.implicitHeight
    NToggle {
      id: preferYrcToggle
      anchors.fill: parent
      label: tr("settings.lyric.prefer-yrc", "优先逐字歌词(yrc)")
      checked: root.editPreferYrc
    }
    MouseArea {
      anchors.fill: parent
      cursorShape: Qt.PointingHandCursor
      onClicked: {
        root.editPreferYrc = !root.editPreferYrc
        preferYrcToggle.checked = root.editPreferYrc
      }
    }
  }

  Item {
    Layout.fillWidth: true
    Layout.preferredHeight: typewriterToggle.implicitHeight
    NToggle {
      id: typewriterToggle
      anchors.fill: parent
      label: tr("settings.lyric.typewriter-enabled", "逐字动画")
      checked: root.editTypewriterEnabled
    }
    MouseArea {
      anchors.fill: parent
      cursorShape: Qt.PointingHandCursor
      onClicked: {
        root.editTypewriterEnabled = !root.editTypewriterEnabled
        typewriterToggle.checked = root.editTypewriterEnabled
      }
    }
  }

  ColumnLayout {
    Layout.fillWidth: true
    spacing: Style.marginS
    enabled: root.editTypewriterEnabled

    NLabel {
      label: tr("settings.lyric.typewriter-interval", "逐字间隔(ms)") + ": " + root.editTypewriterIntervalMs
      description: tr("settings.lyric.typewriter-interval-desc", "每个字符显示间隔，越小越快")
    }

    NSpinBox {
      from: 10
      to: 300
      stepSize: 5
      value: root.editTypewriterIntervalMs
      onValueChanged: if (value !== root.editTypewriterIntervalMs) root.editTypewriterIntervalMs = value
    }
  }

  Item {
    Layout.fillWidth: true
    Layout.preferredHeight: openPanelToggle.implicitHeight
    NToggle {
      id: openPanelToggle
      anchors.fill: parent
      label: tr("settings.behavior.open-panel", "左键打开面板")
      checked: root.editOpenPanelOnClick
    }
    MouseArea {
      anchors.fill: parent
      cursorShape: Qt.PointingHandCursor
      onClicked: {
        root.editOpenPanelOnClick = !root.editOpenPanelOnClick
        openPanelToggle.checked = root.editOpenPanelOnClick
      }
    }
  }

  function saveSettings() {
    if (!pluginApi) return

    if (!pluginApi.pluginSettings) {
      try {
        pluginApi.pluginSettings = ({})
      } catch (e) {
        return
      }
    }

    pluginApi.pluginSettings.connection = {
      host: root.editHost,
      port: root.editPort,
      autoReconnect: root.editAutoReconnect,
      reconnectMs: root.editReconnectMs,
      heartbeatSec: root.editHeartbeatSec,
      websocatBin: root.editWebsocatBin
    }

    pluginApi.pluginSettings.display = {
      width: root.editWidth,
      minWidth: Math.min(root.editMinWidth, root.editWidth),
      showArtist: root.editShowArtist,
      showAlbum: root.editShowAlbum,
      showProgress: root.editShowProgress,
      showLyric: root.editShowLyric,
      emptyText: root.editEmptyText
    }

    pluginApi.pluginSettings.lyric = {
      preferYrc: root.editPreferYrc,
      typewriterEnabled: root.editTypewriterEnabled,
      typewriterIntervalMs: root.editTypewriterIntervalMs
    }

    pluginApi.pluginSettings.behavior = {
      openPanelOnClick: root.editOpenPanelOnClick
    }

    pluginApi.saveSettings()

    if (pluginApi.mainInstance) {
      pluginApi.mainInstance.reloadSettings()
      pluginApi.mainInstance.reconnect()
    }
  }
}
