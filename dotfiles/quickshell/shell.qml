// ~/.config/quickshell/shell.qml
// ─────────────────────────────────────────────────────────────────────────────
// Minimal Quickshell starter: a top bar (one per monitor) with a label + clock.
// Edit + save → Quickshell hot-reloads. This file is distro-agnostic.
// Docs: https://quickshell.org/docs/master/
// If it doesn't render, run `quickshell` (or `qs`) in a terminal to see errors.
// ─────────────────────────────────────────────────────────────────────────────

import Quickshell
import QtQuick

ShellRoot {
    // One PanelWindow per connected screen.
    Variants {
        model: Quickshell.screens

        PanelWindow {
            required property var modelData
            screen: modelData

            anchors {
                top: true
                left: true
                right: true
            }
            implicitHeight: 34
            color: "#1e1e2e"

            // Left: label
            Text {
                anchors.left: parent.left
                anchors.leftMargin: 16
                anchors.verticalCenter: parent.verticalCenter
                color: "#cdd6f4"
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 14
                text: "ricing-test"
            }

            // Center: live clock
            Text {
                id: clock
                anchors.centerIn: parent
                color: "#cdd6f4"
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 14

                Timer {
                    interval: 1000
                    running: true
                    repeat: true
                    triggeredOnStart: true
                    onTriggered: clock.text =
                        Qt.formatDateTime(new Date(), "ddd d MMM  hh:mm:ss")
                }
            }
        }
    }
}
