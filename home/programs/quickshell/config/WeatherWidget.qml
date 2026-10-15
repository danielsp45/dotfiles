// WeatherWidget.qml
// Center-bar weather element: a small weather glyph + current temperature that
// opens a detail popup on click. Owns the WeatherService (so the pill stays live
// whether or not the popup is open) and hosts the WeatherPopup.
//   left click   → toggle the popup
//   middle click → force a refresh
import QtQuick
import QtQuick.Layouts

RowLayout {
    id: root

    // The bar window, forwarded to the popup's focus grab so clicking the pill
    // to close doesn't count as an outside click.
    property var triggerWindow: null
    // Item the popup anchors to. Defaults to this pill; set it to a full-width
    // bar item to center the popup on the screen instead of under the pill.
    property Item popupAnchorItem: null
    property int fontPx: 12

    property bool popupShown: false

    spacing: Math.round(fontPx * 0.4)

    WeatherService { id: ts }

    Text {
        text: ts.available ? ts.iconGlyph : ""
        font.family: "Symbols Nerd Font"
        font.pixelSize: Math.round(root.fontPx * 1.15)
        color: "white"
        Layout.alignment: Qt.AlignVCenter
    }

    Text {
        text: ts.available ? ts.tempText : "—"
        font.pixelSize: root.fontPx
        font.bold: true
        color: "white"
        Layout.alignment: Qt.AlignVCenter
    }

    TapHandler {
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton
        onTapped: function(point, button) {
            if (button === Qt.MiddleButton) ts.refresh()
            else root.popupShown = !root.popupShown
        }
    }

    WeatherPopup {
        id: popup
        service: ts
        anchorItem: root.popupAnchorItem ? root.popupAnchorItem : root
        triggerWindow: root.triggerWindow
        shown: root.popupShown
        onDismissed: root.popupShown = false
    }
}
