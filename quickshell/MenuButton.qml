// MenuButton.qml
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland

Rectangle {
    id: root
    implicitHeight: 22
    implicitWidth: 22
    radius: height / 2
    color: hovered ? "#555555" : "transparent"

    property bool hovered: false
    property bool popupHovered: false

    // Small delay so the popup doesn't flicker when moving between button and popup
    Timer {
        id: hideTimer
        interval: 150
        onTriggered: if (!root.hovered && !root.popupHovered) powerMenu.visible = false
    }

    function scheduleHide() {
        if (powerMenu.visible) hideTimer.restart()
    }

    Image {
        anchors.centerIn: parent
        source: "./icons/nixos.svg"
        fillMode: Image.PreserveAspectFit
        smooth: true
        antialiasing: true
        width: parent.height * 0.8
        height: parent.height * 0.8
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onEntered: {
            root.hovered = true
            hideTimer.stop()
        }
        onExited: {
            root.hovered = false
            root.scheduleHide()
        }
        onClicked: powerMenu.visible = !powerMenu.visible
    }

    PopupWindow {
        id: powerMenu
        visible: false
        color: "transparent"

        anchor.item: root
        anchor.edges: Edges.Bottom
        anchor.gravity: Edges.Bottom | Edges.Left
        anchor.margins.top: 4

        width: 200
        height: menuCol.implicitHeight + 24

        Item {
            anchors.fill: parent
            focus: true
            Keys.onEscapePressed: powerMenu.visible = false

            HoverHandler {
                onHoveredChanged: {
                    root.popupHovered = hovered
                    if (!hovered) root.scheduleHide()
                    else hideTimer.stop()
                }
            }

            Rectangle {
                anchors.fill: parent
                radius: 10
                color: "#111111"
                border.color: "#444444"
                border.width: 1

                ColumnLayout {
                    id: menuCol
                    anchors {
                        top: parent.top
                        left: parent.left
                        right: parent.right
                        topMargin: 8
                        leftMargin: 8
                        rightMargin: 8
                        bottomMargin: 8
                    }
                    spacing: 2

                    Repeater {
                        model: [
                            { icon: "󰐥", label: "Shutdown", cmd: "systemctl poweroff" },
                            { icon: "󰑓", label: "Reboot",   cmd: "systemctl reboot"   },
                            { icon: "󰒲", label: "Suspend",  cmd: "~/.local/share/config/bin/suspend" },
                            { icon: "󰌾", label: "Lock",     cmd: "~/.local/share/config/bin/lock-screen" }
                        ]

                        delegate: Rectangle {
                            required property var modelData
                            Layout.fillWidth: true
                            implicitHeight: 34
                            radius: 6
                            color: rowHovered ? "#333333" : "transparent"
                            property bool rowHovered: false

                            Behavior on color { ColorAnimation { duration: 100 } }

                            RowLayout {
                                width: 120
                                height: parent.height
                                anchors.centerIn: parent
                                spacing: 10

                                Text {
                                    Layout.preferredWidth: 20
                                    horizontalAlignment: Text.AlignHCenter
                                    text: modelData.icon
                                    color: "white"
                                    font.pixelSize: 15
                                }

                                Text {
                                    Layout.fillWidth: true
                                    text: modelData.label
                                    color: "white"
                                    font.pixelSize: 13
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onEntered: parent.rowHovered = true
                                onExited: parent.rowHovered = false
                                onClicked: {
                                    powerMenu.visible = false
                                    Quickshell.execDetached(["sh", "-c", modelData.cmd])
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
