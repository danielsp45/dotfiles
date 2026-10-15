// WeatherPopup.qml
// Detail popup for the center weather widget: a PopupWindow centered under the
// bar item (same pattern as MprisWidget), styled with the Theme palette and a
// drop shadow. Read-only — mirrors omarchy's weather panel layout:
//   • hero row: big condition icon + temperature on the left; location and
//     FEELS / WIND / HUMID stats stacked on the right
//   • hairline divider
//   • forecast row: three days, each a condition icon beside DAY + hi/lo temps
// Data comes from the bound WeatherService. Dismisses on click-away or Esc.
import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import "QuickSettings"
import "WeatherModel.js" as Model

PopupWindow {
    id: win

    property var service: null
    property Item anchorItem: null
    property var triggerWindow: null

    property bool shown: false
    property bool _render: false
    signal dismissed()

    // Dimmed label/detail color, derived from the theme foreground.
    readonly property color dim: Theme.subtext

    color: "transparent"
    anchor.item: anchorItem
    anchor.edges: Edges.Bottom
    anchor.gravity: Edges.Bottom | Edges.HCenter
    anchor.margins.top: 0
    anchor.adjustment: PopupAdjustment.Flip | PopupAdjustment.Slide

    readonly property int shadowMargin: 24
    // Gap kept between the bar and the visible card. The card is pulled up by
    // `nudge` within its window so most of the shadow gutter falls to the
    // bottom/sides instead of pushing the card away from the bar.
    readonly property int edgeGap: 3
    readonly property int nudge: shadowMargin - edgeGap
    readonly property int cardWidth: 400
    readonly property int innerWidth: cardWidth - Theme.pad * 2

    visible: _render
    implicitWidth: cardWidth + shadowMargin * 2
    implicitHeight: card.height + shadowMargin * 2

    onShownChanged: {
        if (shown) {
            _render = true
            if (service) service.refresh()
        } else {
            hideTimer.restart()
        }
    }
    Timer { id: hideTimer; interval: 170; onTriggered: win._render = false }

    HyprlandFocusGrab {
        windows: win.triggerWindow ? [win, win.triggerWindow] : [win]
        active: win.shown
        onCleared: win.dismissed()
    }

    Item {
        anchors.fill: parent

        Item {
            id: card
            x: win.shadowMargin
            width: win.cardWidth
            height: content.implicitHeight + Theme.pad * 2
            y: win.shown ? win.edgeGap : win.edgeGap - 16
            opacity: win.shown ? 1 : 0

            Behavior on y { NumberAnimation { duration: win.shown ? 200 : 150; easing.type: win.shown ? Easing.OutCubic : Easing.InCubic } }
            Behavior on opacity { NumberAnimation { duration: win.shown ? 200 : 140 } }

            MultiEffect {
                source: bg
                anchors.fill: bg
                z: -1
                autoPaddingEnabled: true
                shadowEnabled: true
                shadowColor: "#000000"
                shadowOpacity: 0.35
                shadowBlur: 0.45
                shadowVerticalOffset: 3
            }

            Rectangle {
                id: bg
                anchors.fill: parent
                radius: Theme.radius
                color: Theme.background
                layer.enabled: true
            }

            Item {
                anchors.fill: parent
                focus: win.shown
                Keys.onEscapePressed: win.dismissed()
            }

            ColumnLayout {
                id: content
                x: Theme.pad
                y: Theme.pad
                width: win.innerWidth
                spacing: 16

                // ---------------- hero ----------------
                Item {
                    Layout.fillWidth: true
                    implicitHeight: Math.max(heroLeft.implicitHeight, heroRight.implicitHeight)

                    // big icon + temperature
                    RowLayout {
                        id: heroLeft
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 12

                        Text {
                            text: win.service ? win.service.iconGlyph : ""
                            font.family: "Symbols Nerd Font"
                            font.pixelSize: 52
                            color: Theme.text
                            Layout.alignment: Qt.AlignVCenter
                        }
                        Row {
                            spacing: 2
                            Layout.alignment: Qt.AlignVCenter
                            Text {
                                id: tempBig
                                text: win.service && win.service.tempNum !== "" ? win.service.tempNum : "—"
                                color: Theme.text
                                font.pixelSize: 46
                                font.bold: true
                            }
                            Text {
                                text: win.service && win.service.available ? win.service.tempUnit : ""
                                color: Theme.text
                                font.pixelSize: 18
                                anchors.top: tempBig.top
                                anchors.topMargin: 8
                            }
                        }
                    }

                    // location + stats
                    ColumnLayout {
                        id: heroRight
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 12

                        Text {
                            Layout.alignment: Qt.AlignRight
                            visible: win.service && win.service.locationName !== ""
                            text: win.service ? win.service.locationName.toUpperCase() : ""
                            color: win.dim
                            font.pixelSize: 12
                            font.letterSpacing: 1
                            elide: Text.ElideRight
                        }

                        RowLayout {
                            Layout.alignment: Qt.AlignRight
                            visible: win.service && win.service.available
                            spacing: 22

                            Repeater {
                                model: [
                                    { k: "FEELS", v: win.service ? win.service.feelsText : "" },
                                    { k: "WIND",  v: win.service ? win.service.windText : "" },
                                    { k: "HUMID", v: win.service ? win.service.humidityText : "" }
                                ]
                                ColumnLayout {
                                    required property var modelData
                                    spacing: 4
                                    Text {
                                        text: modelData.k
                                        color: win.dim
                                        font.pixelSize: 10
                                        font.letterSpacing: 1
                                    }
                                    Text {
                                        text: modelData.v
                                        color: Theme.text
                                        font.pixelSize: 16
                                    }
                                }
                            }
                        }
                    }
                }

                // ---------------- loading / error ----------------
                Text {
                    Layout.fillWidth: true
                    visible: win.service && !win.service.available
                    text: win.service && win.service.lastError !== "" ? win.service.lastError : "Fetching forecast…"
                    color: win.dim
                    font.pixelSize: 12
                    font.italic: true
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.WordWrap
                }

                // ---------------- divider ----------------
                Rectangle {
                    Layout.fillWidth: true
                    height: 1
                    color: Theme.divider
                    visible: win.service && win.service.forecastDays.length > 0
                }

                // ---------------- forecast ----------------
                Item {
                    Layout.fillWidth: true
                    visible: win.service && win.service.forecastDays.length > 0
                    implicitHeight: forecastRow.implicitHeight

                    RowLayout {
                        id: forecastRow
                        anchors.horizontalCenter: parent.horizontalCenter
                        spacing: 26

                        Repeater {
                            model: win.service ? win.service.forecastDays : []
                            RowLayout {
                                required property var modelData
                                spacing: 8

                                Text {
                                    text: Model.dayIcon(modelData)
                                    font.family: "Symbols Nerd Font"
                                    font.pixelSize: 26
                                    color: Theme.text
                                    Layout.alignment: Qt.AlignVCenter
                                }
                                ColumnLayout {
                                    spacing: 2
                                    Text {
                                        text: Model.dayName(modelData.date).slice(0, 3).toUpperCase()
                                        color: win.dim
                                        font.pixelSize: 10
                                        font.letterSpacing: 1
                                    }
                                    RowLayout {
                                        spacing: 6
                                        Text {
                                            text: Model.bareTempForDay(modelData, "max", win.service.useImperial)
                                            color: Theme.text
                                            font.pixelSize: 13
                                            font.bold: true
                                        }
                                        Text {
                                            text: Model.bareTempForDay(modelData, "min", win.service.useImperial)
                                            color: win.dim
                                            font.pixelSize: 13
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

            }
        }
    }
}
