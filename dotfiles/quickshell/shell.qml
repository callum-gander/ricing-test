// ~/.config/quickshell/shell.qml — Catppuccin Mocha bar + animated control-centre popups
// ─────────────────────────────────────────────────────────────────────────────
// logo(→launcher) · workspaces | clock | CPU/RAM · audio · net · bt · tray
// Click audio/net/bt → an animated dropdown (fade + slide). Auto-sizes to content.
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

                // ───────── LEFT: logo (→ launcher) + live workspaces ─────────
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
                        color: logoTap.hovered ? "#b4befe" : "#89b4fa"
                        Behavior on color { ColorAnimation { duration: 120 } }
                        TapHandler { id: logoTap; onTapped: rofiProc.running = true }
                        HoverHandler { id: logoHov }
                        property bool hovered: logoHov.hovered
                        Process { id: rofiProc; command: ["rofi", "-show", "drun"]; running: false }
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
                                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: modelData.activate() }
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

                    Row {
                        spacing: 6
                        Text { text: String.fromCharCode(0xF2DB); font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 14; color: "#a6e3a1" }
                        Text {
                            id: loadText; text: "—"
                            font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 13; color: "#cdd6f4"
                            Process { id: loadProc; command: ["sh", "-c", "cut -d' ' -f1 /proc/loadavg"]; running: true
                                stdout: StdioCollector { onStreamFinished: loadText.text = this.text.trim() } }
                            Timer { interval: 3000; running: true; repeat: true; onTriggered: loadProc.running = true }
                        }
                        Text {
                            id: ramText; text: "—"
                            font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 13; color: "#f9e2af"
                            Process { id: ramProc; command: ["sh", "-c", "free | awk 'NR==2{printf \"%d%%\", $3/$2*100}'"]; running: true
                                stdout: StdioCollector { onStreamFinished: ramText.text = this.text.trim() } }
                            Timer { interval: 3000; running: true; repeat: true; onTriggered: ramProc.running = true }
                        }
                    }

                    // audio
                    Row {
                        id: volRow
                        spacing: 6
                        property real vol: Pipewire.defaultAudioSink?.audio?.volume ?? 0
                        property bool muted: Pipewire.defaultAudioSink?.audio?.muted ?? false
                        TapHandler { onTapped: { netPopup.open = false; btPopup.open = false; audioPopup.open = !audioPopup.open } }
                        Text { text: volRow.muted ? String.fromCharCode(0xF026) : String.fromCharCode(0xF028); font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 16; color: "#cba6f7" }
                        Text { text: Math.round(volRow.vol * 100) + "%"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 13; color: "#cdd6f4" }
                    }

                    Text {
                        id: netIcon
                        anchors.verticalCenter: parent.verticalCenter
                        text: String.fromCharCode(0xF1EB)
                        font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 15; color: "#a6e3a1"
                        TapHandler { onTapped: { audioPopup.open = false; btPopup.open = false; netPopup.open = !netPopup.open } }
                    }

                    Text {
                        id: btIcon
                        anchors.verticalCenter: parent.verticalCenter
                        text: String.fromCharCode(0xF293)
                        font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 15; color: "#89b4fa"
                        TapHandler { onTapped: { audioPopup.open = false; netPopup.open = false; btPopup.open = !btPopup.open } }
                    }

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

            // ════════════ POPUPS (animated: fade + slide) ════════════

            PopupWindow {
                id: audioPopup
                property bool open: false
                parentWindow: panel
                relativeX: panel.width - 330
                relativeY: panel.height + 4
                visible: open || audioContent.opacity > 0.01
                implicitWidth: 300
                implicitHeight: audioCol.implicitHeight + 36
                color: "transparent"
                Rectangle {
                    id: audioContent
                    anchors.fill: parent
                    color: "#1e1e2e"; radius: 16; border.color: "#89b4fa"; border.width: 2
                    opacity: audioPopup.open ? 1 : 0
                    transform: Translate { y: audioPopup.open ? 0 : -8; Behavior on y { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } } }
                    Behavior on opacity { NumberAnimation { duration: 160 } }
                    Column {
                        id: audioCol
                        anchors { left: parent.left; right: parent.right; top: parent.top; margins: 18 }
                        spacing: 14
                        Item {
                            width: parent.width; height: 20
                            Text { anchors.left: parent.left; text: "Audio"; color: "#cdd6f4"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 15; font.bold: true }
                            Text { anchors.right: parent.right; text: Math.round((Pipewire.defaultAudioSink?.audio?.volume ?? 0) * 100) + "%"; color: "#89b4fa"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 15 }
                        }
                        Rectangle {
                            width: parent.width; height: 12; radius: 6; color: "#45475a"
                            Rectangle { width: parent.width * (Pipewire.defaultAudioSink?.audio?.volume ?? 0); height: parent.height; radius: 6; color: "#89b4fa" }
                            MouseArea {
                                anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                onPressed: (m) => { if (Pipewire.defaultAudioSink?.audio) Pipewire.defaultAudioSink.audio.volume = Math.max(0, Math.min(1, m.x / width)) }
                                onPositionChanged: (m) => { if (pressed && Pipewire.defaultAudioSink?.audio) Pipewire.defaultAudioSink.audio.volume = Math.max(0, Math.min(1, m.x / width)) }
                            }
                        }
                        Rectangle {
                            width: parent.width; height: 34; radius: 10
                            color: pavuMa.containsMouse ? "#585b70" : "#313244"
                            Behavior on color { ColorAnimation { duration: 120 } }
                            Text { anchors.centerIn: parent; text: "Open pavucontrol"; color: "#cdd6f4"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 13 }
                            MouseArea { id: pavuMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: { pavuProc.running = true; audioPopup.open = false } }
                        }
                    }
                }
                Process { id: pavuProc; command: ["pavucontrol"]; running: false }
            }

            PopupWindow {
                id: netPopup
                property bool open: false
                parentWindow: panel
                relativeX: panel.width - 290
                relativeY: panel.height + 4
                visible: open || netContent.opacity > 0.01
                implicitWidth: 270
                implicitHeight: netCol.implicitHeight + 36
                color: "transparent"
                onOpenChanged: if (open) netProc.running = true
                Rectangle {
                    id: netContent
                    anchors.fill: parent
                    color: "#1e1e2e"; radius: 16; border.color: "#89b4fa"; border.width: 2
                    opacity: netPopup.open ? 1 : 0
                    transform: Translate { y: netPopup.open ? 0 : -8; Behavior on y { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } } }
                    Behavior on opacity { NumberAnimation { duration: 160 } }
                    Column {
                        id: netCol
                        anchors { left: parent.left; right: parent.right; top: parent.top; margins: 18 }
                        spacing: 12
                        Text { text: "Network"; color: "#cdd6f4"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 15; font.bold: true }
                        Text {
                            id: netStatus; text: "…"; width: parent.width; wrapMode: Text.WordWrap
                            color: "#bac2de"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 13
                            Process { id: netProc; running: false
                                command: ["sh", "-c", "n=$(nmcli -t -f NAME connection show --active 2>/dev/null | head -1); [ -n \"$n\" ] && echo \"Connected · $n\" || echo Disconnected"]
                                stdout: StdioCollector { onStreamFinished: netStatus.text = this.text.trim() } }
                        }
                        Rectangle {
                            width: parent.width; height: 34; radius: 10
                            color: netMa.containsMouse ? "#585b70" : "#313244"
                            Behavior on color { ColorAnimation { duration: 120 } }
                            Text { anchors.centerIn: parent; text: "Network settings"; color: "#cdd6f4"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 13 }
                            MouseArea { id: netMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: { netCfgProc.running = true; netPopup.open = false } }
                        }
                    }
                }
                Process { id: netCfgProc; command: ["nm-connection-editor"]; running: false }
            }

            PopupWindow {
                id: btPopup
                property bool open: false
                parentWindow: panel
                relativeX: panel.width - 270
                relativeY: panel.height + 4
                visible: open || btContent.opacity > 0.01
                implicitWidth: 270
                implicitHeight: btCol.implicitHeight + 36
                color: "transparent"
                onOpenChanged: if (open) btProc.running = true
                Rectangle {
                    id: btContent
                    anchors.fill: parent
                    color: "#1e1e2e"; radius: 16; border.color: "#89b4fa"; border.width: 2
                    opacity: btPopup.open ? 1 : 0
                    transform: Translate { y: btPopup.open ? 0 : -8; Behavior on y { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } } }
                    Behavior on opacity { NumberAnimation { duration: 160 } }
                    Column {
                        id: btCol
                        anchors { left: parent.left; right: parent.right; top: parent.top; margins: 18 }
                        spacing: 12
                        Text { text: "Bluetooth"; color: "#cdd6f4"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 15; font.bold: true }
                        Text {
                            id: btStatus; text: "…"
                            color: "#bac2de"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 13
                            Process { id: btProc; running: false
                                command: ["sh", "-c", "bluetoothctl show 2>/dev/null | grep -q 'Powered: yes' && echo 'Powered on' || echo 'Off / no adapter'"]
                                stdout: StdioCollector { onStreamFinished: btStatus.text = this.text.trim() } }
                        }
                        Rectangle {
                            width: parent.width; height: 34; radius: 10
                            color: btMa.containsMouse ? "#585b70" : "#313244"
                            Behavior on color { ColorAnimation { duration: 120 } }
                            Text { anchors.centerIn: parent; text: "Open Blueman"; color: "#cdd6f4"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 13 }
                            MouseArea { id: btMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: { bluemanProc.running = true; btPopup.open = false } }
                        }
                    }
                }
                Process { id: bluemanProc; command: ["blueman-manager"]; running: false }
            }
        }
    }
}
