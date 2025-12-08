import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import QtQuick
import QtQuick.Layouts

RowLayout {
  Repeater {
    model: Hyprland.workspaces

    Text {
      text: modelData.id
      color: modelData.active ? "white" : "gray"
      font.pixelSize: 12
      font.bold: modelData.active
      Layout.leftMargin:  6
      Layout.rightMargin: 6

      MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor

        onClicked: {
          modelData.activate()
        }
      }
    }
  }
}
