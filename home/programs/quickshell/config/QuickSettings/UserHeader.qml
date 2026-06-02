// UserHeader.qml
// Avatar + username on the left; lock / power on the right.
// Tapping the power button reveals an inline row of action buttons that
// expands downward (GNOME-style), pushing the rest of the panel down.
import QtQuick
import QtQuick.Layouts
import Quickshell

ColumnLayout {
    id: root

    property string userName: (Quickshell.env("USER") || "user")
    property string settingsCommand: ""
    property string lockCommand: "~/.local/share/config/bin/lock-screen"
    property bool powerMenuOpen: false

    spacing: 0

    // --- header row ---
    RowLayout {
        id: headerRow
        Layout.fillWidth: true
        Layout.preferredHeight: 40
        spacing: 12

        // avatar
        Rectangle {
            Layout.preferredWidth: 32
            Layout.preferredHeight: 32
            radius: 16
            color: Theme.surface
            clip: true

            Image {
                id: avatar
                anchors.fill: parent
                source: "file:///var/lib/AccountsService/icons/" + root.userName
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                visible: status === Image.Ready
            }
            Text {
                anchors.centerIn: parent
                text: "󰀄"
                font.family: "Symbols Nerd Font"
                font.pixelSize: 18
                color: Theme.subtext
                visible: !avatar.visible
            }
        }

        Text {
            text: root.userName
            color: Theme.text
            font.pixelSize: 14
            font.bold: true
            Layout.fillWidth: true
            elide: Text.ElideRight
        }

        // action buttons: settings (optional), lock, power
        Repeater {
            model: [
                { glyph: "",   act: "settings", show: root.settingsCommand !== "" },
                { glyph: "󰌾", act: "lock",     show: true },
                { glyph: "󰐥", act: "power",    show: true }
            ]
            delegate: Rectangle {
                required property var modelData
                visible: modelData.show
                Layout.preferredWidth: visible ? 32 : 0
                Layout.preferredHeight: 32
                radius: 16
                color: (btnTap.pressed || btnHover.hovered) ? Theme.surfaceAlt : Theme.surface
                Behavior on color { ColorAnimation { duration: 120 } }

                Text {
                    anchors.centerIn: parent
                    text: modelData.glyph
                    font.family: "Symbols Nerd Font"
                    font.pixelSize: 15
                    // Highlight the power icon while the menu is open
                    color: (modelData.act === "power" && root.powerMenuOpen)
                        ? Theme.accent : Theme.text
                    Behavior on color { ColorAnimation { duration: 120 } }
                }

                HoverHandler { id: btnHover }
                TapHandler {
                    id: btnTap
                    onTapped: {
                        if (modelData.act === "settings")
                            Quickshell.execDetached(["sh", "-c", root.settingsCommand])
                        else if (modelData.act === "lock")
                            Quickshell.execDetached(["sh", "-c", root.lockCommand])
                        else if (modelData.act === "power")
                            root.powerMenuOpen = !root.powerMenuOpen
                    }
                }
            }
        }
    }

    // --- inline power section (slides down, pushing content below) ---
    Item {
        id: powerSection
        Layout.fillWidth: true
        // Height animates between 0 (closed) and the content height (open).
        // clip: true keeps children from leaking out during the transition.
        implicitHeight: root.powerMenuOpen ? powerRow.implicitHeight + 16 : 0
        clip: true
        opacity: root.powerMenuOpen ? 1 : 0

        Behavior on implicitHeight {
            NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
        }
        Behavior on opacity {
            NumberAnimation { duration: 150 }
        }

        // Horizontal row of circular action buttons with labels
        RowLayout {
            id: powerRow
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            spacing: 8

            Repeater {
                model: [
                    { icon: "󰍃", label: "Log Out",  cmd: "hyprctl dispatch exit" },
                    { icon: "󰒲", label: "Suspend",   cmd: "~/.local/share/config/bin/suspend" },
                    { icon: "󰑓", label: "Restart",   cmd: "systemctl reboot" },
                    { icon: "󰐥", label: "Power Off", cmd: "systemctl poweroff" }
                ]
                delegate: Item {
                    required property var modelData
                    Layout.fillWidth: true
                    implicitHeight: actionCircle.height + actionLabel.height + 6

                    Rectangle {
                        id: actionCircle
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: 48; height: 48
                        radius: 24
                        color: (actionTap.pressed || actionHover.hovered)
                            ? Theme.surfaceAlt : Theme.surface
                        Behavior on color { ColorAnimation { duration: 120 } }

                        Text {
                            anchors.centerIn: parent
                            text: modelData.icon
                            font.family: "Symbols Nerd Font"
                            font.pixelSize: 20
                            color: Theme.text
                        }

                        HoverHandler { id: actionHover }
                        TapHandler {
                            id: actionTap
                            onTapped: {
                                root.powerMenuOpen = false
                                Quickshell.execDetached(["sh", "-c", modelData.cmd])
                            }
                        }
                    }

                    Text {
                        id: actionLabel
                        anchors.top: actionCircle.bottom
                        anchors.topMargin: 6
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: modelData.label
                        color: Theme.subtext
                        font.pixelSize: 10
                        horizontalAlignment: Text.AlignHCenter
                    }
                }
            }
        }
    }
}
