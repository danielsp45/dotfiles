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
      color: "#ebdbb2"
      font.pixelSize: 12
      Layout.margins: 4
    }
  }
}
