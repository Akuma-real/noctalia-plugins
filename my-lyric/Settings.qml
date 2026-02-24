import QtQuick
import QtQuick.Layouts
import "core/app" as App
import "core/ui" as Ui

ColumnLayout {
  id: root
  property var pluginApi: null

  App.LyricSettingsController {
    id: controller
    pluginApi: root.pluginApi
  }

  Ui.SettingsPage {
    id: page
    Layout.fillWidth: true
    controller: controller
  }

  function saveSettings() {
    page.saveSettings()
  }
}
