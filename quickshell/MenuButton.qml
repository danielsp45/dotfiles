// MenuButton.qml
import QtQuick
import QtQuick.Layouts
import Quickshell

Rectangle {
    id: root
    implicitHeight: 22
    implicitWidth: 22  // will auto-expand if SVG is larger
    radius: height / 2
    color: hovered ? "#555555" : "transparent"

    property bool hovered: false

    Image {
        id: icon
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
        onEntered: root.hovered = true
        onExited: root.hovered = false

        onClicked: {
            Quickshell.execDetached(["sh", "-c", "~/.local/share/config/bin/menu"])
        }
    }
}
