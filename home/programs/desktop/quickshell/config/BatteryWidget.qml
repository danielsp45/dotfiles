// BatteryWidget.qml
// Icon-only battery indicator for the bar (GNOME default). The percentage
// lives in the Quick Settings header; state comes from BatteryService.
import QtQuick
import "QuickSettings"

Item {
    id: root
    visible: BatteryService.available
    implicitWidth: batteryText.implicitWidth
    implicitHeight: batteryText.implicitHeight

    property int fontPx: 11

    Text {
        id: batteryText
        text: BatteryService.available ? BatteryService.glyph : ""
        color: BatteryService.pluggedIn ? "#33d17a"          // GNOME green
             : BatteryService.critical ? "#ff0000" : "white"
        font.pixelSize: root.fontPx
        font.bold: true
    }
}
