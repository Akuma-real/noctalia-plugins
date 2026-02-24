import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Services.UI
import qs.Widgets
import "core/domain/LyricMatcher.js" as LyricMatcher

Item {
  id: root

  property var pluginApi: null
  readonly property var mainInstance: pluginApi?.mainInstance
  readonly property string coverSource: (mainInstance?.coverUrl || "").toString().trim()
  readonly property string trackText: (mainInstance?.trackName || (pluginApi?.tr("panel.empty") || "暂无播放信息")).toString()
  readonly property string artistAlbumText: {
    var artist = (mainInstance?.artistName || "").toString().trim()
    var album = (mainInstance?.albumName || "").toString().trim()
    if (artist && album) return artist + " · " + album
    return artist || album || ""
  }
  readonly property string currentLyricText: (mainInstance?.currentLyric || "").toString()
  readonly property string nextLyricText: (mainInstance?.nextLyric || "").toString()
  readonly property real progressValue: Math.max(0, Math.min(1, Number(mainInstance?.progressRatio || 0)))
  readonly property string connectionState: (mainInstance?.connectionState || "disconnected").toString()
  readonly property bool connected: connectionState === "connected"
  readonly property string connectionStateText: (pluginApi?.tr("panel.state." + connectionState) || connectionState)
  readonly property bool hasConnectionIssue: connectionState === "disconnected" || connectionState === "error"
  readonly property var lyricSourceLines: {
    var preferYrc = Boolean(mainInstance?.preferYrc ?? true)
    var yrcData = mainInstance?.yrcData
    var lrcData = mainInstance?.lrcData
    if (preferYrc && Array.isArray(yrcData) && yrcData.length > 0) return yrcData
    if (Array.isArray(lrcData) && lrcData.length > 0) return lrcData
    return []
  }
  readonly property var lyricPickResult: LyricMatcher.pickLines(lyricSourceLines, Number(mainInstance?.currentTimeMs || 0))
  readonly property int lyricCurrentIndex: Number(lyricPickResult?.index ?? -1)
  readonly property var lyricDisplayModel: {
    var source = Array.isArray(lyricSourceLines) ? lyricSourceLines : []
    var mapped = []
    for (var i = 0; i < source.length; i++) {
      var text = lineText(source[i])
      if (!text) continue
      mapped.push({
        "text": text,
        "sourceIndex": i
      })
    }
    if (mapped.length === 0) {
      var current = root.currentLyricText.toString().trim()
      var next = root.nextLyricText.toString().trim()
      if (current) {
        mapped.push({
          "text": current,
          "sourceIndex": 0
        })
      }
      if (next && next !== current) {
        mapped.push({
          "text": next,
          "sourceIndex": 1
        })
      }
    }
    return mapped
  }
  readonly property bool hasLyricLines: Array.isArray(lyricDisplayModel) && lyricDisplayModel.length > 0
  readonly property int lyricDisplayActiveIndex: {
    if (!hasLyricLines) return -1

    for (var i = 0; i < lyricDisplayModel.length; i++) {
      if (Number(lyricDisplayModel[i]?.sourceIndex ?? -1) === lyricCurrentIndex) return i
    }

    var current = root.currentLyricText.toString().trim()
    if (current) {
      for (var j = 0; j < lyricDisplayModel.length; j++) {
        if ((lyricDisplayModel[j]?.text || "").toString().trim() === current) return j
      }
    }
    return 0
  }

  readonly property real actionButtonSize: 34 * Style.uiScaleRatio
  readonly property real controlButtonSize: 46 * Style.uiScaleRatio
  readonly property real controlMainButtonSize: 56 * Style.uiScaleRatio

  readonly property var geometryPlaceholder: panelContainer
  property real contentPreferredWidth: 520 * Style.uiScaleRatio
  property real contentPreferredHeight: 620 * Style.uiScaleRatio
  readonly property bool allowAttach: true

  anchors.fill: parent

  function formatMs(ms) {
    var total = Math.max(0, Math.floor(Number(ms || 0) / 1000))
    var h = Math.floor(total / 3600)
    var m = Math.floor((total % 3600) / 60)
    var s = total % 60
    var mm = (m < 10 && h > 0) ? ("0" + m) : m
    var ss = (s < 10) ? ("0" + s) : s
    if (h > 0) return h + ":" + mm + ":" + ss
    return m + ":" + ss
  }

  function openSettings() {
    var screen = pluginApi?.panelOpenScreen
    if (screen && pluginApi?.manifest) {
      BarService.openPluginSettings(screen, pluginApi.manifest)
    }
  }

  function lineText(line) {
    if (line === undefined || line === null) return ""

    if (typeof line === "string" || typeof line === "number" || typeof line === "boolean") {
      var primitive = line.toString().trim()
      if (primitive) return primitive
      return ""
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
      if (value !== undefined && value !== null) {
        var mapped = value.toString().trim()
        if (mapped) return mapped
      }
    }

    var fallback = line.toString ? line.toString().trim() : ""
    if (fallback && fallback !== "[object Object]") return fallback
    return ""
  }

  function syncLyricViewCenter() {
    if (!lyricListView || lyricListView.count <= 0 || !root.hasLyricLines) return
    var target = root.lyricDisplayActiveIndex
    if (target < 0) target = 0
    if (target >= lyricListView.count) target = lyricListView.count - 1
    lyricListView.positionViewAtIndex(target, ListView.Center)
  }

  onLyricCurrentIndexChanged: lyricCenterTimer.restart()
  onLyricSourceLinesChanged: lyricCenterTimer.restart()
  onCurrentLyricTextChanged: lyricCenterTimer.restart()
  onNextLyricTextChanged: lyricCenterTimer.restart()

  Timer {
    id: lyricCenterTimer
    interval: 0
    repeat: false
    onTriggered: root.syncLyricViewCenter()
  }

  Rectangle {
    id: panelContainer
    anchors.fill: parent
    color: "transparent"

    ColumnLayout {
      anchors {
        fill: parent
        margins: Style.marginL
      }
      spacing: Style.marginM

      Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: 132 * Style.uiScaleRatio
        radius: Style.radiusL
        color: Color.mSurfaceVariant

        RowLayout {
          anchors {
            fill: parent
            margins: Style.marginM
          }
          spacing: Style.marginM

          Rectangle {
            Layout.preferredWidth: 84 * Style.uiScaleRatio
            Layout.preferredHeight: 84 * Style.uiScaleRatio
            radius: Style.radiusM
            color: Color.mSurface

            NImageRounded {
              anchors.fill: parent
              radius: Style.radiusM
              imagePath: root.coverSource
              fallbackIcon: mainInstance?.isPlaying ? "music" : "music-off"
              fallbackIconSize: Style.fontSizeXL * 1.4
              imageFillMode: Image.PreserveAspectCrop
              borderWidth: 0
            }
          }

          ColumnLayout {
            Layout.fillWidth: true
            spacing: Style.marginXS

            RowLayout {
              Layout.fillWidth: true
              Layout.preferredHeight: root.actionButtonSize
              spacing: Style.marginS

              NText {
                text: pluginApi?.tr("panel.title") || "SPlayer WS Adapter"
                pointSize: Style.fontSizeXS * Style.uiScaleRatio
                color: Qt.alpha(Color.mOnSurfaceVariant, 0.84)
                elide: Text.ElideRight
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignVCenter
              }

              Rectangle {
                Layout.preferredWidth: 7 * Style.uiScaleRatio
                Layout.preferredHeight: 7 * Style.uiScaleRatio
                Layout.alignment: Qt.AlignVCenter
                radius: width / 2
                color: "#4BC773"
                visible: root.connected
                opacity: 0.95
              }

              RowLayout {
                Layout.alignment: Qt.AlignVCenter
                spacing: Style.marginXS

                Rectangle {
                  Layout.preferredWidth: root.actionButtonSize
                  Layout.preferredHeight: root.actionButtonSize
                  radius: width / 2
                  color: reconnectMouse.containsMouse ? Qt.alpha(Color.mPrimary, 0.16) : "transparent"
                  border.width: reconnectMouse.containsMouse ? 0 : 1
                  border.color: Qt.alpha(Color.mOnSurfaceVariant, 0.2)

                  Behavior on color {
                    ColorAnimation {
                      duration: 140
                    }
                  }

                  NIcon {
                    anchors.centerIn: parent
                    icon: "refresh"
                    applyUiScale: false
                    color: Color.mOnSurface
                  }

                  MouseArea {
                    id: reconnectMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: mainInstance?.reconnect()
                  }
                }

                Rectangle {
                  Layout.preferredWidth: root.actionButtonSize
                  Layout.preferredHeight: root.actionButtonSize
                  radius: width / 2
                  color: settingsMouse.containsMouse ? Qt.alpha(Color.mPrimary, 0.16) : "transparent"
                  border.width: settingsMouse.containsMouse ? 0 : 1
                  border.color: Qt.alpha(Color.mOnSurfaceVariant, 0.2)

                  Behavior on color {
                    ColorAnimation {
                      duration: 140
                    }
                  }

                  NIcon {
                    anchors.centerIn: parent
                    icon: "settings"
                    applyUiScale: false
                    color: Color.mOnSurface
                  }

                  MouseArea {
                    id: settingsMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.openSettings()
                  }
                }
              }
            }

            NText {
              text: root.trackText
              pointSize: Style.fontSizeXL * Style.uiScaleRatio
              font.weight: Font.Bold
              color: Color.mOnSurface
              elide: Text.ElideRight
              Layout.fillWidth: true
            }

            NText {
              text: root.artistAlbumText
              pointSize: Style.fontSizeM * Style.uiScaleRatio
              color: Qt.alpha(Color.mOnSurfaceVariant, 0.88)
              elide: Text.ElideRight
              visible: text.length > 0
              Layout.fillWidth: true
            }
          }
        }
      }

      Rectangle {
        Layout.fillWidth: true
        Layout.topMargin: Style.marginXS
        Layout.preferredHeight: progressColumn.implicitHeight + Style.marginM * 2
        radius: Style.radiusL
        color: Color.mSurfaceVariant

        ColumnLayout {
          id: progressColumn
          anchors {
            fill: parent
            margins: Style.marginM
          }
          spacing: Style.marginS

          NText {
            text: (pluginApi?.tr("panel.connection") || "连接状态") + ": " + root.connectionStateText
            pointSize: Style.fontSizeS * Style.uiScaleRatio
            color: root.hasConnectionIssue ? "#DF5F5F" : "#D8A845"
            visible: !root.connected
          }

          RowLayout {
            Layout.fillWidth: true
            spacing: Style.marginS

            NText {
              text: formatMs(mainInstance?.currentTimeMs || 0)
              pointSize: Style.fontSizeXS * Style.uiScaleRatio
              color: Color.mOnSurfaceVariant
            }

            Item {
              Layout.fillWidth: true
              Layout.preferredHeight: 16 * Style.uiScaleRatio

              Rectangle {
                id: progressTrack
                anchors {
                  left: parent.left
                  right: parent.right
                  verticalCenter: parent.verticalCenter
                }
                height: 6 * Style.uiScaleRatio
                radius: height / 2
                color: Color.mSurface
              }

              Rectangle {
                id: progressFill
                anchors {
                  left: progressTrack.left
                  verticalCenter: progressTrack.verticalCenter
                }
                width: progressTrack.width * root.progressValue
                height: progressTrack.height
                radius: progressTrack.radius
                color: Color.mPrimary
              }

              Rectangle {
                width: 10 * Style.uiScaleRatio
                height: width
                radius: width / 2
                color: Color.mPrimary
                anchors.verticalCenter: progressTrack.verticalCenter
                x: Math.max(0, Math.min(progressTrack.width - width, progressFill.width - width / 2))
                visible: Number(mainInstance?.durationMs || 0) > 0
              }
            }

            NText {
              text: formatMs(mainInstance?.durationMs || 0)
              pointSize: Style.fontSizeXS * Style.uiScaleRatio
              color: Color.mOnSurfaceVariant
            }
          }
        }
      }

      Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: controlsRow.implicitHeight + Style.marginM * 2
        radius: Style.radiusL
        color: Color.mSurfaceVariant

        RowLayout {
          id: controlsRow
          anchors {
            fill: parent
            margins: Style.marginM
          }
          spacing: Style.marginL

          Item { Layout.fillWidth: true }

          Rectangle {
            Layout.preferredWidth: root.controlButtonSize
            Layout.preferredHeight: root.controlButtonSize
            radius: width / 2
            color: prevMouse.containsMouse ? Qt.alpha(Color.mPrimary, 0.14) : Qt.alpha(Color.mOnSurfaceVariant, 0.08)

            Behavior on color {
              ColorAnimation {
                duration: 140
              }
            }

            NIcon {
              anchors.centerIn: parent
              icon: "media-prev"
              applyUiScale: false
              color: Color.mOnSurface
            }

            MouseArea {
              id: prevMouse
              anchors.fill: parent
              hoverEnabled: true
              cursorShape: Qt.PointingHandCursor
              onClicked: mainInstance?.sendControl("prev")
            }
          }

          Rectangle {
            Layout.preferredWidth: root.controlMainButtonSize
            Layout.preferredHeight: root.controlMainButtonSize
            radius: width / 2
            color: toggleMouse.containsMouse ? Qt.alpha(Color.mPrimary, 0.28) : Qt.alpha(Color.mPrimary, 0.2)

            Behavior on color {
              ColorAnimation {
                duration: 140
              }
            }

            NIcon {
              anchors.centerIn: parent
              icon: mainInstance?.isPlaying ? "media-pause" : "media-play"
              applyUiScale: false
              color: Color.mOnSurface
            }

            MouseArea {
              id: toggleMouse
              anchors.fill: parent
              hoverEnabled: true
              cursorShape: Qt.PointingHandCursor
              onClicked: mainInstance?.sendControl("toggle")
            }
          }

          Rectangle {
            Layout.preferredWidth: root.controlButtonSize
            Layout.preferredHeight: root.controlButtonSize
            radius: width / 2
            color: nextMouse.containsMouse ? Qt.alpha(Color.mPrimary, 0.14) : Qt.alpha(Color.mOnSurfaceVariant, 0.08)

            Behavior on color {
              ColorAnimation {
                duration: 140
              }
            }

            NIcon {
              anchors.centerIn: parent
              icon: "media-next"
              applyUiScale: false
              color: Color.mOnSurface
            }

            MouseArea {
              id: nextMouse
              anchors.fill: parent
              hoverEnabled: true
              cursorShape: Qt.PointingHandCursor
              onClicked: mainInstance?.sendControl("next")
            }
          }

          Item { Layout.fillWidth: true }
        }
      }

      Rectangle {
        Layout.fillWidth: true
        Layout.fillHeight: true
        Layout.preferredHeight: 232 * Style.uiScaleRatio
        Layout.maximumHeight: 320 * Style.uiScaleRatio
        radius: Style.radiusL
        color: Color.mSurfaceVariant

        Item {
          id: lyricViewport
          anchors {
            fill: parent
            margins: Style.marginM
          }
          clip: true

          ListView {
            id: lyricListView
            anchors {
              fill: parent
              leftMargin: Style.marginS
              rightMargin: Style.marginS
            }
            model: root.lyricDisplayModel
            visible: root.hasLyricLines
            interactive: false
            spacing: Style.marginXS
            boundsBehavior: Flickable.StopAtBounds
            cacheBuffer: 220 * Style.uiScaleRatio
            currentIndex: root.lyricDisplayActiveIndex
            highlightMoveDuration: 240
            highlightMoveVelocity: -1

            Behavior on contentY {
              NumberAnimation {
                duration: 260
                easing.type: Easing.OutCubic
              }
            }

            delegate: Item {
              id: lyricDelegate
              width: lyricListView.width
              readonly property bool active: index === root.lyricDisplayActiveIndex
              readonly property real lineHeight: (lyricDelegate.active ? Style.fontSizeXL * 2.05 : Style.fontSizeM * 1.9) * Style.uiScaleRatio
              height: lineHeight

              NText {
                id: lyricText
                anchors {
                  left: parent.left
                  right: parent.right
                  top: parent.top
                  bottom: parent.bottom
                }
                text: (modelData?.text || "").toString()
                pointSize: (lyricDelegate.active ? Style.fontSizeXL : Style.fontSizeM) * Style.uiScaleRatio
                font.weight: lyricDelegate.active ? Font.DemiBold : Font.Normal
                color: lyricDelegate.active ? Color.mOnSurface : Qt.alpha(Color.mOnSurfaceVariant, 0.52)
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                wrapMode: Text.Wrap
                visible: text.length > 0
              }
            }

            onCountChanged: lyricCenterTimer.restart()
            onHeightChanged: lyricCenterTimer.restart()
            Component.onCompleted: lyricCenterTimer.restart()
          }

          Item {
            anchors.fill: lyricListView
            visible: lyricListView.visible
            z: 2

            Rectangle {
              anchors {
                left: parent.left
                right: parent.right
                top: parent.top
              }
              height: parent.height * 0.2
              gradient: Gradient {
                orientation: Gradient.Vertical
                GradientStop { position: 0.0; color: Qt.alpha(Color.mSurfaceVariant, 1.0) }
                GradientStop { position: 1.0; color: Qt.alpha(Color.mSurfaceVariant, 0.0) }
              }
            }

            Rectangle {
              anchors {
                left: parent.left
                right: parent.right
                bottom: parent.bottom
              }
              height: parent.height * 0.2
              gradient: Gradient {
                orientation: Gradient.Vertical
                GradientStop { position: 0.0; color: Qt.alpha(Color.mSurfaceVariant, 0.0) }
                GradientStop { position: 1.0; color: Qt.alpha(Color.mSurfaceVariant, 1.0) }
              }
            }
          }

          NText {
            anchors.centerIn: parent
            width: parent.width - Style.marginL * 2
            text: root.trackText
            pointSize: Style.fontSizeM * Style.uiScaleRatio
            color: Qt.alpha(Color.mOnSurfaceVariant, 0.78)
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.Wrap
            visible: !root.hasLyricLines
          }
        }
      }
    }
  }
}
