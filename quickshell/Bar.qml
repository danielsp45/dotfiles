// Bar.qml
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import QtQuick
import QtQuick.Layouts



Scope {
  // no more time object

  Variants {
    model: Quickshell.screens

    PanelWindow {
      required property var modelData
      screen: modelData
      color: "#AEAEAE"

      anchors {
        top: true
        left: true
        right: true
      }

      implicitHeight: 25

      ClockWidget {
        color: "#030303"
        anchors.centerIn: parent
      }

      WorkspaceWidget {

      }
    }
  }
}
