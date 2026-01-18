// Bar.qml (drop-in replacement)
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

      // --- Per-screen scaling + compact breakpoint ---
      // 96 DPI baseline; clamp so it never gets silly on weird DPI reports.
      readonly property real uiScale: Math.max(0.85, Math.min(1.45,
        (screen.logicalDotsPerInch ? screen.logicalDotsPerInch / 96.0 : 1.0)
      ))
      function sp(x) { return Math.round(x * uiScale) }

      // "Compact" for narrow screens (e.g. vertical 1080). Tweak threshold if you want.
      readonly property bool compact: screen.width < sp(1300)

      // --- Window placement ---
      anchors {
        top: true
        left: true
        right: true
      }

      implicitHeight: sp(35)

      Rectangle {
        id: barBg
        height: sp(30)
        width: parent.width - sp(15)

        anchors {
          top: parent.top
          topMargin: sp(4)
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
          anchors.leftMargin: sp(10)
          anchors.rightMargin: sp(14)
          spacing: compact ? sp(3) : sp(6)

          // LEFT SIDE: menu + workspaces + mpris
          RowLayout {
            id: leftRow
            spacing: compact ? sp(2) : sp(4)
            Layout.alignment: Qt.AlignVCenter
            Layout.fillWidth: true

            MenuButton {
              Layout.alignment: Qt.AlignVCenter
            }

            Item { width: compact ? sp(3) : sp(6) } // spacer

            WorkspaceWidget {
              Layout.alignment: Qt.AlignVCenter
            }

            Item { width: compact ? sp(3) : sp(6) } // spacer

            HyprsunsetWidget {
              Layout.alignment: Qt.AlignVCenter | Qt.AlignRight
              visible: !compact
              size: sp(24)
              radius: sp(16)
              iconPx: sp(16)
            }

            Item { width: compact ? sp(3) : sp(6) } // spacer

            // In compact mode, hide MPRIS to reduce clutter on narrow displays
            Item {
              id: mprisAnchor
              visible: !compact
              Layout.alignment: Qt.AlignVCenter

              // Let the layout size this wrapper to the widget
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

          // RIGHT SIDE: stats (optionally hide in compact)
          RowLayout {
            spacing: sp(8)
            Layout.alignment: Qt.AlignVCenter | Qt.AlignRight
            visible: !compact

            IoStatsWidget {
              Layout.alignment: Qt.AlignVCenter
            }

            BatteryWidget {
              Layout.alignment: Qt.AlignVCenter
            }
          }
        }

        // CENTER CLOCK: independent of layout, truly centered in the pill
        ClockWidget {
          id: clock
          color: "white"
          px: sp(compact ? 10 : 12)
          anchors.centerIn: parent
        }
      }
    }
  }
}
