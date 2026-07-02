// ~/.config/quickshell/shell.qml — Catppuccin Mocha bar + control-centre popups
// ─────────────────────────────────────────────────────────────────────────────
// logo · workspaces | clock | CPU/RAM · audio · net · bt · tray
// Click audio/net/bt → a styled dropdown (level/status + "open full app").
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
            id: panel
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
                        text: String.fromCharCode(0x2744)
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
                                visible: modelData.id > 0
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

                // ───────── CENTRE: clock ─────────
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

                // ───────── RIGHT: resources · audio · net · bt · tray ─────────
                Row {
                    anchors.right: parent.right
                    anchors.rightMargin: 16
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 16

                    // resources
                    Row {
                        spacing: 6
                        Text {
                            text: String.fromCharCode(0xF2DB)
                            font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 14; color: "#a6e3a1"
                        }
                        Text {
                            id: loadText; text: "—"
                            font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 13; color: "#cdd6f4"
                            Process {
                                id: loadProc
                                command: ["sh", "-c", "cut -d' ' -f1 /proc/loadavg"]
                                running: true
                                stdout: StdioCollector { onStreamFinished: loadText.text = this.text.trim() }
                            }
                            Timer { interval: 3000; running: true; repeat: true; onTriggered: loadProc.running = true }
                        }
                        Text {
                            id: ramText; text: "—"
                            font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 13; color: "#f9e2af"
                            Process {
                                id: ramProc
                                command: ["sh", "-c", "free | awk 'NR==2{printf \"%d%%\", $3/$2*100}'"]
                                running: true
                                stdout: StdioCollector { onStreamFinished: ramText.text = this.text.trim() }
                            }
                            Timer { interval: 3000; running: true; repeat: true; onTriggered: ramProc.running = true }
                        }
                    }

                    // audio (click → audioPopup)
                    Row {
                        id: volRow
                        spacing: 6
                        property real vol: Pipewire.defaultAudioSink?.audio?.volume ?? 0
                        property bool muted: Pipewire.defaultAudioSink?.audio?.muted ?? false
                        TapHandler { onTapped: { netPopup.visible = false; btPopup.visible = false; audioPopup.visible = !audioPopup.visible } }
                        Text {
                            text: volRow.muted ? String.fromCharCode(0xF026) : String.fromCharCode(0xF028)
                            font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 16; color: "#cba6f7"
                        }
                        Text {
                            text: Math.round(volRow.vol * 100) + "%"
                            font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 13; color: "#cdd6f4"
                        }
                    }

                    // network (click → netPopup)
                    Text {
                        id: netIcon
                        anchors.verticalCenter: parent.verticalCenter
                        text: String.fromCharCode(0xF1EB)
                        font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 15; color: "#a6e3a1"
                        TapHandler { onTapped: { audioPopup.visible = false; btPopup.visible = false; netPopup.visible = !netPopup.visible } }
                    }

                    // bluetooth (click → btPopup)
                    Text {
                        id: btIcon
                        anchors.verticalCenter: parent.verticalCenter
                        text: String.fromCharCode(0xF293)
                        font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 15; color: "#89b4fa"
                        TapHandler { onTapped: { audioPopup.visible = false; netPopup.visible = false; btPopup.visible = !btPopup.visible } }
                    }

                    // system tray
                    Row {
                        spacing: 10
                        Repeater {
                            model: SystemTray.items
                            delegate: MouseArea {
                                required property var modelData
                                width: 18; height: 18
                                cursorShape: Qt.PointingHandCursor
                                onClicked: modelData.activate()
                                Image { anchors.fill: parent; source: modelData.icon; fillMode: Image.PreserveAspectFit }
                            }
                        }
                    }
                }
            }

            // ════════════ POPUPS ════════════

            // ---- Audio ----
            PopupWindow {
                id: audioPopup
                parentWindow: panel
                relativeX: panel.width - 320
                relativeY: panel.height + 2
                visible: false
                implicitWidth: 290
                implicitHeight: 150
                color: "transparent"
                Rectangle {
                    anchors.fill: parent; anchors.margins: 6
                    color: "#f21e1e2e"; radius: 14; border.color: "#89b4fa"; border.width: 2
                    Column {
                        anchors.fill: parent; anchors.margins: 16; spacing: 14
                        Item {
                            width: parent.width; height: 20
                            Text { anchors.left: parent.left; text: "Audio"; color: "#cdd6f4"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 15; font.bold: true }
                            Text { anchors.right: parent.right; text: Math.round((Pipewire.defaultAudioSink?.audio?.volume ?? 0) * 100) + "%"; color: "#89b4fa"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 15 }
                        }
                        Rectangle {
                            width: parent.width; height: 12; radius: 6; color: "#45475a"
                            Rectangle {
                                width: parent.width * (Pipewire.defaultAudioSink?.audio?.volume ?? 0)
                                height: parent.height; radius: 6; color: "#89b4fa"
                            }
                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onPressed: (m) => { if (Pipewire.defaultAudioSink?.audio) Pipewire.defaultAudioSink.audio.volume = Math.max(0, Math.min(1, m.x / width)) }
                                onPositionChanged: (m) => { if (pressed && Pipewire.defaultAudioSink?.audio) Pipewire.defaultAudioSink.audio.volume = Math.max(0, Math.min(1, m.x / width)) }
                            }
                        }
                        Rectangle {
                            width: parent.width; height: 34; radius: 10
                            color: pavuMa.containsMouse ? "#585b70" : "#313244"
                            Text { anchors.centerIn: parent; text: "Open pavucontrol"; color: "#cdd6f4"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 13 }
                            MouseArea { id: pavuMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: { pavuProc.running = true; audioPopup.visible = false } }
                        }
                    }
                }
                Process { id: pavuProc; command: ["pavucontrol"]; running: false }
            }

            // ---- Network ----
            PopupWindow {
                id: netPopup
                parentWindow: panel
                relativeX: panel.width - 280
                relativeY: panel.height + 2
                visible: false
                implicitWidth: 260
                implicitHeight: 120
                color: "transparent"
                onVisibleChanged: if (visible) netProc.running = true
                Rectangle {
                    anchors.fill: parent; anchors.margins: 6
                    color: "#f21e1e2e"; radius: 14; border.color: "#89b4fa"; border.width: 2
                    Column {
                        anchors.fill: parent; anchors.margins: 16; spacing: 12
                        Text { text: "Network"; color: "#cdd6f4"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 15; font.bold: true }
                        Text {
                            id: netStatus; text: "…"
                            width: parent.width; wrapMode: Text.WordWrap
                            color: "#bac2de"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 13
                            Process {
                                id: netProc
                                command: ["sh", "-c", "n=$(nmcli -t -f NAME connection show --active 2>/dev/null | head -1); [ -n \"$n\" ] && echo \"Connected · $n\" || echo Disconnected"]
                                running: false
                                stdout: StdioCollector { onStreamFinished: netStatus.text = this.text.trim() }
                            }
                        }
                        Rectangle {
                            width: parent.width; height: 34; radius: 10
                            color: netMa.containsMouse ? "#585b70" : "#313244"
                            Text { anchors.centerIn: parent; text: "Network settings"; color: "#cdd6f4"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 13 }
                            MouseArea { id: netMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: { netCfgProc.running = true; netPopup.visible = false } }
                        }
                    }
                }
                Process { id: netCfgProc; command: ["nm-connection-editor"]; running: false }
            }

            // ---- Bluetooth ----
            PopupWindow {
                id: btPopup
                parentWindow: panel
                relativeX: panel.width - 260
                relativeY: panel.height + 2
                visible: false
                implicitWidth: 260
                implicitHeight: 120
                color: "transparent"
                onVisibleChanged: if (visible) btProc.running = true
                Rectangle {
                    anchors.fill: parent; anchors.margins: 6
                    color: "#f21e1e2e"; radius: 14; border.color: "#89b4fa"; border.width: 2
                    Column {
                        anchors.fill: parent; anchors.margins: 16; spacing: 12
                        Text { text: "Bluetooth"; color: "#cdd6f4"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 15; font.bold: true }
                        Text {
                            id: btStatus; text: "…"
                            color: "#bac2de"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 13
                            Process {
                                id: btProc
                                command: ["sh", "-c", "bluetoothctl show 2>/dev/null | grep -q 'Powered: yes' && echo 'Powered on' || echo 'Off / no adapter'"]
                                running: false
                                stdout: StdioCollector { onStreamFinished: btStatus.text = this.text.trim() }
                            }
                        }
                        Rectangle {
                            width: parent.width; height: 34; radius: 10
                            color: btMa.containsMouse ? "#585b70" : "#313244"
                            Text { anchors.centerIn: parent; text: "Open Blueman"; color: "#cdd6f4"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 13 }
                            MouseArea { id: btMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: { bluemanProc.running = true; btPopup.visible = false } }
                        }
                    }
                }
                Process { id: bluemanProc; command: ["blueman-manager"]; running: false }
            }
        }
    }
}
