// ToggleButton.qml
// GNOME-style pill toggle. The left region toggles (toggled()); the chevron
// region (when hasSubMenu) opens the sub-panel (subMenuRequested()). The two
// hit areas are disjoint so a chevron tap never also flips the toggle.
import QtQuick
import QtQuick.Layouts

Item {
    id: root

    property string label: ""
    property string sublabel: ""
    property string iconName: ""      // Nerd Font glyph (used when iconComponent is null)
    property bool   checked: false
    property bool   hasSubMenu: false

    // Optional custom icon (e.g. a natively-drawn logo) rendered instead of the
    // font glyph. Bind its color to `iconColor` so it follows the checked state.
    property Component iconComponent: null
    readonly property color iconColor: pill.fg

    signal toggled()
    signal subMenuRequested()

    implicitHeight: 56

    Rectangle {
        id: pill
        anchors.fill: parent
        radius: Theme.toggleRadius
        // GNOME-style hover feedback: lighten the tile while the body is hovered.
        readonly property color baseColor: root.checked ? Theme.accent : Theme.surface
        color: bodyHover.hovered
            ? (root.checked ? Qt.lighter(Theme.accent, 1.12) : Theme.surfaceAlt)
            : baseColor
        scale: bodyTap.pressed ? 0.96 : 1.0

        Behavior on color { ColorAnimation { duration: 120 } }
        Behavior on scale { NumberAnimation { duration: 80; easing.type: Easing.OutCubic } }

        readonly property color fg: root.checked ? Theme.accentText : Theme.text
        readonly property color fgSub: root.checked ? Qt.rgba(1, 1, 1, 0.8) : Theme.subtext

        // --- left: icon + labels (visual only) ---
        RowLayout {
            id: bodyRow
            anchors.left: parent.left
            anchors.right: chevronArea.visible ? chevronArea.left : parent.right
            anchors.verticalCenter: parent.verticalCenter
            anchors.leftMargin: 16
            anchors.rightMargin: 8
            spacing: 12

            Item {
                Layout.preferredWidth: 20
                Layout.preferredHeight: 20
                Layout.alignment: Qt.AlignVCenter

                Loader {
                    anchors.centerIn: parent
                    active: root.iconComponent !== null
                    visible: active
                    sourceComponent: root.iconComponent
                }
                Text {
                    anchors.centerIn: parent
                    visible: root.iconComponent === null
                    text: root.iconName
                    color: pill.fg
                    font.pixelSize: 20
                    font.family: "Symbols Nerd Font"
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 0
                Text {
                    text: root.label
                    color: pill.fg
                    font.pixelSize: 13
                    font.bold: true
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }
                Text {
                    text: root.sublabel
                    color: pill.fgSub
                    font.pixelSize: 11
                    elide: Text.ElideRight
                    visible: root.sublabel !== ""
                    Layout.fillWidth: true
                }
            }
        }

        // --- toggle hit area (everything left of the chevron) ---
        Item {
            id: bodyHit
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            anchors.right: chevronArea.visible ? chevronArea.left : parent.right

            HoverHandler { id: bodyHover }
            TapHandler { id: bodyTap; onTapped: root.toggled() }
        }

        // --- right: chevron sub-menu affordance ---
        Item {
            id: chevronArea
            visible: root.hasSubMenu
            width: visible ? 40 : 0
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.bottom: parent.bottom

            Rectangle {   // hairline divider
                width: 1
                height: parent.height * 0.5
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                color: pill.fgSub
                opacity: 0.4
            }

            // circular hover highlight behind the chevron
            Rectangle {
                anchors.centerIn: parent
                width: 30; height: 30; radius: 15
                color: Qt.rgba(1, 1, 1, 0.15)
                visible: chevronHover.hovered
            }

            Text {
                anchors.centerIn: parent
                text: "󰅂"   // chevron-right (nf-md-chevron_right)
                font.family: "Symbols Nerd Font"
                font.pixelSize: 18
                color: pill.fg
            }

            HoverHandler { id: chevronHover }
            TapHandler { onTapped: root.subMenuRequested() }
        }
    }
}
