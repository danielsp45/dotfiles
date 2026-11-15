// LowBatteryDialog.qml
// Adwaita-style alert shown when the battery drops to 10%. It stays up (even
// after plugging in) until acknowledged with the button or Enter/Esc. Shown on
// the monitor that was focused when the alert fired.
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Io
import "QuickSettings"

Scope {
    id: root

    // Screen the alert opened on, captured when it fires so it doesn't jump
    // monitors if focus changes while it's up.
    property var targetScreen: null

    // `quickshell ipc call lowBattery test` previews the dialog.
    IpcHandler {
        target: "lowBattery"
        function test() { BatteryService.lowAlert = true }
        function dismiss() { BatteryService.acknowledgeLow() }
    }

    Connections {
        target: BatteryService
        function onLowAlertChanged() {
            if (!BatteryService.lowAlert) return
            const name = Hyprland.focusedMonitor ? Hyprland.focusedMonitor.name : ""
            root.targetScreen = Quickshell.screens.find(s => s.name === name) || Quickshell.screens[0]
        }
    }

    LazyLoader {
        active: BatteryService.lowAlert && root.targetScreen !== null

        PanelWindow {
            id: dialog
            screen: root.targetScreen
            color: "transparent"

            // No anchors → layer-shell centers the surface on the output.
            implicitWidth: card.width
            implicitHeight: card.height

            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.namespace: "quickshell-low-battery"
            // OnDemand: don't steal keystrokes from whatever you're typing in
            // (an accidental Enter shouldn't ack it); click it to focus.
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
            exclusionMode: ExclusionMode.Ignore

            Rectangle {
                id: card
                width: 340
                height: content.implicitHeight + 48
                radius: 18
                color: Theme.background
                border.width: 1
                border.color: Theme.divider

                focus: true
                Keys.onReturnPressed: BatteryService.acknowledgeLow()
                Keys.onEnterPressed: BatteryService.acknowledgeLow()
                Keys.onEscapePressed: BatteryService.acknowledgeLow()

                ColumnLayout {
                    id: content
                    anchors.fill: parent
                    anchors.margins: 24
                    spacing: 10

                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: BatteryService.charging ? "󰂄" : "󰂃"
                        font.family: "Symbols Nerd Font"
                        font.pixelSize: 40
                        color: BatteryService.charging ? Theme.text : Theme.danger
                    }

                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: "Battery Low"
                        color: Theme.text
                        font.pixelSize: 18
                        font.bold: true
                    }

                    Text {
                        Layout.fillWidth: true
                        horizontalAlignment: Text.AlignHCenter
                        wrapMode: Text.WordWrap
                        color: Theme.subtext
                        font.pixelSize: 13
                        text: BatteryService.charging
                            ? BatteryService.percent + "% remaining. Charging."
                            : BatteryService.percent + "% remaining. Connect your charger soon."
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.topMargin: 10
                        Layout.preferredHeight: 38
                        radius: 19
                        color: (okTap.pressed || okHover.hovered) ? Theme.surfaceAlt : Theme.surface
                        Behavior on color { ColorAnimation { duration: 120 } }

                        Text {
                            anchors.centerIn: parent
                            text: "OK"
                            color: Theme.text
                            font.pixelSize: 14
                            font.bold: true
                        }

                        HoverHandler { id: okHover }
                        TapHandler {
                            id: okTap
                            onTapped: BatteryService.acknowledgeLow()
                        }
                    }
                }
            }
        }
    }
}
