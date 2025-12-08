// Bar.qml
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import QtQuick
import QtQuick.Layouts

Scope {
  Variants {
    model: Quickshell.screens

    PanelWindow {
      required property var modelData
      screen: modelData

      color: "transparent"

      anchors {
        top: true
        left: true
        right: true
      }

      implicitHeight: 40

      Rectangle {
        id: barBg
        height: 35
        width: parent.width - 15

        anchors {
          top: parent.top
          topMargin: 4
          horizontalCenter: parent.horizontalCenter
        }

        radius: height / 2
        color: "black"
        border.color: "#555555"
        border.width: 1

        // MAIN ROW: left group + right stats
        RowLayout {
          id: mainRow
          anchors.fill: parent
          anchors.leftMargin: 10
          anchors.rightMargin: 14
          spacing: 6

          // LEFT SIDE: menu + workspaces + mpris
          RowLayout {
            id: leftRow
            spacing: 4
            Layout.alignment: Qt.AlignVCenter
            Layout.fillWidth: true      // <-- this row stretches, not MprisWidget

            MenuButton {
              Layout.alignment: Qt.AlignVCenter
            }

            Item { width: 6 }           // spacer

            WorkspaceWidget {
              Layout.alignment: Qt.AlignVCenter
            }

            Item { width: 6 }           // spacer

            MprisWidget {
                Layout.alignment: Qt.AlignVCenter
            }
          }

          // RIGHT SIDE: stats
          IoStatsWidget {
            Layout.alignment: Qt.AlignVCenter | Qt.AlignRight
          }
        }

        // CENTER CLOCK: independent of layout, truly centered in the pill
        ClockWidget {
          id: clock
          color: "white"
          anchors.centerIn: parent
        }
      }
    }
  }
}
