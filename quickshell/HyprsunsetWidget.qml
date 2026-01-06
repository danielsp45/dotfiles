// SunsetToggleWidget.qml
import QtQuick
import QtQuick.Controls
import Quickshell.Io

Item {
  id: root

  // sizing hooks
  property int size: 26
  property int radius: 8
  property int iconPx: 14

  // your script path
  property string togglePath: "/home/daniel/.local/share/config/bin/toggle-hyprsunset"

  // purely visual state for now (you can wire real state later)
  property bool sunsetOn: false

  width: size
  height: size

  // Run the toggle script detached (doesn't block Quickshell)
  Process {
    id: toggleProc
    // Use bash -lc to match terminal-like environment behavior
    command: ["bash", "-lc", root.togglePath]
  }

  Rectangle {
    id: bg
    anchors.fill: parent
    radius: root.radius

    color: root.sunsetOn ? "#ffb84d" : "transparent"
    border.color: root.sunsetOn ? "#ffb84d" : "#555555"
    border.width: 1

    property bool hovered: false
    property bool pressed: false
    opacity: pressed ? 0.85 : (hovered ? 1.0 : 0.95)

    Behavior on color { ColorAnimation { duration: 140 } }
    Behavior on border.color { ColorAnimation { duration: 140 } }
    Behavior on opacity { NumberAnimation { duration: 90 } }
  }

  Text {
    anchors.centerIn: parent
    text: root.sunsetOn ? "☾" : "☀"
    color: root.sunsetOn ? "black" : "white"
    font.bold: true
    font.pixelSize: root.iconPx
  }

  HoverHandler {
    id: hover
    onHoveredChanged: bg.hovered = hovered
    cursorShape: Qt.PointingHandCursor
  }

  TapHandler {
    acceptedButtons: Qt.LeftButton
    onPressedChanged: bg.pressed = pressed

    onTapped: {
      console.log("Toggling hyprsunset:", root.togglePath)
      toggleProc.startDetached()

      // optimistic UI (optional)
      root.sunsetOn = !root.sunsetOn
    }
  }
}
