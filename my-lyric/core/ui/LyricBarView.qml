import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.Commons
import qs.Widgets

Rectangle {
  id: root

  property ShellScreen screen
  property int widgetWidth: 360
  property int minWidgetWidth: 180
  property bool trackAdaptive: true
  property string trackLongestLine: ""
  property bool showWhenEmpty: false
  property string emptyText: ""
  property string currentLine: ""
  property string status: ""

  signal leftClicked()
  signal rightClicked(string tip)
  signal pointerExited()

  readonly property string screenName: screen ? screen.name : ""
  readonly property string barPosition: Settings.getBarPositionForScreen(screenName)
  readonly property bool isVertical: barPosition === "left" || barPosition === "right"
  readonly property real capsuleHeight: Style.getCapsuleHeightForScreen(screenName)
  readonly property real barFontSize: Style.getBarFontSizeForScreen(screenName)
  readonly property bool hasLine: currentLine.trim().length > 0
  readonly property bool visibleContent: hasLine || showWhenEmpty
  readonly property int minWidthResolved: Math.max(120, Math.round(minWidgetWidth || 0))
  readonly property int maxWidthResolved: Math.max(minWidthResolved, Math.round(widgetWidth || 0))
  readonly property int autoWidthEstimate: Math.round(
    metrics.advanceWidth
    + iconItem.implicitWidth
    + rowContent.spacing
    + rowContent.anchors.leftMargin
    + rowContent.anchors.rightMargin
  )
  readonly property int resolvedContentWidth: trackAdaptive
    ? Math.max(minWidthResolved, Math.min(maxWidthResolved, autoWidthEstimate))
    : maxWidthResolved

  implicitHeight: capsuleHeight
  implicitWidth: isVertical ? capsuleHeight : (visibleContent ? resolvedContentWidth : capsuleHeight)
  color: "transparent"

  TextMetrics {
    id: metrics
    text: root.trackLongestLine || root.currentLine || root.emptyText
    font.pointSize: root.barFontSize
  }

  Rectangle {
    id: capsule
    x: Style.pixelAlignCenter(parent.width, width)
    y: Style.pixelAlignCenter(parent.height, height)
    width: Style.toOdd(root.implicitWidth)
    height: Style.toOdd(root.implicitHeight)
    radius: Style.radiusM
    color: Style.capsuleColor
    border.color: Style.capsuleBorderColor
    border.width: Style.capsuleBorderWidth
    clip: true

    RowLayout {
      id: rowContent
      anchors.fill: parent
      anchors.leftMargin: Style.marginS
      anchors.rightMargin: Style.marginS
      spacing: Style.marginS

      NIcon {
        id: iconItem
        icon: "music"
        applyUiScale: false
        color: Color.mPrimary
      }

      NScrollText {
        Layout.fillWidth: true
        Layout.preferredHeight: capsule.height
        text: root.hasLine ? root.currentLine : root.emptyText
        scrollMode: NScrollText.ScrollMode.Hover
        gradientColor: Style.capsuleColor
        gradientWidth: Math.round(8 * Style.uiScaleRatio)
        cornerRadius: Style.radiusM

        NText {
          color: root.hasLine ? Color.mPrimary : Color.mOnSurfaceVariant
          pointSize: root.barFontSize
          elide: Text.ElideNone
        }
      }
    }
  }

  MouseArea {
    anchors.fill: parent
    hoverEnabled: true
    acceptedButtons: Qt.LeftButton | Qt.RightButton

    onClicked: mouse => {
      if (mouse.button === Qt.LeftButton) {
        root.leftClicked()
      } else {
        var tip = root.currentLine || root.status
        if (tip) root.rightClicked(tip)
      }
    }

    onExited: root.pointerExited()
  }
}
