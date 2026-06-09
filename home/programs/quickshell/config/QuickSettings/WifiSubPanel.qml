// WifiSubPanel.qml
// Native NetworkManager-backed Wi-Fi list (Quickshell.Networking). Wi-Fi
// networks hang off the WifiDevice inside Networking.devices; each WifiNetwork
// exposes connect()/connectWithPsk()/disconnect() plus signalStrength/security.
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Networking

ColumnLayout {
    id: root
    signal back()

    spacing: 8

    // The first Wi-Fi capable device, if any.
    readonly property var wifiDevice: {
        const ds = Networking.devices ? Networking.devices.values : []
        for (let i = 0; i < ds.length; ++i)
            if (ds[i] && ds[i].type === DeviceType.Wifi) return ds[i]
        return null
    }
    readonly property var networks: wifiDevice ? wifiDevice.networks.values : []
    readonly property var sortedNetworks: {
        const arr = Array.from(root.networks)
        arr.sort((a, b) => {
            if (a.connected && !b.connected) return -1
            if (!a.connected && b.connected) return 1
            return 0
        })
        return arr
    }

    property string pwTarget: ""   // network name currently showing a password field

    function secured(n) {
        return n.security !== WifiSecurityType.Open
            && n.security !== WifiSecurityType.Unknown
    }
    function signalGlyph(s) {
        const v = s <= 1 ? s * 100 : s
        if (v <= 20) return "󰤯"
        if (v <= 40) return "󰤟"
        if (v <= 60) return "󰤢"
        if (v <= 80) return "󰤥"
        return "󰤨"
    }
    function activate(n) {
        if (n.connected) { n.disconnect(); return }
        if (root.secured(n) && !n.known) {
            root.pwTarget = (root.pwTarget === n.name) ? "" : n.name
            return
        }
        n.connect()
    }

    // Keep scanning while this sub-panel is shown.
    Binding {
        target: root.wifiDevice
        property: "scannerEnabled"
        value: root.visible
        when: root.wifiDevice !== null
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
            Text {
                anchors.centerIn: parent; text: "󰅁"
                font.family: "Symbols Nerd Font"; font.pixelSize: 16; color: Theme.text
            }
            HoverHandler { id: backHover }
            TapHandler { id: backTap; onTapped: root.back() }
        }
        Text { text: "Wi-Fi"; color: Theme.text; font.pixelSize: 15; font.bold: true; Layout.fillWidth: true }
    }

    Rectangle { Layout.fillWidth: true; height: 1; color: Theme.divider }

    // --- network list ---
    Flickable {
        Layout.fillWidth: true
        Layout.preferredHeight: Math.min(netCol.implicitHeight, 260)
        contentHeight: netCol.implicitHeight
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        ColumnLayout {
            id: netCol
            width: parent.width
            spacing: 2

            Text {
                visible: root.networks.length === 0
                text: root.wifiDevice ? "Searching…" : "No Wi-Fi adapter"
                color: Theme.subtext; font.pixelSize: 12
                Layout.margins: 8
            }

            Repeater {
                model: root.sortedNetworks
                delegate: ColumnLayout {
                    required property var modelData
                    Layout.fillWidth: true
                    spacing: 0

                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: 40
                        radius: 8
                        color: rowTap.pressed ? Theme.surfaceAlt
                            : (rowHover.hovered ? Theme.surface
                            : (modelData.connected ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.18) : "transparent"))

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 8; anchors.rightMargin: 8
                            spacing: 10

                            Text {
                                text: modelData.connected ? "" : " "   // check when connected
                                font.family: "Symbols Nerd Font"; font.pixelSize: 13
                                color: Theme.accent; Layout.preferredWidth: 14
                            }
                            Text {
                                text: modelData.name
                                color: modelData.connected ? Theme.accent : Theme.text
                                font.pixelSize: 13
                                font.bold: modelData.connected
                                elide: Text.ElideRight; Layout.fillWidth: true
                            }
                            Text {
                                visible: root.secured(modelData)
                                text: "󰌾"; font.family: "Symbols Nerd Font"
                                font.pixelSize: 12; color: Theme.subtext
                            }
                            Text {
                                text: root.signalGlyph(modelData.signalStrength)
                                font.family: "Symbols Nerd Font"; font.pixelSize: 14; color: Theme.text
                            }
                        }
                        HoverHandler { id: rowHover }
                        TapHandler { id: rowTap; onTapped: root.activate(modelData) }
                    }

                    // inline password prompt for secured, unknown networks
                    RowLayout {
                        Layout.fillWidth: true
                        Layout.leftMargin: 8; Layout.rightMargin: 8; Layout.bottomMargin: 4
                        visible: root.pwTarget === modelData.name
                        spacing: 6

                        TextField {
                            id: pwField
                            Layout.fillWidth: true
                            echoMode: TextInput.Password
                            placeholderText: "Password"
                            color: Theme.text
                            background: Rectangle { radius: 8; color: Theme.surface; border.color: Theme.divider; border.width: 1 }
                            onAccepted: { modelData.connectWithPsk(text); root.pwTarget = "" }
                        }
                        Rectangle {
                            Layout.preferredWidth: 36; Layout.preferredHeight: 32
                            radius: 8
                            color: pskHover.hovered ? Qt.lighter(Theme.accent, 1.12) : Theme.accent
                            Text { anchors.centerIn: parent; text: "󰄬"; font.family: "Symbols Nerd Font"; color: Theme.accentText }
                            HoverHandler { id: pskHover }
                            TapHandler { onTapped: { modelData.connectWithPsk(pwField.text); root.pwTarget = "" } }
                        }
                    }
                }
            }
        }
    }

    Rectangle { Layout.fillWidth: true; height: 1; color: Theme.divider }

    // --- enable toggle ---
    RowLayout {
        Layout.fillWidth: true
        Text { text: "Enable Wi-Fi"; color: Theme.text; font.pixelSize: 13; Layout.fillWidth: true }
        Rectangle {
            Layout.preferredWidth: 44; Layout.preferredHeight: 24; radius: 12
            color: Networking.wifiEnabled ? Theme.accent : Theme.surfaceAlt
            Behavior on color { ColorAnimation { duration: 120 } }
            Rectangle {
                width: 18; height: 18; radius: 9; color: "white"
                anchors.verticalCenter: parent.verticalCenter
                x: Networking.wifiEnabled ? parent.width - width - 3 : 3
                Behavior on x { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
            }
            TapHandler { onTapped: Networking.wifiEnabled = !Networking.wifiEnabled }
        }
    }

    // --- settings launcher ---
    Rectangle {
        Layout.fillWidth: true; implicitHeight: 36; radius: 8
        color: setTap.pressed ? Theme.surfaceAlt
            : (setHover.hovered ? Theme.surface : "transparent")
        RowLayout {
            anchors.fill: parent; anchors.leftMargin: 8; anchors.rightMargin: 8
            Text { text: "Wi-Fi Settings"; color: Theme.text; font.pixelSize: 13; Layout.fillWidth: true }
            Text { text: "󰅂"; font.family: "Symbols Nerd Font"; font.pixelSize: 12; color: Theme.subtext }
        }
        HoverHandler { id: setHover }
        TapHandler { id: setTap; onTapped: Quickshell.execDetached(["nm-connection-editor"]) }
    }
}
