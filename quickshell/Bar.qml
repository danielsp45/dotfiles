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

      implicitHeight: 35

      Rectangle {
        id: barBg
        height: 30
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

            Item {
              id: mprisAnchor
              Layout.alignment: Qt.AlignVCenter

              // let the layout size this wrapper to the widget
              implicitWidth: mprisInner.implicitWidth
              implicitHeight: mprisInner.implicitHeight

              MprisWidget {
                id: mprisInner
                anchors.fill: parent
              }

              TapHandler {
                acceptedButtons: Qt.LeftButton
                onTapped: mprisPopup.visible = !mprisPopup.visible
              }
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
