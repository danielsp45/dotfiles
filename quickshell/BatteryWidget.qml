// BatteryWidget.qml
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

Item {
    id: root
    visible: hasBattery
    implicitWidth: batteryText.implicitWidth
    implicitHeight: batteryText.implicitHeight

    property bool hasBattery: false
    property int batteryPercent: 0
    property bool isCharging: false

    Text {
        id: batteryText
        text: {
            if (!root.hasBattery) return ""

            let icon = ""
            if (root.isCharging) {
                icon = "󰂄"
            } else {
                // Battery discharge icons based on percentage
                if (root.batteryPercent >= 80) {
                    icon = "󰁹"      // Full
                } else if (root.batteryPercent >= 60) {
                    icon = "󰁾"      // 70%
                } else if (root.batteryPercent >= 40) {
                    icon = "󰁽"      // 50%
                } else if (root.batteryPercent >= 20) {
                    icon = "󰁼"      // 30%
                } else if (root.batteryPercent >= 10) {
                    icon = "󰁻"      // 10%
                } else {
                    icon = "󰁺"      // Empty/Critical
                }
            }

            return icon + " " + root.batteryPercent + "%"
        }
        color: root.batteryPercent < 10 && !root.isCharging ? "#ff0000" : "white"
        font.pixelSize: 11
        font.bold: true
    }

    // Check if battery exists on startup
    Process {
        id: batteryCheckProc
        command: ["sh", "-c", "test -d /sys/class/power_supply/BAT0 && echo 'yes' || echo 'no'"]
        running: true

        stdout: StdioCollector {
            onStreamFinished: {
                root.hasBattery = text.trim() === "yes"
                if (root.hasBattery) {
                    batteryTimer.running = true
                }
            }
        }
    }

    // Update battery stats every 5 seconds
    Timer {
        id: batteryTimer
        interval: 5000
        running: false
        repeat: true
        onTriggered: {
            batteryProc.running = true
            chargeProc.running = true
        }
    }

    // Get battery percentage
    Process {
        id: batteryProc
        command: ["sh", "-c", "cat /sys/class/power_supply/BAT0/capacity"]
        running: false

        stdout: StdioCollector {
            onStreamFinished: {
                const percent = Number(text.trim())
                if (!isNaN(percent)) {
                    root.batteryPercent = percent
                }
            }
        }
    }

    // Get charging status
    Process {
        id: chargeProc
        command: ["sh", "-c", "cat /sys/class/power_supply/BAT0/status"]
        running: false

        stdout: StdioCollector {
            onStreamFinished: {
                const status = text.trim()
                root.isCharging = (status === "Charging" || status === "Full")
            }
        }
    }
}
