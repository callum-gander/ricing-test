// ~/.config/quickshell/shell.qml — Editorial Paper bar + control-centre popups
// ─────────────────────────────────────────────────────────────────────────────
// Warm-paper masthead: pilcrow(→launcher) · 一二三 workspaces · now-playing |
// clock (Playfair) | cpu·ram · audio · net · bt · tray.
// Popups: sharp corners, 1px hairline, rust accent; slide+fade, click-outside dismiss.
// Icons via String.fromCharCode(0xXXXX) so the source stays pure-ASCII.
//
// PALETTE (Editorial Paper)          FONTS
//   surface  #faf8f2  raised           Playfair Display   clock · titles · wordmark
//   base     #f4f1e8  desktop          Noto Sans          UI text · values · labels
//   panel    #ece7dd  inset/tracks     Noto Serif CJK SC  一 二 三 workspace numerals
//   ink      #1b1916  primary text     JetBrainsMono NF   functional glyphs (icons)
//   muted    #8b8475  secondary
//   hairline #d9d2c5  1px rules
//   accent   #a35e3a  rust (focus/active/selection)
// ─────────────────────────────────────────────────────────────────────────────

import Quickshell
import Quickshell.Hyprland
import Quickshell.Services.Pipewire
import Quickshell.Services.SystemTray
import Quickshell.Services.Mpris
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
            implicitHeight: 38
            color: "transparent"

            // dismiss any popup when clicking outside it
            HyprlandFocusGrab {
                windows: [audioPopup, netPopup, btPopup, sysPopup]
                active: audioPopup.open || netPopup.open || btPopup.open || sysPopup.open
                onCleared: { audioPopup.open = false; netPopup.open = false; btPopup.open = false; sysPopup.open = false }
            }

            Rectangle {
                id: bar
                anchors.fill: parent
                color: "#faf8f2"                       // opaque paper masthead

                // masthead underline — a single warm hairline rule
                Rectangle {
                    anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
                    height: 1
                    color: "#d9d2c5"
                }

                // ───────── LEFT: wordmark(→launcher) · workspaces · now-playing ─────────
                Row {
                    anchors.left: parent.left
                    anchors.leftMargin: 16
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 16

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: String.fromCharCode(0x00B6)      // ¶ pilcrow — editorial launcher mark
                        font.family: "Playfair Display"
                        font.pixelSize: 20
                        color: logoHov.hovered ? "#a35e3a" : "#1b1916"
                        Behavior on color { ColorAnimation { duration: 120 } }
                        TapHandler { onTapped: rofiProc.running = true }
                        HoverHandler { id: logoHov }
                        Process { id: rofiProc; command: ["rofi", "-show", "drun"]; running: false }
                    }

                    Row {
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 2
                        Repeater {
                            model: Hyprland.workspaces
                            delegate: Item {
                                required property var modelData
                                visible: modelData.id > 0
                                width: 24
                                height: 34
                                Column {
                                    anchors.centerIn: parent
                                    spacing: 3
                                    Text {
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        // Chinese numerals 一二三四… built from code points (ASCII-safe source)
                                        text: {
                                            var pts = [0x4E00, 0x4E8C, 0x4E09, 0x56DB, 0x4E94,
                                                       0x516D, 0x4E03, 0x516B, 0x4E5D, 0x5341];
                                            return (modelData.id >= 1 && modelData.id <= 10)
                                                ? String.fromCharCode(pts[modelData.id - 1])
                                                : "" + modelData.id;
                                        }
                                        font.family: "Noto Serif CJK SC"
                                        font.pixelSize: 17
                                        color: modelData.focused ? "#a35e3a" : "#1b1916"
                                        Behavior on color { ColorAnimation { duration: 120 } }
                                    }
                                    Rectangle {
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        width: 16; height: 2
                                        color: "#a35e3a"
                                        opacity: modelData.focused ? 1 : 0
                                        Behavior on opacity { NumberAnimation { duration: 150 } }
                                    }
                                }
                                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: modelData.activate() }
                            }
                        }
                    }

                    // now-playing (MPRIS) — hidden when nothing is playing
                    Row {
                        id: mediaRow
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 8
                        property var player: (Mpris.players && Mpris.players.values && Mpris.players.values.length > 0) ? Mpris.players.values[0] : null
                        visible: player !== null
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: (mediaRow.player && mediaRow.player.isPlaying) ? String.fromCharCode(0xF04C) : String.fromCharCode(0xF04B)
                            font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 13; color: "#8b8475"
                            TapHandler { onTapped: if (mediaRow.player) mediaRow.player.togglePlaying() }
                        }
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            width: 240; elide: Text.ElideRight
                            text: mediaRow.player ? (mediaRow.player.trackTitle + (mediaRow.player.trackArtist ? "  ·  " + mediaRow.player.trackArtist : "")) : ""
                            font.family: "Noto Sans"; font.pixelSize: 13; color: "#1b1916"
                        }
                    }
                }

                // ───────── CENTRE: clock ─────────
                Text {
                    id: clock
                    anchors.centerIn: parent
                    font.family: "Playfair Display"; font.pixelSize: 16; color: "#1b1916"
                    Timer {
                        interval: 1000; running: true; repeat: true; triggeredOnStart: true
                        onTriggered: clock.text = Qt.formatDateTime(new Date(), "dddd, d MMMM  ·  HH:mm")
                    }
                }

                // ───────── RIGHT: resources · audio · net · bt · tray ─────────
                Row {
                    anchors.right: parent.right
                    anchors.rightMargin: 18
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 16

                    Row {
                        id: resRow
                        spacing: 12
                        property real prevIdle: -1
                        property real prevTotal: -1
                        property real cpuPct: 0
                        property real ramPct: 0
                        property string ramDetail: ""
                        property string loadStr: ""
                        property string uptimeStr: ""
                        TapHandler { onTapped: { audioPopup.open = false; netPopup.open = false; btPopup.open = false; sysPopup.open = !sysPopup.open } }

                        Row {
                            spacing: 5
                            Text { text: String.fromCharCode(0xF2DB); font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 14; color: "#8b8475" }
                            Text { id: cpuText; text: "0%"; font.family: "Noto Sans"; font.pixelSize: 13; color: "#1b1916" }
                        }
                        Row {
                            spacing: 5
                            Text { text: String.fromCharCode(0xF1C0); font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 13; color: "#8b8475" }
                            Text { id: ramText; text: "0%"; font.family: "Noto Sans"; font.pixelSize: 13; color: "#1b1916" }
                        }

                        Process {
                            id: cpuProc
                            command: ["sh", "-c", "head -1 /proc/stat"]
                            running: true
                            stdout: StdioCollector {
                                onStreamFinished: {
                                    var f = this.text.trim().split(/\s+/);
                                    var idle = parseInt(f[4]) + parseInt(f[5]);
                                    var total = 0;
                                    for (var i = 1; i < f.length; i++) total += parseInt(f[i]);
                                    if (resRow.prevTotal >= 0) {
                                        var dt = total - resRow.prevTotal;
                                        var di = idle - resRow.prevIdle;
                                        var pct = dt > 0 ? Math.round((1 - di / dt) * 100) : 0;
                                        resRow.cpuPct = pct;
                                        cpuText.text = pct + "%";
                                    }
                                    resRow.prevIdle = idle;
                                    resRow.prevTotal = total;
                                }
                            }
                        }
                        Timer { interval: 2000; running: true; repeat: true; onTriggered: cpuProc.running = true }
                        Process {
                            id: ramProc
                            command: ["sh", "-c", "free -m | awk 'NR==2{printf \"%d %d %d\", $3, $2, $3/$2*100}'"]
                            running: true
                            stdout: StdioCollector {
                                onStreamFinished: {
                                    var p = this.text.trim().split(/\s+/);
                                    resRow.ramPct = parseInt(p[2]);
                                    ramText.text = p[2] + "%";
                                    resRow.ramDetail = (parseInt(p[0]) / 1024).toFixed(1) + " / " + (parseInt(p[1]) / 1024).toFixed(1) + " GB";
                                }
                            }
                        }
                        Timer { interval: 2000; running: true; repeat: true; onTriggered: ramProc.running = true }
                        Process { id: loadProc; command: ["sh", "-c", "cut -d' ' -f1-3 /proc/loadavg"]; running: true
                            stdout: StdioCollector { onStreamFinished: resRow.loadStr = this.text.trim() } }
                        Timer { interval: 5000; running: true; repeat: true; onTriggered: loadProc.running = true }
                        Process { id: uptimeProc; command: ["sh", "-c", "uptime -p | sed 's/^up //'"]; running: true
                            stdout: StdioCollector { onStreamFinished: resRow.uptimeStr = this.text.trim() } }
                        Timer { interval: 30000; running: true; repeat: true; onTriggered: uptimeProc.running = true }
                    }

                    Row {
                        id: volRow
                        spacing: 6
                        property real vol: Pipewire.defaultAudioSink?.audio?.volume ?? 0
                        property bool muted: Pipewire.defaultAudioSink?.audio?.muted ?? false
                        TapHandler { onTapped: { sysPopup.open = false; netPopup.open = false; btPopup.open = false; audioPopup.open = !audioPopup.open } }
                        Text { text: volRow.muted ? String.fromCharCode(0xF026) : String.fromCharCode(0xF028); font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 16; color: "#8b8475" }
                        Text { text: Math.round(volRow.vol * 100) + "%"; font.family: "Noto Sans"; font.pixelSize: 13; color: "#1b1916" }
                    }

                    Text {
                        id: netIcon
                        anchors.verticalCenter: parent.verticalCenter
                        text: String.fromCharCode(0xF1EB)
                        font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 15; color: "#8b8475"
                        TapHandler { onTapped: { sysPopup.open = false; audioPopup.open = false; btPopup.open = false; netPopup.open = !netPopup.open } }
                    }

                    Text {
                        id: btIcon
                        anchors.verticalCenter: parent.verticalCenter
                        text: String.fromCharCode(0xF293)
                        font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 15; color: "#8b8475"
                        TapHandler { onTapped: { sysPopup.open = false; audioPopup.open = false; netPopup.open = false; btPopup.open = !btPopup.open } }
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

            // ════════════ POPUPS ════════════

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
                    color: "#faf8f2"; radius: 0; border.color: "#d9d2c5"; border.width: 1
                    opacity: audioPopup.open ? 1 : 0
                    transform: Translate { y: audioPopup.open ? 0 : -8; Behavior on y { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } } }
                    Behavior on opacity { NumberAnimation { duration: 160 } }
                    Column {
                        id: audioCol
                        anchors { left: parent.left; right: parent.right; top: parent.top; margins: 18 }
                        spacing: 14
                        Item {
                            width: parent.width; height: 22
                            Text { anchors.left: parent.left; text: "Audio"; color: "#1b1916"; font.family: "Playfair Display"; font.pixelSize: 16; font.bold: true }
                            Text { anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter; text: Math.round((Pipewire.defaultAudioSink?.audio?.volume ?? 0) * 100) + "%"; color: "#a35e3a"; font.family: "Noto Sans"; font.pixelSize: 14 }
                        }
                        Rectangle {
                            width: parent.width; height: 10; radius: 0; color: "#ece7dd"
                            Rectangle { width: parent.width * (Pipewire.defaultAudioSink?.audio?.volume ?? 0); height: parent.height; radius: 0; color: "#a35e3a" }
                            MouseArea {
                                anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                onPressed: (m) => { if (Pipewire.defaultAudioSink?.audio) Pipewire.defaultAudioSink.audio.volume = Math.max(0, Math.min(1, m.x / width)) }
                                onPositionChanged: (m) => { if (pressed && Pipewire.defaultAudioSink?.audio) Pipewire.defaultAudioSink.audio.volume = Math.max(0, Math.min(1, m.x / width)) }
                            }
                        }
                        Rectangle {
                            width: parent.width; height: 34; radius: 0
                            color: pavuMa.containsMouse ? "#e2dccd" : "#ece7dd"
                            Behavior on color { ColorAnimation { duration: 120 } }
                            Text { anchors.centerIn: parent; text: "Open pavucontrol"; color: "#1b1916"; font.family: "Noto Sans"; font.pixelSize: 13 }
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
                    color: "#faf8f2"; radius: 0; border.color: "#d9d2c5"; border.width: 1
                    opacity: netPopup.open ? 1 : 0
                    transform: Translate { y: netPopup.open ? 0 : -8; Behavior on y { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } } }
                    Behavior on opacity { NumberAnimation { duration: 160 } }
                    Column {
                        id: netCol
                        anchors { left: parent.left; right: parent.right; top: parent.top; margins: 18 }
                        spacing: 12
                        Text { text: "Network"; color: "#1b1916"; font.family: "Playfair Display"; font.pixelSize: 16; font.bold: true }
                        Text {
                            id: netStatus; text: "..."; width: parent.width; wrapMode: Text.WordWrap
                            color: "#8b8475"; font.family: "Noto Sans"; font.pixelSize: 13
                            Process { id: netProc; running: false
                                command: ["sh", "-c", "n=$(nmcli -t -f NAME connection show --active 2>/dev/null | head -1); [ -n \"$n\" ] && echo \"Connected · $n\" || echo Disconnected"]
                                stdout: StdioCollector { onStreamFinished: netStatus.text = this.text.trim() } }
                        }
                        Rectangle {
                            width: parent.width; height: 34; radius: 0
                            color: netMa.containsMouse ? "#e2dccd" : "#ece7dd"
                            Behavior on color { ColorAnimation { duration: 120 } }
                            Text { anchors.centerIn: parent; text: "Network settings"; color: "#1b1916"; font.family: "Noto Sans"; font.pixelSize: 13 }
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
                    color: "#faf8f2"; radius: 0; border.color: "#d9d2c5"; border.width: 1
                    opacity: btPopup.open ? 1 : 0
                    transform: Translate { y: btPopup.open ? 0 : -8; Behavior on y { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } } }
                    Behavior on opacity { NumberAnimation { duration: 160 } }
                    Column {
                        id: btCol
                        anchors { left: parent.left; right: parent.right; top: parent.top; margins: 18 }
                        spacing: 12
                        Text { text: "Bluetooth"; color: "#1b1916"; font.family: "Playfair Display"; font.pixelSize: 16; font.bold: true }
                        Text {
                            id: btStatus; text: "..."
                            color: "#8b8475"; font.family: "Noto Sans"; font.pixelSize: 13
                            Process { id: btProc; running: false
                                command: ["sh", "-c", "bluetoothctl show 2>/dev/null | grep -q 'Powered: yes' && echo 'Powered on' || echo 'Off / no adapter'"]
                                stdout: StdioCollector { onStreamFinished: btStatus.text = this.text.trim() } }
                        }
                        Rectangle {
                            width: parent.width; height: 34; radius: 0
                            color: btMa.containsMouse ? "#e2dccd" : "#ece7dd"
                            Behavior on color { ColorAnimation { duration: 120 } }
                            Text { anchors.centerIn: parent; text: "Open Blueman"; color: "#1b1916"; font.family: "Noto Sans"; font.pixelSize: 13 }
                            MouseArea { id: btMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: { bluemanProc.running = true; btPopup.open = false } }
                        }
                    }
                }
                Process { id: bluemanProc; command: ["blueman-manager"]; running: false }
            }

            PopupWindow {
                id: sysPopup
                property bool open: false
                parentWindow: panel
                relativeX: panel.width - 430
                relativeY: panel.height + 4
                visible: open || sysContent.opacity > 0.01
                implicitWidth: 300
                implicitHeight: sysCol.implicitHeight + 36
                color: "transparent"
                Rectangle {
                    id: sysContent
                    anchors.fill: parent
                    color: "#faf8f2"; radius: 0; border.color: "#d9d2c5"; border.width: 1
                    opacity: sysPopup.open ? 1 : 0
                    transform: Translate { y: sysPopup.open ? 0 : -8; Behavior on y { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } } }
                    Behavior on opacity { NumberAnimation { duration: 160 } }
                    Column {
                        id: sysCol
                        anchors { left: parent.left; right: parent.right; top: parent.top; margins: 18 }
                        spacing: 10
                        Text { text: "System"; color: "#1b1916"; font.family: "Playfair Display"; font.pixelSize: 16; font.bold: true }
                        Item {
                            width: parent.width; height: 16
                            Text { anchors.left: parent.left; text: "CPU"; color: "#8b8475"; font.family: "Noto Sans"; font.pixelSize: 13 }
                            Text { anchors.right: parent.right; text: Math.round(resRow.cpuPct) + "%"; color: "#1b1916"; font.family: "Noto Sans"; font.pixelSize: 13 }
                        }
                        Rectangle { width: parent.width; height: 8; radius: 0; color: "#ece7dd"
                            Rectangle { width: parent.width * (resRow.cpuPct / 100); height: parent.height; radius: 0; color: "#a35e3a"; Behavior on width { NumberAnimation { duration: 300 } } } }
                        Item {
                            width: parent.width; height: 16
                            Text { anchors.left: parent.left; text: "RAM"; color: "#8b8475"; font.family: "Noto Sans"; font.pixelSize: 13 }
                            Text { anchors.right: parent.right; text: resRow.ramDetail; color: "#1b1916"; font.family: "Noto Sans"; font.pixelSize: 13 }
                        }
                        Rectangle { width: parent.width; height: 8; radius: 0; color: "#ece7dd"
                            Rectangle { width: parent.width * (resRow.ramPct / 100); height: parent.height; radius: 0; color: "#a35e3a"; Behavior on width { NumberAnimation { duration: 300 } } } }
                        Text { text: "Load   " + resRow.loadStr; color: "#8b8475"; font.family: "Noto Sans"; font.pixelSize: 12 }
                        Text { text: "Up     " + resRow.uptimeStr; width: parent.width; wrapMode: Text.WordWrap; color: "#8b8475"; font.family: "Noto Sans"; font.pixelSize: 12 }
                        Rectangle {
                            width: parent.width; height: 34; radius: 0
                            color: btopMa.containsMouse ? "#e2dccd" : "#ece7dd"
                            Behavior on color { ColorAnimation { duration: 120 } }
                            Text { anchors.centerIn: parent; text: "Open btop"; color: "#1b1916"; font.family: "Noto Sans"; font.pixelSize: 13 }
                            MouseArea { id: btopMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: { btopProc.running = true; sysPopup.open = false } }
                        }
                    }
                }
                Process { id: btopProc; command: ["foot", "btop"]; running: false }
            }
        }
    }
}
