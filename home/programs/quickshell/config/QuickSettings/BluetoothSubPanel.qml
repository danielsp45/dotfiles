// BluetoothSubPanel.qml
// Native BlueZ-backed device list (Quickshell.Bluetooth). Devices come from
// Bluetooth.devices; the default adapter drives the enable/discovery toggles.
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Bluetooth

ColumnLayout {
    id: root
    signal back()

    spacing: 8

    readonly property var adapter: Bluetooth.defaultAdapter
    readonly property var devices: Bluetooth.devices ? Bluetooth.devices.values : []

    // Discover while the sub-panel is visible (and the adapter is on).
    Binding {
        target: root.adapter
        property: "discovering"
        value: root.visible && root.adapter && root.adapter.enabled
        when: root.adapter !== null
    }

    function activate(d) {
        if (d.connected) d.disconnect()
        else d.connect()
    }
    function subtitle(d) {
        if (d.connected) return d.batteryAvailable ? ("Connected · " + Math.round(d.battery * 100) + "%") : "Connected"
        if (d.bonded || d.paired) return "Paired"
        return "Available"
    }

    // --- header ---
    RowLayout {
        Layout.fillWidth: true
        spacing: 10
        Rectangle {
            Layout.preferredWidth: 28; Layout.preferredHeight: 28
            radius: 14
            color: backTap.pressed ? Theme.surfaceAlt
                : (backHover.hovered ? Theme.surface : "transparent")
            Text { anchors.centerIn: parent; text: "󰅁"; font.family: "Symbols Nerd Font"; font.pixelSize: 16; color: Theme.text }
            HoverHandler { id: backHover }
            TapHandler { id: backTap; onTapped: root.back() }
        }
        Text { text: "Bluetooth"; color: Theme.text; font.pixelSize: 15; font.bold: true; Layout.fillWidth: true }
    }

    Rectangle { Layout.fillWidth: true; height: 1; color: Theme.divider }

    // --- device list ---
    Flickable {
        Layout.fillWidth: true
        Layout.preferredHeight: Math.min(devCol.implicitHeight, 260)
        contentHeight: devCol.implicitHeight
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        ColumnLayout {
            id: devCol
            width: parent.width
            spacing: 2

            Text {
                visible: root.devices.length === 0
                text: root.adapter ? (root.adapter.enabled ? "Searching…" : "Bluetooth off") : "No adapter"
                color: Theme.subtext; font.pixelSize: 12
                Layout.margins: 8
            }

            Repeater {
                model: root.devices
                delegate: Rectangle {
                    required property var modelData
                    Layout.fillWidth: true
                    implicitHeight: 44
                    radius: 8
                    color: devTap.pressed ? Theme.surfaceAlt
                        : (devHover.hovered ? Theme.surface : "transparent")

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 8; anchors.rightMargin: 8
                        spacing: 10

                        Text {
                            text: modelData.connected ? "󰂱" : "󰂯"   // bt-connected / bt
                            font.family: "Symbols Nerd Font"; font.pixelSize: 16
                            color: modelData.connected ? Theme.accent : Theme.text
                            Layout.preferredWidth: 20
                        }
                        ColumnLayout {
                            Layout.fillWidth: true; spacing: 0
                            Text { text: modelData.name || modelData.address; color: Theme.text; font.pixelSize: 13; elide: Text.ElideRight; Layout.fillWidth: true }
                            Text { text: root.subtitle(modelData); color: Theme.subtext; font.pixelSize: 11; elide: Text.ElideRight; Layout.fillWidth: true }
                        }
                    }
                    HoverHandler { id: devHover }
                    TapHandler { id: devTap; onTapped: root.activate(modelData) }
                }
            }
        }
    }

    Rectangle { Layout.fillWidth: true; height: 1; color: Theme.divider }

    // --- enable toggle ---
    RowLayout {
        Layout.fillWidth: true
        Text { text: "Enable Bluetooth"; color: Theme.text; font.pixelSize: 13; Layout.fillWidth: true }
        Rectangle {
            Layout.preferredWidth: 44; Layout.preferredHeight: 24; radius: 12
            enabled: root.adapter !== null
            opacity: root.adapter ? 1 : 0.4
            color: (root.adapter && root.adapter.enabled) ? Theme.accent : Theme.surfaceAlt
            Behavior on color { ColorAnimation { duration: 120 } }
            Rectangle {
                width: 18; height: 18; radius: 9; color: "white"
                anchors.verticalCenter: parent.verticalCenter
                x: (root.adapter && root.adapter.enabled) ? parent.width - width - 3 : 3
                Behavior on x { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
            }
            TapHandler { onTapped: if (root.adapter) root.adapter.enabled = !root.adapter.enabled }
        }
    }

    // --- settings launcher ---
    Rectangle {
        Layout.fillWidth: true; implicitHeight: 36; radius: 8
        color: setTap.pressed ? Theme.surfaceAlt
            : (setHover.hovered ? Theme.surface : "transparent")
        RowLayout {
            anchors.fill: parent; anchors.leftMargin: 8; anchors.rightMargin: 8
            Text { text: "Bluetooth Settings"; color: Theme.text; font.pixelSize: 13; Layout.fillWidth: true }
            Text { text: "󰅂"; font.family: "Symbols Nerd Font"; font.pixelSize: 12; color: Theme.subtext }
        }
        HoverHandler { id: setHover }
        TapHandler { id: setTap; onTapped: Quickshell.execDetached(["blueman-manager"]) }
    }
}
