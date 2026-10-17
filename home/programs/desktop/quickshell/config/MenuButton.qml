// MenuButton.qml
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import "QuickSettings"

Rectangle {
    id: root
    implicitHeight: 22
    implicitWidth: 22
    radius: height / 2
    color: hovered ? "#555555" : "transparent"

    property bool hovered: false
    property bool popupHovered: false

    Timer {
        id: hideTimer
        interval: 150
        onTriggered: if (!root.hovered && !root.popupHovered) sysPanel.shown = false
    }

    function scheduleHide() {
        if (sysPanel.shown) hideTimer.restart()
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

        onEntered: {
            root.hovered = true
            hideTimer.stop()
        }
        onExited: {
            root.hovered = false
            root.scheduleHide()
        }
        onClicked: sysPanel.shown = !sysPanel.shown
    }

    SystemInfoPanel {
        id: sysPanel
        anchor.item: root
        shown: false

        onEntered: hideTimer.stop()
        onExited: {
            root.popupHovered = false
            root.scheduleHide()
        }
    }
}
