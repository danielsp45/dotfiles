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
    property bool lowBatteryNotified: false

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
        interval: 1000
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
                    const oldPercent = root.batteryPercent
                    root.batteryPercent = percent

                    // Send notification when battery reaches 10% and not charging
                    if (percent <= 10 && !root.isCharging && !root.lowBatteryNotified) {
                        notifyProc.running = true
                        root.lowBatteryNotified = true
                    }

                    // Reset notification flag if battery goes above 15% or starts charging
                    if ((percent > 15 || root.isCharging) && root.lowBatteryNotified) {
                        root.lowBatteryNotified = false
                    }
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

    // Send low battery notification
    Process {
        id: notifyProc
        command: ["notify-send", "-i", "battery-caution", "Low Battery", "Battery is at " + root.batteryPercent + "%. Please plug in your charger."]
        running: false
    }
}
