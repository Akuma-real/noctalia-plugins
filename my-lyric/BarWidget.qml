import QtQuick
import Quickshell
import qs.Services.UI
import qs.Modules.Bar.Extras
import "core/app" as App
import "core/ui" as Ui

Rectangle {
  id: root

  property var pluginApi: null
  property ShellScreen screen
  property string widgetId: ""
  property string section: ""

  color: "transparent"
  implicitWidth: view.implicitWidth
  implicitHeight: view.implicitHeight

  App.LyricWidgetController {
    id: controller
    pluginApi: root.pluginApi
  }

  Ui.LyricBarView {
    id: view
    anchors.fill: parent
    screen: root.screen
    widgetWidth: Number(controller.settings?.display?.width ?? 360)
    minWidgetWidth: Number(controller.settings?.display?.minWidth ?? 180)
    trackAdaptive: Boolean(controller.settings?.display?.trackAdaptive ?? true)
    trackLongestLine: controller.trackLongestLine
    showWhenEmpty: Boolean(controller.settings?.display?.showWhenEmpty ?? false)
    emptyText: (controller.settings?.display?.emptyText ?? "").toString()
    currentLine: controller.currentLine
    status: controller.status

    onLeftClicked: controller.refreshNow(true)
    onRightClicked: tip => TooltipService.show(root, tip, BarService.getTooltipDirection(root.screen?.name))
    onPointerExited: TooltipService.hide()
  }
}
