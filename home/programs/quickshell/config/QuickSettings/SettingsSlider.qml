// SettingsSlider.qml
// Generic icon + slider row used for volume and brightness. Kept backend-free:
// the parent binds `value` and reacts to moved()/iconActivated().
import QtQuick
import QtQuick.Layouts

RowLayout {
    id: root

    property string iconName: ""       // leading glyph (also the action button)
    property real   value: 0.0         // 0.0 - 1.0
    property bool   iconActive: true   // tints the leading icon when "on"

    signal moved(real v)
    signal iconActivated()

    spacing: 12
    implicitHeight: 28

    // Leading icon doubles as the action button (e.g. mute toggle).
    Text {
        text: root.iconName
        font.family: "Symbols Nerd Font"
        font.pixelSize: 18
        color: iconHover.hovered ? Theme.accent
            : (root.iconActive ? Theme.text : Theme.subtext)
        Layout.alignment: Qt.AlignVCenter
        Layout.preferredWidth: 22
        horizontalAlignment: Text.AlignHCenter

        HoverHandler { id: iconHover }
        TapHandler { onTapped: root.iconActivated() }
    }

    // Custom slider — uses MouseArea instead of Qt Quick Controls Slider to
    // ensure reliable drag events inside a Wayland PopupWindow.
    Item {
        id: track
        Layout.fillWidth: true
        Layout.alignment: Qt.AlignVCenter
        implicitHeight: 20

        // `pos` is the visual position (0–1). Follows root.value when idle;
        // updated immediately during drag so the handle moves without latency.
        property real pos: root.value

        // Sync external value changes while not dragging.
        Connections {
            target: root
            function onValueChanged() {
                if (!dragArea.pressed) track.pos = root.value
            }
        }

        // Track background
        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width
            height: 4
            radius: 2
            color: Theme.surfaceAlt

            // Filled (accent) portion
            Rectangle {
                width: parent.width * track.pos
                height: parent.height
                radius: 2
                color: Theme.accent
            }
        }

        // Draggable handle
        Rectangle {
            x: (track.width - width) * track.pos
            anchors.verticalCenter: parent.verticalCenter
            width: 16; height: 16; radius: 8
            color: dragArea.pressed ? Qt.lighter(Theme.accent, 1.15) : Theme.accent
            border.color: Qt.lighter(Theme.accent, 1.3)
            border.width: 1
        }

        MouseArea {
            id: dragArea
            anchors.fill: parent

            function valueAt(mouseX) {
                return Math.max(0.0, Math.min(1.0, mouseX / track.width))
            }

            onPressed: function(mouse) {
                var v = valueAt(mouse.x)
                track.pos = v
                root.moved(v)
            }
            onPositionChanged: function(mouse) {
                if (pressed) {
                    var v = valueAt(mouse.x)
                    track.pos = v
                    root.moved(v)
                }
            }
            onReleased: {
                // Snap back to actual system value after the backend confirms.
                track.pos = root.value
            }
        }
    }
}
