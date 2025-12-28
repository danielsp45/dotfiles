// IoStatsWidget.qml
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io    // <- important

RowLayout {
    id: root
    spacing: 11

    // --- CPU --------------------------------------------------------------
    property double prevCpuTotal: 0
    property double prevCpuIdle: 0
    property int cpuPercent: 0
    property double cpuTemperature: 0.0
    // --- MEM --------------------------------------------------------------
    property double memUsedGiB: 0.0
    // --- DISK -------------------------------------------------------------
    property double diskUsedGiB: 0.0

    Text {
        // Nerd Font CPU icon
        text: "  " + cpuPercent + "%" + " | " + cpuTemperature + "°C" 
        color: "white"
        font.pixelSize: 11
        font.bold: true
    }

    Text {
        // RAM icon
        text: "  " + memUsedGiB.toFixed(1) + "GB"
        color: "white"
        font.pixelSize: 11
        font.bold: true
    }

    Text {
        // Disk icon
        text: "󰋊  " + diskUsedGiB.toFixed(1) + "GB"
        color: "white"
        font.pixelSize: 11
        font.bold: true
    }

    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: {
            cpuProc.running = true
            memProc.running = true
            diskProc.running = true
            tempProc.running = true
        }
    }

    // ---------------- CPU ----------------
    Process {
        id: cpuProc
        command: ["sh", "-c", "grep '^cpu ' /proc/stat"]
        running: false

        stdout: StdioCollector {
            onStreamFinished: {
                const line = text.trim()
                if (!line.length)
                    return

                const parts = line.split(/\s+/)
                // "cpu user nice system idle iowait irq softirq steal ..."
                const user    = Number(parts[1])
                const nice    = Number(parts[2])
                const system  = Number(parts[3])
                const idle    = Number(parts[4])
                const iowait  = Number(parts[5])
                const irq     = Number(parts[6])
                const softirq = Number(parts[7])
                const steal   = Number(parts[8])

                const idleAll = idle + iowait
                const nonIdle = user + nice + system + irq + softirq + steal
                const total   = idleAll + nonIdle

                if (root.prevCpuTotal > 0) {
                    const totald = total - root.prevCpuTotal
                    const idled  = idleAll - root.prevCpuIdle
                    if (totald > 0) {
                        root.cpuPercent = Math.round((totald - idled) * 100 / totald)
                    }
                }

                root.prevCpuTotal = total
                root.prevCpuIdle  = idleAll
            }
        }
    }

    // --------------- Temperature ----------------
    Process {
        id: tempProc
        command: ["sh", "-c", "~/.local/share/config/bin/get-cpu-temp"]
        running: false

        stdout: StdioCollector {
            onStreamFinished: {
                const t = Number(text.trim())
                if (!isNaN(t)) {
                    root.cpuTemperature = t
                }
            }
        }
    }

    // ---------------- Memory ----------------
    Process {
        id: memProc
        command: ["sh", "-c", "grep -E 'MemTotal:|MemAvailable:' /proc/meminfo"]
        running: false

        stdout: StdioCollector {
            onStreamFinished: {
                let total = 0
                let avail = 0
                const lines = text.trim().split("\n")
                for (let i = 0; i < lines.length; ++i) {
                    const parts = lines[i].trim().split(/\s+/)
                    if (parts[0] === "MemTotal:") {
                        total = Number(parts[1]) // kB
                    } else if (parts[0] === "MemAvailable:") {
                        avail = Number(parts[1]) // kB
                    }
                }
                if (total > 0) {
                    const usedKiB = total - avail
                    root.memUsedGiB = usedKiB / (1024 * 1024)
                }
            }
        }
    }

    // ---------------- Disk (/) ----------------
    Process {
        id: diskProc
        command: ["sh", "-c", "df -B1 / | tail -1 | awk '{print $3}'"]
        running: false

        stdout: StdioCollector {
            onStreamFinished: {
                const usedBytes = Number(text.trim())
                if (!isNaN(usedBytes)) {
                    root.diskUsedGiB = usedBytes / (1024 * 1024 * 1024)
                }
            }
        }
    }
}
