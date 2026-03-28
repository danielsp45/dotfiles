// NetworkWidget.qml
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

RowLayout {
    id: root
    spacing: 4
    implicitHeight: networkText.implicitHeight

    property string networkLabel: ""

    Text {
        id: networkText
        text: root.networkLabel
        color: "white"
        font.pixelSize: 14
        font.bold: true
        visible: root.networkLabel !== ""
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: Quickshell.execDetached(["nm-connection-editor"])
    }

    Timer {
        id: poll
        running: true
        repeat: true
        interval: 5000
        onTriggered: networkProc.running = true
    }

    Process {
        id: networkProc
        // First section: device status (TYPE:DEVICE:STATE:CONNECTION)
        // Second section: active wifi entry (ACTIVE:SIGNAL:SSID) — only if wifi
        command: ["sh", "-c",
            "nmcli -t -f TYPE,DEVICE,STATE,CONNECTION device status; " +
            "echo '---'; " +
            "nmcli -t -f ACTIVE,SIGNAL,SSID dev wifi 2>/dev/null || true"
        ]
        running: true

        stdout: StdioCollector {
            onStreamFinished: {
                const sections = text.trim().split("---\n")
                const deviceLines = sections[0].trim().split("\n")
                const wifiLines   = sections.length > 1 ? sections[1].trim().split("\n") : []

                // Parse active wifi signal
                let wifiSignal = -1
                let wifiSsid   = ""
                for (let wl of wifiLines) {
                    const wp = wl.split(":")
                    if (wp.length >= 3 && wp[0].trim() === "yes") {
                        wifiSignal = parseInt(wp[1].trim()) || 0
                        wifiSsid   = wp.slice(2).join(":").trim()
                        break
                    }
                }

                function wifiIcon(signal) {
                    if (signal <= 20) return "󰤯"
                    if (signal <= 40) return "󰤟"
                    if (signal <= 60) return "󰤢"
                    if (signal <= 80) return "󰤥"
                    return "󰤨"
                }

                let label = ""
                for (let line of deviceLines) {
                    const parts = line.split(":")
                    if (parts.length < 3) continue
                    const type  = parts[0].trim()
                    const state = parts[2].trim()
                    if (state !== "connected") continue

                    if (type === "ethernet") {
                        label = "󰌗"   // solid ethernet plug icon
                        break
                    } else if (type === "wifi") {
                        const ssid = wifiSsid || parts.slice(3).join(":").trim()
                        label = wifiIcon(wifiSignal) + " " + ssid
                        break
                    }
                }

                root.networkLabel = label
            }
        }
    }
}
