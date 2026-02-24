// Settings.qml – Plugin settings panel for the my-lyric bar widget.
//
// Noctalia renders this inside its plugin-settings dialog.
// Implement saveSettings() to persist user changes via pluginApi.

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    // Injected by Noctalia
    property var pluginApi

    // Local copies of the settings (initialised from pluginApi.settings)
    property string settingPlayerName: (pluginApi && pluginApi.settings)
        ? (pluginApi.settings.playerName || "splayer")
        : "splayer"

    property int settingRefreshMs: (pluginApi && pluginApi.settings)
        ? (pluginApi.settings.refreshMs  || 1000)
        : 1000

    // ------------------------------------------------------------------
    // Called by Noctalia when the user confirms the settings dialog
    // ------------------------------------------------------------------
    function saveSettings() {
        if (!pluginApi) return
        pluginApi.saveSettings({
            playerName: playerNameField.text || "splayer",
            refreshMs:  parseInt(refreshMsField.text) || 1000
        })
    }

    implicitWidth:  400
    implicitHeight: mainLayout.implicitHeight + 32

    ColumnLayout {
        id: mainLayout
        anchors {
            top:    parent.top
            left:   parent.left
            right:  parent.right
            margins: 16
        }
        spacing: 12

        // ── Player name ─────────────────────────────────────────────
        Label { text: "MPRIS player name" }

        TextField {
            id:               playerNameField
            Layout.fillWidth: true
            text:             settingPlayerName
            placeholderText:  "splayer"
        }

        Label {
            text:    "The name reported by playerctl (e.g. splayer, mpv, vlc)."
            opacity: 0.6
            font.pixelSize: 11
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
        }

        // ── Refresh interval ────────────────────────────────────────
        Label { text: "Refresh interval (ms)" }

        TextField {
            id:               refreshMsField
            Layout.fillWidth: true
            text:             settingRefreshMs.toString()
            placeholderText:  "1000"
            validator: IntValidator { bottom: 100; top: 10000 }
            inputMethodHints: Qt.ImhDigitsOnly
        }

        Label {
            text:    "How often the widget polls for the current lyric line (100 – 10 000 ms)."
            opacity: 0.6
            font.pixelSize: 11
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
        }

        // ── Save button ─────────────────────────────────────────────
        Button {
            text:    "Save"
            Layout.alignment: Qt.AlignRight
            onClicked: saveSettings()
        }
    }
}
