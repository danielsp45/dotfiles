// Bar.qml
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Services.Pipewire
import QtQuick
import QtQuick.Layouts
import "QuickSettings"

Scope {
  id: barScope

  // Name of the screen whose Quick Settings panel is open ("" = none). A single
  // shared value guarantees only one panel — and thus one focus grab — at a time.
  property string qsScreen: ""

  IpcHandler {
    target: "quickSettings"
    // Toggle on the currently focused monitor.
    function toggle() {
      const n = Hyprland.focusedMonitor ? Hyprland.focusedMonitor.name : ""
      barScope.qsScreen = (barScope.qsScreen === n) ? "" : n
    }
  }

  Variants {
    model: Quickshell.screens

    PanelWindow {
      id: barWindow
      required property var modelData
      screen: modelData

      color: "transparent"

      // --- Per-screen scaling + compact breakpoint ---
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

      implicitHeight: sp(30)

      Rectangle {
        id: barBg
        anchors.fill: parent

        radius: 0
        color: "black"

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

            Rectangle {
              color: "#333333"
              radius: height / 2
              implicitHeight: sp(24)
              implicitWidth: ioStats.implicitWidth + sp(20)
              Layout.alignment: Qt.AlignVCenter

              IoStatsWidget {
                id: ioStats
                anchors.centerIn: parent
              }
            }

            // Clickable status cluster: volume + network + battery. Opens the
            // GNOME-style Quick Settings panel.
            Rectangle {
              id: statusCluster
              Layout.alignment: Qt.AlignVCenter
              radius: height / 2
              implicitHeight: sp(24)
              implicitWidth: clusterRow.implicitWidth + sp(16)
              readonly property bool qsOpen: barScope.qsScreen === barWindow.modelData.name
              color: (clusterHover.hovered || qsOpen) ? "#333333" : "transparent"
              Behavior on color { ColorAnimation { duration: 120 } }

              // Keep the default sink tracked so the bar volume glyph is live.
              PwObjectTracker { objects: Pipewire.defaultAudioSink ? [Pipewire.defaultAudioSink] : [] }

              RowLayout {
                id: clusterRow
                anchors.centerIn: parent
                spacing: sp(8)

                Text {
                  readonly property var sink: Pipewire.defaultAudioSink
                  Layout.alignment: Qt.AlignVCenter
                  color: "white"
                  font.pixelSize: sp(16)
                  font.bold: true
                  font.family: "Symbols Nerd Font"
                  text: (sink && sink.audio && sink.audio.muted) ? "󰝟" : "󰕾"
                }

                NetworkWidget { Layout.alignment: Qt.AlignVCenter; fontPx: sp(15) }

                BatteryWidget { Layout.alignment: Qt.AlignVCenter; fontPx: sp(15) }
              }

              HoverHandler { id: clusterHover }
              TapHandler {
                onTapped: barScope.qsScreen =
                  (barScope.qsScreen === barWindow.modelData.name ? "" : barWindow.modelData.name)
              }
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

      // GNOME-style Quick Settings dropdown, anchored under the status cluster.
      QuickSettingsPanel {
        id: qsPanel
        anchorItem: barBg
        triggerWindow: barWindow
        shown: barScope.qsScreen === barWindow.modelData.name
        onDismissed: barScope.qsScreen = ""
      }
    }
  }
}
