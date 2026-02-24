// BarWidget.qml – Noctalia bar widget that shows the current synced lyric line.
//
// Injected by Noctalia: pluginApi, screen, widgetId, section
// Requires: Quickshell + Quickshell.Io (ships with Noctalia ≥ 3.6.0)

import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Io

Item {
    // -----------------------------------------------------------------------
    // Properties injected by Noctalia's bar system
    // -----------------------------------------------------------------------
    property var    pluginApi
    property var    screen
    property string widgetId: ""
    property string section:  ""

    // -----------------------------------------------------------------------
    // Derived settings (fall back to safe defaults when pluginApi is not ready)
    // -----------------------------------------------------------------------
    readonly property string playerName: (pluginApi && pluginApi.settings)
        ? (pluginApi.settings.playerName || "splayer")
        : "splayer"

    readonly property int refreshMs: (pluginApi && pluginApi.settings)
        ? (pluginApi.settings.refreshMs  || 1000)
        : 1000

    // Absolute path to the bundled helper script
    readonly property string scriptPath: Qt.resolvedUrl("scripts/get-lyric.py")
        .toString()
        .replace(/^file:\/\//, "")

    // -----------------------------------------------------------------------
    // State
    // -----------------------------------------------------------------------
    property string currentLyric: ""

    implicitWidth:  lyricText.implicitWidth  + 16
    implicitHeight: lyricText.implicitHeight + 4

    // -----------------------------------------------------------------------
    // Poll timer
    // -----------------------------------------------------------------------
    Timer {
        interval:         refreshMs
        running:          true
        repeat:           true
        triggeredOnStart: true
        onTriggered: {
            if (!lyricProcess.running) {
                lyricProcess.running = true
            }
        }
    }

    // -----------------------------------------------------------------------
    // Child process that runs the Python helper
    // -----------------------------------------------------------------------
    Process {
        id: lyricProcess
        command: ["python3", scriptPath, "--player", playerName]
        running: false

        stdout: SplitParser {
            // Each full line emitted by the script updates the label
            onRead: data => { currentLyric = data }
        }
    }

    // -----------------------------------------------------------------------
    // Visual
    // -----------------------------------------------------------------------
    Text {
        id: lyricText
        anchors.centerIn: parent
        text:             currentLyric
        color:            "white"
        font.pixelSize:   12
        elide:            Text.ElideRight
        maximumLineCount: 1
    }
}
