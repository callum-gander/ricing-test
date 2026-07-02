// ~/.config/quickshell/shell.qml — Catppuccin Mocha bar
// ─────────────────────────────────────────────────────────────────────────────
// logo · live workspaces | date/clock | CPU-load · RAM% · volume · system tray
// Portable QML — hot-reloads on save. Run `quickshell` in a terminal to see errors.
// Icons via String.fromCharCode(0xXXXX) so the source stays pure-ASCII.
// ─────────────────────────────────────────────────────────────────────────────

import Quickshell
import Quickshell.Hyprland
import Quickshell.Services.Pipewire
import Quickshell.Services.SystemTray
import Quickshell.Io
import QtQuick

ShellRoot {
    PwObjectTracker { objects: [Pipewire.defaultAudioSink] }

    Variants {
        model: Quickshell.screens

        PanelWindow {
            required property var modelData
            screen: modelData

            anchors { top: true; left: true; right: true }
            implicitHeight: 40
            color: "transparent"

            Rectangle {
                id: bar
                anchors.fill: parent
                anchors.leftMargin: 10
                anchors.rightMargin: 10
                anchors.topMargin: 8
                anchors.bottomMargin: 2
                radius: 14
                color: "#e61e1e2e"

                // ───────── LEFT: logo + live workspaces ─────────
                Row {
                    anchors.left: parent.left
                    anchors.leftMargin: 14
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 12

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: String.fromCharCode(0x2744)   // ❄ snowflake
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 18
                        color: "#89b4fa"
                    }

                    Row {
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 6
                        Repeater {
                            model: Hyprland.workspaces
                            delegate: Rectangle {
                                required property var modelData
                                visible: modelData.id > 0        // hide special workspaces (scratchpad = negative id)
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

                // ───────── CENTRE: date · clock ─────────
                Text {
                    id: clock
                    anchors.centerIn: parent
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 14
                    color: "#cdd6f4"
                    Timer {
                        interval: 1000; running: true; repeat: true; triggeredOnStart: true
                        onTriggered: clock.text = Qt.formatDateTime(new Date(), "ddd d MMM  ·  hh:mm:ss")
                    }
                }

                // ───────── RIGHT: resources · volume · tray ─────────
                Row {
                    anchors.right: parent.right
                    anchors.rightMargin: 16
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 18

                    // resources: CPU load + RAM%
                    Row {
                        spacing: 6
                        Text {
                            text: String.fromCharCode(0xF2DB)   // microchip
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 14
                            color: "#a6e3a1"
                        }
                        Text {
                            id: loadText
                            text: "—"
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 13
                            color: "#cdd6f4"
                            Process {
                                id: loadProc
                                command: ["sh", "-c", "cut -d' ' -f1 /proc/loadavg"]
                                running: true
                                stdout: StdioCollector { onStreamFinished: loadText.text = this.text.trim() }
                            }
                            Timer { interval: 3000; running: true; repeat: true; onTriggered: loadProc.running = true }
                        }
                        Text {
                            id: ramText
                            text: "—"
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 13
                            color: "#f9e2af"
                            Process {
                                id: ramProc
                                command: ["sh", "-c", "free | awk 'NR==2{printf \"%d%%\", $3/$2*100}'"]
                                running: true
                                stdout: StdioCollector { onStreamFinished: ramText.text = this.text.trim() }
                            }
                            Timer { interval: 3000; running: true; repeat: true; onTriggered: ramProc.running = true }
                        }
                    }

                    // volume
                    Row {
                        id: volRow
                        spacing: 6
                        property real vol: Pipewire.defaultAudioSink?.audio?.volume ?? 0
                        property bool muted: Pipewire.defaultAudioSink?.audio?.muted ?? false
                        TapHandler { onTapped: pavuProc.running = true }   // click → audio settings
                        Process { id: pavuProc; command: ["pavucontrol"]; running: false }
                        Text {
                            text: volRow.muted ? String.fromCharCode(0xF026) : String.fromCharCode(0xF028)
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 16
                            color: "#cba6f7"
                        }
                        Text {
                            text: Math.round(volRow.vol * 100) + "%"
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 13
                            color: "#cdd6f4"
                        }
                    }

                    // system tray (populates when tray apps are running)
                    Row {
                        spacing: 10
                        Repeater {
                            model: SystemTray.items
                            delegate: MouseArea {
                                required property var modelData
                                width: 18
                                height: 18
                                cursorShape: Qt.PointingHandCursor
                                onClicked: modelData.activate()
                                Image {
                                    anchors.fill: parent
                                    source: modelData.icon
                                    fillMode: Image.PreserveAspectFit
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
