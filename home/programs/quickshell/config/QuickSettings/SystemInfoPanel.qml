// SystemInfoPanel.qml
// System-info card that appears below the NixOS menu button.
// Design mirrors QuickSettingsPanel: same background, radius, shadow, and
// slide-in animation. Data is fetched once on Component.onCompleted so the
// values are ready before the user ever opens the popup.
pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "."

PopupWindow {
    id: win

    property bool shown: false

    // MenuButton observes this to decide whether to keep the panel alive.
    property bool panelHovered: false

    signal entered()
    signal exited()

    color: "transparent"
    anchor.edges: Edges.Bottom
    anchor.gravity: Edges.Bottom | Edges.Left
    anchor.margins.top: 4
    anchor.adjustment: PopupAdjustment.Slide

    readonly property int shadowMargin: 16  // right/bottom shadow space
    readonly property int cardWidth: 264

    visible: shown
    implicitWidth: cardWidth + shadowMargin
    implicitHeight: card.implicitHeight + shadowMargin

    // ---- system data ----
    property string hostname:        "—"
    property string kernelVersion:   "—"
    property string hyprlandVersion: "—"
    property string nixosVersion:    "—"
    property string uptime:          "—"

    Component.onCompleted: {
        hostnameProc.running   = true
        kernelProc.running     = true
        hyprlandProc.running   = true
        nixosProc.running      = true
        uptimeProc.running     = true
    }

    Process {
        id: hostnameProc
        command: ["hostname"]
        stdout: StdioCollector { onStreamFinished: win.hostname = text.trim() }
    }
    Process {
        id: kernelProc
        command: ["uname", "-r"]
        stdout: StdioCollector { onStreamFinished: win.kernelVersion = text.trim() }
    }
    Process {
        id: hyprlandProc
        command: ["sh", "-c", "hyprctl version 2>/dev/null | head -1"]
        stdout: StdioCollector {
            onStreamFinished: {
                const m = text.match(/v\d+\.\d+\.\d+/)
                win.hyprlandVersion = m ? m[0] : text.trim()
            }
        }
    }
    Process {
        id: nixosProc
        command: ["nixos-version"]
        stdout: StdioCollector { onStreamFinished: win.nixosVersion = text.trim() }
    }
    Process {
        id: uptimeProc
        command: ["sh", "-c", "uptime -p | sed 's/^up //'"]
        stdout: StdioCollector { onStreamFinished: win.uptime = text.trim() }
    }

    // ---- card ----
    Item {
        id: card
        x: 0
        y: win.shown ? 0 : -12
        opacity: win.shown ? 1.0 : 0.0
        implicitWidth: win.cardWidth
        implicitHeight: content.implicitHeight + Theme.pad * 2

        Behavior on y       { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
        Behavior on opacity { NumberAnimation { duration: 180 } }

        // soft drop shadow
        MultiEffect {
            source: cardBg
            anchors.fill: cardBg
            z: -1
            autoPaddingEnabled: true
            shadowEnabled: true
            shadowColor: "#000000"
            shadowOpacity: 0.35
            shadowBlur: 0.45
            shadowVerticalOffset: 3
            shadowHorizontalOffset: 0
        }

        Rectangle {
            id: cardBg
            anchors.fill: parent
            radius: Theme.radius
            color: Theme.background
            layer.enabled: true
        }

        Item {
            anchors.fill: parent
            focus: win.shown
            Keys.onEscapePressed: win.exited()
        }

        HoverHandler {
            onHoveredChanged: {
                win.panelHovered = hovered
                if (hovered) win.entered(); else win.exited()
            }
        }

        ColumnLayout {
            id: content
            x: Theme.pad
            y: Theme.pad
            width: win.cardWidth - Theme.pad * 2
            spacing: Theme.rowGap

            // section label
            Text {
                text: "System"
                color: Theme.subtext
                font.pixelSize: 11
                font.bold: true
                Layout.fillWidth: true
            }

            Rectangle { Layout.fillWidth: true; height: 1; color: Theme.divider }

            // info rows
            Repeater {
                model: [
                    { icon: "󰒋", label: "Host",     value: win.hostname },
                    { icon: "󰌽", label: "Kernel",   value: win.kernelVersion },
                    { icon: "󰖲", label: "Hyprland", value: win.hyprlandVersion },
                    { icon: "󱄅", label: "NixOS",    value: win.nixosVersion },
                    { icon: "󰔛", label: "Uptime",   value: win.uptime }
                ]
                delegate: RowLayout {
                    required property var modelData
                    Layout.fillWidth: true
                    spacing: 10

                    Text {
                        text: modelData.icon
                        font.family: "Symbols Nerd Font"
                        font.pixelSize: 14
                        color: Theme.accent
                        Layout.preferredWidth: 18
                        horizontalAlignment: Text.AlignHCenter
                        Layout.alignment: Qt.AlignVCenter
                    }
                    Text {
                        text: modelData.label
                        color: Theme.subtext
                        font.pixelSize: 12
                        Layout.preferredWidth: 58
                        Layout.alignment: Qt.AlignVCenter
                    }
                    Text {
                        text: modelData.value
                        color: Theme.text
                        font.pixelSize: 12
                        font.family: "monospace"
                        Layout.fillWidth: true
                        elide: Text.ElideRight
                        Layout.alignment: Qt.AlignVCenter
                    }
                }
            }
        }
    }
}
