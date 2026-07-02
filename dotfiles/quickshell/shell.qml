// ~/.config/quickshell/shell.qml — Catppuccin Mocha bar
// ─────────────────────────────────────────────────────────────────────────────
// A real top bar: logo · live workspaces · date/clock · live volume.
// Portable QML — hot-reloads on save. If it doesn't render, run `quickshell`
// in a terminal to read the QML error.  Docs: https://quickshell.org/docs/master/
//
// Icons are Nerd Font glyphs built with String.fromCharCode(0xXXXX) so the source
// stays pure-ASCII. If one shows as a box, that codepoint isn't in JetBrainsMono
// Nerd Font — change the hex.  0x2744 ❄ snowflake · 0xF028 vol-on · 0xF026 vol-off
// (For the exact NixOS logo use 0xF313 instead of the snowflake.)
// ─────────────────────────────────────────────────────────────────────────────

import Quickshell
import Quickshell.Hyprland
import Quickshell.Services.Pipewire
import QtQuick

ShellRoot {
    // Bind the default sink so we can read its volume/mute below.
    PwObjectTracker { objects: [Pipewire.defaultAudioSink] }

    Variants {
        model: Quickshell.screens

        PanelWindow {
            required property var modelData
            screen: modelData

            anchors { top: true; left: true; right: true }
            implicitHeight: 40
            color: "transparent"

            // Floating rounded bar (Mocha base @ ~90%)
            Rectangle {
                id: bar
                anchors.fill: parent
                anchors.leftMargin: 10
                anchors.rightMargin: 10
                anchors.topMargin: 8
                anchors.bottomMargin: 2
                radius: 14
                color: "#e61e1e2e"   // #AARRGGBB

                // ───────── LEFT: logo + live workspaces ─────────
                Row {
                    anchors.left: parent.left
                    anchors.leftMargin: 14
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 12

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: String.fromCharCode(0x2744)   // ❄ snowflake (0xF313 = NixOS logo)
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 18
                        color: "#89b4fa"
                    }

                    Row {
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 6
                        Repeater {
                            model: Hyprland.workspaces      // live; fallback: Hyprland.workspaces.values
                            delegate: Rectangle {
                                required property var modelData
                                width: modelData.focused ? 30 : 22
                                height: 22
                                radius: 11
                                color: modelData.focused ? "#89b4fa"
                                     : modelData.active  ? "#585b70"
                                     :                      "#313244"
                                Behavior on width { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }

                                Text {
                                    anchors.centerIn: parent
                                    text: modelData.id
                                    font.family: "JetBrainsMono Nerd Font"
                                    font.pixelSize: 12
                                    color: modelData.focused ? "#1e1e2e" : "#cdd6f4"
                                }
                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: modelData.activate()
                                }
                            }
                        }
                    }
                }

                // ───────── CENTER: date · clock ─────────
                Text {
                    id: clock
                    anchors.centerIn: parent
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 14
                    color: "#cdd6f4"

                    Timer {
                        interval: 1000; running: true; repeat: true; triggeredOnStart: true
                        onTriggered: clock.text =
                            Qt.formatDateTime(new Date(), "ddd d MMM  ·  hh:mm:ss")
                    }
                }

                // ───────── RIGHT: live volume ─────────
                Row {
                    id: volRow
                    anchors.right: parent.right
                    anchors.rightMargin: 16
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 8

                    property real vol: Pipewire.defaultAudioSink?.audio?.volume ?? 0
                    property bool muted: Pipewire.defaultAudioSink?.audio?.muted ?? false

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: volRow.muted ? String.fromCharCode(0xF026) : String.fromCharCode(0xF028)
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 16
                        color: "#cba6f7"
                    }
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: Math.round(volRow.vol * 100) + "%"
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 13
                        color: "#cdd6f4"
                    }
                }
            }
        }
    }
}
