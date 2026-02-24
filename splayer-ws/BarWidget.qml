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

  readonly property var mainInstance: pluginApi?.mainInstance

  readonly property var defaultDisplay: pluginApi?.manifest?.metadata?.defaultSettings?.display || ({})
  readonly property var defaultBehavior: pluginApi?.manifest?.metadata?.defaultSettings?.behavior || ({})

  readonly property var displayCfg: mainInstance?.settings?.display || defaultDisplay
  readonly property var behaviorCfg: mainInstance?.settings?.behavior || defaultBehavior

  readonly property int widgetWidth: Number(displayCfg?.width ?? 360)
  readonly property int minWidgetWidth: Number(displayCfg?.minWidth ?? 180)
  readonly property bool showArtist: Boolean(displayCfg?.showArtist ?? true)
  readonly property bool showAlbum: Boolean(displayCfg?.showAlbum ?? false)
  readonly property bool showProgress: Boolean(displayCfg?.showProgress ?? true)
  readonly property bool showLyric: Boolean(displayCfg?.showLyric ?? true)
  readonly property string emptyText: (displayCfg?.emptyText ?? "").toString()
  readonly property bool openPanelOnClick: Boolean(behaviorCfg?.openPanelOnClick ?? true)

  readonly property string connectionState: (mainInstance?.connectionState ?? "disconnected").toString()
  readonly property bool connected: connectionState === "connected"
  readonly property bool playing: Boolean(mainInstance?.isPlaying ?? false)

  readonly property string trackLine: {
    var name = (mainInstance?.trackName ?? "").toString().trim()
    var artist = (mainInstance?.artistName ?? "").toString().trim()
    var album = (mainInstance?.albumName ?? "").toString().trim()

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

  readonly property string lyricLine: (mainInstance?.currentLyric ?? "").toString().trim()
  readonly property string displayText: {
    if (!connected) return emptyText || (pluginApi?.tr("widget.disconnected") || "SPlayer 未连接")
    if (showLyric && lyricLine) return lyricLine
    if (trackLine) return trackLine
    return emptyText || (pluginApi?.tr("widget.empty") || "暂无播放信息")
  }

  readonly property real ratio: Number(mainInstance?.progressRatio ?? 0)
  readonly property bool showProgressLine: connected && showProgress && Number(mainInstance?.durationMs ?? 0) > 0

  implicitWidth: Math.max(minWidgetWidth, widgetWidth)
  implicitHeight: Style.capsuleHeight

  Rectangle {
    id: capsule
    anchors.fill: parent
    color: Style.capsuleColor
    radius: Style.radiusL
    border.color: Style.capsuleBorderColor
    border.width: Style.capsuleBorderWidth
    clip: true

    RowLayout {
      anchors {
        fill: parent
        leftMargin: Style.marginM
        rightMargin: Style.marginM
      }
      spacing: Style.marginS

      NIcon {
        icon: connected ? (playing ? "music" : "music-off") : "network-offline"
        applyUiScale: false
        color: connected ? Color.mPrimary : Color.mOnSurfaceVariant
      }

      NText {
        Layout.fillWidth: true
        text: root.displayText
        color: connected ? Color.mOnSurface : Color.mOnSurfaceVariant
        pointSize: Style.barFontSize
        elide: Text.ElideRight
      }
    }

    Rectangle {
      visible: root.showProgressLine
      anchors {
        left: parent.left
        right: parent.right
        bottom: parent.bottom
      }
      height: 2
      color: Color.mSurfaceVariant

      Rectangle {
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        width: parent.width * Math.max(0, Math.min(1, root.ratio))
        color: Color.mPrimary
      }
    }
  }

  NPopupContextMenu {
    id: contextMenu
    model: {
      var items = []
      if (mainInstance) {
        items.push({
          "label": playing ? (pluginApi?.tr("menu.pause") || "暂停") : (pluginApi?.tr("menu.play") || "播放"),
          "action": "toggle",
          "icon": playing ? "media-pause" : "media-play"
        })
        items.push({
          "label": pluginApi?.tr("menu.prev") || "上一首",
          "action": "prev",
          "icon": "media-prev"
        })
        items.push({
          "label": pluginApi?.tr("menu.next") || "下一首",
          "action": "next",
          "icon": "media-next"
        })
      }
      items.push({
        "label": pluginApi?.tr("menu.reconnect") || "重连",
        "action": "reconnect",
        "icon": "refresh"
      })
      items.push({
        "label": pluginApi?.tr("menu.settings") || "设置",
        "action": "settings",
        "icon": "settings"
      })
      return items
    }

    onTriggered: action => {
      contextMenu.close()
      PanelService.closeContextMenu(screen)

      if (action === "toggle") mainInstance?.sendControl("toggle")
      if (action === "prev") mainInstance?.sendControl("prev")
      if (action === "next") mainInstance?.sendControl("next")
      if (action === "reconnect") mainInstance?.reconnect()
      if (action === "settings" && pluginApi?.manifest) {
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
        pluginApi?.openPanel(root.screen, root)
      } else {
        mainInstance?.sendControl("toggle")
      }
    }

    onEntered: {
      TooltipService.show(root, root.displayText, BarService.getTooltipDirection(root.screen?.name))
    }
    onExited: TooltipService.hide()
  }
}
